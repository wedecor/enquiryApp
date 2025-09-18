#!/usr/bin/env tsx
/**
 * Automated Secret Refactoring Tool
 * Finds hardcoded secrets and replaces them with environment variables
 */

import { glob } from 'glob';
import { readFileSync, writeFileSync, existsSync } from 'fs';
import colors from 'picocolors';
import path from 'path';

interface SecretReplacement {
  file: string;
  line: number;
  original: string;
  replacement: string;
  envKey: string;
  type: 'secret' | 'config';
}

interface RefactorResult {
  replacements: SecretReplacement[];
  envKeysAdded: string[];
  filesModified: number;
  summary: {
    secrets: number;
    configs: number;
    skipped: number;
  };
}

class SecretRefactor {
  private replacements: SecretReplacement[] = [];
  private envKeysAdded = new Set<string>();
  private allowlist = new Set([
    // Test/example values that are safe
    'admin@wedecorevents.com',
    'admin12',
    'test@example.com',
    'example.com',
    'localhost',
    '127.0.0.1',
    'PASTE_WEB_PUSH_CERTIFICATE_PUBLIC_KEY',
    'your-actual-api-key',
    'wedecorenquries',
  ]);

  // Patterns for detecting secrets
  private readonly secretPatterns = {
    // Private keys
    privateKey: /process.env.PRIVATE_KEY_2/g,
    
    // Service account JSON blocks
    serviceAccount: /"private_key"\s*:\s*"[^"]+"/g,
    clientEmail: /"client_email"\s*:\s*"[^@]+@[^"]+"/g,
    
    // FCM server keys (legacy)
    fcmServerKey: /AAAA[0-9A-Za-z_\-]{100,}/g,
    
    // JWT tokens
    jwtToken: /eyJ[0-9A-Za-z_\-]+\.[0-9A-Za-z_\-]+\.[0-9A-Za-z_\-]+/g,
    
    // Access tokens
    accessToken: /ya29\.[0-9A-Za-z\-_\.]+/g,
    
    // Password literals
    passwordLiteral: /password\s*[:=]\s*["']([^"']{4,})["']/gi,
    
    // API keys
    apiKey: /api[_-]?key\s*[:=]\s*["']([^"']{10,})["']/gi,
    
    // Generic secrets
    secretLiteral: /secret\s*[:=]\s*["']([^"']{10,})["']/gi,
  };

  // Files to ignore
  private readonly ignorePatterns = [
    'node_modules/**',
    '.dart_tool/**',
    '.git/**',
    'build/**',
    'lib/**.g.dart',
    'lib/**.freezed.dart',
    'functions/lib/**',
    'config/*.env*',
    '**/*.min.*',
    'coverage/**',
  ];

  async refactor(): Promise<RefactorResult> {
    console.log(colors.blue('🔧 Starting automated secret refactoring...\n'));

    const files = await this.getFilesToScan();
    
    for (const file of files) {
      await this.processFile(file);
    }

    // Update environment template
    await this.updateEnvTemplate();

    return {
      replacements: this.replacements,
      envKeysAdded: Array.from(this.envKeysAdded),
      filesModified: new Set(this.replacements.map(r => r.file)).size,
      summary: {
        secrets: this.replacements.filter(r => r.type === 'secret').length,
        configs: this.replacements.filter(r => r.type === 'config').length,
        skipped: 0,
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
        '.dart', '.ts', '.js', '.tsx', '.jsx', '.json',
        '.yaml', '.yml', '.md', '.txt', '.sh', '.bat',
        '.gradle', '.properties', '.xml'
      ].includes(ext) || !ext;
    });
  }

  private async processFile(filePath: string): Promise<void> {
    try {
      const content = readFileSync(filePath, 'utf8');
      let modifiedContent = content;
      let hasChanges = false;

      const lines = content.split('\n');

      // Check each secret pattern
      Object.entries(this.secretPatterns).forEach(([patternName, regex]) => {
        let match;
        while ((match = regex.exec(content)) !== null) {
          const secretValue = match[1] || match[0];
          
          // Skip if in allowlist
          if (this.allowlist.has(secretValue)) {
            continue;
          }

          const lineNumber = content.substring(0, match.index).split('\n').length;
          const line = lines[lineNumber - 1];

          // Generate environment variable name
          const envKey = this.generateEnvKey(patternName, secretValue);
          
          // Create replacement based on file type
          const replacement = this.createReplacement(filePath, line, secretValue, envKey);
          
          if (replacement) {
            modifiedContent = modifiedContent.replace(secretValue, replacement);
            hasChanges = true;

            this.replacements.push({
              file: filePath,
              line: lineNumber,
              original: line.trim(),
              replacement: line.replace(secretValue, replacement).trim(),
              envKey,
              type: this.getSecretType(patternName),
            });

            this.envKeysAdded.add(envKey);
          }
        }
        regex.lastIndex = 0; // Reset regex
      });

      // Write modified file if changes were made
      if (hasChanges) {
        writeFileSync(filePath, modifiedContent, 'utf8');
      }

    } catch (error) {
      // Skip files we can't process
    }
  }

  private generateEnvKey(patternName: string, value: string): string {
    const baseNames: Record<string, string> = {
      privateKey: 'PRIVATE_KEY',
      serviceAccount: 'SERVICE_ACCOUNT_KEY',
      clientEmail: 'SERVICE_ACCOUNT_EMAIL',
      fcmServerKey: 'FCM_SERVER_KEY',
      jwtToken: 'JWT_TOKEN',
      accessToken: 'ACCESS_TOKEN',
      passwordLiteral: 'PASSWORD',
      apiKey: 'API_KEY',
      secretLiteral: 'SECRET',
    };

    const baseName = baseNames[patternName] || 'SECRET';
    
    // Add suffix if needed for uniqueness
    let envKey = baseName;
    let counter = 1;
    while (this.envKeysAdded.has(envKey)) {
      envKey = `${baseName}_${counter}`;
      counter++;
    }

    return envKey;
  }

  private createReplacement(filePath: string, line: string, secretValue: string, envKey: string): string | null {
    const ext = path.extname(filePath).toLowerCase();

    if (['.ts', '.js', '.tsx', '.jsx'].includes(ext)) {
      // Node/TypeScript files
      if (line.includes('process.env.')) {
        return `process.env.${envKey} || ''`;
      } else {
        return `process.env.${envKey}`;
      }
    } else if (ext === '.dart') {
      // Flutter files - don't put secrets in Dart, only public config
      if (this.isPublicConfig(secretValue)) {
        return `const String.fromEnvironment('${envKey}', defaultValue: '')`;
      } else {
        // Skip - secrets should not be in Flutter code
        return null;
      }
    } else if (['.json', '.yaml', '.yml'].includes(ext)) {
      // Config files
      return `\${${envKey}}`;
    }

    return `\${${envKey}}`;
  }

  private isPublicConfig(value: string): boolean {
    // Only VAPID public keys and similar public values
    return value.startsWith('BK') || // VAPID public key
           value.includes('firebaseapp.com') || // Public URLs
           value.includes('googleapis.com');
  }

  private getSecretType(patternName: string): 'secret' | 'config' {
    const secretPatterns = ['privateKey', 'serviceAccount', 'fcmServerKey', 'jwtToken', 'accessToken', 'passwordLiteral'];
    return secretPatterns.includes(patternName) ? 'secret' : 'config';
  }

  private async updateEnvTemplate(): Promise<void> {
    if (this.envKeysAdded.size === 0) return;

    const templatePath = 'config/.env.example';
    let template = '';
    
    if (existsSync(templatePath)) {
      template = readFileSync(templatePath, 'utf8');
    }

    // Add new environment variables
    const newVars = Array.from(this.envKeysAdded)
      .filter(key => !template.includes(`${key}=`))
      .map(key => `${key}=`)
      .join('\n');

    if (newVars) {
      template += '\n# Auto-generated from secret refactoring\n' + newVars + '\n';
      writeFileSync(templatePath, template, 'utf8');
    }
  }

  printResults(result: RefactorResult): void {
    console.log(colors.bold(colors.blue('📊 SECRET REFACTORING RESULTS')));
    console.log(colors.blue('═'.repeat(50)));
    console.log(`📁 Files modified: ${result.filesModified}`);
    console.log(`🔐 Secrets replaced: ${result.summary.secrets}`);
    console.log(`⚙️  Config values: ${result.summary.configs}`);
    console.log(`🔑 Environment variables added: ${result.envKeysAdded.length}`);
    console.log();

    if (result.replacements.length === 0) {
      console.log(colors.green('✅ No hardcoded secrets found to replace!'));
      return;
    }

    console.log(colors.bold('🔧 REPLACEMENTS MADE:'));
    console.log('-'.repeat(50));

    result.replacements.forEach((replacement, index) => {
      const typeColor = replacement.type === 'secret' ? colors.red : colors.yellow;
      console.log(`${index + 1}. ${typeColor(replacement.type.toUpperCase())}`);
      console.log(`   📍 ${replacement.file}:${replacement.line}`);
      console.log(`   🔑 Environment variable: ${colors.cyan(replacement.envKey)}`);
      console.log(`   📝 Change: ${colors.dim(replacement.original)}`);
      console.log(`   ➡️  ${colors.green(replacement.replacement)}`);
      console.log();
    });

    if (result.envKeysAdded.length > 0) {
      console.log(colors.bold('🌍 ENVIRONMENT VARIABLES TO SET:'));
      console.log('-'.repeat(40));
      result.envKeysAdded.forEach(key => {
        console.log(`• ${colors.cyan(key)}= (fill in config/.env.local)`);
      });
      console.log();
    }

    console.log(colors.bold('🚨 IMPORTANT NEXT STEPS:'));
    console.log('-'.repeat(30));
    console.log('1. Fill in actual values in config/.env.local');
    console.log('2. Verify all applications still work');
    console.log('3. Rotate any exposed credentials');
    console.log('4. Test deployment with new environment setup');
    console.log();
  }
}

// Main execution
async function main() {
  const refactor = new SecretRefactor();
  
  try {
    const result = await refactor.refactor();
    
    refactor.printResults(result);
    
    // Exit with success
    process.exit(0);
    
  } catch (error) {
    console.error(colors.red('❌ Secret refactoring failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { SecretRefactor, SecretReplacement, RefactorResult };
