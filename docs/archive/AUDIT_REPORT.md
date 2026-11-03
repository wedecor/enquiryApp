# We Decor Enquiries — Independent Technical Audit

Date: 2026-06-18
Scope: Full repository at `/Users/mohammedilyas/Desktop/AppDevelopment/wedecorEnquries` (Flutter app + Firebase backend + Cloud Functions + CI/CD + docs)
Method: Direct inspection of source, configuration, security rules, CI workflows, test files, and documentation. Findings below are evidence-based; anything not directly verifiable from the filesystem is flagged as such rather than assumed.

A note up front: this repository contains its own internal "audit" and "QA" documents claiming scores like 8.2/10, "320 tests passing," and "production ready." Several of these are templated documents with unfilled placeholders (`$(date)`, `[TBD]`) or numbers that contradict each other across files. This report does not rely on those documents' conclusions — every score and finding below is derived from reading the actual code, rules, and configuration.

---

## Phase 1 — Application Discovery

### What it is

We Decor Enquiries is a single-business CRM for an event decoration company. It manages the lifecycle of a customer enquiry from intake through assignment, status tracking, and completion. Two roles exist: **admin** (business owner/manager) and **staff** (decorators/coordinators assigned to jobs). It is not a multi-tenant SaaS product — it is built for one organization's internal use.

Core workflow: an admin creates an enquiry (customer name/phone/email, event type, date, location, guest count, budget, description) → assigns it to a staff member → staff updates status/notes as the job progresses → admin tracks payment status and cost separately from operational status → history is recorded per enquiry → dashboards/analytics summarize volume, conversion, and revenue.

### Tech stack (verified)

- **Frontend**: Flutter 3.32.8 / Dart ^3.8.1, targeting Android, iOS, Web, and desktop build configs (macOS/Windows/Linux folders exist, but evidence — see Phase 7 — suggests the UI is tuned for mobile-portrait, not genuinely adaptive).
- **State management**: `flutter_riverpod` ^2.4.9 (StateNotifier/Provider/Stream/FutureProvider patterns), with one isolated exception using `riverpod_annotation`/`@riverpod` codegen (`riverpod_generator`, `build_runner` in dev_dependencies exist almost entirely to support this one file).
- **Codegen**: Freezed (immutable models) + `json_serializable`.
- **Backend**: Firebase — Auth ^6.0.2, Cloud Firestore ^6.0.1, Cloud Functions ^6.0.1 (Node/TypeScript), Storage ^13.0.1, Cloud Messaging ^16.0.1, Crashlytics ^5.0.1, Performance Monitoring ^0.11.0, Analytics ^12.0.1.
- **Other notable deps**: `fl_chart` (analytics charts), `table_calendar` (calendar view), `flutter_contacts` (one-tap contact import), `url_launcher` (call/WhatsApp shortcuts), `csv` + `file_saver` (export), `connectivity_plus`, `package_info_plus`, `device_info_plus`.
- **CI/CD**: 7 GitHub Actions workflows (`ci.yml`, `ci_hardening.yml`, `ci_rbac.yml`, `deploy.yml`, `firebase-distribute.yml`, `secret-scan.yml`, `security-audit.yml`); `gitleaks` (`.gitleaks.toml`) for secret scanning; Semgrep (`.semgrep.yml`); pre-commit config (`.pre-commit-config.yaml`) and a `.husky/` directory with git hooks.
- **Hosting/deploy**: Firebase Hosting (web) + evidence of Vercel config; real signed APKs and release-candidate artifacts exist in the repo history.

### Repository structure

```
lib/
  core/        - services, providers, auth, theme, notifications, a11y, contacts, export, logging, perf
  features/     - admin/{analytics,dropdowns,users}, auth, dashboard, enquiries/{data,domain,filters,presentation},
                  legal, notifications, settings
  legacy/       - dead code (see Phase 2/10)
  shared/, ui/components/, widgets/, services/
functions/      - Cloud Functions, Node 20 + TypeScript (src/: index.ts, autoExpireEnquiries.ts, env.ts)
test/           - 35 test files
rules-tests/    - Jest + @firebase/rules-unit-testing emulator tests for Firestore rules
docs/ + root    - ~60+ markdown files (architecture notes, QA reports, release checklists, security docs)
```

