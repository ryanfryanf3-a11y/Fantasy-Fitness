-- Fantasy Fitness: catalog data (items, dungeons, rank exams, quest templates, starter recipes).
-- Safe to re-run: every insert skips rows that already exist.

-- ---------------------------------------------------------------------------
-- Items. Effects are in-game only and never count toward exams.
-- ---------------------------------------------------------------------------

insert into public.items (id, name, slot, rarity, effect, flavor, starter, droppable) values
  ('iron-helm',        'Iron Helm',        'head',    'common',    '+2 dungeon defense',             'Dented, but honest.',             true,  true),
  ('leather-jerkin',   'Leather Jerkin',   'chest',   'common',    '+2 dungeon defense',             'Smells faintly of the forge.',    true,  true),
  ('oak-longsword',    'Oak Longsword',    'weapon',  'common',    '+3 dungeon attack',              'Every adventurer starts here.',   true,  true),
  ('copper-ring',      'Copper Ring',      'trinket', 'common',    '+2% XP from daily quests',       'Turns your finger a little green.', true, true),
  ('moss-hood',        'Moss Hood',        'head',    'uncommon',  '+3 dungeon defense',             'Dropped in the Mossy Crypt.',     false, true),
  ('studded-vest',     'Studded Vest',     'chest',   'uncommon',  '+4 dungeon defense',             'Each stud is a finished set.',    false, true),
  ('ash-spear',        'Ash Spear',        'weapon',  'uncommon',  '+5 dungeon attack',              'Light enough for long runs.',     false, true),
  ('ember-charm',      'Ember Charm',      'trinket', 'uncommon',  '+5% XP from Strength quests',    'Warm to the touch after a PR.',   false, true),
  ('ranger-cowl',      'Ranger''s Cowl',   'head',    'rare',      '+5 dungeon defense',             'Smells of pine and rain.',        false, true),
  ('chainmail',        'Chainmail',        'chest',   'rare',      '+6 dungeon defense',             'Heavy. Good for carries.',        false, true),
  ('war-hammer',       'War Hammer',       'weapon',  'rare',      '+7 dungeon attack',              'Forged in the Sunken Mine.',      false, true),
  ('restful-amulet',   'Restful Amulet',   'trinket', 'rare',      '+10% XP on Well-Rested days',    'Glows after 8 hours of sleep.',   false, true),
  ('wyrm-helm',        'Wyrm Helm',        'head',    'epic',      '+8 dungeon defense',             'Still faintly warm.',             false, true),
  ('rune-axe',         'Rune Axe',         'weapon',  'epic',      '+9 dungeon attack',              'Hums before a heavy set.',        false, true),
  ('tide-pendant',     'Tide Pendant',     'trinket', 'epic',      '+10% XP from Endurance quests',  'Pulses with every stride.',       false, true),
  ('gilded-plate',     'Gilded Plate',     'chest',   'legendary', 'Cosmetic: golden armor glow',    'Worn by S-rank legends.',         false, true),
  ('crown-of-iron',    'Crown of Iron',    'head',    'legendary', 'Cosmetic: iron crown',           'For those who never skip legs.',  false, true)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Dungeons
-- ---------------------------------------------------------------------------

insert into public.dungeons
  (id, name, tier, required_rank, boss, boss_health, energy_cost, loot_rarity, system_image, map_x, map_y, sort_order) values
  ('goblin-cellar', 'Goblin Cellar', 'F-tier', 'F', 'Goblin Brute', 60,  1, 'common',   'flame.fill',             0.22, 0.86, 1),
  ('mossy-crypt',   'Mossy Crypt',   'E-tier', 'F', 'Moss Golem',   100, 1, 'uncommon', 'leaf.fill',              0.70, 0.62, 2),
  ('sunken-mine',   'Sunken Mine',   'E-tier', 'E', 'Ore Wyrm',     140, 2, 'rare',     'mountain.2.fill',        0.28, 0.40, 3),
  ('iron-keep',     'Iron Keep',     'D-tier', 'D', 'Iron Warden',  220, 2, 'epic',     'building.columns.fill',  0.72, 0.14, 4)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Rank exams (bodyweight-relative)
-- ---------------------------------------------------------------------------

