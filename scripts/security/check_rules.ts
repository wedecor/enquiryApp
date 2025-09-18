#!/usr/bin/env tsx
/**
 * Firestore Security Rules Analyzer
 * Checks for common security pitfalls in Firestore rules
 */

import { readFileSync, existsSync } from 'fs';
import { glob } from 'glob';

interface RuleFinding {
  severity: 'FAIL' | 'WARN' | 'INFO';
  rule: string;
  message: string;
  line?: number;
  remediation?: string;
}

interface RulesAnalysis {
  findings: RuleFinding[];
  summary: {
    critical: number;
    warnings: number;
    info: number;
  };
}

class FirestoreRulesChecker {
  private findings: RuleFinding[] = [];
  private rulesContent = '';
  private hasUserTokenStorage = false;

  async analyze(): Promise<RulesAnalysis> {
    console.log('🔒 Analyzing Firestore security rules...\n');

    // Check if rules file exists
    if (!existsSync('firestore.rules')) {
      this.findings.push({
        severity: 'FAIL',
        rule: 'missing-rules',
        message: 'firestore.rules file not found',
        remediation: 'Create firestore.rules with proper security rules',
      });
      return this.getResults();
    }

    // Read and analyze rules
    this.rulesContent = readFileSync('firestore.rules', 'utf8');
    
    // Check for token storage patterns in codebase
    await this.checkTokenStoragePatterns();
    
    // Analyze rules
    this.checkBasicRuleSafety();
    this.checkUserCollectionSecurity();
    this.checkNotificationsSecurity();
    this.checkDropdownsSecurity();
    this.checkFunctionSecurity();
    
    return this.getResults();
  }

  private async checkTokenStoragePatterns(): Promise<void> {
    try {
      const dartFiles = await glob('lib/**/*.dart');
      
      for (const file of dartFiles) {
        const content = readFileSync(file, 'utf8');
        
        // Check if code writes fcmToken to users collection (more precise check)
        if ((content.includes("collection('users')") || content.includes('collection("users")')) && 
            (content.includes("'fcmToken'") || content.includes('"fcmToken"') || 
             content.includes("'webTokens'") || content.includes('"webTokens"'))) {
          // Additional check: ensure it's actually setting these fields
          if (content.includes('.set(') || content.includes('.update(')) {
            this.hasUserTokenStorage = true;
            break;
          }
        }
      }
    } catch (error) {
      // Ignore scan errors
    }
  }

  private checkBasicRuleSafety(): void {
    const lines = this.rulesContent.split('\n');
    
    lines.forEach((line, index) => {
      const trimmed = line.trim();
      
      // Check for overly permissive rules
      if (trimmed.includes('allow read: if true')) {
        this.findings.push({
          severity: 'FAIL',
          rule: 'overly-permissive-read',
          message: 'Unconditional read access detected',
          line: index + 1,
          remediation: 'Replace with proper authentication checks',
        });
      }
      
      if (trimmed.includes('allow write: if true')) {
        this.findings.push({
          severity: 'FAIL',
          rule: 'overly-permissive-write',
          message: 'Unconditional write access detected',
          line: index + 1,
          remediation: 'Replace with proper authorization checks',
        });
      }

      // Check for missing authentication
      if (trimmed.includes('allow') && !trimmed.includes('request.auth')) {
        if (!trimmed.includes('isSignedIn()') && !trimmed.includes('isAdmin()')) {
          this.findings.push({
            severity: 'WARN',
            rule: 'missing-auth-check',
            message: 'Rule may be missing authentication check',
            line: index + 1,
            remediation: 'Ensure proper authentication is required',
          });
        }
      }
    });
  }