~143 Dart files, ~33,000 lines of code excluding generated (`.g.dart`/`.freezed.dart`) files.

**Documentation sprawl is itself a finding.** Dozens of overlapping markdown files exist (multiple QA/release-status docs, multiple security-hardening write-ups) and several contain literal unrendered template placeholders. This is evidence of heavy AI-assisted documentation generation that was never reconciled into a single source of truth — a maintainability risk in its own right (see Phase 10).

### Architecture review

The README claims a "clean architecture" with Presentation/Domain/Data layers. **This claim is not borne out by the code.** Verified directly:

- A 769-line `FirestoreService` god-service exists in `lib/core/services/`, alongside **29+ files** (screens and "repository" classes alike) that call `FirebaseFirestore.instance` directly, bypassing any repository abstraction.
- `EnquiryRepository` (the feature's primary data-access class) takes `FirestoreService` as a constructor dependency but never calls it — a dead injection. Meanwhile `FirestoreService.createEnquiry` and `EnquiryRepository.createEnquiry` are two **independently maintained** write paths with different field-normalization logic, meaning a write through one path doesn't guarantee the same data shape as a write through the other.
- State management is consistently Riverpod 2 across almost the entire app, except `analytics_controller.dart`, which alone uses `@riverpod` codegen — a stranded migration that drags `build_runner`/`riverpod_generator`/`riverpod_annotation` into the dependency tree for one file's benefit.

Net assessment: the folder layout *looks* like clean architecture, but the dependency direction and data-access discipline that would make it real are not enforced or consistently followed. This is "clean architecture" as aspiration, not as implemented constraint.

```
Claimed:           Presentation → Domain → Data → Firestore
Actual (verified): Presentation ───────────────────→ Firestore  (29+ files, direct)
                    Presentation → "Repository" ──┬──→ Firestore
                                                    └─→ FirestoreService → (unused by Repository)
```

### Data model (verified from `firestore.rules` and repository code)

```
users/{uid}
  role: "admin" | "staff"                      (drives all RBAC)
  private/notifications/tokens/{tid}            (FCM tokens, owner-only)
  notifications/{notificationId}
  settings/{docId}

enquiries/{id}
  customerName, customerPhone, customerEmail
  eventType, eventDate, eventLocation, guestCount, budgetRange, description
  eventStatus, paymentStatus, priority, source
  assignedTo, createdBy, createdAt, updatedAt
  totalCost, advancePaid                        (financial fields — write-restricted, see Phase 5)
  history/{historyId}                           (subcollection, audit trail of changes)

dropdowns/{group}/items/{value}                 group ∈ {statuses, event_types, priorities, payment_statuses}
notifications/{uid}/items/{nid}                 (created by Cloud Functions only)
analytics/{doc=**}
app_config/{docId}
admin_audit/{auditId}
```

Consistency is enforced entirely through Firestore Security Rules plus ad hoc Dart-side normalization — there is no schema-migration framework. Evidence of past schema drift is visible directly in field names (e.g. paired `statusValue`/`statusLabel` fields and `FieldValue.delete()` cleanup calls for legacy fields), indicating field renames were handled manually rather than through a structured migration path.

---

## Phase 2 — Feature Inventory

| Feature | Role | Status | Evidence |
|---|---|---|---|
| Auth (email/password sign-in, gate) | All | **Complete** | `lib/features/auth/` is wired from `main.dart` via `AuthGate`. |
| Enquiry CRUD + assignment | Admin (create/assign), Staff (update assigned) | **Complete** | Matches `firestore.rules` enquiry rules exactly. |
| Enquiry history log | All (read-scoped) | **Complete** | `history/` subcollection, rules mirror parent enquiry. |
| Dashboard + calendar view | All | **Complete** | `table_calendar` integration, 1633-line `dashboard_screen.dart`. |
| Enquiry filters | All | **Built, never wired in (abandoned)** | A `filters_controller_broken.dart.bak` stray file exists alongside a complete `lib/features/enquiries/filters/` module with no live screen referencing it. |
| Admin analytics | Admin | **Complete** | `fl_chart`-based, the one screen using Riverpod codegen. |
| Admin dropdown management | Admin | **Complete** | CRUD over `dropdowns/{group}/items`. |
| Admin user management | Admin | **Complete** | Backed by `inviteUser` Cloud Function (admin-only server check). |
| Push notifications (FCM) | All | **Partial** | Token registration and background delivery work; there is **no in-app notification center/inbox** — the write path (`notifications/{uid}/items`) exists but has no UI consumer found anywhere in `lib/`. |
| Settings (6 tabs) | All | **Complete** | Theme, profile, etc. |
| Legal/docs screens | All | **Complete** | Static content. |
| `lib/legacy/features/auth/*` | — | **Dead code** | Fully unreferenced; superseded by `lib/features/auth/`, which `main.dart` actually imports. |
| `route_guards.dart` (`AdminOnlyScreen`) | — | **Dead code** | Built, zero callers found. |
| `database_setup_service` / `schema_verification_service` / `user_firestore_sync_service` | — | **Orphaned dev tools** | Not invoked from `main.dart` or any production bootstrap path. |
| `one_time_seed.dart` / `seed_data.dart` | — | **Dev-only, correctly isolated** | Separate Dart entrypoint, confirmed not reachable from the production app start — this is the *correct* pattern, called out as a positive. |

Cloud Functions (`functions/src/`): `inviteUser`, `notifyOnEnquiryChange`, `autoExpireEnquiries` are live, in-source, and deployed per `functions/package.json` deploy scripts. Three additional compiled artifacts (`migrateStatusFields.js`, `dailyDigest.js`, `notifyOverdueInTalks.js`) exist only in the gitignored `functions/lib/` build output with **no corresponding `.ts` source** — they were deliberately removed from source (visible in commit history) but deletion from source does not automatically undeploy a Cloud Function. **Whether these are still live in the actual Firebase project cannot be determined from the filesystem alone** and should be checked with `firebase functions:list` against the real project.

---

## Phase 3 — Code Quality Review

| Dimension | Score /10 | Notes |
|---|---|---|
| Code Organization | 5 | Feature-folder skeleton exists but is not consistently respected (see Phase 1 architecture findings). |
| Readability | 6 | Generally clear naming and doc comments at the function level; undermined by file-level bloat. |
| Maintainability | 4 | Three god-screens over 1000 lines (`dashboard_screen.dart` 1633, `enquiry_form_screen.dart` 1311, `enquiry_details_screen.dart` 1020) make targeted changes risky. |
| Reusability / Modularity | 5 | Shared widgets (`EmptyState`, `ErrorState`) exist and are reused, but core data-access logic is duplicated rather than shared (Phase 1). |
| Naming Conventions | 6 | Mostly consistent and descriptive. |
| Error Handling | 3 | At least 4 different ad hoc error-handling conventions found across the codebase; no shared exception hierarchy. |
| Logging Strategy | 3 | **Two independent logger implementations** (`lib/core/logging/logger.dart`'s `Logger` and `lib/utils/logger.dart`'s `Log`) are both actively used by different files, each with its own PII-redaction regex. A third wrapper, `safe_log.dart`, wraps only one of the two and does **not** redact phone numbers — meaning some logging paths can leak customer phone numbers into logs. |
| Dependency Management | 5 | Dependencies are reasonably current; the Riverpod-codegen toolchain (`build_runner`, `riverpod_generator`) is justified by a single file, which is a poor cost/benefit trade for the build complexity it adds. |
| Configuration Management | 4 | `AppConfig` exists and gates Crashlytics/Performance/Analytics correctly in code, but the automated deploy pipeline never passes the `--dart-define` flags needed to turn them on in production (see Phase 9). |

**Average: ~4.6/10.**

---

## Phase 4 — Architecture Review

Already substantively covered in Phase 1. Summary scoring:

- Design decisions: feature-folder structure is reasonable for the project's size; the "clean architecture" framing oversells what's actually enforced. **5/10**
- Coupling/cohesion: low cohesion within the data-access layer specifically — two competing Firestore access patterns, one unused. **3/10**
- State management: consistent Riverpod 2 usage except one stranded codegen file. **7/10**
- Service boundaries / domain modeling: enquiry/user/dropdown domains are reasonably separated; no clear bounded-context violations found. **6/10**

**Overall Architecture: 4/10.** The skeleton is sound for a single-business app of this size; the execution drifted from its own stated design without anyone consolidating it back.

---

## Phase 5 — Security Review

Findings classified by severity, each verified directly against `firestore.rules`, `storage.rules`, and `functions/src/index.ts`.

### Critical

1. **Hardcoded live credential in source.** `functions/src/index.ts` contains a Gmail App Password used as an SMTP fallback for sending email. This is a live credential committed to the repository today — anyone with read access to the repo (or its history) has send-as capability on a real Google account. **Action: rotate the password and move it to Secret Manager / Cloud Functions runtime config immediately.**
2. **Leaked Google API key remains recoverable in git history.** A prior commit references having "removed" a leaked API key, and a history-purge script exists in the repo — but verification shows the purge was never actually executed, so the key is still retrievable by anyone who clones the full history. **Action: actually run the purge (or treat the key as permanently burned and rotate it), then force-push and have all clones re-fetch.**

### High

3. **Storage rules have no ownership/assignment check.** Both `/attachments/{enquiryId}/{fileName}` and `/enquiries/{enquiryId}/images/{fileName}` in `storage.rules` allow **any authenticated user** to read or write, regardless of whether they're an admin or the staff member assigned to that specific enquiry. This directly contradicts the assignment-scoped read model enforced in `firestore.rules` for the enquiry documents themselves — a staff member can be blocked from reading another staff member's enquiry document but can still read that enquiry's attached files if they know or guess the enquiry ID. Practical exploitability is lowered by enquiry IDs being non-guessable Firestore auto-IDs, but the rule itself is a real gap, not a defense-in-depth measure.

### Medium

4. **Financial fields are write-protected but not read-protected for staff.** `isModifyingOnlyNonFinancialFields()` correctly blocks staff from *writing* `totalCost`, `advancePaid`, `paymentStatus`, etc. — but the `allow read` rule for `/enquiries/{id}` has no field-level restriction, so any staff member assigned to an enquiry can read its financial data. If staff seeing cost/payment data is not intended by the business, this is a real gap; if it's intended, the rules should say so explicitly rather than leaving it as an apparent oversight.
5. **`/admin_audit/{auditId}` accepts `create` from any signed-in user**, not just admins or trusted server code (`allow create: if isSignedIn();`). This undermines the integrity of the audit trail as a forensic record — any authenticated user (including staff) can write arbitrary audit entries.
6. **CI verification of the security rules themselves is unconfirmed.** `ci_hardening.yml` references a script, `tool/ci/test_firestore_rules.sh`, that does not exist in the repository — this job would fail if actually triggered. `ci_rbac.yml` is gated behind GCP secrets that may not be configured, and at least one workflow hardcodes a static "127 tests passing" summary string regardless of actual results (see Phase 8). **It cannot currently be confirmed that the well-built `rules-tests/spec/rbac.spec.js` suite ever runs as part of CI.**

### Low

7. `/users/{uid}` is readable by any signed-in user (not just admins), exposing all user profile documents to every staff member. Likely intentional (needed for assignment UI/contact lookups) but worth confirming the fields exposed don't include anything sensitive beyond name/role.

**What's done well:** the core RBAC model (admin sees all, staff sees only assigned enquiries, staff blocked from financial writes, server-side admin check before privileged Cloud Functions like `inviteUser`) is genuinely correctly implemented in the rules — this is not boilerplate, it reflects real, working logic. The security posture is undermined by the two live-credential issues above and the storage-layer gap, not by the core data-access model.

---

## Phase 6 — Performance Review

- Cursor-based pagination is implemented for enquiry lists (not naive offset pagination) — a correct choice for Firestore.
- Firestore offline persistence is explicitly configured in `main.dart` (100MB cache, platform-aware for web vs. mobile).
- A confirmed `StreamSubscription` leak exists in the session service: the auth-state listener is not cancelled on dispose.
- Three god-screens (1000+ lines each) are likely doing more rebuild work than necessary given their size and the volume of state they hold directly; no `const` widget audit or `select`-based granular Riverpod watching was found being used consistently to limit rebuild scope.
- No image caching/compression strategy beyond ad hoc handling found for picked images.
- No bundle-size or lazy-loading strategy evident for the web target (single `MaterialApp` tree, no deferred imports found).

**Performance: 5/10** — the data-layer choices (pagination, offline cache) are sound; the widget-layer choices (giant stateful screens) work against them.

---

## Phase 7 — UX/UI Review

- **Accessibility was a genuine, deliberate investment**, not an afterthought: `lib/core/a11y/semantics_ext.dart` provides a comprehensive `Semantics` extension toolkit (button/header/image/textfield/switch/checkbox/radio/slider/tab/menu/link roles, each with sensible default hints), used in 50+ call sites across the app. This is uncommon thoroughness for a project this size and deserves explicit credit.
- Business-specific UX touches are thoughtful: one-tap call/WhatsApp shortcuts with platform fallback, calendar-based conflict awareness, contact-import shortcuts.
- `EmptyState`/`ErrorState` shared widgets exist and are reused across multiple screens, rather than every screen inventing its own loading/error/empty handling.
- **Responsiveness is weak.** Only 5 files in the entire codebase use `MediaQuery` or `LayoutBuilder`, despite the app shipping web, desktop, and mobile build targets. This strongly suggests the UI is tuned for a single mobile-portrait breakpoint and has not been validated or adapted for tablet, desktop, or wide web viewports — a real risk given Firebase Hosting + Vercel deployment implies the web build is an actual, used surface, not a throwaway target.
- No standalone design-system documentation was found beyond theme token definitions; consistency across the three 1000+ line screens cannot be fully assessed without a closer file-by-file pass, but file size alone is a signal that visual/interaction consistency is harder to maintain than it would be with smaller, composed widgets.

**UX/UI: 6/10.**

---

## Phase 8 — Testing Review

- 35 files exist under `test/`. A meaningful fraction are real and useful: pure-logic unit tests for `status_validator`, `filters_state`, `event_colors`, and `role_guards` are genuine and not placeholders.
- However, a substantial number of tests are either literal placeholders (`expect(true, isTrue)`) or are gated on Firebase availability in a way that causes them to **silently no-op** rather than fail when Firebase isn't reachable in the test environment — meaning a "passing" test run does not reliably indicate the gated assertions ran at all.
- Historical coverage reports in the repo (`coverage_report.txt` and an "enhanced" variant, both dated September 2025) show **12% and 18% line coverage respectively — both below the project's own documented 30% threshold**, and both are stale relative to the current codebase size.
- The current `lcov.info` in the repo has all-zero hit counts, meaning it does not reflect a real instrumented run; it cannot be used as evidence of current coverage.
- Claims across different internal docs of "320 tests passing," "8.2/10" quality, and "105/105 passing" are **mutually inconsistent** and none could be reproduced or verified from the current test suite's actual size.
- No `integration_test/` directory exists despite some documentation referencing integration tests as if they were present.
- `rules-tests/` (Jest + `@firebase/rules-unit-testing`) is a well-constructed Firestore-rules emulator test suite — but as noted in Phase 5, its actual execution in CI is unconfirmed due to a missing script reference and secret-gated jobs.

**High-risk untested areas:** the three largest screens (dashboard, enquiry form, enquiry details) have the least evidence of dedicated widget tests relative to their size and centrality to the app's core workflow.

**Testing: 3/10.**

---

## Phase 9 — Production Readiness Review

- **Crashlytics, Performance Monitoring, and Analytics are correctly gated in code** (`AppConfig.enableCrashlytics` etc., checked against `kReleaseMode` in `main.dart`) — but the automated `deploy.yml` pipeline never passes the `--dart-define` flags required to turn these on for a release build. Net effect: **the production app, as built by the documented CI/CD pipeline, currently ships with no crash reporting, no performance monitoring, and no analytics**, despite the code being fully wired to support all three. This is a configuration gap, not a missing-feature gap, which makes it easy to fix but currently real.
- No monitoring or alerting exists beyond the (currently disabled) Crashlytics — no Sentry, no Datadog, no external status page.
- CI has at least one broken job (`ci_hardening.yml`'s missing `tool/ci/test_firestore_rules.sh`) and at least one workflow producing fabricated test-count output regardless of actual results (`ci_rbac.yml`).
- A `Dockerfile` exists but is unrelated to the main app — it packages an unrelated Node-based seeding script, which is confusingly placed at a location that suggests (incorrectly) it's for the app itself.
- `terraform/oauth_clients.tf` is a non-functional stub that documents manual console steps rather than performing real infrastructure-as-code provisioning.
- Mobile distribution via `firebase-distribute.yml` is disabled by default (`DEPLOY_MOBILE` flag false) — deliberate, and reasonable for a project still iterating, but means there's no continuous mobile QA distribution happening automatically.
- **Genuine positive evidence of real operational discipline exists alongside the above**: at least 3 real release-candidate builds with checksums/notes, and a real `rollback/mobile-polish-backup` branch, indicating the developer has practiced an actual rollback procedure rather than only describing one in docs.

**Production Readiness: 3/10.** The gap between "code supports this" and "the deploy pipeline actually turns it on" is the single most fixable, highest-leverage finding in this entire audit (see Roadmap #1).

---

## Phase 10 — Technical Debt Analysis

Ranked by impact:

1. **Dual Firestore access pattern** (god-service + 29 direct-access files, one of which is a dead dependency injection) — highest impact, touches every future data-layer change.
2. **Three logging implementations with inconsistent PII redaction**, including a path that doesn't redact phone numbers — compliance/privacy-relevant, not just style.
3. **Dead code**: `lib/legacy/features/auth/*`, `route_guards.dart`/`AdminOnlyScreen`, `database_setup_service`/`schema_verification_service`/`user_firestore_sync_service`, a stray `filters_controller_broken.dart.bak`.
4. **Abandoned, fully-built feature**: the enquiry filters/saved-views module exists but is never wired into any screen.
5. **God screens**: three files exceeding 1000 lines each, working against testability and reuse.
6. **Documentation contradiction and template sprawl**: dozens of overlapping markdown files, several with unfilled placeholders, presenting inflated or inconsistent self-assessment of test/security/readiness status.
7. **Orphaned Cloud Function build artifacts** with no source — unclear deploy status, unclear maintenance owner.
8. **Stranded Riverpod-codegen migration** affecting a single file but the entire dev toolchain.

---

## Phase 11 — Improvement Roadmap

| Priority | Issue | Impact | Recommended Fix | Effort |
|---|---|---|---|---|
| **Critical** | Hardcoded Gmail App Password in `functions/src/index.ts` | Live credential exposure, account takeover risk | Remove from source, rotate password, move to Secret Manager | S |
| **Critical** | Leaked API key still recoverable in git history | Credential exposure persists despite a commit claiming removal | Actually execute history purge (BFG/filter-repo) or rotate the key and accept history exposure | S–M |
| **High** | Storage rules lack ownership/assignment checks | Staff can access attachments outside their assignment | Add a Firestore lookup of `assignedTo` in storage rules, mirroring the Firestore rule pattern | M |
| **High** | Deploy pipeline ships with Crashlytics/Performance/Analytics off | Production failures invisible; no real observability | Add the missing `--dart-define` flags to `deploy.yml` | S |
| **High** | CI rules-test job references a missing script; RBAC job fabricates output | Security rules may be effectively untested in CI | Create the missing script or remove the dead job; replace the hardcoded summary with real emulator-test output | M |
| **Medium** | Dual Firestore access pattern / dead repository dependency | Inconsistent writes, hard to reason about data integrity | Pick one access layer (repository pattern), delete or fully adopt `FirestoreService`, remove dead injection | L |
| **Medium** | Three logging implementations, inconsistent PII redaction | Customer phone numbers may leak into logs | Consolidate to one logger with one redaction policy covering phone + email | M |
| **Medium** | Financial fields readable by staff with no rule documenting intent | Possible unintended data exposure | Decide intent; if unintended, restrict reads; if intended, document it in the rules file | S |
| **Medium** | Three 1000+ line "god screens" | Hard to test/modify safely | Decompose into smaller widgets incrementally, starting with the highest-change-frequency screen | L |
| **Low** | Stale/placeholder test coverage, contradictory test-count claims | False confidence in quality | Replace placeholder tests with real ones for the three largest screens; regenerate and commit a real `lcov.info` | L |
| **Low** | Dead code (legacy auth, route guards, orphaned dev services, `.bak` file) | Maintainability drag, confusing for new contributors | Delete after confirming zero references | S |
| **Low** | Abandoned filters/saved-views feature | Wasted prior investment, unclear feature status | Finish wiring it in, or delete it — don't leave it half-built | M |
| **Future** | No in-app notification center despite working push/write path | Incomplete feature, user-visible gap | Build the inbox UI consuming the existing `notifications/{uid}/items` data | M |
| **Future** | No responsive/adaptive layout despite multi-platform targets | Web/desktop UX likely degraded vs. mobile | Introduce `LayoutBuilder`-based breakpoints for the three core screens | L |
| **Future** | Documentation sprawl and contradictory self-reports | Misleads future contributors (human or AI) about real project state | Consolidate to one living README + one architecture doc; delete or clearly mark superseded reports | M |

---

## Final Scorecard

| Dimension | Score /10 |
|---|---|
| Product Design | 6 |
| Architecture | 4 |
| Code Quality | 4 |
| Security | 4 |
| Performance | 5 |
| Scalability | 5 |
| Maintainability | 3 |
| Testing | 3 |
| UX/UI | 6 |
| Production Readiness | 3 |

**Overall average: ~4.3/10.**

This is meaningfully below the project's own internal self-assessments (which range as high as 8.2/10). The gap is the headline finding of this audit: **the application is a functioning, single-developer business tool with several genuinely well-built subsystems (Firestore RBAC rules, the accessibility toolkit, offline persistence), but it carries two live unresolved security exposures, inflated/contradictory internal documentation, and enough architectural drift and dead code that a new contributor — human or AI — would currently be misled by the project's own records of itself.**

### Top 10 Strengths

1. Clear, well-scoped business workflow mapped cleanly onto the Firestore schema.
2. Firestore security rules correctly implement non-trivial RBAC (admin/staff, assignment-scoped reads, financial-write protection) — verified working, not just claimed.
3. Genuine, comprehensive accessibility investment: a full `Semantics` extension toolkit used in 50+ places.
4. Cursor-based pagination for enquiry lists, not naive offset pagination.
5. Real cross-platform delivery: signed APKs, multiple release candidates, working CI with secret scanning.
6. Cloud Functions correctly enforce server-side admin checks before privileged operations.
7. Firestore offline persistence explicitly and correctly configured for both web and mobile.
8. Real, non-trivial unit tests exist for pure business logic (status validation, filters, role guards).
9. Evidence of real operational maturity: an actual rollback branch and multiple real release-candidate cuts with notes.
10. Thoughtful, business-specific UX details: one-tap call/WhatsApp shortcuts, calendar awareness, contact import.

### Top 10 Weaknesses

1. Two incompatible Firestore access patterns, with one unused dependency injection in the busiest repository class.
2. Three separate logging implementations with inconsistent (and in one path, absent) phone-number redaction.
3. No shared error-handling convention — 4+ ad hoc patterns coexist.
4. Real test coverage is far below internal claims; many tests are placeholders or silently no-op.
5. Multiple dead-code paths: legacy auth UI, unused route guards, orphaned dev-tool services, a stray `.bak` file.
6. Notifications feature is half-built: delivery works, but there's no in-app inbox.
7. Three "god screens" exceeding 1000 lines each.
8. Documentation sprawl with internally contradictory, sometimes templated, self-assessments.
9. Deploy pipeline ships production builds with crash/performance/analytics monitoring off, despite the code fully supporting all three.
10. Minimal responsive/adaptive layout work despite shipping to web, desktop, and mobile.

### Top 10 Risks

1. **Critical:** a live Gmail App Password is hardcoded in `functions/src/index.ts` today.
2. **Critical:** a previously leaked API key remains recoverable in git history; the purge that was claimed never actually ran.
3. Storage rules allow any authenticated user to read/write any enquiry's attachments, bypassing the assignment boundary enforced at the Firestore level.
4. Staff can read financial fields of assigned enquiries despite being blocked from writing them — likely unintended.
5. Possible still-deployed orphaned Cloud Functions with no remaining source to audit or maintain (unverifiable from the filesystem; needs a live `firebase functions:list` check).
6. Production currently ships with no crash/performance monitoring, so real failures may go undetected.
7. The Firestore-rules CI job references a missing script and would fail if triggered; the RBAC job fabricates its summary output — real CI coverage of the security rules is unconfirmed.
8. `/admin_audit` accepts writes from any signed-in user, undermining its value as a forensic record.
9. Single-author project (one contributor responsible for the overwhelming majority of commits) with no evident code-review process, raising the chance of unreviewed regressions.
10. Heavy reliance on unverified, self-generated documentation risks future decisions being made on false confidence about the project's actual security/test/readiness state.

### Top 10 Recommended Improvements

1. Remove and rotate the hardcoded Gmail App Password in `functions/src/index.ts` immediately.
2. Actually execute a verified git-history purge of the previously leaked API key, or rotate it and accept the historical exposure.
3. Add assignment/ownership checks to `storage.rules`, mirroring the pattern already correct in `firestore.rules`.
4. Wire the missing `--dart-define` flags into `deploy.yml` so Crashlytics/Performance/Analytics actually turn on in production.
5. Fix or remove the broken `ci_hardening.yml` job and replace `ci_rbac.yml`'s fabricated summary with real emulator-test output.
6. Consolidate to a single Firestore access layer; delete or fully adopt `FirestoreService`; remove the dead `EnquiryRepository` dependency.
7. Merge the two logger implementations into one with a single, complete PII-redaction policy covering phone numbers.
8. Decide explicitly whether staff should read financial fields, and make the rules match that decision.
9. Replace placeholder/no-op tests with real tests for the three largest, highest-traffic screens; regenerate a real coverage report.
10. Delete confirmed dead code (legacy auth, route guards, orphaned dev services) and either finish or remove the abandoned filters feature.

---

*This report reflects direct inspection of the repository as of 2026-06-18. Items noted as "unverifiable from the filesystem" (live Cloud Functions deploy state, whether CI jobs have actually executed with real secrets) require checking the live Firebase project and GitHub Actions run history respectively, and should not be assumed resolved either way without that check.*