insert into public.rank_exams (id, rank, lift, bodyweight_multiple) values
  ('e-bench',  'E', 'Bench',    0.75),
  ('e-squat',  'E', 'Squat',    1.00),
  ('d-bench',  'D', 'Bench',    1.00),
  ('d-squat',  'D', 'Squat',    1.25),
  ('d-dead',   'D', 'Deadlift', 1.50),
  ('c-bench',  'C', 'Bench',    1.25),
  ('c-squat',  'C', 'Squat',    1.50),
  ('c-dead',   'C', 'Deadlift', 1.75),
  ('b-bench',  'B', 'Bench',    1.50),
  ('b-squat',  'B', 'Squat',    1.75),
  ('b-dead',   'B', 'Deadlift', 2.25),
  ('a-bench',  'A', 'Bench',    1.75),
  ('a-squat',  'A', 'Squat',    2.25),
  ('a-dead',   'A', 'Deadlift', 2.75),
  ('s-bench',  'S', 'Bench',    2.00),
  ('s-squat',  'S', 'Squat',    2.50),
  ('s-dead',   'S', 'Deadlift', 3.00)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Quest templates. Dailies rotate per class and include a rest day.
-- ---------------------------------------------------------------------------

insert into public.quest_templates (id, guild_class, kind, arc, title, objectives, rewards, xp_reward, reward_rarity, sort_order) values
  -- Warrior
  ('warrior-push', 'warrior', 'daily', 'Iron Trial', 'Push Day', '[
    {"name": "Bench press", "detail": "4 sets × 6 reps", "metric": "lift", "exercise": "Bench press", "target": 4, "min_reps": 6},
    {"name": "Overhead press", "detail": "3 sets × 8 reps", "metric": "lift", "exercise": "Overhead press", "target": 3, "min_reps": 8},
    {"name": "Incline dumbbell press", "detail": "3 sets × 10 reps", "metric": "lift", "exercise": "Incline dumbbell press", "target": 3, "min_reps": 10},
    {"name": "Triceps dips", "detail": "3 sets × 12 reps", "metric": "lift", "exercise": "Triceps dips", "target": 3, "min_reps": 12}
  ]', '{"+120 XP", "+ Strength", "Common chest"}', 120, 'common', 1),
  ('warrior-pull', 'warrior', 'daily', 'Iron Trial', 'Pull Day', '[
    {"name": "Deadlift", "detail": "3 sets × 5 reps", "metric": "lift", "exercise": "Deadlift", "target": 3, "min_reps": 5},
    {"name": "Barbell row", "detail": "4 sets × 8 reps", "metric": "lift", "exercise": "Barbell row", "target": 4, "min_reps": 8},
    {"name": "Pull-ups", "detail": "3 sets × 6 reps", "metric": "lift", "exercise": "Pull-ups", "target": 3, "min_reps": 6}
  ]', '{"+120 XP", "+ Strength", "Common chest"}', 120, 'common', 2),
  ('warrior-legs', 'warrior', 'daily', 'Iron Trial', 'Leg Day', '[
    {"name": "Back squat", "detail": "4 sets × 6 reps", "metric": "lift", "exercise": "Back squat", "target": 4, "min_reps": 6},
    {"name": "Romanian deadlift", "detail": "3 sets × 8 reps", "metric": "lift", "exercise": "Romanian deadlift", "target": 3, "min_reps": 8},
    {"name": "Walking lunges", "detail": "3 sets × 12 reps", "metric": "lift", "exercise": "Walking lunges", "target": 3, "min_reps": 12}
  ]', '{"+120 XP", "+ Strength", "Common chest"}', 120, 'common', 3),
  -- Ranger
  ('ranger-tempo', 'ranger', 'daily', 'The Long Road', 'Tempo Run', '[
    {"name": "Run or jog", "detail": "5 km at a steady pace", "metric": "distance_km", "target": 5}
  ]', '{"+120 XP", "+ Endurance", "Common chest"}', 120, 'common', 1),
  ('ranger-strength', 'ranger', 'daily', 'The Long Road', 'Trail Strength', '[
    {"name": "Goblet squat", "detail": "3 sets × 12 reps", "metric": "lift", "exercise": "Goblet squat", "target": 3, "min_reps": 12},
    {"name": "Step-ups", "detail": "3 sets × 10 reps", "metric": "lift", "exercise": "Step-ups", "target": 3, "min_reps": 10}
  ]', '{"+100 XP", "+ Strength", "Common chest"}', 100, 'common', 2),
  -- Monk
  ('monk-push', 'monk', 'daily', 'The Quiet Path', 'Bodyweight Push', '[
    {"name": "Push-ups", "detail": "4 sets × 15 reps", "metric": "lift", "exercise": "Push-ups", "target": 4, "min_reps": 15},
    {"name": "Pike push-ups", "detail": "3 sets × 8 reps", "metric": "lift", "exercise": "Pike push-ups", "target": 3, "min_reps": 8},
    {"name": "Dips", "detail": "3 sets × 10 reps", "metric": "lift", "exercise": "Dips", "target": 3, "min_reps": 10}
  ]', '{"+120 XP", "+ Strength", "Common chest"}', 120, 'common', 1),
  ('monk-pull', 'monk', 'daily', 'The Quiet Path', 'Bodyweight Pull', '[
    {"name": "Pull-ups", "detail": "4 sets × 6 reps", "metric": "lift", "exercise": "Pull-ups", "target": 4, "min_reps": 6},
    {"name": "Inverted rows", "detail": "3 sets × 10 reps", "metric": "lift", "exercise": "Inverted rows", "target": 3, "min_reps": 10}
  ]', '{"+120 XP", "+ Agility", "Common chest"}', 120, 'common', 2),
  -- Paladin
  ('paladin-strength', 'paladin', 'daily', 'Oath of Balance', 'Oath of Iron', '[
    {"name": "Back squat", "detail": "3 sets × 5 reps", "metric": "lift", "exercise": "Back squat", "target": 3, "min_reps": 5},
    {"name": "Bench press", "detail": "3 sets × 5 reps", "metric": "lift", "exercise": "Bench press", "target": 3, "min_reps": 5}
  ]', '{"+120 XP", "+ Strength", "Common chest"}', 120, 'common', 1),
  ('paladin-conditioning', 'paladin', 'daily', 'Oath of Balance', 'Oath of the Road', '[
    {"name": "Run, row or cycle", "detail": "3 km", "metric": "distance_km", "target": 3}
  ]', '{"+100 XP", "+ Endurance", "Common chest"}', 100, 'common', 2),
  -- Every class: rest days are rewarded.
  ('rest-day', null, 'daily', 'Recovery', 'Rest at the Inn', '[
    {"name": "Sleep 7+ hours", "detail": "Earns the Well-Rested buff", "metric": "sleep_nights", "target": 1, "min_hours": 7}
  ]', '{"+60 XP", "+ Vitality", "Well-Rested"}', 60, null, 9),

  -- Weekly
  ('weekly-forge', null, 'weekly', 'Forge Week', 'Forge Week', '[
    {"name": "Complete 4 workouts", "detail": "Any logged workouts", "metric": "workouts", "target": 4},
    {"name": "Hit your protein goal", "detail": "5 days this week", "metric": "protein_days", "target": 5},
    {"name": "Sleep 7+ hours", "detail": "4 nights this week", "metric": "sleep_nights", "target": 4, "min_hours": 7}
  ]', '{"+400 XP", "+ Vitality", "Uncommon chest"}', 400, 'uncommon', 1),
  ('weekly-ranger', 'ranger', 'weekly', 'Long Road Week', 'Miles on the Map', '[
    {"name": "Cover 15 km", "detail": "Run, walk, row or cycle", "metric": "distance_km", "target": 15},
    {"name": "Hit your protein goal", "detail": "4 days this week", "metric": "protein_days", "target": 4},
    {"name": "Sleep 7+ hours", "detail": "4 nights this week", "metric": "sleep_nights", "target": 4, "min_hours": 7}
  ]', '{"+400 XP", "+ Endurance", "Uncommon chest"}', 400, 'uncommon', 1),

  -- Story (four weeks, ends with a deload)
  ('story-iron-trial', null, 'story', 'Iron Trial, chapter 1', 'The Iron Trial', '[
    {"name": "Week 1: Foundations", "detail": "Finish a weekly quest", "metric": "weekly_quests", "target": 1},
    {"name": "Week 2: Building heat", "detail": "Finish two weekly quests", "metric": "weekly_quests", "target": 2},
    {"name": "Week 3: The forge", "detail": "Finish three weekly quests", "metric": "weekly_quests", "target": 3},
    {"name": "Week 4: Deload", "detail": "Lighter week to recover", "metric": "weekly_quests", "target": 4}
  ]', '{"+800 XP", "Rare chest", "Title: Ironbound"}', 800, 'rare', 1),
  ('story-sunken-oath', null, 'story', 'Iron Trial, chapter 2', 'The Sunken Oath', '[
    {"name": "Week 1: Descent", "detail": "Finish a weekly quest", "metric": "weekly_quests", "target": 1},
    {"name": "Week 2: Deeper", "detail": "Finish two weekly quests", "metric": "weekly_quests", "target": 2},
    {"name": "Week 3: The wyrm", "detail": "Finish three weekly quests", "metric": "weekly_quests", "target": 3},
    {"name": "Week 4: Deload", "detail": "Lighter week to recover", "metric": "weekly_quests", "target": 4}
  ]', '{"+900 XP", "Epic chest"}', 900, 'epic', 2)