  private checkUserCollectionSecurity(): void {
    const userRulePattern = /match\s+\/users\/\{uid\}/;
    const userRuleMatch = this.rulesContent.match(userRulePattern);
    
    if (!userRuleMatch) {
      this.findings.push({
        severity: 'WARN',
        rule: 'missing-user-rules',
        message: 'No specific rules found for users collection',
        remediation: 'Add explicit rules for users/{uid} documents',
      });
      return;
    }

    // Check if users collection allows read to all signed-in users
    // and we detected token storage
    if (this.hasUserTokenStorage) {
      const userSection = this.extractRuleSection('users');
      if (userSection.includes('allow read: if isSignedIn()') || 
          userSection.includes('allow read: if request.auth != null')) {
        
        this.findings.push({
          severity: 'FAIL',
          rule: 'token-exposure-risk',
          message: 'FCM tokens stored in publicly readable users collection',
          remediation: `Move FCM tokens to private subcollection:
          
RECOMMENDED STRUCTURE:
users/{uid}                           # public profile data only
users/{uid}/private/notifications/   # FCM tokens (owner-only access)

RULES FIX:
match /users/{uid}/private/notifications/{tokenId} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}`,
        });
      }
    }
  }

  private checkNotificationsSecurity(): void {
    const notificationPattern = /match\s+\/notifications\/\{uid\}\/items\/\{nid\}/;
    
    if (this.rulesContent.match(notificationPattern)) {
      const notificationSection = this.extractRuleSection('notifications');
      
      // Check if notifications are properly restricted to owner
      if (!notificationSection.includes('request.auth.uid == uid')) {
        this.findings.push({
          severity: 'FAIL',
          rule: 'notification-access-leak',
          message: 'Notifications may be readable by wrong users',
          remediation: 'Ensure notifications are only readable by owner: request.auth.uid == uid',
        });
      }
    }
  }

  private checkDropdownsSecurity(): void {
    const dropdownPattern = /match\s+\/dropdowns/;
    
    if (this.rulesContent.match(dropdownPattern)) {
      const dropdownSection = this.extractRuleSection('dropdowns');
      
      // Check if dropdowns allow write without admin check
      if (dropdownSection.includes('allow write:') && 
          !dropdownSection.includes('isAdmin()')) {
        this.findings.push({
          severity: 'WARN',
          rule: 'dropdown-write-access',
          message: 'Dropdowns may allow write access without admin check',
          remediation: 'Restrict dropdown writes to admin users only',
        });
      }
    }
  }

