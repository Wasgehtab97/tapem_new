---
name: ui-ux-pro-app
description: "UI/UX design intelligence for Flutter mobile apps. Includes 50+ styles, 161 color palettes, 57 font pairings, 161 product types, 99 UX guidelines, and 25 chart types. Actions: plan, build, create, design, implement, review, fix, improve, optimize, enhance, refactor, and check UI/UX code. Projects: mobile app, workout tracker, gym app, dashboard, onboarding, profile, NFC scan flow. Elements: button, modal, bottom sheet, nav bar, card, list tile, form, chart. Styles: glassmorphism, claymorphism, minimalism, brutalism, neumorphism, bento grid, dark mode, material you, cupertino. Topics: Flutter widget composition, Material 3, Cupertino, color systems, accessibility, animation, layout, typography, spacing, interaction states, shadow, gradient. Stack: Flutter/Dart with Riverpod and GoRouter."
---

# UI/UX Pro App - Flutter Design Intelligence

Comprehensive design guide for Flutter mobile applications. Contains 50+ styles, 161 color palettes, 57 font pairings, 161 product types with reasoning rules, 99 UX guidelines, and 25 chart types. Optimized for Flutter/Dart with Material 3, Cupertino, and custom widget patterns. Searchable database with priority-based recommendations.

## When to Apply

This Skill should be used when the task involves **Flutter UI structure, visual design decisions, interaction patterns, or user experience quality control**.

### Must Use

This Skill must be invoked in the following situations:

- Designing new Flutter screens (Home, Gym, Workout, Nutrition, Profile, Admin)
- Creating or refactoring Flutter widgets (buttons, bottom sheets, cards, list tiles, forms, charts, etc.)
- Choosing color schemes, typography systems, spacing standards, or ThemeData configuration
- Reviewing Flutter widget code for user experience, accessibility, or visual consistency
- Implementing navigation structures (GoRouter), animations, or responsive behavior
- Making product-level design decisions (style, information hierarchy, brand expression)
- Improving perceived quality, clarity, or usability of the Tap'em app

### Recommended

This Skill is recommended in the following situations:

- A Flutter screen looks "not professional enough" but the reason is unclear
- Receiving feedback on usability or experience
- Pre-release UI quality optimization
- Aligning design across iOS and Android (Material 3 + adaptive Cupertino)
- Building reusable widget libraries or ThemeData systems

### Skip

This Skill is not needed in the following situations:

- Pure backend/Supabase logic
- Drift database schema changes
- Riverpod provider logic unrelated to UI
- Edge Function or Supabase migration work
- Non-visual scripts or automation tasks

**Decision criteria**: If the task will change how a Flutter screen or widget **looks, feels, moves, or is interacted with**, this Skill should be used.

## Rule Categories by Priority

*For human/AI reference: follow priority 1→10 to decide which rule category to focus on first; use `--domain <Domain>` to query details when needed. Scripts do not read this table.*

