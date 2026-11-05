---
name: framer-motion
description: Build React animations with Motion (formerly Framer Motion) - motion components, variants, enter/exit with AnimatePresence, layout and shared-element animations, gestures (hover, tap, drag), scroll-linked and in-view effects, springs, staggering, reduced motion and bundle size. Use when the user mentions Framer Motion, Motion for React, `motion/react`, `framer-motion`, or asks to animate, transition, or add micro-interactions to a React or Next.js UI.
---

# Motion (Framer Motion) for React

## Package and imports

- Current package: `motion` -> `import { motion, AnimatePresence } from "motion/react"`.
- Legacy package `framer-motion` has the same API. If the project already uses it,
  keep it; don't mix both in one app. Migration is just
  `npm i motion` + replace `"framer-motion"` imports with `"motion/react"`.
- Check `package.json` first and match what is installed.
- Next.js App Router: motion components are client-only. Either put
  `"use client"` at the top of the file, or import from `"motion/react-client"`
  (`import * as motion from "motion/react-client"`) inside server components.

## Core pattern

```tsx
<motion.div
  initial={{ opacity: 0, y: 16 }}
  animate={{ opacity: 1, y: 0 }}
  transition={{ duration: 0.3, ease: "easeOut" }}
/>
```

- Animate `transform` (`x`, `y`, `scale`, `rotate`) and `opacity` - they run on the
  GPU. Avoid animating `width`/`height`/`top`/`left`; use `layout` instead.
- `initial={false}` skips the mount animation (start in the `animate` state).
- Custom components: `motion.create(MyComponent)` (it must forward `ref`).

## Transitions

- Spring (default for physical values): `{ type: "spring", stiffness: 300, damping: 30 }`
  or the simpler `{ type: "spring", bounce: 0.2, visualDuration: 0.4 }`.
- Tween: `{ duration: 0.25, ease: "easeInOut" }` or a cubic bezier `[0.4, 0, 0.2, 1]`.
- Per-property: `transition={{ opacity: { duration: 0.2 }, x: { type: "spring" } }}`.
- App-wide defaults: wrap in `<MotionConfig transition={...}>`.

## Variants and staggering

```tsx
const list = {
  hidden: { opacity: 0 },
  show: { opacity: 1, transition: { staggerChildren: 0.06, delayChildren: 0.1 } },
};
const item = { hidden: { opacity: 0, y: 8 }, show: { opacity: 1, y: 0 } };

<motion.ul variants={list} initial="hidden" animate="show">
  {items.map((i) => <motion.li key={i.id} variants={item} />)}
</motion.ul>
```

Children inherit the variant names from the parent; don't repeat `initial`/`animate` on them.

## Exit animations (AnimatePresence)

```tsx
<AnimatePresence mode="wait">
  {open && (
    <motion.div key="modal" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} />
  )}
</AnimatePresence>
```

- The conditional element must be a **direct child** with a stable, unique `key`.
- `AnimatePresence` itself must stay mounted (don't put it inside the condition).
- `mode`: `"sync"` (default), `"wait"` (old leaves before new enters - route/step
  transitions), `"popLayout"` (removed item pops out of layout, siblings reflow with `layout`).
- Changing `key` on a child replays exit + enter (e.g. slideshows).

## Layout animations

- `layout` on a `motion.*` element animates size/position changes caused by any
  re-render (reorder, expand, flex changes).
- `layoutId="x"` on two different elements creates a shared-element transition
  (tabs underline, card -> modal).
- Wrap independently-rendered siblings in `<LayoutGroup>` so they animate together.
- Fix distorted children/border radius: give children `layout` too and set
  `borderRadius` via `style`, not CSS classes.
- `layout="position"` animates only position (good for text that reflows).

## Gestures

```tsx
<motion.button whileHover={{ scale: 1.04 }} whileTap={{ scale: 0.97 }} whileFocus={{ outline: "2px solid" }} />
<motion.div drag="x" dragConstraints={{ left: -100, right: 100 }} dragElastic={0.2} />
```

`dragConstraints` can also be a `ref` to a container element. Use `onTap`, not
`onClick`, if you also handle drag.

## Scroll

- In-view on scroll: `whileInView={{ opacity: 1 }}` + `viewport={{ once: true, amount: 0.3 }}`.
- Scroll-linked:

```tsx
const { scrollYProgress } = useScroll(); // or useScroll({ target: ref, offset: ["start end", "end start"] })
const scaleX = useSpring(scrollYProgress, { stiffness: 100, damping: 30 });
<motion.div style={{ scaleX, transformOrigin: "0%" }} />
```

- `useInView(ref, { once: true })` returns a boolean for non-animation logic.

## Motion values and imperative control

- `useMotionValue(0)`, `useTransform(x, [0, 100], [1, 0])`, `useSpring(x)` -
  pass via `style`; they update without React re-renders.
- `useMotionValueEvent(value, "change", cb)` to react to changes.
- `const [scope, animate] = useAnimate()` for sequences / imperative timelines:
  `await animate(scope.current, { x: 100 }); animate("li", { opacity: 1 }, { delay: stagger(0.05) })`.

## Accessibility

- Respect reduced motion: `<MotionConfig reducedMotion="user">` at the app root
  (disables transform/layout animations for users who request it), or branch on
  `useReducedMotion()` for custom behaviour.
- Keep UI feedback short (150-300 ms); avoid looping or large parallax motion on
  essential content.

## Bundle size

For size-sensitive apps use `LazyMotion` + the `m` component:

```tsx
import { LazyMotion, domAnimation, m } from "motion/react";
<LazyMotion features={domAnimation} strict><m.div animate={{ opacity: 1 }} /></LazyMotion>
```

Use `domMax` instead of `domAnimation` if you need drag or layout animations.

## Common pitfalls

- Exit animation not running -> missing/unstable `key`, or `AnimatePresence` unmounts too.
- Animation fires on every render -> objects for `animate` are fine, but a changing
  `key` remounts the element; check keys.
- Hydration warnings in Next.js -> component missing `"use client"`.
- Jank -> animating layout properties directly; switch to transforms or `layout`.
- Tailwind `transition-*` classes on the same element fight Motion; remove them.

Verify visually: run the app (see the `run` skill) and check the animation in a
browser, including with reduced motion enabled.
