#!/usr/bin/env tsx
/**
 * Risky Logging Refactoring Tool
 * Finds and replaces risky logging patterns with safe alternatives
 */

import { glob } from 'glob';
import { readFileSync, writeFileSync } from 'fs';
import colors from 'picocolors';
import path from 'path';

interface LogReplacement {
  file: string;
  line: number;
  original: string;
  replacement: string;
  reason: string;
}

interface LogRefactorResult {
  replacements: LogReplacement[];
  filesModified: number;
  summary: {
    dartLogs: number;
    nodeLogs: number;
    skipped: number;
  };
}

class RiskyLogRefactor {
  private replacements: LogReplacement[] = [];

  // Risky patterns in logs
  private readonly riskyPatterns = [
    'token', 'authorization', 'cookie', 'secret', 'private', 
    'key', 'password', 'auth', 'bearer', 'jwt', 'session'
  ];

  // Files to ignore
  private readonly ignorePatterns = [
    'node_modules/**',
    '.dart_tool/**',
    '.git/**',
    'build/**',
    'lib/**.g.dart',
    'lib/**.freezed.dart',
    'functions/lib/**',
    'scripts/refactors/**', // Don't refactor ourselves
    'scripts/security/**',
    'test/**', // Skip test files
  ];

  async refactor(): Promise<LogRefactorResult> {
    console.log(colors.blue('📝 Starting risky logging refactoring...\n'));

    const files = await this.getFilesToScan();
    
    for (const file of files) {
      await this.processFile(file);
    }

    return {
      replacements: this.replacements,
      filesModified: new Set(this.replacements.map(r => r.file)).size,
      summary: {
        dartLogs: this.replacements.filter(r => r.file.endsWith('.dart')).length,
        nodeLogs: this.replacements.filter(r => !r.file.endsWith('.dart')).length,
        skipped: 0,
      },
    };
  }

  private async getFilesToScan(): Promise<string[]> {
    const allFiles = await glob('**/*', {
      ignore: this.ignorePatterns,
      nodir: true,
    });

    return allFiles.filter(file => {
      const ext = path.extname(file).toLowerCase();
      return ['.dart', '.ts', '.js', '.tsx', '.jsx'].includes(ext);
    });
  }

  private async processFile(filePath: string): Promise<void> {
    try {
      const content = readFileSync(filePath, 'utf8');
      const lines = content.split('\n');
      let modifiedLines = [...lines];
      let hasChanges = false;

      lines.forEach((line, index) => {
        const newLine = this.processLine(line, filePath, index + 1);
        if (newLine !== line) {
          modifiedLines[index] = newLine;
          hasChanges = true;

          this.replacements.push({
            file: filePath,
            line: index + 1,
            original: line.trim(),
            replacement: newLine.trim(),
            reason: 'Sanitized risky logging pattern',
          });
        }
      });

      if (hasChanges) {
        writeFileSync(filePath, modifiedLines.join('\n'), 'utf8');
      }

    } catch (error) {
      // Skip files we can't process
    }
  }

  private processLine(line: string, filePath: string, lineNumber: number): string {
    const trimmed = line.trim();
    
    // Skip comments
    if (trimmed.startsWith('//') || trimmed.startsWith('*') || trimmed.startsWith('#')) {
      return line;
    }

    const ext = path.extname(filePath).toLowerCase();
    
    if (ext === '.dart') {
      return this.processDartLog(line);
    } else if (['.ts', '.js', '.tsx', '.jsx'].includes(ext)) {
      return this.processNodeLog(line);
    }

    return line;
  }

