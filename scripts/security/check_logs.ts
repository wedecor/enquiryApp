#!/usr/bin/env tsx
/**
 * Precise Risky Logging Checker
 * Detects actual sensitive data exposure in logs with minimal false positives
 */

import { glob } from 'glob';
import { readFileSync } from 'fs';
import path from 'path';
import colors from 'picocolors';

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

  // Sensitive data patterns
  private readonly sensitivePatterns = [
    'token', 'authorization', 'cookie', 'secret', 
    'private', 'key', 'password', 'auth'
  ];

  // Only scan these specific paths
  private readonly includePatterns = [
    'lib/**/*.dart',
    'functions/src/**/*.ts',
    'functions/src/**/*.js',
  ];

  async analyze(): Promise<LogAnalysis> {
    console.log(colors.blue('📝 Scanning for risky logging patterns...\n'));

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
    return await glob(this.includePatterns, {
      nodir: true,
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
    
    // Skip comments and documentation
    if (trimmedLine.startsWith('//') || trimmedLine.startsWith('*') || 
        trimmedLine.startsWith('#') || trimmedLine.startsWith('///')) {
      return;
    }

    // Check for logging functions
    const logFunctionPattern = /(print|debugPrint|console\.\w+|logger\.\w+)\s*\(/;
    const logMatch = trimmedLine.match(logFunctionPattern);
    
    if (!logMatch) {
      return;
    }

    // Check if line contains sensitive patterns AND dynamic values
    const hasSensitivePattern = this.sensitivePatterns.some(pattern => 
      trimmedLine.toLowerCase().includes(pattern.toLowerCase())
    );

    if (!hasSensitivePattern) {
      return;
    }

    // Check if it's logging dynamic values (variables, interpolation)
    const hasDynamicValue = trimmedLine.includes('$') || // Dart interpolation
                           trimmedLine.includes('${') || // Template literals
                           trimmedLine.includes('`') ||  // Template strings
                           /\w+\.\w+/.test(trimmedLine); // Object properties

    if (!hasDynamicValue) {
      // Static text like "no token found" is just INFO
      this.findings.push({
        severity: 'INFO',
        message: `Static log with sensitive keyword: ${this.extractSensitiveWords(trimmedLine).join(', ')}`,
        file,
        line: lineNumber,
        context: trimmedLine.length > 120 ? trimmedLine.substring(0, 117) + '...' : trimmedLine,
        suggestion: 'Consider if this static message could be more generic',
      });
      return;
    }

    // Dynamic logging with sensitive patterns is WARN
    const severity = this.determineSeverity(trimmedLine);
    
    this.findings.push({
      severity,
      message: `Risky dynamic logging: ${this.extractSensitiveWords(trimmedLine).join(', ')}`,
      file,
      line: lineNumber,
      context: trimmedLine.length > 120 ? trimmedLine.substring(0, 117) + '...' : trimmedLine,
      suggestion: this.getSuggestion(file, trimmedLine),
    });
  }

  private extractSensitiveWords(line: string): string[] {
    return this.sensitivePatterns.filter(pattern => 
      line.toLowerCase().includes(pattern.toLowerCase())
    );
  }

  private determineSeverity(line: string): 'WARN' | 'INFO' {
    const highRiskPatterns = ['token', 'secret', 'private', 'password', 'authorization'];
    const lineLower = line.toLowerCase();
    
    const hasHighRisk = highRiskPatterns.some(pattern => 
      lineLower.includes(pattern)
    );

    // Check if it's likely safe (just counting/status)
    const seemsSafe = lineLower.includes('length') || 
                      lineLower.includes('count') || 
                      lineLower.includes('size') ||
                      lineLower.includes('status') ||
                      lineLower.includes('null') ||
                      lineLower.includes('empty');

    return hasHighRisk && !seemsSafe ? 'WARN' : 'INFO';
  }

  private getSuggestion(file: string, line: string): string {
    const isDart = file.endsWith('.dart');
    const isNode = file.endsWith('.ts') || file.endsWith('.js');

    if (isDart) {
      if (line.includes('$')) {
        return 'Replace with safeLog(\'label\', {\'key\': value}) from lib/core/logging/safe_log.dart';
      } else {
        return 'Consider using safeLog for structured logging';
      }
    } else if (isNode) {
      if (line.includes('token') || line.includes('secret')) {
        return 'Log token/secret length or status, not the actual value';
      } else {
        return 'Use structured logging with sanitized fields';
      }
    }

    return 'Review if sensitive data could be exposed in logs';
  }

  printResults(analysis: LogAnalysis): void {
    console.log(colors.bold(colors.blue('📊 PRECISE RISKY LOGGING ANALYSIS')));
    console.log(colors.blue('═'.repeat(45)));
    console.log(`📁 Files scanned: ${analysis.summary.scannedFiles}`);
    console.log(`⚠️  Risky patterns: ${analysis.summary.riskyLogs}`);
    console.log();

    if (analysis.findings.length === 0) {
      console.log(colors.green('✅ No risky logging patterns detected!'));
      return;
    }

    // Group by severity
    const warnings = analysis.findings.filter(f => f.severity === 'WARN');
    const info = analysis.findings.filter(f => f.severity === 'INFO');

    if (warnings.length > 0) {
      console.log(colors.yellow(colors.bold('⚠️  DYNAMIC SENSITIVE LOGGING:')));
      console.log('-'.repeat(35));
      warnings.forEach((finding, index) => {
        console.log(`${index + 1}. ${colors.yellow('⚠️')} ${finding.message}`);
        console.log(`   📍 ${finding.file}:${finding.line}`);
        console.log(`   💬 ${colors.dim(finding.context)}`);
        console.log(`   🔧 ${finding.suggestion}`);
        console.log();
      });
    }

    if (info.length > 0) {
      console.log(colors.blue(colors.bold('ℹ️  STATIC REFERENCES (review):')));
      console.log('-'.repeat(35));
      info.forEach((finding, index) => {
        console.log(`${index + 1}. ${colors.blue('ℹ️')} ${finding.message}`);
        console.log(`   📍 ${finding.file}:${finding.line}`);
        console.log(`   💡 ${finding.suggestion}`);
        console.log();
      });
    }

    // Best practices
    console.log(colors.bold('🔧 SECURE LOGGING BEST PRACTICES:'));
    console.log('-'.repeat(35));
    console.log('• Use safeLog() for Dart structured logging');
    console.log('• Log counts/lengths/status, never actual values');
    console.log('• Implement log sanitization in production');
    console.log('• Use structured logging with known-safe fields');
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
    console.log(colors.dim('\n📋 JSON Report:'));
    console.log(colors.dim(jsonOutput));
    
    // Never fail on logging checks (warnings only)
    process.exit(0);
    
  } catch (error) {
    console.error(colors.red('❌ Log analysis failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { RiskyLoggingChecker, LogFinding, LogAnalysis };