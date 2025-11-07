#!/usr/bin/env tsx
/**
 * Refined Security Exposure Scanner
 * Precise detection of real secrets with minimal false positives
 */

import { glob } from 'glob';
import { readFileSync, existsSync } from 'fs';
import { execSync } from 'child_process';
import path from 'path';
import colors from 'picocolors';

interface SecurityFinding {
  type: 'secret' | 'warning';
  severity: 'FAIL' | 'WARN';
  message: string;
  file?: string;
  line?: number;
  context?: string;
  reason?: string;
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

  // Refined patterns for real secrets only
  private readonly patterns = {
    // Real private keys (with boundary checks)
    privateKey: /-----BEGIN PRIVATE KEY-----[\s\S]*?-----END PRIVATE KEY-----/g,
    
    // Service account credentials
    serviceAccountPrivateKey: /"private_key"\s*:\s*"-----BEGIN PRIVATE KEY-----[^"]*"/g,
    clientEmail: /"client_email"\s*:\s*"[^@]+@[^"]+\.gserviceaccount\.com"/g,
    
    // FCM server keys (legacy format)
    fcmServerKey: /AAAA[0-9A-Za-z_\-]{100,}/g,
    
    // JWT/Access tokens
    accessToken: /ya29\.[0-9A-Za-z\-_\.]{50,}/g,
    
    // VAPID private keys (should never be in repo)
    vapidPrivate: /-----BEGIN EC PRIVATE KEY-----[\s\S]*?-----END EC PRIVATE KEY-----/g,
  };

  // Precise file inclusion (not exclusion)
  private readonly includePatterns = [
    'lib/**/*.dart',
    'functions/src/**/*.ts',
    'functions/src/**/*.js',
    'scripts/**/*.ts',
    'scripts/**/*.js',
    'scripts/**/*.mjs',
    'firestore.rules',
    '*.yaml',
    '*.yml',
    'firebase.json',
    'pubspec.yaml',
  ];

  // Paths to exclude
  private readonly excludePatterns = [
    'scripts/security/**', // Don't scan security scripts themselves
    'scripts/refactors/**', // Don't scan refactoring tools
  ];

  async scan(): Promise<ScanResult> {
    console.log(colors.blue('🔍 Starting refined security exposure scan...\n'));

    // Check if sensitive files are tracked by git
    await this.checkGitTrackedSecrets();

    // Scan included files only
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
    const files = await glob(this.includePatterns, {
      nodir: true,
    });

    // Additional filtering for text files only
    return files.filter(file => {
      // Skip .md files entirely
      if (file.endsWith('.md')) return false;
      
      // Skip excluded paths
      if (this.excludePatterns.some(pattern => file.includes(pattern.replace('/**', '')))) {
        return false;
      }
      
      const ext = path.extname(file).toLowerCase();
      return [
        '.dart', '.ts', '.js', '.json', '.yaml', '.yml', 
        '.mjs', '.gradle', '.properties', '.xml'
      ].includes(ext) || !ext;
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

          // Skip comments and documentation
          if (this.isCommentOrDoc(line)) {
            continue;
          }

          // Check if it's a test fixture or safe value
          const isSafe = this.isSafeFixture(match[0], line);
          
          this.findings.push({
            type: 'secret',
            severity: isSafe ? 'WARN' : 'FAIL',
            message: this.getMessageForPattern(patternName),
            file: filePath,
            line: lineNumber,
            context: line.length > 100 ? line.substring(0, 97) + '...' : line,
            reason: isSafe ? 'likely test/fixture/comment' : undefined,
          });
        }
        regex.lastIndex = 0; // Reset regex
      });

    } catch (error) {
      // Skip binary files or files we can't read
    }
  }

  private isCommentOrDoc(line: string): boolean {
    const trimmed = line.trim();
    return trimmed.startsWith('//') || 
           trimmed.startsWith('#') || 
           trimmed.startsWith('*') ||
           trimmed.startsWith('///') ||
           trimmed.includes('TODO:') ||
           trimmed.includes('FIXME:') ||
           trimmed.includes('NOTE:');
  }

  private isSafeFixture(value: string, line: string): boolean {
    const safePatterns = [
      'AAAA_TEST_', 'FAKE_', 'DUMMY_', 'EXAMPLE_', 'PLACEHOLDER_',
      'your-', 'example.com', 'test@', 'localhost',
      'PASTE_', 'CHANGE_THIS_', 'TODO:', 'FIXME:'
    ];

    const lineLower = line.toLowerCase();
    const valueLower = value.toLowerCase();

    // Check for safe patterns
    if (safePatterns.some(pattern => 
      valueLower.includes(pattern.toLowerCase()) || 
      lineLower.includes(pattern.toLowerCase())
    )) {
      return true;
    }

    // Check if it's in a test/example context
    if (lineLower.includes('test') || 
        lineLower.includes('example') || 
        lineLower.includes('fixture') ||
        lineLower.includes('mock')) {
      return true;
    }

    return false;
  }

  private async checkGitTrackedSecrets(): Promise<void> {
    const sensitiveFiles = [
      'serviceAccountKey.json',
      'firebase-service-account.json',
      '.env',
      '.env.local',
      '.env.production',
      '.env.development',
      'config/.env.local',
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

  private getMessageForPattern(patternName: string): string {
    const messages: Record<string, string> = {
      privateKey: 'Private key detected in source code',
      serviceAccountPrivateKey: 'Service account private key in source',
      clientEmail: 'Service account email in source',
      fcmServerKey: 'FCM server key exposed in source',
      accessToken: 'Access token found in source',
      vapidPrivate: 'VAPID private key in repository',
    };

    return messages[patternName] || `Potential secret detected: ${patternName}`;
  }

  printResults(result: ScanResult): void {
    console.log(colors.bold(colors.blue('📊 REFINED SECURITY EXPOSURE SCAN')));
    console.log(colors.blue('═'.repeat(50)));
    console.log(`📁 Files scanned: ${result.summary.scannedFiles}`);
    console.log(`🚨 Real secrets: ${result.summary.secrets}`);
    console.log(`⚠️  Test/fixture warnings: ${result.summary.warnings}`);
    console.log();

    if (result.findings.length === 0) {
      console.log(colors.green('✅ No security exposures detected!'));
      return;
    }

    // Group findings by severity
    const critical = result.findings.filter(f => f.severity === 'FAIL');
    const warnings = result.findings.filter(f => f.severity === 'WARN');

    if (critical.length > 0) {
      console.log(colors.red(colors.bold('🚨 REAL SECRETS (must fix):')));
      console.log('-'.repeat(40));
      critical.forEach((finding, index) => {
        console.log(`${index + 1}. ${colors.red('❌')} ${finding.message}`);
        if (finding.file) {
          console.log(`   📍 ${finding.file}${finding.line ? `:${finding.line}` : ''}`);
        }
        if (finding.context) {
          console.log(`   💬 ${colors.dim(finding.context)}`);
        }
        console.log();
      });
    }

    if (warnings.length > 0) {
      console.log(colors.yellow(colors.bold('⚠️  TEST/FIXTURE WARNINGS (review):')));
      console.log('-'.repeat(40));
      warnings.forEach((finding, index) => {
        console.log(`${index + 1}. ${colors.yellow('⚠️')} ${finding.message}`);
        if (finding.reason) {
          console.log(`   💡 ${colors.dim(finding.reason)}`);
        }
        if (finding.file) {
          console.log(`   📍 ${finding.file}${finding.line ? `:${finding.line}` : ''}`);
        }
        console.log();
      });
    }

    // Remediation for real secrets only
    if (result.summary.secrets > 0) {
      console.log(colors.bold('🔧 IMMEDIATE ACTION REQUIRED:'));
      console.log('-'.repeat(35));
      console.log('• Move secrets to environment variables immediately');
      console.log('• Rotate any exposed credentials');
      console.log('• Add sensitive files to .gitignore');
      console.log('• Audit git history for leaked secrets');
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
        reason: f.reason,
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
    console.log(colors.dim('\n📋 JSON Report:'));
    console.log(colors.dim(jsonOutput));
    
    // Exit with error code only if real secrets found
    process.exit(result.summary.secrets > 0 ? 1 : 0);
    
  } catch (error) {
    console.error(colors.red('❌ Security scan failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { ExposureScanner, SecurityFinding, ScanResult };