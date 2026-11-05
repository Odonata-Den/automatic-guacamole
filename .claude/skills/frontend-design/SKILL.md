---
name: frontend-design
description: Design rules for building or changing any web UI in this project - landing pages, sections, components, layouts, styling, animation. Use whenever writing or editing JSX/TSX, HTML, CSS or Tailwind classes, integrating a 21st.dev or other copied component, or when the user asks to make something look better, more premium, or less "AI-generated".
---

# Frontend design

Every UI change follows one design system. Never introduce a one-off value
(font size, spacing, color, radius, shadow, duration) - use a token, or add a
token first and say so.

## 1. Tokens (single source of truth)

Define tokens once as CSS variables in `app/globals.css` and map them in
`tailwind.config` (`theme.extend`). Components use the Tailwind names, never raw hex.

```css
:root {
  /* neutrals - slightly warm, never pure #000/#fff for large surfaces */
  --bg: 40 20% 99%;        --surface: 40 14% 96%;   --border: 40 8% 88%;
  --fg: 30 10% 10%;        --muted: 30 6% 42%;
  /* brand - ONE primary, ONE accent; adjust hue to the brand */
  --primary: 250 70% 56%;  --primary-fg: 0 0% 100%;
  --accent: 160 60% 42%;
  --danger: 0 72% 51%;
}
.dark {
  --bg: 30 8% 6%;          --surface: 30 6% 10%;    --border: 30 5% 18%;
  --fg: 40 20% 96%;        --muted: 30 6% 64%;
  --primary: 250 85% 68%;  --accent: 160 55% 52%;
}
```

Usage ratio: ~85% neutrals, ~10% primary, ≤5% accent. Text contrast ≥ 4.5:1
(≥ 3:1 for text ≥ 24px). Check both themes.

## 2. Typography

- Two families max: a display face for headings (e.g. a characterful serif or
  geometric sans) + a neutral text sans. Load via `next/font` with
  `display: swap`; subset; no more than 2-3 weights per family.
- Scale (ratio ~1.25), in rem: `12 / 14 / 16 / 18 / 20 / 24 / 30 / 36 / 48 / 60 / 72`.
  Body 16-18px. Hero headline uses `clamp()` (e.g. `clamp(2.5rem, 6vw, 4.5rem)`).
- Headings: tight leading (1.05-1.15) and slight negative tracking (-0.02em).
  Body: leading 1.5-1.7, line length 60-75ch (`max-w-prose`).
- Hierarchy through size and weight, not color alone. One h1 per page.

## 3. Spacing & layout

- 8px base grid: `4, 8, 12, 16, 24, 32, 48, 64, 96, 128`. Nothing in between.
- Section vertical padding: 96-128px desktop, 64px mobile.
- Content width: `max-w-6xl` (1152px) with `px-4 sm:px-6 lg:px-8` gutters.
- Mobile-first. Breakpoints `sm 640 / md 768 / lg 1024 / xl 1280`. No horizontal
  scroll at 360px.
- Group related things tightly, separate unrelated things generously - whitespace
  is the main hierarchy tool.

## 4. Components

- **Radius**: `sm 6px` (inputs, small buttons), `md 10px` (buttons, cards), `lg 16px`
  (large panels), `full` (pills/avatars). Pick one per component type and keep it.
- **Shadows**: at most two levels, soft and low-opacity; prefer borders + subtle
  surface contrast over heavy shadows.
- **Buttons**: primary (filled), secondary (outline/surface), ghost. Every
  interactive element has `hover`, `focus-visible` (2px ring in `--primary`
  with offset), `active` and `disabled` states. Min target 44×44px.
- **Cards**: consistent padding (24 or 32), border `--border`, one heading, max
  ~3 lines of body text, optional icon at a fixed size.
- **Forms**: label above input, helper/error text below, error in `--danger`
  plus an icon or text (not color alone).
- **Icons**: one set only (e.g. lucide-react), one stroke width, sized 16/20/24.

## 5. Motion (Framer Motion)

- Use `motion` components; wrap the app in `<MotionConfig reducedMotion="user">`.
- Durations: 150ms (hover/press), 250ms (small UI), 400-600ms (section reveals).
  Easing `[0.22, 1, 0.36, 1]` (ease-out). No bouncy springs on text.
- Scroll reveals: `initial={{ opacity: 0, y: 16 }}`, `whileInView={{ opacity: 1, y: 0 }}`,
  `viewport={{ once: true, margin: "-80px" }}`. Lists stagger 60-80ms via
  `staggerChildren`.
- Hover: small `y: -2` / `scale: 1.02` lifts at most. Animate only `transform`
  and `opacity`.
- Keep animated client components small (`"use client"` leaf components);
  sections stay server components.

## 6. Integrating copied components (21st.dev etc.)

1. Replace every hard-coded color, radius, font size and spacing with the tokens above.
2. Replace placeholder copy and images with real content (or clearly marked TODOs).
3. Remove unused variants, dependencies and dead props.
4. Add the motion rules from section 5; check keyboard and screen-reader use.

## 7. Avoid the generic "AI website" look

- No purple-to-blue gradient blobs, glassmorphism everywhere, or emoji as icons.
- No three identical centered cards with a generic icon each as the only layout -
  vary rhythm (split layouts, asymmetric grids, a large visual, a quote).
- No vague copy ("Unlock the power of…", "Revolutionize your workflow").
  Headlines state a concrete benefit; CTAs say what happens ("Start free trial").
- Real proof: specific numbers, named customers/logos, real screenshots.
- Restraint: one strong visual idea per section.

## 8. Performance & accessibility (definition of done)

- `next/image` with explicit sizes; hero image `priority`, everything else lazy.
- No layout shift: reserve space for images, fonts and embeds.
- Semantic landmarks (`header`, `nav`, `main`, `footer`), alt text, label every
  control, visible focus, logical tab order.
- Target Lighthouse ≥ 90 for Performance, Accessibility, Best Practices, SEO.
