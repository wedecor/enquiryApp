#!/usr/bin/env tsx
/**
 * Risky Logging Checker
 * Scans for potentially dangerous logging that might expose sensitive data
 */

import { glob } from 'glob';
import { readFileSync } from 'fs';
import path from 'path';

interface LogFinding {
  severity: 'WARN' | 'INFO';
  message: string;
  file: string;
  line: number;
  context: string;
  suggestion: string;
}

interface LogAnalysis {
  findings: LogFinding[];
  summary: {
    riskyLogs: number;
    scannedFiles: number;
  };
}

class RiskyLoggingChecker {
  private findings: LogFinding[] = [];
  private scannedFiles = 0;

  // Patterns for risky logging
  private readonly logPatterns = {
    // Log functions to check
    logFunctions: [
      'logger.info', 'logger.debug', 'logger.warn', 'logger.error',
      'print', 'console.log', 'console.debug', 'console.info',
      'console.warn', 'console.error', 'debugPrint'
    ],
    
    // Sensitive data patterns
    sensitivePatterns: [
      'token', 'authorization', 'cookie', 'set-cookie', 
      'secret', 'private', 'key', 'password', 'auth',
      'bearer', 'jwt', 'session', 'credential'
    ],
  };

  // Files to ignore
  private readonly ignorePatterns = [
    'node_modules/**',
    '.dart_tool/**',
    '.git/**',
    'build/**',
    'functions/lib/**',
    'coverage/**',
    '**/*.min.*',
    'scripts/security/**', // Don't scan ourselves
  ];

  async analyze(): Promise<LogAnalysis> {
    console.log('📝 Scanning for risky logging patterns...\n');

    const files = await this.getFilesToScan();
    
    for (const file of files) {
      await this.scanFile(file);
    }

    return {
      findings: this.findings,
      summary: {
        riskyLogs: this.findings.length,
        scannedFiles: this.scannedFiles,
      },
    };
  }

