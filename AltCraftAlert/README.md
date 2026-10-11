# AltCraftAlert

**AltCraftAlert** is a lightweight World of Warcraft: Wrath of the Lich King (3.3.5a) addon designed to track and report profession cooldowns across all your alts on login or on demand.

It integrates seamlessly with **DataStore** and **DataStore_Crafts** to inspect account-wide profession states, giving you real-time countdowns and ready-status alerts for critical daily and multi-day crafts.

---

## Features

- **Automatic Login Report**: Displays active or ready craft cooldowns 3 seconds after entering the world.
- **On-Demand Slash Commands**: Run reports anytime using `/aca` or `/altcraft`.
- **Per-Character Configuration Panel**: Customize tracking preferences for each alt dynamically via `/aca config` or the standard WoW AddOn options menu.
- **Class-Colored Names**: Automatically formats character names according to their class color.
- **Smart Category Tracking**: Normalizes shared cooldowns (e.g., Transmutes, Alchemy Research, Inscription Research) to prevent duplicate reports.
- **Accurate Offline Math**: Adjusts timer calculations based on character logout timestamps to report precise remaining times.

---

## Monitored Cooldowns

AltCraftAlert automatically tracks key WotLK crafting categories, including:

- **Tailoring**: Glacial Bag, Moonshroud, Ebonweave
- **Alchemy**: Transmutes (Eternal Water to Fire, etc.), Northrend Alchemy Research
- **Inscription**: Inscription Research

---

## Requirements & Dependencies

To function properly, AltCraftAlert requires the following DataStore modules enabled:

1. **DataStore**
2. **DataStore_Crafts**

> **Important Note on DataStore Syncing:**  
> DataStore updates its internal database when you open your profession window in-game. When you perform a craft or log into an alt:
> 1. Press `K` and open your profession book once.
> 2. Perform your craft or check active cooldowns.
> 3. Log off or `/reload` to allow DataStore to write active timers to disk.

---

## Slash Commands

| Command | Action |
| :--- | :--- |
| `/aca` | Runs an immediate cooldown check for all alts. |
| `/altcraft` | Alias for `/aca`. |
| `/aca config` | Opens the GUI Options Panel. |
| `/aca options` | Alias for `/aca config`. |

---

## Installation

1. Download or extract the `AltCraftAlert` folder into your WoW AddOns directory:
   `World of Warcraft/Interface/AddOns/AltCraftAlert`
2. Ensure your directory contains:
   - `AltCraftAlert.toc`
   - `AltCraftAlert.lua`
   - `CooldownsList.lua`
3. Launch World of Warcraft and make sure **AltCraftAlert** and **DataStore_Crafts** are enabled in your AddOns menu.

---

## License

Created for 3.3.5a / WotLK private servers (ChromieCraft compatible). Distributed under the MIT License.