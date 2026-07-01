# We Decor Enquiries — Design Spec v1

**Status:** Draft for review  
**Scope:** Presentation layer only — no business logic, Firestore, or provider changes  
**North star:** *Calm cream workspace. Terracotta for actions only. Enquiries as scannable rows — not decorated cards.*

---

## 1. Design principles

| Principle | Meaning |
|-----------|---------|
| **Calm first** | The dashboard should feel like a quiet workspace, not a chart wall. |
| **One accent** | Terracotta is the only strong brand hue in daily UI. Sage and clay are supporting neutrals. |
| **Semantics ≠ brand** | Status colors convey meaning; they are muted and never compete with terracotta. |
| **Scan, then act** | List rows are readable in &lt;2 seconds. Details and actions are one tap away. |
| **One pattern per entity** | Every enquiry list uses the same row anatomy everywhere. |
| **Tokens, not literals** | All spacing, radius, color, and type come from `tokens.dart` / `app_theme.dart`. |

---

## 2. Color system

### 2.1 Roles (strict)

```
┌─────────────────────────────────────────────────────────────┐
│  BRAND     Terracotta — FAB, primary buttons, active nav,   │
│              focused inputs, key CTAs only                   │
├─────────────────────────────────────────────────────────────┤
│  NEUTRAL   Cream / warm white / warm brown text & borders   │
│              — surfaces, backgrounds, metadata               │
├─────────────────────────────────────────────────────────────┤
│  SEMANTIC  Success / warning / error — status & alerts only │
│              — never used for decoration                     │
├─────────────────────────────────────────────────────────────┤
│  CHANNEL   WhatsApp green, phone blue — icon or label tint  │
│              on contact buttons only; not chips or headers   │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Brand palette (light mode)

Keep the existing cream/terracotta foundation; tighten usage rather than replacing hues.

| Token | Hex | Use |
|-------|-----|-----|
| `brand.primary` | `#D4603A` | FAB, filled buttons, active tab indicator, focused field border |
| `brand.primaryContainer` | `#FFE0D3` | Selected nav item bg, subtle highlights (max 10% of screen) |
| `brand.secondary` | `#B07355` | Secondary labels, rail icons (inactive→active transition) |
| `brand.tertiary` | `#5B7553` | “All caught up”, success-adjacent calm states only |
| `surface.canvas` | `#FBF8F3` | Scaffold background |
| `surface.card` | `#FFFFFF` | Cards, list rows, modals |
| `surface.muted` | `#F0E6DA` | KPI strip bg, input fill (from `surfaceContainerHighest`) |
| `text.primary` | `#2C241D` | Headings, names |
| `text.secondary` | `#6B5E52` | Metadata, captions |
| `border.subtle` | `#E8DDD0` | Card outlines, dividers |

**Rule:** No more than **one** `brand.primary` element in the viewport above the fold (e.g. FAB *or* active tab — not both screaming; FAB is allowed as the single strong accent).

### 2.3 Status colors (muted)

Status must read at a glance but not rainbow the list. Use **dot + short label** or **ghost pill** (10–14% opacity fill), not full saturated chips.

| Status | Color | Dot / pill |
|--------|-------|------------|
| New | `#2563EB` | Blue |
| In talks | `#D97706` | Amber |
| Quote sent | `#7C3AED` | Purple |
| Confirmed | `#059669` | Green |
| Completed | `#0891B2` | Cyan |
| Closed / not interested | `#DC2626` | Red |

**Do not** also paint event-type badges in a second strong hue on the same row. Event type = plain text or neutral pill.

### 2.4 Urgency (Needs Attention only)

Replace pink/red tinted cards with a single system:

| Level | Treatment |
|-------|-----------|
| Critical | Left border 3px `error` + neutral card bg |
| High | Left border 3px `warning` + neutral card bg |
| Medium | Left border 3px `primary` + neutral card bg |
| Low | No border; icon + text only |

No full-card pink backgrounds.

### 2.5 Dark mode

Keep existing dark warm browns. Apply the same role rules: terracotta for actions only, muted status dots, cream-tinted text.

---

## 3. Typography

### 3.1 Font stack