  private async getFilesToScan(): Promise<string[]> {
    const allFiles = await glob('**/*', {
      ignore: this.ignorePatterns,
      nodir: true,
    });

    // Filter for source code files
    return allFiles.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return [
        '.dart', '.ts', '.js', '.tsx', '.jsx',
        '.java', '.kt', '.swift', '.m', '.mm',
        '.py', '.rb', '.go', '.rs', '.php',
        '.c', '.cpp', '.h', '.hpp'
      ].includes(ext);
    });
  }

  private async scanFile(filePath: string): Promise<void> {
    try {
      const content = readFileSync(filePath, 'utf8');
      this.scannedFiles++;

      const lines = content.split('\n');

      lines.forEach((line, index) => {
        this.checkLineForRiskyLogging(line, filePath, index + 1);
      });

    } catch (error) {
      // Skip files we can't read
    }
  }

  private checkLineForRiskyLogging(line: string, file: string, lineNumber: number): void {
    const trimmedLine = line.trim();
    
    // Skip comments (basic detection)
    if (trimmedLine.startsWith('//') || trimmedLine.startsWith('*') || 
        trimmedLine.startsWith('#')) {
      return;
    }

    // Check if line contains a logging function
    const hasLogFunction = this.logPatterns.logFunctions.some(func => 
      trimmedLine.includes(func)
    );

    if (!hasLogFunction) {
      return;
    }

    // Check if the log line contains sensitive patterns
    const sensitiveMatches = this.logPatterns.sensitivePatterns.filter(pattern => 
      trimmedLine.toLowerCase().includes(pattern.toLowerCase())
    );

    if (sensitiveMatches.length > 0) {
      // Determine severity based on context
      const severity = this.determineSeverity(trimmedLine, sensitiveMatches);
      
      this.findings.push({
        severity,
        message: `Potentially risky logging detected: ${sensitiveMatches.join(', ')}`,
        file,
        line: lineNumber,
        context: trimmedLine.length > 120 ? trimmedLine.substring(0, 117) + '...' : trimmedLine,
        suggestion: this.getSuggestion(trimmedLine, sensitiveMatches),
      });
    }
  }

  private determineSeverity(line: string, matches: string[]): 'WARN' | 'INFO' {
    const highRiskPatterns = ['token', 'secret', 'private', 'password', 'authorization'];
    const hasHighRisk = matches.some(match => 
      highRiskPatterns.includes(match.toLowerCase())
    );

    // Check if it's likely just a variable name or safe logging
    const seemsSafe = line.includes('length') || 
                      line.includes('count') || 
                      line.includes('size') ||
                      line.includes('type') ||
                      line.includes('null') ||
                      line.includes('undefined');

    return hasHighRisk && !seemsSafe ? 'WARN' : 'INFO';
  }

  private getSuggestion(line: string, matches: string[]): string {
    const suggestions = [];

    if (matches.includes('token') || matches.includes('authorization')) {
      suggestions.push('Consider logging token length/type instead of value');
    }

    if (matches.includes('password')) {
      suggestions.push('Never log passwords - remove or mask completely');
    }

    if (matches.includes('secret') || matches.includes('private')) {
      suggestions.push('Avoid logging secrets - use generic success/failure messages');
    }

    if (matches.includes('key')) {
      suggestions.push('Log key names/types, not values');
    }

    if (suggestions.length === 0) {
      suggestions.push('Review if sensitive data could be exposed in logs');
    }

    return suggestions.join('. ');
  }

  printResults(analysis: LogAnalysis): void {
    console.log('📊 RISKY LOGGING ANALYSIS');
    console.log('═'.repeat(40));
    console.log(`📁 Files scanned: ${analysis.summary.scannedFiles}`);
    console.log(`⚠️  Risky logs found: ${analysis.summary.riskyLogs}`);
    console.log();

    if (analysis.findings.length === 0) {
      console.log('✅ No risky logging patterns detected!');
      return;
    }

    // Group by severity
    const warnings = analysis.findings.filter(f => f.severity === 'WARN');
    const info = analysis.findings.filter(f => f.severity === 'INFO');

    if (warnings.length > 0) {
      console.log('⚠️  HIGH RISK LOGGING:');
      console.log('-'.repeat(30));
      warnings.forEach(finding => {
        console.log(`⚠️  ${finding.message}`);
        console.log(`   📍 ${finding.file}:${finding.line}`);
        console.log(`   💬 ${finding.context}`);
        console.log(`   🔧 ${finding.suggestion}`);
        console.log();
      });
    }

    if (info.length > 0) {
      console.log('ℹ️  REVIEW RECOMMENDED:');
      console.log('-'.repeat(30));
      info.forEach(finding => {
        console.log(`ℹ️  ${finding.message}`);
        console.log(`   📍 ${finding.file}:${finding.line}`);
        console.log(`   💬 ${finding.context}`);
        console.log(`   💡 ${finding.suggestion}`);
        console.log();
      });
    }

    // General recommendations
    console.log('🔧 LOGGING SECURITY BEST PRACTICES:');
    console.log('-'.repeat(30));
    console.log('• Log events and outcomes, not sensitive data');
    console.log('• Use structured logging with sanitized fields');
    console.log('• Log token/key lengths or types, never values');
    console.log('• Implement log sanitization in production');
    console.log('• Regularly audit logs for accidental exposures');
    console.log();
  }

  exportJson(analysis: LogAnalysis): string {
    return JSON.stringify({
      timestamp: new Date().toISOString(),
      summary: analysis.summary,
      findings: analysis.findings,
    }, null, 2);
  }
}

// Main execution
async function main() {
  const checker = new RiskyLoggingChecker();
  
  try {
    const analysis = await checker.analyze();
    
    // Print results
    checker.printResults(analysis);
    
    // Export JSON
    const jsonOutput = checker.exportJson(analysis);
    console.log('\n📋 JSON Report:');
    console.log(jsonOutput);
    
    // Always exit 0 for logging checks (warnings only)
    process.exit(0);
    
  } catch (error) {
    console.error('❌ Log analysis failed:', error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { RiskyLoggingChecker, LogFinding, LogAnalysis };
