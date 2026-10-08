# Project: Fantasy Fitness RPG (iOS)

A SwiftUI iOS app that gamifies weightlifting and exercise as a fantasy RPG. The player is an adventurer in a Guild. Real workouts, meals, and sleep are the ONLY source of character power. The game layer (quests, dungeons, loot, ranks) exists to make real effort feel rewarding.

## Core design rules (do not violate)

- Real progress drives in-game power, never the reverse. Loot cannot change real performance; it boosts in-game combat, XP multipliers, quest variants, or cosmetics.
- The client never awards rewards. The app submits raw data (sets, reps, weight, distance, sleep, meals); the server calculates XP, stat gains, and loot.
- Quest objectives complete automatically from logged data. No manual "mark done" checkboxes for workout objectives (prevents cheating).
- Rest days are rewarded (Well-Rested buff), never punished. No stat loss for missed days; use streak freezes and a "welcome back" quest.
- No pay-to-win. Monetization is cosmetics and premium features only.
- Strength rank standards are bodyweight-relative (or DOTS/Wilks), with weight classes for leaderboards. Plate milestones (135/225/315) are separate achievements.
- Nutrition features frame food as fuel. Calorie targets have floors; never generate aggressive restriction quests.

## Tech stack

- Xcode project from the **App** template, SwiftUI, Swift.
- Local storage: **SwiftData** (offline-first; gyms have bad signal). Keep a pending-uploads queue and sync when online.
- Backend: **Supabase** (Postgres, Auth, Storage, Realtime, Edge Functions) via `supabase-swift`.
  - Auth: Sign in with Apple (required if offering other third-party logins), email, Google.
  - Row-level security on every table. Users may insert workouts but may NOT write their own XP, stats, or inventory.
  - XP / stat / loot calculation happens in Postgres functions or Edge Functions.
  - Storage: avatars, recipe photos, later lift-verification videos.
  - Realtime: guild raid boss health.
- HealthKit integration for cardio and sleep. Follow Apple's rules: no ad use of health data, clear privacy policy; prefer keeping raw health data on-device.
- Game visuals (battles) later via SpriteKit embedded with SwiftUI `SpriteView`.

## Starting database schema

- `profiles`: user id, display name, class, level, rank, bodyweight
- `stats`: strength, endurance, speed, agility, vitality (per user)
- `workouts`, `workout_sets`: exercise, weight, reps, timestamps
- `quests`, `quest_progress`
- `items` (catalog), `inventory` (owned, equipped)
- `recipes`, `recipe_ingredients`, `recipe_ratings`, `meal_logs`
- `guilds`, `guild_members`
- `exam_attempts`: lift, result, video path, verification status

## Game systems

**Stats:** Strength (compound lifts, PRs, volume), Endurance (cardio duration/volume), Speed (pace, sprint times), Agility (plyometrics, drills), Vitality (sleep consistency, protein/calorie targets), optional Flexibility (mobility).

**Level vs stats:** Level = total XP (consistency). Stats = capability (only rise when real performance rises).

**Classes:** Warrior (strength), Ranger (endurance), Monk (calisthenics), Paladin (hybrid). Class sets default routine and bonus XP.

**Core loop:** Train → Grow (level, stats, unlock exams) → Fight (dungeons/bosses, costs Energy) → Loot → Train. Energy refills only from real activity and sleep.

**Quests:** generated from the chosen program. Types: Daily, Weekly, Story (multi-week arcs tied to a program block, include deloads), Side. Each covers training, nutrition, and recovery.

**Ranks:** Guild ranks F → E → D → C → B → A → S. Each requires exams across stats (e.g., D-rank bench = 1.0× bodyweight). Passing grants badge, title, unique gear, new dungeon tiers. Exams include warm-up protocol and spotter prompt for bench.

**Loot rarity:** Common → Uncommon → Rare → Epic → Legendary. Gear never counts toward exams.

**Tavern (food):** meal library with macros (USDA FoodData Central / Open Food Facts), recipe creator with auto macros, barcode scanner, meal logging feeding nutrition quests. Ratings on separate axes: taste, ease, cost, macro profile (auto).

