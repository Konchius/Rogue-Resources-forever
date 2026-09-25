# Changelog

## 1.2.1

- Added cooldown tracking for Cold Blood, Ghostly Strike, Premeditation, and Preparation.
  Each shows only once you've taken the talent.
- The weapon-poison tracker now stays hidden until level 20.
- The poison timer counts down smoothly now.

## 1.2.0

- Options now live in the built-in interface panel: **ESC → Options → AddOns →
  Rogue Resources**. `/rr options` still opens the standalone movable window, and
  both show the same controls and stay in sync.
- Added a **UI scale** slider (50–200%) for the bars and poison icons (`/rr scale`).
- The **Improved Slice and Dice** duration bonus is now detected automatically from
  your talent rank, so the Slice and Dice timer is right without any setup. You can
  still override it manually.
- Added an **options button on the minimap** and an **Addon Compartment** entry to
  open the panel (`/rr minimap` hides/shows the minimap button).
- Moved the common toggles into the options panel: **Lock/Unlock**, **Reset
  positions**, **Show poison icons**, and the Improved Slice and Dice selector.
- The options UI is now **localized** (Portuguese, Spanish, French, German; English
  elsewhere), and the Slice and Dice heading uses the game's own talent name.
- The addon now only loads its UI for **Rogues**, so it stays out of the way on
  other characters.

## 1.1.1

- The ability icon row now wraps to the width of the bars: it fits as many
  icons per row as possible under the energy bar and flows onto further rows,
  instead of running off the sides when many abilities are shown.
- Poison support is now language-independent. Poisons are identified by item ID
  and their names read from your bags, so detection, the right-click poison
  menu, and click-to-apply all work on non-English clients.
- Click-to-apply now uses the highest rank of the chosen poison you're carrying,
  and updates automatically as you get better ranks.

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
