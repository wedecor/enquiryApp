#!/usr/bin/env tsx
/**
 * Security Audit Runner
 * Aggregates all security checks and provides a unified report
 */

import { ExposureScanner, ScanResult } from './exposure_scan';
import { FirestoreRulesChecker, RulesAnalysis } from './check_rules';
import { RiskyLoggingChecker, LogAnalysis } from './check_logs';
import { readFileSync, existsSync } from 'fs';
import colors from 'picocolors';

interface AcknowledgedFinding {
  file: string;
  line: number;
  hash: string;
  reason: string;
}

interface AuditSummary {
  timestamp: string;
  overall: 'PASS' | 'WARN' | 'FAIL';
  sections: {
    secrets: AuditSection;
    rules: AuditSection;
    logging: AuditSection;
  };
  recommendations: string[];
}

interface AuditSection {
  status: 'PASS' | 'WARN' | 'FAIL';
  critical: number;
  warnings: number;
  info: number;
  message: string;
}

class SecurityAuditor {
  private recommendations: string[] = [];
  private acknowledgedFindings: AcknowledgedFinding[] = [];

  constructor() {
    this.loadAcknowledgedFindings();
  }

  private loadAcknowledgedFindings(): void {
    try {
      if (existsSync('scripts/security/acknowledge.json')) {
        const content = readFileSync('scripts/security/acknowledge.json', 'utf8');
        this.acknowledgedFindings = JSON.parse(content);
      }
    } catch (error) {
      // Ignore errors loading acknowledge file
    }
  }

  async runFullAudit(): Promise<AuditSummary> {
    console.log(colors.bold(colors.blue('🛡️  WEDECOR SECURITY AUDIT')));
    console.log(colors.blue('═'.repeat(50)));
    console.log(`🕐 Started: ${new Date().toLocaleString()}\n`);

    // Run all security checks
    const [secretsResult, rulesResult, logsResult] = await Promise.all([
      this.runSecretsCheck(),
      this.runRulesCheck(),
      this.runLogsCheck(),
    ]);

    // Create summary
    const summary = this.createSummary(secretsResult, rulesResult, logsResult);
    
    // Print unified report
    this.printUnifiedReport(summary);
    
    return summary;
  }

  private async runSecretsCheck(): Promise<ScanResult> {
    console.log(colors.yellow('🔍 Running secrets exposure scan...'));
    const scanner = new ExposureScanner();
    const result = await scanner.scan();
    console.log(colors.green('✓ Secrets scan complete\n'));
    return result;
  }

  private async runRulesCheck(): Promise<RulesAnalysis> {
    console.log(colors.yellow('🔒 Analyzing Firestore rules...'));
    const checker = new FirestoreRulesChecker();
    const result = await checker.analyze();
    console.log(colors.green('✓ Rules analysis complete\n'));
    return result;
  }

  private async runLogsCheck(): Promise<LogAnalysis> {
    console.log(colors.yellow('📝 Checking for risky logging...'));
    const checker = new RiskyLoggingChecker();
    const result = await checker.analyze();
    console.log(colors.green('✓ Logging check complete\n'));
    return result;
  }

  private createSummary(
    secrets: ScanResult, 
    rules: RulesAnalysis, 
    logs: LogAnalysis
  ): AuditSummary {
    // Filter out acknowledged findings
    const realSecrets = this.filterAcknowledgedFindings(secrets);
    const realSecretsCount = realSecrets.filter(f => f.severity === 'FAIL').length;
    const secretsSection: AuditSection = {
      status: realSecretsCount > 0 ? 'FAIL' : 
              secrets.summary.warnings > 0 ? 'WARN' : 'PASS',
      critical: realSecretsCount,
      warnings: secrets.summary.warnings,
      info: 0,
      message: this.getSecretsMessage({ ...secrets, summary: { ...secrets.summary, secrets: realSecretsCount } }),
    };

    const rulesSection: AuditSection = {
      status: rules.summary.critical > 0 ? 'FAIL' :
              rules.summary.warnings > 0 ? 'WARN' : 'PASS',
      critical: rules.summary.critical,
      warnings: rules.summary.warnings,
      info: rules.summary.info,
      message: this.getRulesMessage(rules),
    };

    const logsSection: AuditSection = {
      status: logs.summary.riskyLogs > 0 ? 'WARN' : 'PASS',
      critical: 0,
      warnings: logs.findings.filter(f => f.severity === 'WARN').length,
      info: logs.findings.filter(f => f.severity === 'INFO').length,
      message: this.getLogsMessage(logs),
    };

    // Generate recommendations
    this.generateRecommendations(secrets, rules, logs);

    // Determine overall status
    const overall = secretsSection.status === 'FAIL' || rulesSection.status === 'FAIL' ? 'FAIL' :
                   secretsSection.status === 'WARN' || rulesSection.status === 'WARN' || logsSection.status === 'WARN' ? 'WARN' : 'PASS';

    return {
      timestamp: new Date().toISOString(),
      overall,
      sections: {
        secrets: secretsSection,
        rules: rulesSection,
        logging: logsSection,
      },
      recommendations: this.recommendations,
    };
  }