**Later:** pose-estimation lift verification (MediaPipe/MoveNet: ROM, rep count, form flags; weight verification via video + community/friend review first), async PvP by rank and weight class, guild raids, stat-driven avatar evolution (body-composition avatar must be opt-in and never shaming).

## Navigation map

App shell: `TabView` with a `NavigationStack` per tab. Title screen and onboarding sit outside it, gated by a `hasCompletedOnboarding` flag.

- **Title screen** → New game → **Onboarding** (class, goals, program) → Guild Hall
- **Title screen** → Continue → **Guild Hall**
- **Settings** (profile, sync, units) reachable from Title and Guild Hall

Tabs:
1. **Guild Hall** (home hub: today's quests, Energy, unlocked exams)
2. **Quests**: Quest board → Workout session → Quest complete → Loot reveal
3. **Character**: Character sheet → Inventory → Item detail → Equip/compare
4. **Dungeons**: Dungeon map → Loadout → Battle → Loot reveal
5. **Tavern**: Meal library → Recipe detail → Log meal → Rate recipe; Create recipe opens as a sheet

Notes:
- **Loot reveal** is shared by Quests and Dungeons: build once as a reusable view/modal.
- **Workout session** and **Battle** are presented with `.fullScreenCover` (tab bar hidden).
- **Rank exams** appear as a card on the Quest board and launch Workout session in "exam mode."
- Quest board "Begin quest" button opens Workout session (log weight/reps per set, rest timer) → Quest complete (XP, stat gains) → Loot reveal. Label varies by tab: Daily "Begin quest", Weekly "View progress", Story "Continue story".

## Visual style (Quest Board reference)

Blend of realistic rustic (wood plank board, brass pins, aged parchment) and cartoon (thick brown outlines, flat warm fills, rolled scroll ends with wooden knobs, hard drop shadows). Readability first.

Fonts:
- Title only: **Pirata One** (blackletter)
- Headings / quest names / buttons: **Alegreya** (700–800)
- Body / objectives / numbers: **Alegreya Sans** (400–700)

Colors:
- Wood: base `#7A4B2A`, plank seams `rgba(38,18,6,.6)`, dark wood `#5A3418`, darkest `#3A2008` / `#241204`
- Parchment: `#F4DFAE` (scroll), `#F1D9A2` (notes), scroll rolls `#E2B565`, knobs `#8A4B1C`
- Outline brown: `#5C3412`; ink text `#3B2412`; secondary text `#6B4423`; kicker `#8A4B1C`
- Gold (title, active tab/nav): `#F2C14E`
- Wax seal / primary button accent: `#A3341F` with border `#4A1A0E`, text `#FFF3D6`
- Progress / completed green: `#6E8B3D`; positive text `#3F5A1E`
- Brass pins: `#C9962E`

Quest Board layout (top to bottom): Level/rank pill + Energy pill; wooden sign with "Quest Board" title; Daily / Weekly / Story tabs; featured quest on a cartoon scroll (kicker, title, wax seal icon, progress bar, objectives, reward chips, primary button); pinned notes grid (Ration duty protein progress, Rest at the inn sleep goal, full-width Guild notice for unlocked exam); bottom tab bar on dark wood. Touch targets ≥ 44 pt.

## Roadmap

- **MVP (v0.1):** accounts, class selection, workout logging with 3–4 preset programs, stats and leveling, daily/weekly quests, basic cosmetic loot, one simple dungeon.
- **v0.5:** rank exams (bodyweight-relative), nutrition logging and basic Tavern, HealthKit/wearable sync, guilds with shared raid bosses.
- **v1.0:** full dungeon/boss system, video verification with community review, gear with XP modifiers.
- **Future:** pose-estimation verification, async PvP and seasonal arenas, avatar evolution.

## Open questions

- Daily time spent in the game layer (target ~5 minutes)
- Combat: skill-based or purely stat-based
- Balancing lifters vs. runners across classes
- Inactivity: stats plateau (preferred) vs. decay
- Art style (pixel art is cheapest)
