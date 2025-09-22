# Secret Rotation Playbook

This playbook describes how to revoke, rotate, and roll out new credentials safely.

## General Guidance
- Revoke exposed credentials immediately.
- Create replacement keys with least privileges.
- Store secrets in CI secret stores (GitHub Actions Secrets) or cloud secret managers; never commit.
- Rotate across all environments (dev/stage/prod).
- Update apps to read from env vars or secret manager at runtime.

## GitHub Personal Access Token (PAT)
- Revoke: GitHub → Settings → Developer settings → Personal access tokens.
- Create: New fine-scoped PAT; prefer short expiry.
- Store: GitHub repo/org Secrets → `GITHUB_TOKEN` (or specific).
- Rollout: Update workflows/CLIs to use `${{ secrets.<NAME> }}`.

## Google Cloud / Firebase
- Service Accounts: IAM & Admin → Service Accounts → Keys → Delete leaked key; create new key if needed. Prefer Workload Identity / default credentials in Cloud Functions instead of JSON keys.
- FCM Server Key (v1): Go to Firebase Console → Project Settings → Cloud Messaging → Server key; regenerate.
- Store: Use Secret Manager or GitHub Secrets.
- Rollout: Update server functions/env to new key; redeploy.

## Stripe
- Revoke: Dashboard → Developers → API keys → reveal/regenerate secret keys.
- Store: Secret manager / GitHub Secrets as `STRIPE_SECRET_KEY`.
- Rollout: Update backend/env; verify webhook signatures where applicable.

## Twilio
- Revoke: Console → Account → API Keys → Revoke leaked key; create new key/secret.
- Store: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN` in secrets store.
- Rollout: Update server config and redeploy.

## Slack
- Revoke: API dashboard → Your apps → OAuth & Permissions → Reissue tokens.
- Store: Secret manager / GitHub Secrets as `SLACK_BOT_TOKEN`.
- Rollout: Update bot config; reinstall app if needed.

## Post-Rotation Checklist
- [ ] Replace secrets in CI / envs
- [ ] Redeploy affected services
- [ ] Purge secrets from history (scripts/history_purge.sh)
- [ ] Monitor logs for unauthorized attempts
- [ ] Update runbooks/docs