  private getSecretsMessage(result: ScanResult): string {
    if (result.summary.secrets > 0) {
      return `${result.summary.secrets} exposed secrets found`;
    }
    if (result.summary.warnings > 0) {
      return `${result.summary.warnings} potential issues found`;
    }
    return 'No secrets exposure detected';
  }

  private getRulesMessage(result: RulesAnalysis): string {
    if (result.summary.critical > 0) {
      return `${result.summary.critical} critical rule vulnerabilities`;
    }
    if (result.summary.warnings > 0) {
      return `${result.summary.warnings} rule security warnings`;
    }
    return 'Firestore rules look secure';
  }

  private getLogsMessage(result: LogAnalysis): string {
    const warnings = result.findings.filter(f => f.severity === 'WARN').length;
    if (warnings > 0) {
      return `${warnings} high-risk logging patterns found`;
    }
    if (result.summary.riskyLogs > 0) {
      return `${result.summary.riskyLogs} logging patterns to review`;
    }
    return 'No risky logging detected';
  }

  private generateRecommendations(
    secrets: ScanResult, 
    rules: RulesAnalysis, 
    logs: LogAnalysis
  ): void {
    // Secrets recommendations
    if (secrets.summary.secrets > 0) {
      this.recommendations.push('🚨 CRITICAL: Rotate any exposed credentials immediately');
      this.recommendations.push('🔧 Move all secrets to environment variables');
      this.recommendations.push('📋 Audit git history for leaked secrets');
    }

    // Rules recommendations
    const tokenExposure = rules.findings.find(f => f.rule === 'token-exposure-risk');
    if (tokenExposure) {
      this.recommendations.push('🔒 SECURITY: Move FCM tokens to private subcollection');
      this.recommendations.push(`
🛠️  RECOMMENDED FCM TOKEN STRUCTURE:
   users/{uid}                           # public profile only
   users/{uid}/private/notifications/    # FCM tokens (owner-only)
   
   FIRESTORE RULES:
   match /users/{uid}/private/notifications/{tokenId} {
     allow read, write: if request.auth != null && request.auth.uid == uid;
   }
   
   CLIENT CODE UPDATE:
   final tokens = FirebaseFirestore.instance
     .collection('users').doc(user.uid)
     .collection('private').doc('notifications')
     .collection('tokens');
   await tokens.doc(token).set({
     'token': token,
     'createdAt': FieldValue.serverTimestamp(),
   });`);
    }

    if (rules.summary.critical > 0) {
      this.recommendations.push('🔐 Fix critical Firestore rule vulnerabilities');
    }

    // Logging recommendations
    const highRiskLogs = logs.findings.filter(f => f.severity === 'WARN').length;
    if (highRiskLogs > 0) {
      this.recommendations.push('📝 Review and sanitize high-risk logging patterns');
    }

    // General recommendations
    this.recommendations.push('🔍 Run security audit regularly in CI/CD');
    this.recommendations.push('📚 Train team on secure coding practices');
    
    // Default admin password warning
    this.recommendations.push('⚠️  IMPORTANT: Change default admin password (admin@wedecorevents.com)');
    this.recommendations.push('🔐 Enable 2FA for all admin accounts');
  }