| Role | Family | Fallback |
|------|--------|----------|
| **Display / headings** | [Outfit](https://fonts.google.com/specimen/Outfit) SemiBold | system sans |
| **Body / UI** | [DM Sans](https://fonts.google.com/specimen/DM+Sans) Regular/Medium | system sans |

Add to `pubspec.yaml` under `fonts:` when implementing. Until then, use system with adjusted weights.

### 3.2 Type scale

| Style | Size | Weight | Use |
|-------|------|--------|-----|
| `display` | 28px | 600 | Login hero, empty states |
| `titleLarge` | 20px | 600 | Screen titles (AppBar) |
| `titleMedium` | 16px | 600 | Card titles, customer name in row |
| `bodyLarge` | 16px | 400 | Form labels, primary body |
| `bodyMedium` | 14px | 400 | Default UI text |
| `bodySmall` | 12px | 400 | Metadata (date, location, age) |
| `labelMedium` | 12px | 500 | Chips, buttons, tab labels |

**Rules:**
- Customer name in lists: `titleMedium` only — not `headlineSmall` + bold.
- Metadata always `bodySmall` + `onSurfaceVariant`.
- Max **two** weights on one row (semibold name + regular meta).

### 3.3 Line height

- Headings: 1.25  
- Body: 1.45  
- Dense metadata rows: 1.35  

---

## 4. Spacing & layout

### 4.1 Grid

- Base unit: **4px**
- Screen horizontal padding: **`space4` (16px)** on phone; **`space6` (24px)** on tablet+
- Section gap: **`space6` (24px)** between major blocks
- List item gap: **`space3` (12px)** between rows

### 4.2 Radius

| Element | Radius |
|---------|--------|
| Cards, list rows | `radiusLarge` (12px) |
| Buttons, inputs | `radiusMedium` (8px) |
| Pills, status dots | `radiusFull` |
| Bottom sheets | `radiusXLarge` (16px) top corners |

### 4.3 Elevation

| Level | Use |
|-------|-----|
| 0 | List rows (border only, no shadow) |
| 1 | Cards on canvas, pinned header |
| 2 | FAB, dialogs |
| 3 | Modals, bottom sheets |

**Rule:** Prefer **1px `outlineVariant` border** over shadow for list rows.

### 4.4 Breakpoints (existing)

| Width | Navigation | Content max-width |
|-------|------------|-------------------|
| &lt; 768px | Bottom nav (max **4** items visible; rest in “More” if needed) | 100% |
| 768–1023px | Collapsed rail | 100% |
| ≥ 1024px | Extended rail | Optional 1200px centered content on analytics |

---

## 5. Navigation shell

### 5.1 Destinations

**Staff (4):** Dashboard · Calendar · Enquiries · Settings  

**Admin (5):** Dashboard · Calendar · Enquiries · Analytics · Settings  

Move **Board** under Enquiries as a view toggle (list ↔ kanban), not a top-level tab.

### 5.2 Chrome

```
┌──────────────────────────────────────────┐
│ [Logo mark]  Screen title     🔔  ⎋    │  AppBar — white surface, no tint
├──────────────────────────────────────────┤
│                                          │
│              (screen body)               │
│                                          │
├──────────────────────────────────────────┤
│  ◉ Dash   Calendar   Enquiries   ⚙      │  Bottom nav — icon + short label
└──────────────────────────────────────────┘
```

- **AppBar:** `surface` bg, `titleLarge`, no colored background.
- **Active nav item:** `primary` icon + label; inactive: `onSurfaceVariant`.
- **FAB:** `primary` fill; single FAB per screen (Add enquiry).
- **Remove** debug banners from release builds.

### 5.3 Brand mark

- Placeholder until logo asset exists: wordmark **“We Decor”** in Outfit 600 + small terracotta dot or leaf icon.
- Rail expanded (desktop): logo + wordmark at top.

---

## 6. Dashboard — information architecture

### 6.1 Wireframe (mobile)

```
┌─────────────────────────────────────┐
│ Good morning, Mohammed    [avatar]  │  compact greeting — 1 line
├─────────────────────────────────────┤
│ NEEDS ATTENTION                     │  section label (titleSmall)
│ ┌──────┐ ┌──────┐ ┌──────┐         │  horizontal scroll, neutral cards
│ │14 new│ │19 f/u│ │14 evt│         │  left accent border by urgency
│ └──────┘ └──────┘ └──────┘         │
├─────────────────────────────────────┤
│ [New][In Talks][Follow Up]… →      │  scrollable tabs
│ 🔍 Search by name or phone…        │  pinned below tabs
├─────────────────────────────────────┤
│ 14 results · Sort: [Event↑]…       │  single line, muted
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ ● Shifa          Wedding · 6 Jul │ │  enquiry row (see §7)
│ │   Wilson Garden · 9h · Zakir    │ │
│ └─────────────────────────────────┘ │
│ ┌─────────────────────────────────┐ │
│ │ ● Tanisha        Birthday · …   │ │
│ └─────────────────────────────────┘ │
│              …                      │
└─────────────────────────────────────┘
                                    [+]
```

### 6.2 What moves out of dashboard

| Element | New home |
|---------|----------|
| 7 KPI cards + date filter | **Analytics** screen (admin) or collapsible “Stats” sheet |
| Sort chip bar (4 modes) | Overflow menu “Sort by…” on dashboard; default Event date ↑ |
| Duplicate “new” counts | One source: Needs Attention **or** tab badge, not both KPI + bucket |

### 6.3 KPI rule (when shown)

- Never show **“—”** as a primary value. Hide the metric or show `0`.
- Label the time range explicitly: `This month` / `All time`.
- Max **3** KPIs on phone if a summary strip is kept.

### 6.4 Tab badges (optional)

Small count on tab: `New (14)` — uses `onSurfaceVariant`, not red.

---

## 7. Enquiry row — canonical component

**Name:** `EnquiryListRow` (replaces dual `EnquiryCard` + `EnquiryTileStatusStrip` patterns)

### 7.1 Anatomy

```
┌────────────────────────────────────────────────────────┐
│ ●  Customer name                          ›           │  row 1: status dot, name, chevron
│    Event type · Event date                             │  row 2: muted, single line
│    Location · age · assignee                           │  row 3: optional, truncated
└────────────────────────────────────────────────────────┘
```

### 7.2 Spec

| Part | Spec |
|------|------|
| Height | Min 72px; max ~88px with 3 lines |
| Status | 8px dot, color from status table (§2.3) |
| Name | `titleMedium`, 1 line ellipsis |
| Line 2 | `bodySmall`, `onSurfaceVariant`, ` · ` separated |
| Line 3 | Same as line 2; omit if empty |
| Container | `surface.card`, 1px `outlineVariant`, `radiusLarge`, **no** left color strip |
| Tap | Whole row → enquiry detail |
| Long press | Bottom sheet: Call · WhatsApp · Update status |

### 7.3 Actions

**Remove** per-row WhatsApp / Call / View button row from lists.

Contact actions live in:
1. **Detail screen** header (primary)
2. **Long-press sheet** on list row (secondary)

### 7.4 Where used

- Dashboard tabs  
- Enquiries list  
- Search results  
- Calendar day drawer (compact variant: 2 lines only)

### 7.5 Deprecated patterns

- `EnquiryTileStatusStrip` full tile with chip wrap + action row → migrate to `EnquiryListRow`
- `EnquiryCard` with inline action buttons → migrate or keep only for kanban/board cards

---

## 8. Component library

### 8.1 Status pill (detail & filters only)

Ghost pill for filters and detail header — not in dense lists.

```
background: statusColor @ 12%
border:     statusColor @ 25%
text:       statusColor @ 100%
padding:    4px 10px
radius:     full
```

### 8.2 Needs Attention card

```
width:      140px (phone), 160px (tablet+)
height:     80px
padding:    12px
background: surface.card
border:     1px outlineVariant + 3px left accent (urgency)
icon:       20px, accent color
label:      titleSmall
sublabel:   bodySmall, onSurfaceVariant
```

### 8.3 Search field (pinned)

```
height:     40px
fill:       surface.muted
border:     none (default), 1.5px primary (focused)
radius:     full (24px) — keep current pill shape
icon:       20px search, 18px clear
```

### 8.4 Buttons

| Type | Style |
|------|-------|
| Primary | Filled terracotta, white label |
| Secondary | Outlined terracotta 40% border |
| Tertiary | Text only, terracotta label |
| Destructive | Filled error (confirm dialogs only) |
| Contact | Outlined neutral; icon tinted channel color |

### 8.5 Empty states

- Icon 48px `onSurfaceVariant` @ 60%  
- Title `titleMedium`  
- Body `bodySmall`  
- Optional CTA: primary button “Add enquiry”  
- Vertically centered in scrollable area  

---

## 9. Screen guidelines

### 9.1 Login

- Cream canvas, centered card max 400px wide  
- Logo + “We Decor Enquiries” display  
- Minimal fields; primary button full width  
- No debug UI  

### 9.2 Enquiry detail

Sections as stacked cards with **section title** (`labelMedium`, uppercase optional, letter-spacing 0.5):

1. Customer (name, phone, WhatsApp)  
2. Event (type, date, location)  
3. Status (inline control)  
4. Financial (admin only)  
5. Notes & history  

**Sticky footer** on mobile: `Update status` (primary) + overflow menu.

### 9.3 Enquiry form

- Same section cards as detail  
- One column on phone  
- Save sticky footer; validate on save  
- Images: horizontal thumbnail strip  

### 9.4 Analytics (admin)

- Home for KPI grid, date filters, charts  
- Use `chartPalette` here — charts are the one place rainbow is acceptable  
- Dashboard links here via “View all stats” text button  

### 9.5 Calendar

- Month grid: event dots use status color (dot only)  
- Day panel: `EnquiryListRow` compact  

### 9.6 Settings

- Standard M3 list tiles  
- No brand color except switches and primary links  

---

## 10. Motion

| Interaction | Duration | Curve |
|-------------|----------|-------|
| Tab change | 200ms | easeOut |
| Row tap ripple | default | — |
| Bottom sheet | 300ms | easeOutCubic |
| Needs attention scroll | physics default | — |

Avoid animation on KPI numbers or list reorder unless explicit user action.

---

## 11. Accessibility

- All tappable rows: min 48px height  
- Status dot + text label (never color alone)  
- Preserve existing `Semantics` / `semantics_ext.dart` patterns when refactoring  
- Contrast: metadata `onSurfaceVariant` must pass 4.5:1 on `surface.card`  

---

## 12. Implementation phases (when ready)

| Phase | Work | Outcome |
|-------|------|---------|
| **1** | Color role audit — remove inline colors; mute list chips | Less visual noise |
| **2** | Build `EnquiryListRow`; migrate dashboard + enquiries list | One list pattern |
| **3** | Dashboard IA — move KPIs, simplify header, urgency cards | Calmer home |
| **4** | Typography — load Outfit + DM Sans | Brand voice |
| **5** | Nav — 4–5 destinations, Board as view toggle | Less cramped mobile nav |
| **6** | Detail/form sticky footers + section cards | Cohesive forms |
| **7** | Polish — logo, remove debug, dark mode pass | Ship-ready feel |

Each phase: one PR, visual check on phone + web at 3 breakpoints.

---

## 13. Acceptance checklist

- [ ] Terracotta appears on ≤2 component types per screen (e.g. FAB + active nav)  
- [ ] Enquiry list uses one row component everywhere  
- [ ] No “—” in primary metrics without explicit “N/A” copy  
- [ ] No full-width action button row on list items  
- [ ] No raw `Color(0x…)` outside `app_theme.dart`  
- [ ] No raw `EdgeInsets.all(16)` — use `AppSpacing` / `AppTokens`  
- [ ] Dashboard shows Needs Attention above tabs, KPIs relocated  
- [ ] Light + dark spot-checked on dashboard, detail, settings  
- [ ] Release build has no DEBUG banner  

---

## 14. Open decisions (for product owner)

1. **Logo asset** — provide SVG/PNG or use wordmark placeholder?  
2. **Board view** — keep kanban for admin only or all users?  
3. **KPIs on dashboard** — remove entirely vs single collapsible “Stats” row?  
4. **Default sort** — event date asc (current) vs created desc?  
5. **Font licensing** — Outfit + DM Sans are free (Google Fonts); confirm for APK size budget.  

---

*End of spec v1*
