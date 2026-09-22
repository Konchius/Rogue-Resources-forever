# Changelog

## 1.1.0

- Added a weapon poison tracker: a separate, movable pair of icons showing your
  main-hand and off-hand weapons. Each shows remaining minutes, red-pulses when
  that weapon is unpoisoned, and — while locked — **left-click applies poison** to
  that weapon. **Right-click** to choose which poison (Instant / Deadly / Wound /
  Mind-numbing / Crippling) per weapon. The off-hand icon hides when not
  dual-wielding. `/rr poison` shows/hides the pair.

## 1.0.0

- Initial release.
- Energy bar and a segmented combo-point bar.
- Slice and Dice tracker: an icon with an estimated remaining-time countdown,
  driven by the combo points spent (exact values can't be read on this client, so
  it's estimated from your builder casts).
- Ability cooldown trackers with a swipe, countdown, and a "ready" flash when each
  comes back up: Evasion, Vanish, Kick, Sprint, Blade Flurry, Adrenaline Rush,
  Blind, Kidney Shot, Gouge.
- Only shows abilities you've actually learned; new ones appear as you train them.
- Options panel (`/rr options`) to drag-reorder the icons and toggle each on/off.
- Movable frame (`/rr unlock`), with saved position and settings.