  private checkFunctionSecurity(): void {
    // Check if there are any function-related security configurations
    try {
      const functionFiles = glob.sync('functions/src/**/*.ts');
      let hasGlobalOptions = false;
      
      for (const file of functionFiles) {
        const content = readFileSync(file, 'utf8');
        if (content.includes('setGlobalOptions')) {
          hasGlobalOptions = true;
          
          // Check for reasonable memory limits
          if (content.includes('memory:') || content.includes('memoryMiB:')) {
            const memoryMatch = content.match(/memory(?:MiB)?:\s*["']?(\d+)/);
            if (memoryMatch) {
              const memory = parseInt(memoryMatch[1]);
              if (memory > 512) {
                this.findings.push({
                  severity: 'WARN',
                  rule: 'high-memory-function',
                  message: `Function uses ${memory}MB memory - consider if necessary`,
                  remediation: 'Use minimal memory to reduce abuse potential',
                });
              }
            }
          }
          
          // Check for timeout settings
          if (!content.includes('timeoutSeconds')) {
            this.findings.push({
              severity: 'INFO',
              rule: 'missing-timeout',
              message: 'Function missing explicit timeout setting',
              remediation: 'Add timeoutSeconds to prevent long-running abuse',
            });
          }
        }
      }
      
      if (!hasGlobalOptions && functionFiles.length > 0) {
        this.findings.push({
          severity: 'WARN',
          rule: 'missing-global-options',
          message: 'Cloud Functions missing setGlobalOptions configuration',
          remediation: 'Add setGlobalOptions with region, memory, and timeout limits',
        });
      }
    } catch (error) {
      // Ignore function scan errors
    }
  }

  private extractRuleSection(collection: string): string {
    const lines = this.rulesContent.split('\n');
    const sectionStart = lines.findIndex(line => 
      line.includes(`match `) && line.includes(`/${collection}/`)
    );
    
    if (sectionStart === -1) return '';
    
    let braceCount = 0;
    let sectionEnd = sectionStart;
    
    for (let i = sectionStart; i < lines.length; i++) {
      const line = lines[i];
      braceCount += (line.match(/\{/g) || []).length;
      braceCount -= (line.match(/\}/g) || []).length;
      
      if (braceCount === 0 && i > sectionStart) {
        sectionEnd = i;
        break;
      }
    }
    
    return lines.slice(sectionStart, sectionEnd + 1).join('\n');
  }

  private getResults(): RulesAnalysis {
    return {
      findings: this.findings,
      summary: {
        critical: this.findings.filter(f => f.severity === 'FAIL').length,
        warnings: this.findings.filter(f => f.severity === 'WARN').length,
        info: this.findings.filter(f => f.severity === 'INFO').length,
      },
    };
  }

  printResults(analysis: RulesAnalysis): void {
    console.log('📋 FIRESTORE RULES ANALYSIS');
    console.log('═'.repeat(40));
    console.log(`🚨 Critical issues: ${analysis.summary.critical}`);
    console.log(`⚠️  Warnings: ${analysis.summary.warnings}`);
    console.log(`ℹ️  Info: ${analysis.summary.info}`);
    console.log();

    if (analysis.findings.length === 0) {
      console.log('✅ No rule security issues detected!');
      return;
    }

    // Group by severity
    const critical = analysis.findings.filter(f => f.severity === 'FAIL');
    const warnings = analysis.findings.filter(f => f.severity === 'WARN');
    const info = analysis.findings.filter(f => f.severity === 'INFO');

    if (critical.length > 0) {
      console.log('🚨 CRITICAL SECURITY ISSUES:');
      console.log('-'.repeat(30));
      critical.forEach(finding => {
        console.log(`❌ ${finding.message}`);
        if (finding.line) {
          console.log(`   📍 firestore.rules:${finding.line}`);
        }
        if (finding.remediation) {
          console.log(`   🔧 Fix: ${finding.remediation}`);
        }
        console.log();
      });
    }

    if (warnings.length > 0) {
      console.log('⚠️  SECURITY WARNINGS:');
      console.log('-'.repeat(30));
      warnings.forEach(finding => {
        console.log(`⚠️  ${finding.message}`);
        if (finding.line) {
          console.log(`   📍 firestore.rules:${finding.line}`);
        }
        if (finding.remediation) {
          console.log(`   🔧 Suggestion: ${finding.remediation}`);
        }
        console.log();
      });
    }

    if (info.length > 0) {
      console.log('ℹ️  INFORMATION:');
      console.log('-'.repeat(30));
      info.forEach(finding => {
        console.log(`ℹ️  ${finding.message}`);
        if (finding.remediation) {
          console.log(`   💡 Tip: ${finding.remediation}`);
        }
        console.log();
      });
    }
  }

  exportJson(analysis: RulesAnalysis): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      summary: analysis.summary,
      findings: analysis.findings,
    }, null, 2);
  }
}

// Main execution
async function main() {
  const checker = new FirestoreRulesChecker();
  
  try {
    const analysis = await checker.analyze();
    
    // Print results
    checker.printResults(analysis);
    
    // Export JSON
    const jsonOutput = checker.exportJson(analysis);
    console.log('\n📋 JSON Report:');
    console.log(jsonOutput);
    
    // Exit with error if critical issues
    process.exit(analysis.summary.critical > 0 ? 1 : 0);
    
  } catch (error) {
    console.error('❌ Rules analysis failed:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { FirestoreRulesChecker, RuleFinding, RulesAnalysis };
