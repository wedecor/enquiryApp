# UI/UX Fix Prompt — We Decor Enquiries

Paste this whole document into Claude Code (or another coding agent) when you're ready to act on it. It's written to be self-contained: it states the problem, points at exact files, and defines what "done" looks like, so the agent doesn't have to guess at intent.

---

## Context

This is a Flutter + Firebase CRM app (`we_decor_enquiries`) for an event decoration business. Two roles: admin and staff. The codebase is functionally complete but the UI was never given a deliberate design pass — it's stock Material 3 styled inconsistently across very large screen files. Do not change any business logic, Firestore queries, Riverpod providers, or data models. This is a presentation-layer-only pass.

Before making changes, read these files to understand current state:
- `lib/core/theme/app_theme.dart` — current color scheme and component themes (light + dark)
- `lib/core/theme/tokens.dart` — spacing/radius/elevation/typography/breakpoint tokens (already well-designed, currently underused)
- `lib/features/dashboard/presentation/screens/dashboard_screen.dart` — 1600+ lines, contains the `Drawer`-based navigation (see `_buildNavigationDrawer` near line 1361)
- `lib/features/enquiries/presentation/screens/enquiry_form_screen.dart` — 1300+ lines
- `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart` — 1000+ lines
- `lib/core/a11y/semantics_ext.dart` — an existing, well-built accessibility extension toolkit. **Preserve and continue using this** for any new/refactored widgets; do not regress accessibility.
- `lib/shared/` and `lib/ui/components/` — existing shared widgets (`EmptyState`, `ErrorState`, etc.) — reuse these rather than inventing new ones unless a gap is found.

---

## Task 1 — Branding and color system

**Problem:** the current palette (`AppColorScheme.light`/`.dark` in `app_theme.dart`) is a generic Material teal/cyan (`#00B4D8`) that gives no visual identity to a decor/events business. It's technically correct (valid contrast pairs, light/dark variants, semantic success/warning/error colors already defined) — keep that structure, just change the hues.

