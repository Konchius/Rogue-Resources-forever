# Rogue Resources

A compact resource and cooldown tracker for **Rogues** on the **WoW Classic (Forever)**
client — energy, combo points, Slice and Dice, and your key ability cooldowns, in one
movable bar.

## Features

- **Energy bar** with a live value.
- **Combo-point bar** — a segmented bar showing your current combo points.
- **Slice and Dice** — an icon with an estimated remaining-time countdown. (The client
  keeps combo points and buff durations secret from addons, so the timer is estimated
  from the combo points you spend, not read directly. Every finisher resyncs it.)
- **Cooldown trackers** with a radial swipe, countdown number, and a one-shot **flash**
  when the ability is ready again: Evasion, Vanish, Kick, Sprint, Blade Flurry,
  Adrenaline Rush, Blind, Kidney Shot, Gouge.
- **Only your learned skills** show — abilities appear automatically as you train them.
- **Options panel** to **drag-reorder** the icons and **toggle** each one on or off.

## Installation

**CurseForge app:** search for *Rogue Resources* and install.

**Manual:** download the latest release, unzip it, and drop the `RogueResources`
folder into your WoW install at:

```
World of Warcraft/_classic_beta_/Interface/AddOns/
```

Then fully restart the client (a `/reload` won't pick up a brand-new addon folder) and
enable **Rogue Resources** at the character-select AddOns screen.

## Commands

| Command           | What it does                                  |
| ----------------- | --------------------------------------------- |
| `/rr options`     | Open the options panel (reorder / show-hide)  |
| `/rr unlock`      | Unlock the bar to drag it (then `/rr lock`)   |
| `/rr sndmult <n>` | Set the Improved Slice and Dice multiplier    |

## License

[MIT](LICENSE) © Konchius