| Priority | Category | Impact | Domain | Key Checks (Must Have) | Anti-Patterns (Avoid) |
|----------|----------|--------|--------|------------------------|------------------------|
| 1 | Accessibility | CRITICAL | `ux` | Contrast 4.5:1, Semantics widget, Keyboard nav, accessibilityLabel | Removing focus rings, Icon-only buttons without labels |
| 2 | Touch & Interaction | CRITICAL | `ux` | Min size 44x44pt/48x48dp, 8dp+ spacing, Loading feedback | No visual response on tap, Instant state changes (0ms) |
| 3 | Performance | HIGH | `ux` | const widgets, RepaintBoundary, ListView.builder, avoid rebuild | Rebuilding entire tree, setState in StatelessWidget equivalent |
| 4 | Style Selection | HIGH | `style`, `product` | Match Flutter style to product type, ThemeData consistency | Mixing Material and Cupertino randomly, Emoji as icons |
| 5 | Layout & Responsive | HIGH | `ux` | MediaQuery/LayoutBuilder, SafeArea, no overflow | Hardcoded pixel sizes, Ignoring safe areas |
| 6 | Typography & Color | MEDIUM | `typography`, `color` | TextTheme tokens, ColorScheme, 16sp+ body | Text < 12sp body, Gray-on-gray, Raw hex in widgets |
| 7 | Animation | MEDIUM | `ux` | Duration 150-300ms, AnimationController, Hero widgets | Animating layout properties directly, No reduced-motion respect |
| 8 | Forms & Feedback | MEDIUM | `ux` | Visible labels, SnackBar/error near field, ProgressIndicator | Placeholder-only label, Errors only at top |
| 9 | Navigation Patterns | HIGH | `ux` | GoRouter predictable back, BottomNavigationBar <=5, deep links | Overloaded nav, Broken back behavior |
| 10 | Charts & Data | LOW | `chart` | Legends, Tooltips, Accessible colors | Relying on color alone to convey meaning |

## Quick Reference

### 1. Accessibility (CRITICAL)

- `color-contrast` - Minimum 4.5:1 ratio for normal text (large text 3:1); use ColorScheme.onSurface pairs
- `semantics-widget` - Wrap custom widgets in Semantics() with label, hint, button roles
- `focus-states` - Visible focus rings on interactive elements (FocusNode + decoration)
- `accessibility-label` - Use Semantics(label:) for icon-only buttons and image assets
- `keyboard-nav` - Tab order matches visual order; ensure focusable elements are reachable
- `form-labels` - Always pair TextField with InputDecoration.labelText — never placeholder-only
- `heading-hierarchy` - Use TextTheme roles (displayLarge -> bodySmall) semantically
- `color-not-only` - Don't convey info by color alone (add icon/text)
- `dynamic-type` - Support system font scaling; avoid fixed pixel sizes for text
- `reduced-motion` - Check MediaQuery.disableAnimations; reduce/disable animations when requested
- `voiceover-talkback` - Meaningful Semantics labels/hints; logical traversal order for VoiceOver/TalkBack
- `escape-routes` - Provide cancel/back in dialogs and multi-step flows (PopScope, close button)

### 2. Touch & Interaction (CRITICAL)

- `touch-target-size` - Min 44x44pt (iOS) / 48x48dp (Android); use SizedBox or padding to expand hit area
- `touch-spacing` - Minimum 8dp gap between touch targets
- `inkwell-feedback` - Use InkWell or InkResponse for Material ripple; GestureDetector for custom
- `loading-buttons` - Disable button and show CircularProgressIndicator during async operations
- `error-feedback` - Clear SnackBar or inline error messages near the problem widget
- `gesture-conflicts` - Avoid horizontal swipe on main scroll content; prefer vertical scroll
- `press-feedback` - Visual feedback on press via InkWell ripple or AnimatedContainer opacity
- `haptic-feedback` - Use HapticFeedback.lightImpact() for confirmations; avoid overuse
- `gesture-alternative` - Always provide visible controls alongside gesture-only interactions
- `safe-area-awareness` - Wrap screens in SafeArea; keep tappable targets away from notch and gesture bar
- `no-precision-required` - Avoid requiring pixel-perfect taps on thin edges or tiny icons

### 3. Performance (HIGH)

