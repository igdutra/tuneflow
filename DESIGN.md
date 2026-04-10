# Design System: iTunes Challenge

## Summary

Dark, native-feeling music app UI with a pure black canvas, restrained chrome, and artwork as the primary visual color source. The system covers Splash, Library, Player, Album, Search, and Bottom Sheet states.

## Source of Truth

- Primary reference: approved mock screenshots in this folder.
- Splash gradient reference: `Mockup.png`.
- If code and mock diverge, follow the mock.

## Goals

- Preserve a premium iOS music-player feel without drifting into custom-brand UI.
- Keep hierarchy quiet: black canvas, white primary text, muted secondary text.
- Use glass/material effects sparingly and only where they create tactile playback controls.
- Keep the system implementation-friendly for SwiftUI and easy for downstream AI agents to apply.

## Non-Goals

- No card-based song list UI.
- No gray-tinted base backgrounds.
- No blur/glass on nav bars or full-screen surfaces.
- No dependency on a paid custom font for implementation.

## Visual Theme

- Tone: minimal, dark, native, music-first.
- Primary canvas: pure `#000000`.
- Color source: album artwork and the splash teal gradient.
- No dedicated accent color is visible in the approved mocks; interactive emphasis stays white/neutral.

## Foundations

### Color Tokens

```swift
// Backgrounds
background          #000000   // all screens, dominant canvas
surfaceElevated     #262626   // bottom sheet, search bar fill, icon buttons
surfaceHigh         #2C2C2E   // action sheet rows, contextual menus
separator           #3A3A3C   // progress bar track, dividers

// Text
textPrimary         #FFFFFF
textSecondary       #737373   // artist names, subtitles in list + album screens
textSecondaryAlpha  #FFFFFF @ 70%  // artist subtitle on player screen only

// Splash
splashGradient      linear: #000000 -> #0086A0   // diagonal, dark base to teal highlight

// Overlays
scrimDark           rgba(0,0,0,0.36)
glassBorder         rgba(255,255,255,0.10)
```

### Typography

Implementation font family: **SF Pro / San Francisco** throughout.
Design intent: neutral grotesk, medium-to-semibold emphasis, no decorative font styling.

| Role | Size | Weight | Color | Notes |
|---|---:|---|---|---|
| Screen title "Songs" | 34pt | Bold | `#FFFFFF` | Home screen only |
| Nav title (centered) | 17pt | Semibold | `#FFFFFF` | Player + Album |
| Song title (list) | 16pt | Medium | `#FFFFFF` | Approx. `.body` |
| Artist subtitle (list) | 12pt | Regular | `#737373` | Approx. `.caption` |
| Album header title | 28pt | Semibold | `#FFFFFF` |  |
| Album artist subtitle | 17pt | Regular | `#737373` |  |
| Player track title | 32pt | Bold | `#FFFFFF` | Custom size |
| Player artist subtitle | 16pt | Regular | `#FFFFFF @ 70%` | Player only |
| Time labels | 13pt | Regular | `#FFFFFF @ 60%` | Elapsed / remaining |
| Bottom sheet title | 17pt | Semibold | `#FFFFFF` |  |
| Bottom sheet subtitle | 13pt | Regular | `#737373` |  |

### Elevation & Materials

```text
Level 0   #000000 flat, no shadow      -> canvas, list, player base
Level 1   #1C1C1E contrast only        -> buttons, search bar, icon pills
Level 2   #2C2C2E native material      -> bottom sheet, action sheet
Glass     ultraThinMaterial + border   -> play button, nav icon buttons only
```

Glass is used only on circular playback/nav controls. Not on the nav bar. Not on the list.

## Components

### Song Row

```text
Height:         ~60pt effective tap target
Artwork:        50x50pt, cornerRadius 8pt
Gap art->text:  12pt
Title:          16pt Medium #FFFFFF
Subtitle:       12pt Regular #737373
Trailing (...): #FFFFFF @ 34% opacity, 44pt tap target
Separator:      none
Background:     transparent on #000000
```

