# Secret Scan Report (Redacted)

This report lists potential secrets detected in the repository. All values are redacted.
Severity: HIGH findings fail CI. Verify and rotate any exposed credentials.

## Gitleaks — Working Tree & History

- No findings in working tree
- No findings in history

## Custom Pattern Ripgrep


## Immediate Actions

- Revoke/rotate any exposed keys immediately.
- Purge history if secrets were committed: run scripts/history_purge.sh.
- Move secrets to CI secret store / env vars; never commit plaintext secrets.