- `const-widgets` - Mark widgets const wherever possible to prevent unnecessary rebuilds
- `listview-builder` - Use ListView.builder / SliverList for long lists; never Column + map for 50+ items
- `repaint-boundary` - Wrap frequently-updating children in RepaintBoundary to isolate repaints
- `avoid-opacity-widget` - Prefer AnimatedOpacity or FadeTransition over Opacity widget (forces compositing)
- `image-caching` - Use CachedNetworkImage; avoid raw Image.network without caching
- `lazy-loading` - Load data on demand; use FutureProvider / StreamProvider (Riverpod)
- `skeleton-screens` - Show shimmer/skeleton placeholder for >300ms loads; avoid blank screens
- `debounce-search` - Debounce search input with Timer to avoid excessive API calls
- `main-thread-budget` - Keep per-frame work under ~16ms; use Isolate or compute() for heavy tasks
- `tap-feedback-speed` - Provide visual feedback within 100ms of tap
- `offline-support` - Show offline state messaging and use Drift local cache (Tap'em is offline-first)

### 4. Style Selection (HIGH)

- `style-match` - Match Flutter widget style to product type (use `--design-system` for recommendations)
- `theme-consistency` - Use ThemeData / ColorScheme tokens across all screens; never hardcode colors
- `no-emoji-icons` - Use vector icons (Material Icons, Lucide, custom SVG via flutter_svg)
- `material-you` - Prefer Material 3 (useMaterial3: true) with dynamic color when appropriate
- `platform-adaptive` - Use adaptive widgets (CupertinoNavigationBar on iOS, AppBar on Android)
- `dark-mode-pairing` - Design light/dark ThemeData together; test both before delivery
- `elevation-consistent` - Use consistent Card elevation and shadow values from ThemeData
- `icon-style-consistent` - Use one icon family (Material or custom SVG) throughout the app
- `primary-action` - Each screen has one primary CTA (FilledButton); secondary actions visually subordinate

### 5. Layout & Responsive (HIGH)

- `safe-area` - Wrap root of each screen in SafeArea; handle notch and home indicator
- `media-query` - Use MediaQuery.of(context).size for adaptive sizing; LayoutBuilder for breakpoints
- `no-overflow` - Avoid fixed widths that cause overflow; use Flexible, Expanded, FittedBox
- `spacing-scale` - Use consistent 4dp/8dp spacing system; define spacing constants
- `scroll-behavior` - Use SingleChildScrollView carefully; prefer ListView/Sliver patterns
- `bottom-sheet-inset` - viewInsets.bottom for keyboard-aware scrolling in forms
- `orientation-support` - Keep layout readable and usable in landscape mode
- `tablet-adaptive` - Use wider layouts on tablets; avoid edge-to-edge content on large screens

### 6. Typography & Color (MEDIUM)

- `text-theme` - Use Theme.of(context).textTheme roles (headlineLarge, bodyMedium, etc.)
- `color-scheme` - Use ColorScheme (primary, onPrimary, surface, onSurface) — not raw hex
- `line-height` - Set height parameter on TextStyle (1.4-1.6 for body)
- `font-scale` - Use consistent type scale defined in ThemeData.textTheme
- `contrast-readability` - Dark text on light surfaces; verify with ColorScheme pairs
- `weight-hierarchy` - Bold headings (FontWeight.w700), regular body (w400), medium labels (w500)
- `dark-mode-contrast` - Dark mode text contrast >= 4.5:1; secondary text >= 3:1
- `number-tabular` - Use FontFeatures([FontFeature.tabularFigures()]) for data/timers

### 7. Animation (MEDIUM)

- `duration-timing` - 150-300ms for micro-interactions; use Curves.easeOut (enter) / easeIn (exit)
- `animated-container` - Use AnimatedContainer, AnimatedOpacity, AnimatedSwitcher for state changes
- `hero-transitions` - Use Hero widget for visual continuity between screens (e.g., equipment card -> detail)
- `page-transitions` - Use GoRouter transitions (CustomTransitionPage) for consistent navigation feel
- `loading-states` - Show CircularProgressIndicator or shimmer for loads >300ms
- `spring-physics` - Use SpringSimulation or CurvedAnimation with elastic curves for natural feel
- `reduced-motion` - Check MediaQuery.disableAnimations and skip animations when true
- `interruptible` - AnimationController.stop() on gesture; never block user input during animation
- `scale-feedback` - Subtle scale (0.95-1.0) on press for tappable cards via GestureDetector + AnimatedScale
- `shared-element` - Hero widget for list->detail transitions (NFC scan result, equipment detail)

### 8. Forms & Feedback (MEDIUM)

- `input-labels` - Always use InputDecoration.labelText; avoid placeholder-only fields
- `error-placement` - Use InputDecoration.errorText to show error below the related TextField
- `submit-feedback` - Show CircularProgressIndicator then SnackBar success/error on submit
- `required-indicators` - Mark required fields with asterisk in label
- `empty-states` - Show helpful message + CTA when list is empty (e.g., no workouts yet)
- `snackbar-duration` - Auto-dismiss SnackBars after 3-5 seconds; provide action when appropriate
- `confirmation-dialogs` - Use AlertDialog to confirm destructive actions (delete, reset)
- `inline-validation` - Validate onEditingComplete or on focus-out; not on every keystroke
- `keyboard-type` - Use TextInputType.number, emailAddress, etc. for correct soft keyboard
- `autofill-support` - Use autofillHints for common fields (email, password, name)
- `form-autosave` - Long forms should persist to local state to prevent loss on back navigation
- `sheet-dismiss-confirm` - Confirm before dismissing a ModalBottomSheet with unsaved changes

### 9. Navigation Patterns (HIGH)

- `bottom-nav-limit` - BottomNavigationBar max 5 items with labels + icons (Tap'em has 5 branches)
- `go-router-deep-link` - All key screens must be reachable via GoRouter named routes for notifications
- `back-behavior` - PopScope / GoRouter back must be predictable; preserve scroll and filter state
- `tab-bar-ios` - iOS: bottom tab bar for top-level navigation (matches Tap'em architecture)
- `nav-state-active` - Highlight current route in BottomNavigationBar (currentIndex)
- `modal-escape` - ModalBottomSheet and dialogs must have clear dismiss affordance (drag down, close button)
- `gesture-nav-support` - Don't block iOS swipe-back or Android predictive back
- `bottom-nav-top-level` - BottomNavigationBar for top-level only; never nest sub-nav inside it
- `state-preservation` - GoRouter StatefulShellRoute preserves scroll and state per branch
- `active-workout-guard` - Active workout session must never be interrupted by auth redirects (Drift persistence)

### 10. Charts & Data (LOW)

- `chart-type` - Match chart type to data (trend -> line, comparison -> bar, proportion -> donut)
- `fl-chart` - Use fl_chart package for Flutter charts; configure accessibility descriptions
- `color-guidance` - Use accessible color palettes; avoid red/green-only pairs
- `legend-visible` - Always show legend near the chart
- `tooltip-on-interact` - Show tooltips on tap for exact values (fl_chart TouchCallback)
- `axis-labels` - Label axes with units; avoid rotated labels
- `empty-data-state` - Show meaningful empty state when no data exists (e.g., "Complete a workout to see progress")
- `loading-chart` - Use shimmer placeholder while data loads

---

## How to Use This Skill

Use this skill when the user requests any of the following:

| Scenario | Trigger Examples | Start From |
|----------|-----------------|------------|
| **New Flutter screen** | "Build a workout screen", "Build a home dashboard" | Step 1 -> Step 2 (design system) |
| **New widget** | "Create a workout card", "Add a bottom sheet" | Step 3 (domain search: style, ux) |
| **Choose style / color / font** | "What style fits a gym tracker?", "Recommend a color palette" | Step 2 (design system) |
| **Review existing UI** | "Review this screen for UX issues", "Check accessibility" | Quick Reference checklist above |
| **Fix a UI bug** | "Button state is wrong", "Layout overflows on small phone" | Quick Reference -> relevant section |
| **Improve / optimize** | "Reduce rebuilds", "Improve scroll performance" | Step 3 (domain search: ux) |
| **Add dark mode** | "Add dark mode support" | Step 3 (domain: style "dark mode") |
| **Add charts** | "Add a progress chart" | Step 3 (domain: chart) |

Follow this workflow:

### Step 1: Analyze User Requirements

Extract key information from user request:
- **Product type**: Fitness tracker / Gym workout app / NFC-first experience
- **Target audience**: Gym members and gym owners; varied age, workout-focused context
- **Style keywords**: athletic, dark mode, energetic, minimal, focused, clean
- **Stack**: Flutter (Dart) with Riverpod, GoRouter, Drift, Material 3

### Step 2: Generate Design System (REQUIRED)

**Always start with `--design-system`** to get comprehensive recommendations with reasoning:

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "<product_type> <industry> <keywords>" --design-system [-p "Project Name"]
```

This command:
1. Searches domains in parallel (product, style, color, typography)
2. Applies reasoning rules from `ui-reasoning.csv` to select best matches
3. Returns complete design system: pattern, style, colors, typography, effects
4. Includes anti-patterns to avoid

**Example for Tap'em:**
```bash
python3 skills/ui-ux-pro-app/scripts/search.py "fitness gym workout tracker dark athletic" --design-system -p "Tapem"
```

### Step 2b: Persist Design System (Master + Overrides Pattern)

To save the design system for **hierarchical retrieval across sessions**, add `--persist`:

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "<query>" --design-system --persist -p "Project Name"
```

This creates:
- `design-system/MASTER.md` — Global Source of Truth with all design rules
- `design-system/screens/` — Folder for screen-specific overrides

**With screen-specific override:**
```bash
python3 skills/ui-ux-pro-app/scripts/search.py "<query>" --design-system --persist -p "Tapem" --page "workout-active"
```

**How hierarchical retrieval works:**
1. When building a specific screen (e.g., "Active Workout"), check `design-system/screens/workout-active.md`
2. If it exists, its rules **override** the Master file
3. If not, use `design-system/MASTER.md` exclusively

**Context-aware retrieval prompt:**
```
I am building the [Screen Name] Flutter screen. Please read design-system/MASTER.md.
Also check if design-system/screens/[screen-name].md exists.
If the screen file exists, prioritize its rules.
If not, use the Master rules exclusively.
Now generate the Flutter widget code...
```

### Step 3: Supplement with Detailed Searches (as needed)

After getting the design system, use domain searches for additional details:

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "<keyword>" --domain <domain> [-n <max_results>]
```

**When to use detailed searches:**

| Need | Domain | Example |
|------|--------|---------|
| Product type patterns | `product` | `--domain product "fitness workout tracker"` |
| Style options | `style` | `--domain style "dark mode athletic minimal"` |
| Color palettes | `color` | `--domain color "fitness gym dark"` |
| Font pairings | `typography` | `--domain typography "modern athletic bold"` |
| Chart recommendations | `chart` | `--domain chart "progress trend line"` |
| UX best practices | `ux` | `--domain ux "animation accessibility touch"` |
| Flutter-specific UI guidelines | `web` | `--domain web "accessibilityLabel touch safe-areas Dynamic Type"` |
| Style keywords | `prompt` | `--domain prompt "dark athletic"` |

### Step 4: Stack Guidelines (Flutter)

Get mobile-native implementation best practices:

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "<keyword>" --stack react-native
```

> Note: Use `--stack react-native` for the closest mobile-native guidance; apply the patterns using Flutter equivalents (FlatList -> ListView.builder, StyleSheet -> ThemeData, etc.).

---

## Search Reference

### Available Domains

| Domain | Use For Flutter | Example Keywords |
|--------|----------------|------------------|
| `product` | App type recommendations | fitness, gym, tracker, health, social |
| `style` | UI styles, visual treatment | glassmorphism, dark mode, minimalism, athletic |
| `typography` | Font pairings for ThemeData | bold, modern, clean, professional |
| `color` | ColorScheme palettes | fitness, health, dark, energy |
| `chart` | Chart types for fl_chart | trend, progress, comparison, timeline |
| `ux` | UX best practices | animation, accessibility, loading, touch targets |
| `web` | App interface guidelines (iOS/Android) | accessibilityLabel, safe areas, Dynamic Type |
| `prompt` | Style keywords | (style name) |

---

## Example Workflow

**User request:** "Redesign the Home screen of Tap'em."

### Step 1: Analyze Requirements
- Product type: Fitness / gym workout tracker (NFC-first)
- Target audience: Gym members, workout-focused
- Style keywords: athletic, dark mode, energetic, clean, Material 3
- Stack: Flutter + Riverpod + GoRouter

### Step 2: Generate Design System

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "fitness gym workout dark athletic material" --design-system -p "Tapem"
```

### Step 3: Supplement with Detailed Searches

```bash
# Style for a fitness app
python3 skills/ui-ux-pro-app/scripts/search.py "dark athletic minimal" --domain style

# UX for workout interactions and loading
python3 skills/ui-ux-pro-app/scripts/search.py "touch loading animation progress" --domain ux
```

### Step 4: Stack Guidelines

```bash
python3 skills/ui-ux-pro-app/scripts/search.py "list performance navigation safe-area" --stack react-native
```

**Then:** Synthesize design system + searches and implement Flutter widgets.

---

## Output Formats

```bash
# ASCII box (default) - best for terminal display
python3 skills/ui-ux-pro-app/scripts/search.py "fitness dark athletic" --design-system

# Markdown - best for documentation
python3 skills/ui-ux-pro-app/scripts/search.py "fitness dark athletic" --design-system -f markdown
```

---

## Tips for Better Results

### Query Strategy

- Use **multi-dimensional keywords**: combine product + industry + tone: `"fitness gym workout dark energetic"` not just `"app"`
- Try different keywords: `"athletic dark"` -> `"energetic minimal"` -> `"content-first dark mode"`
- Use `--design-system` first for full recommendations, then `--domain` to deep-dive
- Always translate results to Flutter idioms (TextStyle, ThemeData, ColorScheme, widget names)

### Common Sticking Points

| Problem | What to Do |
|---------|------------|
| Can't decide on style/color | Re-run `--design-system` with different keywords |
| Dark mode contrast issues | Quick Reference §6: `dark-mode-contrast` + `color-scheme` |
| Animations feel unnatural | Quick Reference §7: `spring-physics` + `duration-timing` |
| Form UX is poor | Quick Reference §8: `inline-validation` + `error-placement` |
| Navigation feels confusing | Quick Reference §9: `go-router-deep-link` + `bottom-nav-limit` |
| Layout breaks on small phone | Quick Reference §5: `safe-area` + `no-overflow` |
| Jank / slow scrolling | Quick Reference §3: `const-widgets` + `listview-builder` + `repaint-boundary` |

---

## Common Rules for Professional Flutter UI

### Icons & Visual Elements

| Rule | Standard | Avoid | Why It Matters |
|------|----------|--------|----------------|
| **No Emoji as Icons** | Material Icons, Lucide, or custom SVG via flutter_svg | Emojis for navigation or system controls | Emojis render inconsistently across platforms and can't be themed |
| **Vector-Only Assets** | SVG via flutter_svg or Material IconData | Raster PNG icons that blur on high-DPI screens | Crisp rendering on all device densities |
| **Stable Interaction States** | AnimatedContainer opacity/color transitions | Transforms that shift layout bounds or cause jitter | Prevents visual instability |
| **Consistent Icon Sizing** | Size constants (e.g. 20, 24, 28) in ThemeData | Random ad-hoc sizes per widget | Visual rhythm and hierarchy |
| **Touch Target Minimum** | Min 44x44pt via SizedBox or padding; hitTestBehavior.opaque | Small icons without expanded tap area | Apple HIG + Material accessibility |

### Interaction (Flutter)

| Rule | Do | Don't |
|------|----|----- |
| **Tap feedback** | InkWell ripple or AnimatedOpacity within 80-150ms | Raw GestureDetector with no visual response |
| **Animation timing** | 150-300ms with Curves.easeOut/easeIn | Instant transitions or slow animations (>500ms) |
| **Accessibility** | Semantics widget with label, hint, button role | Unlabeled controls, missing accessibilityLabel |
| **Disabled state** | enabled: false on buttons; opacity 0.38 | Controls that look tappable but do nothing |
| **Touch target** | >=44x44pt via SizedBox/padding | Tiny tap targets without padding |
| **Gesture conflicts** | One primary gesture per region | Overlapping GestureDetectors causing accidental actions |

### Light/Dark Mode Contrast

| Rule | Do | Don't |
|------|----|----- |
| **Surface readability** | ColorScheme.surface with sufficient elevation/shadow | Overly transparent cards that blur hierarchy |
| **Text contrast (light)** | onSurface >=4.5:1 against surface | Low-contrast gray body text |
| **Text contrast (dark)** | Primary >=4.5:1, secondary >=3:1 on dark surfaces | Dark mode text blending into background |
| **Token-driven theming** | ColorScheme semantic tokens throughout | Hardcoded hex colors per-screen |
| **Modal scrim** | ModalBarrier color ~40-60% black | Weak scrim leaving background competing |

### Layout & Spacing

| Rule | Do | Don't |
|------|----|----- |
| **SafeArea compliance** | Wrap screens in SafeArea | Fixed UI overlapping notch or gesture bar |
| **Keyboard insets** | MediaQuery.viewInsets.bottom on forms | Form fields hidden behind keyboard |
| **8dp rhythm** | Consistent 4/8dp spacing via EdgeInsets constants | Random spacing with no rhythm |
| **Scroll + fixed coexistence** | Bottom padding equal to BottomNavigationBar height | List content obscured by bottom nav |
| **Overflow prevention** | Flexible, Expanded, FittedBox | Fixed widths causing RenderFlex overflow |

---

## Pre-Delivery Checklist

### Visual Quality
- [ ] No emojis as icons (use Material Icons or SVG)
- [ ] All icons from a consistent family
- [ ] ThemeData / ColorScheme tokens used — no hardcoded hex
- [ ] Pressed states use InkWell ripple or AnimatedOpacity, not layout shifts
- [ ] Dark and light ThemeData both defined and tested

### Interaction
- [ ] All tappable elements provide pressed feedback within 80-150ms
- [ ] Touch targets >=44x44pt (iOS) / 48x48dp (Android)
- [ ] Micro-interaction timing 150-300ms with native-feeling easing
- [ ] Disabled states: enabled: false + reduced opacity (0.38)
- [ ] Semantics labels on icon-only buttons and images
- [ ] No nested GestureDetector conflicts

### Light/Dark Mode
- [ ] Primary text contrast >=4.5:1 in both modes
- [ ] Secondary text contrast >=3:1 in both modes
- [ ] Dividers and borders visible in both modes
- [ ] Modal/bottom sheet scrim opacity 40-60% black
- [ ] Both themes tested before delivery

### Layout
- [ ] SafeArea applied on all root screens
- [ ] Keyboard-aware scroll (viewInsets.bottom) on forms
- [ ] No RenderFlex overflow on small phone (375pt)
- [ ] Verified on small phone, large phone, and tablet (portrait + landscape)
- [ ] 4/8dp spacing rhythm maintained
- [ ] BottomNavigationBar content inset applied to scrollable lists

### Accessibility
- [ ] All meaningful images/icons have Semantics labels
- [ ] TextFields have labelText, hintText, and clear errorText
- [ ] Color is not the only indicator of state
- [ ] Dynamic Type supported — no fixed text sizes
- [ ] Accessibility traits/roles/states annotated via Semantics