### Navigation

```text
Home screen:    Large title "Songs" 34pt Bold, left-aligned, no nav bar chrome
Player screen:  Compact centered title 17pt Semibold + back (<) left + (...) right
Album screen:   Compact centered title 17pt Semibold + back (<) left only
Nav buttons:    Circular 44pt, background #1C1C1E, icon #FFFFFF
```

### Search Bar

```text
Shape:          full-width rounded pill, cornerRadius 10pt
Background:     #1C1C1E
Icon:           magnifyingglass, #FFFFFF @ 50%
Placeholder:    "Search" #737373
Height:         36pt
```

### Player Screen

```text
Album art:      ~280pt square, cornerRadius 16pt, centered
Track title:    32pt Bold #FFFFFF, left-aligned below art
Artist:         16pt Regular #FFFFFF @ 70%, left-aligned
Repeat icon:    right-aligned same row as artist, #FFFFFF @ 60%
Progress bar:   full-width, track #3A3A3C, fill #FFFFFF, thumb #FFFFFF 12pt circle
Time labels:    13pt #FFFFFF @ 60%, elapsed left / remaining right
Controls row:   previous (28pt) · play (56pt circle glass) · next (28pt), centered
```

### Playback Controls

```text
Play button:    56pt circle
Background:     #3A3A3C + .ultraThinMaterial blur overlay
Border:         1pt rgba(255,255,255,0.10)
Icon:           SF Symbol, #FFFFFF
Back/More btns: same glass pill treatment (44pt)
```

### Bottom Sheet

```text
Background:        #2C2C2E
Corner radius:     12pt top corners
Drag handle:       32x4pt, #3A3A3C, centered top
Title:             17pt Semibold #FFFFFF, centered
Subtitle:          13pt Regular #737373, centered
Action row:        17pt Regular #FFFFFF, leading icon 20pt #FFFFFF
Primary example:   View album
```

### Album Screen

```text
Background:     #000000
Art:            ~160pt square, cornerRadius 12pt, centered
Album title:    28pt Semibold #FFFFFF, centered
Artist:         17pt Regular #737373, centered
Song list:      same row spec as Song Row
```

### Splash Screen

```text
Background:     linear gradient - #000000 to #0086A0, diagonal with teal bias toward upper-right
Logo:           music note icon, centered vertically around 55% from top
```

## Layout Rules

```text
Screen margin:  16pt horizontal
Row padding:    12pt vertical per row
Art->text gap:  12pt
Section gap:    24pt
Top chrome:     safeAreaInset aware, no fixed height
Touch target:   44pt minimum for nav and trailing actions
```

Default to `List` for production data lists when system list behavior is useful. Use `ScrollView + LazyVStack` only when the visual spec or scroll behavior requires custom composition that `List` resists.

## Implementation Guidance

- Keep `#000000` as the true base on all primary screens.
- Use `#737373` for standard secondary text in list and album contexts.
- Use `#FFFFFF @ 70%` only for the player artist subtitle.
- Keep rows borderless and separator-free.
- Use artwork, not UI chrome, as the expressive color layer.
- Reserve glass/material treatment for circular playback and nav controls only.

## Guardrails

| Do | Don't |
|---|---|
| Pure `#000000` canvas | Gray-tinted backgrounds |
| Artwork as only color source | Extra brand colors |
| 16/12pt list rows | Oversized section headers |
| Glass only on circular controls | Blur the nav bar |
| `#737373` for all secondary list text | Apply alpha text everywhere |
| `#FFFFFF @ 70%` for player artist only | Use that alpha outside player context |
| Borderless rows, no separators | Cards around song rows |
| Circular 44pt nav buttons | Full-width rectangular buttons |
| One native font family: SF Pro | Mix multiple UI font families |
