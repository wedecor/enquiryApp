#!/usr/bin/env tsx
/**
 * Security Exposure Scanner
 * Scans the repository for exposed secrets, keys, and sensitive data
 */

import { glob } from 'glob';
import { readFileSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import path from 'path';

interface SecurityFinding {
  type: 'secret' | 'warning';
  severity: 'FAIL' | 'WARN';
  message: string;
  file?: string;
  line?: number;
  context?: string;
}

interface ScanResult {
  findings: SecurityFinding[];
  summary: {
    secrets: number;
    warnings: number;
    scannedFiles: number;
  };
}

class ExposureScanner {
  private findings: SecurityFinding[] = [];
  private scannedFiles = 0;

  // High-risk patterns to detect
  private readonly patterns = {
    // Google service account private keys
    privateKey: /-----BEGIN PRIVATE KEY-----/g,
    
    // Service account key components
    serviceAccountKeys: /"private_key"\s*:\s*"[^"]+"/g,
    clientEmail: /"client_email"\s*:\s*"[^"]+"/g,
    projectId: /"project_id"\s*:\s*"[^"]+"/g,
    
    // Environment variable references (potential exposure)
    googleCreds: /GOOGLE_APPLICATION_CREDENTIALS\s*[:=]\s*["'][^"']+["']/g,
    
    // FCM server keys (legacy format)
    fcmServerKey: /AAAA[0-9A-Za-z_\-]{100,}/g,
    
    // JWT/Access tokens
    accessToken: /ya29\.[0-9A-Za-z\-_\.]{50,}/g,
    
    // Password literals in code
    passwordLiteral: /password\s*[:=]\s*["'][^"']{3,}["']/gi,
    
    // VAPID private keys (should never be in repo)
    vapidPrivate: /-----BEGIN EC PRIVATE KEY-----/g,
    
    // Generic secrets
    apiSecret: /(secret|private).*[:=]\s*["'][0-9A-Za-z_\-]{20,}["']/gi,
    
    // Firebase tokens
    firebaseToken: /[0-9]:[0-9]+:web:[0-9a-f]{17}/g,
  };

  // Files and directories to ignore
  private readonly ignorePatterns = [
    'node_modules/**',
    '.dart_tool/**',
    '.git/**',
    'build/**',
    'lib/generated/**',
    'functions/lib/**',
    'web/assets/**',
    '*.min.*',
    '**/*.min.*',
    '.github/**',
    'coverage/**',
    'test_driver/**',
  ];

  async scan(): Promise<ScanResult> {
    console.log('🔍 Starting security exposure scan...\n');

    // Check if sensitive files are tracked by git
    await this.checkGitTrackedSecrets();

    // Scan all source files
    const files = await this.getFilesToScan();
    
    for (const file of files) {
      await this.scanFile(file);
    }

    return {
      findings: this.findings,
      summary: {
        secrets: this.findings.filter(f => f.severity === 'FAIL').length,
        warnings: this.findings.filter(f => f.severity === 'WARN').length,
        scannedFiles: this.scannedFiles,
      },
    };
  }

  private async getFilesToScan(): Promise<string[]> {
    const allFiles = await glob('**/*', {
      ignore: this.ignorePatterns,
      nodir: true,
    });

    // Filter for text files only
    return allFiles.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return [
        '.dart', '.ts', '.js', '.json', '.yaml', '.yml', 
        '.md', '.txt', '.env', '.config', '.conf',
        '.sh', '.bat', '.ps1', '.gradle', '.properties',
        '.xml', '.html', '.css', '.scss', '.vue', '.jsx', '.tsx'
      ].includes(ext) || !ext; // Include files without extension
    });
  }

  private async scanFile(filePath: string): Promise<void> {
    try {
      const content = readFileSync(filePath, 'utf8');
      this.scannedFiles++;

      const lines = content.split('\n');

      // Check each pattern
      Object.entries(this.patterns).forEach(([patternName, regex]) => {
        let match;
        while ((match = regex.exec(content)) !== null) {
          const lineNumber = content.substring(0, match.index).split('\n').length;
          const line = lines[lineNumber - 1]?.trim() || '';

          this.findings.push({
            type: 'secret',
            severity: this.getSeverityForPattern(patternName),
            message: this.getMessageForPattern(patternName),
            file: filePath,
            line: lineNumber,
            context: line.length > 100 ? line.substring(0, 97) + '...' : line,
          });
        }
        regex.lastIndex = 0; // Reset regex
      });

    } catch (error) {
      // Skip binary files or files we can't read
    }
  }

  private async checkGitTrackedSecrets(): Promise<void> {
    const sensitiveFiles = [
      'serviceAccountKey.json',
      'firebase-service-account.json',
      '.env',
      '.env.local',
      '.env.production',
      '.env.development',
    ];

    for (const file of sensitiveFiles) {
      if (existsSync(file)) {
        try {
          // Check if file is tracked by git
          execSync(`git ls-files --error-unmatch "${file}"`, { stdio: 'pipe' });
          
          this.findings.push({
            type: 'secret',
            severity: 'FAIL',
            message: `Sensitive file is tracked by git: ${file}`,
            file,
          });
        } catch {
          // File is not tracked by git, which is good
        }
      }
    }
  }

  private getSeverityForPattern(patternName: string): 'FAIL' | 'WARN' {
    const failPatterns = [
      'privateKey', 'fcmServerKey', 'accessToken', 
      'vapidPrivate', 'serviceAccountKeys'
    ];
    
    return failPatterns.includes(patternName) ? 'FAIL' : 'WARN';
  }

  private getMessageForPattern(patternName: string): string {
    const messages: Record<string, string> = {
      privateKey: 'Private key detected in source code',
      serviceAccountKeys: 'Service account credentials in source',
      clientEmail: 'Service account email in source',
      projectId: 'Project ID hardcoded in source',
      googleCreds: 'Google credentials path in source',
      fcmServerKey: 'FCM server key exposed in source',
      accessToken: 'Access token found in source',
      passwordLiteral: 'Password literal in source code',
      vapidPrivate: 'VAPID private key in repository',
      apiSecret: 'API secret or private key detected',
      firebaseToken: 'Firebase app token in source',
    };

    return messages[patternName] || `Potential secret detected: ${patternName}`;
  }

  printResults(result: ScanResult): void {
    console.log('📊 SECURITY EXPOSURE SCAN RESULTS');
    console.log('═'.repeat(50));
    console.log(`📁 Files scanned: ${result.summary.scannedFiles}`);
    console.log(`🚨 Critical issues: ${result.summary.secrets}`);
    console.log(`⚠️  Warnings: ${result.summary.warnings}`);
    console.log();

    if (result.findings.length === 0) {
      console.log('✅ No security exposures detected!');
      return;
    }

    // Group findings by severity
    const critical = result.findings.filter(f => f.severity === 'FAIL');
    const warnings = result.findings.filter(f => f.severity === 'WARN');

    if (critical.length > 0) {
      console.log('🚨 CRITICAL ISSUES (must fix):');
      console.log('-'.repeat(30));
      critical.forEach(finding => {
        console.log(`❌ ${finding.message}`);
        if (finding.file) {
          console.log(`   📍 ${finding.file}${finding.line ? `:${finding.line}` : ''}`);
        }
        if (finding.context) {
          console.log(`   💬 ${finding.context}`);
        }
        console.log();
      });
    }

    if (warnings.length > 0) {
      console.log('⚠️  WARNINGS (review recommended):');
      console.log('-'.repeat(30));
      warnings.forEach(finding => {
        console.log(`⚠️  ${finding.message}`);
        if (finding.file) {
          console.log(`   📍 ${finding.file}${finding.line ? `:${finding.line}` : ''}`);
        }
        if (finding.context) {
          console.log(`   💬 ${finding.context}`);
        }
        console.log();
      });
    }

    // Remediation suggestions
    if (result.summary.secrets > 0 || result.summary.warnings > 0) {
      console.log('🔧 REMEDIATION SUGGESTIONS:');
      console.log('-'.repeat(30));
      console.log('• Move all secrets to environment variables');
      console.log('• Add sensitive files to .gitignore');
      console.log('• Use git-secrets or similar tools in CI');
      console.log('• Rotate any exposed credentials immediately');
      console.log('• Review commit history for leaked secrets');
      console.log();
    }
  }

  exportJson(result: ScanResult): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      summary: result.summary,
      findings: result.findings.map(f => ({
        severity: f.severity,
        type: f.type,
        message: f.message,
        location: f.file ? `${f.file}${f.line ? `:${f.line}` : ''}` : undefined,
        context: f.context,
      })),
    }, null, 2);
  }
}

// Main execution
async function main() {
  const scanner = new ExposureScanner();
  
  try {
    const result = await scanner.scan();
    
    // Print human-readable results
    scanner.printResults(result);
    
    // Export JSON for CI/tooling
    const jsonOutput = scanner.exportJson(result);
    console.log('\n📋 JSON Report:');
    console.log(jsonOutput);
    
    // Exit with error code if critical issues found
    process.exit(result.summary.secrets > 0 ? 1 : 0);
    
  } catch (error) {
    console.error('❌ Security scan failed:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { ExposureScanner, SecurityFinding, ScanResult };
