#!/usr/bin/env tsx
/**
 * Precise Firestore Security Rules Analyzer
 * Detects actual FCM token writes to users collection with exact statement matching
 */

import { readFileSync, existsSync } from 'fs';
import { glob } from 'glob';
import colors from 'picocolors';

interface RuleFinding {
  severity: 'FAIL' | 'WARN' | 'INFO';
  rule: string;
  message: string;
  file?: string;
  line?: number;
  context?: string;
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

  async analyze(): Promise<RulesAnalysis> {
    console.log(colors.blue('🔒 Analyzing Firestore security rules...\n'));

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
    
    // Check for precise FCM token write patterns
    await this.checkPreciseFcmTokenWrites();
    
    // Analyze rules structure
    this.checkBasicRuleSafety();
    this.checkUserCollectionSecurity();
    this.checkNotificationsSecurity();
    this.checkFunctionSecurity();
    
    return this.getResults();
  }

  private async checkPreciseFcmTokenWrites(): Promise<void> {
    try {
      const dartFiles = await glob('lib/**/*.dart');
      
      for (const file of dartFiles) {
        const content = readFileSync(file, 'utf8');
        const lines = content.split('\n');
        
        // Look for exact pattern: collection('users').doc(...).set/update with fcmToken/webTokens
        // Check for the pattern across multiple lines to capture the full object
        const usersCollectionMatches = content.match(/collection\(['"]users['"]\)\.doc\([^)]+\)\.(set|update)\s*\(/g);
        
        if (usersCollectionMatches) {
          // For each match, check if the subsequent object contains fcmToken/webTokens
          usersCollectionMatches.forEach(match => {
            const matchIndex = content.indexOf(match);
            const afterMatch = content.substring(matchIndex);
            
            // Find the object being set (look for the opening brace and match closing)
            const objectStart = afterMatch.indexOf('{');
            if (objectStart === -1) return;
            
            let braceCount = 0;
            let objectEnd = objectStart;
            
            for (let i = objectStart; i < afterMatch.length; i++) {
              if (afterMatch[i] === '{') braceCount++;
              if (afterMatch[i] === '}') braceCount--;
              if (braceCount === 0) {
                objectEnd = i;
                break;
              }
            }
            
            const objectContent = afterMatch.substring(objectStart, objectEnd + 1);
            
            // Check if this object actually contains fcmToken or webTokens as properties
            if (objectContent.includes("'fcmToken'") || 
                objectContent.includes('"fcmToken"') || 
                objectContent.includes("'webTokens'") || 
                objectContent.includes('"webTokens"')) {
              
              const lineNumber = content.substring(0, matchIndex).split('\n').length;
              const line = lines[lineNumber - 1]?.trim() || '';
              
              // Skip if it's a comment
              if (line.startsWith('//') || line.startsWith('*')) {
                return;
              }
              
              this.findings.push({
                severity: 'FAIL',
                rule: 'fcm-token-write-to-users',
                message: 'FCM token write to publicly readable users collection detected',
                file,
                line: lineNumber,
                context: line,
                remediation: 'Move FCM tokens to users/{uid}/private/notifications/tokens/ subcollection',
              });
            }
          });
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
          context: trimmed,
          remediation: 'Replace with proper authentication checks',
        });
      }
      
      if (trimmed.includes('allow write: if true')) {
        this.findings.push({
          severity: 'FAIL',
          rule: 'overly-permissive-write',
          message: 'Unconditional write access detected',
          line: index + 1,
          context: trimmed,
          remediation: 'Replace with proper authorization checks',
        });
      }
    });
  }

  private checkUserCollectionSecurity(): void {
    // Check if private token subcollection is properly secured
    const privateTokenPattern = /match\s+\/users\/\{uid\}\/private\/notifications\/tokens\/\{tid\}/;
    
    if (this.rulesContent.match(privateTokenPattern)) {
      const tokenSection = this.extractRuleSection('users/{uid}/private/notifications/tokens');
      
      if (!tokenSection.includes('request.auth.uid == uid')) {
        this.findings.push({
          severity: 'FAIL',
          rule: 'token-access-not-restricted',
          message: 'Private token collection not properly restricted to owner',
          remediation: 'Ensure: allow read, write: if request.auth != null && request.auth.uid == uid',
        });
      } else {
        // Good - private tokens are properly secured
        this.findings.push({
          severity: 'INFO',
          rule: 'private-tokens-secured',
          message: 'FCM tokens properly secured in private subcollection',
        });
      }
    }
  }

  private checkNotificationsSecurity(): void {
    const notificationPattern = /match\s+\/notifications\/\{uid\}\/items\/\{nid\}/;
    
    if (this.rulesContent.match(notificationPattern)) {
      const notificationSection = this.extractRuleSection('notifications');
      
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

  private checkFunctionSecurity(): void {
    try {
      const functionFiles = glob.sync('functions/src/**/*.ts');
      let hasGlobalOptions = false;
      
      for (const file of functionFiles) {
        const content = readFileSync(file, 'utf8');
        if (content.includes('setGlobalOptions')) {
          hasGlobalOptions = true;
          
          // Check for reasonable memory limits
          if (content.includes('memory:') && !content.includes('128MiB')) {
            const memoryMatch = content.match(/memory:\s*["']?(\d+)/);
            if (memoryMatch) {
              const memory = parseInt(memoryMatch[1]);
              if (memory > 512) {
                this.findings.push({
                  severity: 'WARN',
                  rule: 'high-memory-function',
                  message: `Function uses ${memory}MB memory - consider if necessary`,
                  file,
                  remediation: 'Use minimal memory (128MiB) to reduce abuse potential',
                });
              }
            }
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

  private extractRuleSection(matchPattern: string): string {
    const lines = this.rulesContent.split('\n');
    const sectionStart = lines.findIndex(line => 
      line.includes('match ') && line.includes(matchPattern)
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
    console.log(colors.bold(colors.blue('📋 FIRESTORE RULES ANALYSIS')));
    console.log(colors.blue('═'.repeat(40)));
    console.log(`🚨 Critical issues: ${analysis.summary.critical}`);
    console.log(`⚠️  Warnings: ${analysis.summary.warnings}`);
    console.log(`ℹ️  Info: ${analysis.summary.info}`);
    console.log();

    if (analysis.findings.length === 0) {
      console.log(colors.green('✅ No rule security issues detected!'));
      return;
    }

    // Group by severity
    const critical = analysis.findings.filter(f => f.severity === 'FAIL');
    const warnings = analysis.findings.filter(f => f.severity === 'WARN');
    const info = analysis.findings.filter(f => f.severity === 'INFO');

    if (critical.length > 0) {
      console.log(colors.red(colors.bold('🚨 CRITICAL SECURITY ISSUES:')));
      console.log('-'.repeat(35));
      critical.forEach(finding => {
        console.log(`${colors.red('❌')} ${finding.message}`);
        if (finding.file && finding.line) {
          console.log(`   📍 ${finding.file}:${finding.line}`);
        }
        if (finding.context) {
          console.log(`   💬 ${colors.dim(finding.context)}`);
        }
        if (finding.remediation) {
          console.log(`   🔧 Fix: ${finding.remediation}`);
        }
        console.log();
      });
    }

    if (warnings.length > 0) {
      console.log(colors.yellow(colors.bold('⚠️  SECURITY WARNINGS:')));
      console.log('-'.repeat(25));
      warnings.forEach(finding => {
        console.log(`${colors.yellow('⚠️')} ${finding.message}`);
        if (finding.remediation) {
          console.log(`   💡 ${finding.remediation}`);
        }
        console.log();
      });
    }

    if (info.length > 0) {
      console.log(colors.green(colors.bold('ℹ️  SECURITY STATUS:')));
      console.log('-'.repeat(20));
      info.forEach(finding => {
        console.log(`${colors.green('✅')} ${finding.message}`);
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
    console.log(colors.dim('\n📋 JSON Report:'));
    console.log(colors.dim(jsonOutput));
    
    // Exit with error only if critical issues
    process.exit(analysis.summary.critical > 0 ? 1 : 0);
    
  } catch (error) {
    console.error(colors.red('❌ Rules analysis failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { FirestoreRulesChecker, RuleFinding, RulesAnalysis };