**Do:**
- Replace the primary/secondary/tertiary hues with a palette suited to an event-decoration brand (warm, premium, hospitality-adjacent — think gold/amber, blush/rose, or deep emerald/sage rather than tech-cyan). If the user has an existing logo or brand asset anywhere in the repo (check `assets/`), derive the palette from that instead of picking arbitrarily.
- Keep the existing `ColorScheme` structure (all the `on*`/`*Container` roles must stay filled in correctly — don't leave any Material 3 role at a default).
- Keep `AppColorScheme.success/warning/info` semantic colors as functionally distinct from the new primary (they're used for status chips — must stay readable against both light and dark surfaces).
- Update `floatingActionButtonTheme`, `appBarTheme`, `tabBarTheme`, `switchTheme`, `chipTheme` to use the new colors consistently (they currently reference `AppColorScheme.light.primary` etc., so updating the source colors should cascade automatically — verify it actually does).

**Don't:**
- Don't introduce a second theming system or hardcode colors inline in screens — every color must still come from `Theme.of(context).colorScheme` or `AppColorScheme`.

---

## Task 2 — Break up the three oversized screens

**Problem:** `dashboard_screen.dart` (~1633 lines), `enquiry_form_screen.dart` (~1311 lines), and `enquiry_details_screen.dart` (~1020 lines) each mix layout, state, and business logic in one file. This is why spacing/hierarchy is inconsistent — every section was hand-built inline instead of composed from reusable pieces.

**Do, for each of the three screens:**
- Extract visually-distinct sections into their own widget files under that feature's `presentation/widgets/` folder. For example, `enquiry_details_screen.dart` should decompose into something like `CustomerInfoCard`, `EventDetailsCard`, `StatusSection`, `PaymentSection`, `HistoryTimeline` — each a small `StatelessWidget`/`ConsumerWidget` that takes the data it needs as parameters (or watches a narrow provider with `.select()`), not the whole screen's state.
- Every extracted card/section must use `AppSpacing`/`AppTokens` for all padding/margins — no raw `EdgeInsets.all(16)` literals. Audit the existing screens for raw spacing literals and replace them with token references as part of this pass.
- Create one shared `EnquiryCard` widget (if one doesn't already exist in `lib/ui/components/`) and use it everywhere an enquiry is shown in a list (dashboard list, search results, calendar day view) — there should not be more than one place that builds an enquiry list-item's layout from scratch.
- Preserve every `Semantics`/`withButtonSemantics()`/etc. call that exists today — when you move code into a new widget, the accessibility wrapper moves with it, it doesn't get dropped.
- Preserve all existing business logic, validators, and Riverpod provider wiring exactly as-is — this task is "move and restyle," not "rewrite logic."

**Don't:**
- Don't merge the three screens into one or change the navigation graph as part of this task — that's Task 3.
- Don't change Firestore field names, provider names, or method signatures used outside the file unless absolutely required by the extraction — if you must, list every call site you updated.

---

## Task 3 — Replace drawer navigation with bottom nav (mobile) / rail (tablet+)

**Problem:** primary navigation today is a `Drawer` (see `_buildNavigationDrawer` in `dashboard_screen.dart`). For an app with a small number of top-level destinations (Dashboard, Calendar, Enquiries, Analytics [admin only], Settings), a drawer requires two taps to switch sections and gives no persistent indication of where you are. `AppTokens.breakpointMobile/Tablet/Desktop` are already defined in `tokens.dart` but essentially unused elsewhere in the app (almost no screen uses `MediaQuery`/`LayoutBuilder`) — this task is also where that gets fixed.

**Do:**
- Build a single responsive navigation shell (e.g. `lib/core/navigation/app_shell.dart`) that:
  - Below `AppTokens.breakpointTablet`: shows a `NavigationBar` (Material 3 bottom nav) with 3–5 destinations based on role (fewer for staff, full set for admin).
  - At or above `AppTokens.breakpointTablet`: shows a `NavigationRail` (collapsed icons) on the left.
  - At or above `AppTokens.breakpointDesktop`: expand the rail to show labels, or switch to a permanent side nav drawer (the permanent, always-visible kind — not the swipe-in kind currently used).
  - Use `LayoutBuilder` or `MediaQuery.sizeOf(context)` against the existing breakpoint constants — don't invent new breakpoint values.
- Role-gate destinations the same way they're gated today (check how `dashboard_screen.dart` currently decides admin vs. staff drawer contents and replicate that logic, don't loosen it).
- Each top-level screen (Dashboard, Calendar, Enquiries, Analytics, Settings) should become a tab/destination body inside this shell rather than each one independently building its own `Scaffold` + `AppBar` + nav trigger. The existing screen widgets can mostly stay as-is internally — wrap them, don't necessarily gut them, unless their current `Scaffold` conflicts with the shell's.

**Don't:**
- Don't remove or weaken any role-based access check while doing this — if staff currently can't see a destination via the drawer, staff must still not see it in the new nav.
- Don't change deep-linking/route names if any screen is reached via a named route from elsewhere (check `lib/core/` for a router/route table before renaming anything).

---

## Acceptance criteria (verify before calling this done)

1. App builds and runs on at least one mobile target and the web target with no new analyzer warnings introduced.
2. Both light and dark themes render correctly with the new palette — spot check the dashboard, an enquiry detail screen, and settings in both modes.
3. No raw color literals (`Color(0xFF...)`) remain outside `app_theme.dart`/`tokens.dart` — everything else should reference the theme.
4. The three target screens are each reduced to primarily layout/composition code, with sections living in their own widget files.
5. Switching between Dashboard/Calendar/Enquiries/Settings takes one tap on mobile (bottom nav) and the current section is visibly indicated.
6. Resizing the web build across the three breakpoints visibly changes the navigation chrome (bottom bar → rail → expanded rail/permanent side nav) without errors.
7. Run through the app with a screen reader (or at minimum grep for `Semantics(` count before/after) to confirm no accessibility annotations were lost in the refactor.
8. Staff-role and admin-role views are each spot-checked to confirm role-based destination visibility still matches current behavior.

## Suggested order of execution

1. Task 1 (palette) first — it's low-risk and immediately visible, and Task 2/3 will use the updated theme as they go.
2. Task 3 (navigation shell) next — it's the highest-impact UX fix and creates the container the decomposed screens from Task 2 will sit inside.
3. Task 2 (screen decomposition) last, one screen at a time, smallest first (`enquiry_details_screen.dart`) to validate the pattern before tackling the larger two.

Commit after each task (or each screen within Task 2) so changes can be reviewed/reverted independently.
