# Gap List (Actionable)
| # | Area | Severity | Effort | Owner | Finding | Fix Hint |
|---|---|---|---|---|---|---|
| 1 | Tests | P0 | M | Eng | Inline status Undo lacks automated widget/e2e coverage | Add widget test to simulate change + Undo; verify second write & audit |
| 2 | Rules | P0 | S | Eng | No emulator CI gate | Add CI job to run qa/rules/rules_enquiries.spec.js on PRs |
| 3 | Activity Log | P0 | M | Eng | Audit write not wired in repo/service | Create service to append activity subcollection on status/admin edits |
| 4 | Perf Evidence | P1 | M | Eng | No captured cold start/FPS/fetch p95 | Run profiling guide; commit outputs; tune images and queries as needed |
| 5 | Accessibility | P1 | S | Eng/Design | Missing explicit Semantics on some controls | Add semantics/labels; ensure focus order and visible focus rings |
| 6 | Notifications | P1 | M | Eng | Daily digest function not deployed | Deploy functions:dailyDigest; add admins topic subscribe for admins |
| 7 | DevOps | P1 | S | Eng | No coverage threshold in CI | Add flutter test coverage and minimum threshold gate |
| 8 | Docs | P2 | S | TW | Add Verification Playbook for manual checks | Create docs/VERIFICATION_PLAYBOOK.md with steps and expected results |