  private filterAcknowledgedFindings(secrets: ScanResult): any[] {
    return secrets.findings.filter(finding => {
      if (!finding.file || !finding.line) return true;
      
      const isAcknowledged = this.acknowledgedFindings.some(ack => 
        ack.file === finding.file && 
        ack.line === finding.line &&
        finding.context?.includes(ack.hash)
      );
      
      if (isAcknowledged) {
        const ack = this.acknowledgedFindings.find(a => 
          a.file === finding.file && a.line === finding.line
        );
        console.log(colors.dim(`🔄 ACKED: ${finding.message} (${ack?.reason})`));
        return false;
      }
      
      return true;
    });
  }

  private printUnifiedReport(summary: AuditSummary): void {
    console.log(colors.bold(colors.blue('\n📊 UNIFIED SECURITY REPORT')));
    console.log(colors.blue('═'.repeat(50)));

    // Overall status
    const overallColor = summary.overall === 'PASS' ? colors.green : 
                        summary.overall === 'WARN' ? colors.yellow : colors.red;
    console.log(`🎯 Overall Status: ${overallColor(colors.bold(summary.overall))}\n`);

    // Section summary table
    console.log(colors.bold('📋 SECTION SUMMARY'));
    console.log('─'.repeat(70));
    console.log(colors.bold('Section      Status    Critical  Warnings  Info   Message'));
    console.log('─'.repeat(70));
    
    this.printSectionRow('Secrets', summary.sections.secrets);
    this.printSectionRow('Rules', summary.sections.rules);
    this.printSectionRow('Logging', summary.sections.logging);
    
    console.log('─'.repeat(70));

    // Recommendations
    if (summary.recommendations.length > 0) {
      console.log(colors.bold('\n🔧 SECURITY RECOMMENDATIONS'));
      console.log('─'.repeat(50));
      summary.recommendations.forEach((rec, index) => {
        console.log(`${index + 1}. ${rec}`);
      });
    }

    // Next steps
    console.log(colors.bold('\n🚀 NEXT STEPS'));
    console.log('─'.repeat(30));
    if (summary.overall === 'FAIL') {
      console.log(colors.red('❌ CRITICAL: Address security failures before deployment'));
      console.log('• Fix exposed secrets immediately');
      console.log('• Update Firestore rules');
      console.log('• Re-run audit to verify fixes');
    } else if (summary.overall === 'WARN') {
      console.log(colors.yellow('⚠️  RECOMMENDED: Address warnings for better security'));
      console.log('• Review and implement recommendations');
      console.log('• Consider security improvements');
      console.log('• Monitor for security issues');
    } else {
      console.log(colors.green('✅ GOOD: Security audit passed'));
      console.log('• Continue regular security audits');
      console.log('• Keep security practices up to date');
      console.log('• Monitor for new vulnerabilities');
    }

    console.log(colors.bold(`\n🕐 Completed: ${new Date().toLocaleString()}`));
  }

  private printSectionRow(name: string, section: AuditSection): void {
    const statusColor = section.status === 'PASS' ? colors.green : 
                       section.status === 'WARN' ? colors.yellow : colors.red;
    
    const status = statusColor(section.status.padEnd(8));
    const critical = section.critical.toString().padEnd(8);
    const warnings = section.warnings.toString().padEnd(8);
    const info = section.info.toString().padEnd(6);
    const message = section.message.substring(0, 30);
    
    console.log(`${name.padEnd(12)} ${status} ${critical} ${warnings} ${info} ${message}`);
  }

  exportJson(summary: AuditSummary): string {
    return JSON.stringify(summary, null, 2);
  }
}

// Main execution
async function main() {
  const auditor = new SecurityAuditor();
  
  try {
    const summary = await auditor.runFullAudit();
    
    // Export JSON for CI
    const jsonOutput = auditor.exportJson(summary);
    console.log(colors.dim('\n📋 JSON Report (for CI/tooling):'));
    console.log(colors.dim(jsonOutput));
    
    // Exit with appropriate code
    const exitCode = summary.overall === 'FAIL' ? 1 : 0;
    console.log(colors.dim(`\n🔚 Exit code: ${exitCode}`));
    process.exit(exitCode);
    
  } catch (error) {
    console.error(colors.red('❌ Security audit failed:'), error);
    process.exit(1);
  }
}

// Run if this file is executed directly
if (import.meta.url === `file://${process.argv[1]}`) {
  main();
}

export { SecurityAuditor, AuditSummary };