on conflict (id) do nothing;

-- ---------------------------------------------------------------------------
-- Starter recipes (no author: guild-provided)
-- ---------------------------------------------------------------------------

insert into public.recipes (id, author_id, name, meal_type, minutes, servings, calories, protein_g, carbs_g, fat_g) values
  ('00000000-0000-4000-8000-000000000001', null, 'Iron Oats',                  'breakfast', 5,  1, 520, 38, 62, 14),
  ('00000000-0000-4000-8000-000000000002', null, 'Ranger''s Chicken Bowl',     'lunch',     20, 2, 640, 52, 70, 16),
  ('00000000-0000-4000-8000-000000000003', null, 'Smith''s Chili',             'dinner',    45, 4, 580, 44, 48, 22),
  ('00000000-0000-4000-8000-000000000004', null, 'Monk''s Tofu Stir-fry',      'dinner',    25, 2, 480, 30, 50, 18),
  ('00000000-0000-4000-8000-000000000005', null, 'Paladin''s Protein Pancakes', 'breakfast', 15, 1, 450, 40, 45, 10)
on conflict (id) do nothing;

insert into public.recipe_ingredients (recipe_id, position, name, amount) values
  ('00000000-0000-4000-8000-000000000001', 0, 'Rolled oats', '80 g'),
  ('00000000-0000-4000-8000-000000000001', 1, 'Whey protein', '1 scoop'),
  ('00000000-0000-4000-8000-000000000001', 2, 'Banana', '1'),
  ('00000000-0000-4000-8000-000000000001', 3, 'Peanut butter', '1 tbsp'),
  ('00000000-0000-4000-8000-000000000002', 0, 'Chicken thigh', '300 g'),
  ('00000000-0000-4000-8000-000000000002', 1, 'Jasmine rice', '150 g dry'),
  ('00000000-0000-4000-8000-000000000002', 2, 'Black beans', '1 can'),
  ('00000000-0000-4000-8000-000000000002', 3, 'Salsa', '4 tbsp'),
  ('00000000-0000-4000-8000-000000000003', 0, 'Lean ground beef', '500 g'),
  ('00000000-0000-4000-8000-000000000003', 1, 'Kidney beans', '2 cans'),
  ('00000000-0000-4000-8000-000000000003', 2, 'Crushed tomatoes', '1 can'),
  ('00000000-0000-4000-8000-000000000003', 3, 'Onion', '1'),
  ('00000000-0000-4000-8000-000000000004', 0, 'Firm tofu', '400 g'),
  ('00000000-0000-4000-8000-000000000004', 1, 'Broccoli', '1 head'),
  ('00000000-0000-4000-8000-000000000004', 2, 'Soy sauce', '3 tbsp'),
  ('00000000-0000-4000-8000-000000000004', 3, 'Brown rice', '120 g dry'),
  ('00000000-0000-4000-8000-000000000005', 0, 'Oat flour', '60 g'),
  ('00000000-0000-4000-8000-000000000005', 1, 'Egg whites', '150 ml'),
  ('00000000-0000-4000-8000-000000000005', 2, 'Greek yogurt', '100 g'),
  ('00000000-0000-4000-8000-000000000005', 3, 'Blueberries', 'a handful')
on conflict (recipe_id, position) do nothing;