  private processDartLog(line: string): string {
    // Check for print statements with risky content
    const printMatch = line.match(/(\s*)(print\s*\(\s*['"`])([^'"`]*?)(['"`]\s*\))/);
    if (printMatch && this.containsRiskyPattern(printMatch[3])) {
      const indent = printMatch[1];
      const message = printMatch[3];
      
      // Convert to safeLog if it looks like structured data
      if (message.includes(':') || message.includes('$')) {
        return `${indent}// TODO: Replace with safeLog - ${line.trim()}`;
      } else {
        return `${indent}print('${this.sanitizeMessage(message)}');`;
      }
    }

    // Check for debugPrint
    const debugPrintMatch = line.match(/(\s*)(debugPrint\s*\(\s*['"`])([^'"`]*?)(['"`]\s*\))/);
    if (debugPrintMatch && this.containsRiskyPattern(debugPrintMatch[3])) {
      const indent = debugPrintMatch[1];
      const message = debugPrintMatch[3];
      return `${indent}debugPrint('${this.sanitizeMessage(message)}');`;
    }

    return line;
  }

  private processNodeLog(line: string): string {
    // Check for console.log, logger.info, etc.
    const logMatch = line.match(/(\s*)(console\.\w+|logger\.\w+)\s*\(\s*(['"`])([^'"`]*?)(['"`])/);
    if (logMatch && this.containsRiskyPattern(logMatch[4])) {
      const indent = logMatch[1];
      const logFunction = logMatch[2];
      const quote = logMatch[3];
      const message = logMatch[4];
      
      return `${indent}${logFunction}(${quote}${this.sanitizeMessage(message)}${quote});`;
    }

    // Check for template literals
    const templateMatch = line.match(/(\s*)(console\.\w+|logger\.\w+)\s*\(\s*`([^`]*?)`/);
    if (templateMatch && this.containsRiskyPattern(templateMatch[3])) {
      const indent = templateMatch[1];
      const logFunction = templateMatch[2];
      const message = templateMatch[3];
      
      return `${indent}${logFunction}(\`${this.sanitizeMessage(message)}\`);`;
    }

    return line;
  }

  private containsRiskyPattern(text: string): boolean {
    const lowerText = text.toLowerCase();
    return this.riskyPatterns.some(pattern => lowerText.includes(pattern));
  }

  private sanitizeMessage(message: string): string {
    let sanitized = message;

    // Replace variable interpolations that might contain sensitive data
    sanitized = sanitized.replace(/\$\{?(\w*(?:token|secret|key|password|auth)\w*)\}?/gi, 
      (match, varName) => `[${varName.toUpperCase()}_REDACTED]`);
    
    // Replace direct mentions of sensitive words with generic terms
    this.riskyPatterns.forEach(pattern => {
      const regex = new RegExp(`\\b${pattern}\\b`, 'gi');
      sanitized = sanitized.replace(regex, '[REDACTED]');
    });

    return sanitized;
  }

  printResults(result: LogRefactorResult): void {
    console.log(colors.bold(colors.blue('📊 RISKY LOGGING REFACTORING RESULTS')));
    console.log(colors.blue('═'.repeat(50)));
    console.log(`📁 Files modified: ${result.filesModified}`);
    console.log(`🎯 Dart logs sanitized: ${result.summary.dartLogs}`);
    console.log(`🔧 Node logs sanitized: ${result.summary.nodeLogs}`);
    console.log(`📝 Total replacements: ${result.replacements.length}`);
    console.log();

    if (result.replacements.length === 0) {
      console.log(colors.green('✅ No risky logging patterns found to replace!'));
      return;
    }

    console.log(colors.bold('🔧 LOG SANITIZATION CHANGES:'));
    console.log('-'.repeat(50));

    result.replacements.forEach((replacement, index) => {
      console.log(`${index + 1}. ${colors.yellow('LOG SANITIZED')}`);
      console.log(`   📍 ${replacement.file}:${replacement.line}`);
      console.log(`   📝 Before: ${colors.dim(replacement.original)}`);
      console.log(`   ➡️  After:  ${colors.green(replacement.replacement)}`);
      console.log(`   💡 Reason: ${replacement.reason}`);
      console.log();
    });

    console.log(colors.bold('📋 MANUAL REVIEW NEEDED:'));
    console.log('-'.repeat(30));
    console.log('• Check all TODO comments for manual safeLog conversion');
    console.log('• Verify sanitized logs still provide useful debugging info');
    console.log('• Consider implementing structured logging');
    console.log('• Test that applications still work correctly');
    console.log();
  }
}

// Main execution
async function main() {
  const refactor = new RiskyLogRefactor();
  
  try {
    const result = await refactor.refactor();
    
    refactor.printResults(result);
    
    process.exit(0);
    
  } catch (error) {
    console.error(colors.red('❌ Log refactoring failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { RiskyLogRefactor, LogReplacement, LogRefactorResult };
