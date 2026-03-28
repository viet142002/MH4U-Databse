# 🐉 MH4U Database App

A fully offline Flutter database app for **Monster Hunter 4 Ultimate**, built with Riverpod + Drift (SQLite) + go_router.

---

## 📋 Table of Contents

- [Features](#features)
- [Tech Stack](#tech-stack)
- [Project Structure](#project-structure)
- [Quick Start](#quick-start)
- [Code Generation](#code-generation)
- [Architecture](#architecture)
- [Adding Game Data](#adding-game-data)
- [Next Steps](#next-steps)

---

## ✨ Features

| Feature | Status |
|---|---|
| Monster list + search + filter | ✅ |
| Monster detail (weaknesses, drops, habitats, parts) | ✅ |
| Weapon list by type with type tabs | ✅ |
| Weapon detail (stats, sharpness bar, materials) | ✅ |
| Weapon upgrade tree (visual, expandable) | ✅ |
| Armor set list + rank filter | ✅ |
| Armor detail (defense, resistances, skill points) | ✅ |
| Item list + type filter | ✅ |
| Item detail + combine recipes | ✅ |
| Quest list + type/rank filter | ✅ |
| Quest detail (objectives, rewards, monsters) | ✅ |
| Dark theme (MH style, gold accent) | ✅ |
| Offline-first with SQLite | ✅ |
| JSON seed data on first launch | ✅ |
| English + Vietnamese localization | ✅ |

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (latest stable) |
| State Management | Riverpod 2.x + `@riverpod` generator |
| Database | Drift (type-safe SQLite) |
| Navigation | go_router |
| Models | Freezed + json_serializable |
| Localization | flutter_localizations + ARB files |

---

## 📁 Project Structure

```
lib/
├── core/
│   ├── constants/
│   │   └── app_constants.dart       # WeaponType, MonsterType, Rank enums
│   ├── theme/
│   │   └── app_theme.dart           # Dark MH theme, AppColors
│   └── utils/
│       └── extensions.dart          # String/int extensions, helpers
│
├── data/
│   ├── database/
│   │   ├── app_database.dart        # All Drift table definitions + DB class
│   │   ├── app_database.g.dart      # ← GENERATED (run build_runner)
│   │   ├── database_provider.dart   # Riverpod provider for AppDatabase
│   │   └── database_seeder.dart     # Seeds DB from JSON assets on first run
│   ├── models/                      # (for future DTOs if needed)
│   └── repositories/
│       ├── monster_repository.dart  # CRUD + Riverpod providers for monsters
│       └── weapon_repository.dart   # CRUD + upgrade tree builder
│
├── domain/
│   └── entities/
│       ├── monster_entity.dart      # Freezed MonsterEntity + related
│       ├── weapon_entity.dart       # Freezed WeaponEntity
│       └── other_entities.dart      # Armor, Skill, Item, Quest entities
│
├── presentation/
│   ├── screens/
│   │   ├── main_shell.dart          # Bottom nav shell (go_router ShellRoute)
│   │   ├── monsters/
│   │   │   ├── monster_list_screen.dart
│   │   │   └── monster_detail_screen.dart
│   │   ├── weapons/
│   │   │   ├── weapon_list_screen.dart
│   │   │   ├── weapon_detail_screen.dart   # Also contains WeaponTreeScreen
│   │   │   └── weapon_tree_screen.dart     # Re-export
│   │   ├── armor/
│   │   │   ├── armor_list_screen.dart      # Contains ArmorDetailScreen
│   │   │   └── armor_detail_screen.dart    # Re-export
│   │   ├── items/
│   │   │   ├── item_list_screen.dart       # Contains ItemDetailScreen
│   │   │   └── item_detail_screen.dart     # Re-export
│   │   └── quests/
│   │       ├── quest_list_screen.dart      # Contains QuestDetailScreen
│   │       └── quest_detail_screen.dart    # Re-export
│   └── widgets/
│       └── shared_widgets.dart      # MhSearchBar, AsyncStateWidget, ElementChip, etc.
│
├── routes/
│   └── app_router.dart              # All go_router routes
│
├── l10n/
│   ├── app_en.arb                   # English strings
│   └── app_vi.arb                   # Vietnamese strings
│
└── main.dart                        # Entry point, seeds DB, launches app

assets/
└── data/
    ├── monsters.json                # Sample monster data
    ├── weapons.json                 # Sample weapon data
    ├── armor.json                   # Sample armor set data
    ├── items.json                   # Sample item data
    ├── skills.json                  # Sample skill data
    └── quests.json                  # Sample quest data
```

---

## 🚀 Quick Start

### Prerequisites
- Flutter SDK ≥ 3.0.0
- Dart SDK ≥ 3.0.0
- Android Studio or VS Code with Flutter plugin

### 1. Install dependencies

```bash
flutter pub get
```

### 2. Run code generation (REQUIRED before first run)

```bash
dart run build_runner build --delete-conflicting-outputs
```

Or use the helper script:

```bash
chmod +x scripts.sh
./scripts.sh setup
```

### 3. Run the app

```bash
flutter run
```

---

## ⚙️ Code Generation

This project uses **build_runner** to generate:

| Generator | Files Generated | From |
|---|---|---|
| `drift_dev` | `app_database.g.dart` | `app_database.dart` |
| `riverpod_generator` | `*.g.dart` (providers) | `@riverpod` annotations |
| `freezed` | `*.freezed.dart` | `@freezed` classes |
| `json_serializable` | `*.g.dart` (JSON) | `@JsonSerializable` |

**Run once:**
```bash
dart run build_runner build --delete-conflicting-outputs
```

**Watch mode (during development):**
```bash
dart run build_runner watch --delete-conflicting-outputs
```

**Clean and regenerate:**
```bash
./scripts.sh clean-gen
```

> ⚠️ **Important:** The app will NOT compile without running code generation first. The `.g.dart` and `.freezed.dart` files are not committed to git.

---

## 🏗️ Architecture

### Data Flow

```
UI (ConsumerWidget)
  ↓ watch/read
Riverpod Provider (@riverpod)
  ↓ calls
Repository (e.g. MonsterRepository)
  ↓ queries
Drift (AppDatabase)
  ↓ SQL
SQLite file (mh4u.db)
```

### Key Patterns

**1. Repository pattern**
```dart
// All DB logic lives in the repository
class MonsterRepository {
  final AppDatabase _db;
  Future<List<Monster>> getAllMonsters({String? search}) async { ... }
  Future<MonsterEntity?> getMonsterDetail(int id) async { ... }
}
```

**2. Riverpod `@riverpod` generators**
```dart
// Auto-generates monsterListProvider, monsterDetailProvider, etc.
@riverpod
Future<List<Monster>> monsterList(Ref ref, {String? search}) async {
  return ref.watch(monsterRepositoryProvider).getAllMonsters(search: search);
}
```

**3. Consuming in UI**
```dart
class MonsterListScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monstersAsync = ref.watch(monsterListProvider(search: search));
    return AsyncStateWidget(state: monstersAsync, builder: (data) => ...);
  }
}
```

**4. Domain entities with Freezed**
```dart
// Immutable, copyWith, equality out of the box
@freezed
class MonsterEntity with _$MonsterEntity {
  const factory MonsterEntity({
    required int id,
    required String name,
    @Default([]) List<MonsterWeaknessEntity> weaknesses,
  }) = _MonsterEntity;
}
```

---

## 📊 Database Schema

### Tables

```
monsters ──────────────────┐
monster_weaknesses ────────┤ (monsterId FK)
monster_drops ─────────────┤ (monsterId FK, itemId FK)
monster_habitats ──────────┤ (monsterId FK)
monster_breakable_parts ───┘ (monsterId FK)

weapons ────────────────────  (parentId self-ref for upgrade tree)
weapon_materials ───────────  (weaponId FK, itemId FK)

armor_sets ─────────────────┐
armors ─────────────────────┤ (setId FK)
armor_skills ───────────────┤ (armorId FK, skillTreeId FK)
armor_materials ────────────┘ (armorId FK, itemId FK)

skill_trees ────────────────┐
skills ─────────────────────┘ (treeId FK)

items ──────────────────────┐
item_recipes ───────────────┘ (resultItemId FK, ingredient1Id FK)

quests ─────────────────────┐
quest_monsters ─────────────┤ (questId FK, monsterId FK)
quest_rewards ──────────────┘ (questId FK, itemId FK)
```

---

## 📦 Adding Game Data

The app seeds from JSON files in `assets/data/` on the first launch. To add real MH4U data:

### Option 1: Edit JSON files directly
Edit the files in `assets/data/` following the existing schema. The `DatabaseSeeder` reads them on first launch.

### Option 2: Full database import
For large datasets (all ~100+ monsters, 200+ weapons), use a Python script to convert from community sources:

```python
# Example: convert from kiranico CSV exports to our JSON format
import json, csv

monsters = []
with open('kiranico_monsters.csv') as f:
    for row in csv.DictReader(f):
        monsters.append({
            "name": row["name"],
            "type": row["class"],
            "is_elder_dragon": row["class"] == "Elder Dragon",
            "weaknesses": []  # parse separately
        })

with open('assets/data/monsters.json', 'w') as f:
    json.dump(monsters, f, indent=2)
```

### Option 3: Pre-built SQLite database
Replace the auto-seeding approach with a bundled `.db` file:

```dart
// In database_provider.dart, load from assets:
static QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File('${dbFolder.path}/mh4u.db');
    if (!file.existsSync()) {
      final bytes = await rootBundle.load('assets/data/mh4u.db');
      await file.writeAsBytes(bytes.buffer.asUint8List());
    }
    return NativeDatabase(file);
  });
}
```

---

## 🔧 Customization

### Change the accent color
Edit `AppColors.primary` in `lib/core/theme/app_theme.dart`:
```dart
static const primary = Color(0xFFD4A017); // Change this gold color
```

### Add a new screen/feature
1. Create the Drift table in `app_database.dart`
2. Run `dart run build_runner build`
3. Create the repository in `data/repositories/`
4. Create domain entity in `domain/entities/`
5. Create list + detail screens in `presentation/screens/`
6. Add routes in `routes/app_router.dart`
7. Add tab to `main_shell.dart` if needed

---

## 🚀 Next Steps

### Phase 2 (Recommended)
- [ ] **Complete data set** - Import all MH4U data from community databases (kiranico, mhworld-db format)
- [ ] **Skill screen** - Dedicated Skills tab with `SkillTrees` + `Skills` tables
- [ ] **Monster images** - Add `assets/images/monsters/` with official icons
- [ ] **Search improvements** - Debounced search, highlight matches

### Phase 3 (Advanced)
- [ ] **Armor Set Builder** - Build and compare armor combinations, calculate skill activations
- [ ] **Wishlist/Bookmarks** - Save favorite monsters, weapons, quests
- [ ] **Damage Calculator** - True raw calculation with motion values
- [ ] **Widget tests** - Add unit + widget test coverage
- [ ] **iOS support** - Add iOS-specific configurations

---

## 📱 Building for Release

### Android APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### Android App Bundle (Play Store)
```bash
flutter build appbundle --release
```

### iOS (Mac only)
```bash
flutter build ios --release
```

---

## 🐛 Troubleshooting

| Problem | Solution |
|---|---|
| `part '*.g.dart'` errors | Run `dart run build_runner build --delete-conflicting-outputs` |
| `Undefined name '_$MonsterEntity'` | Run build_runner (Freezed not generated yet) |
| App shows empty lists | Check `assets/data/*.json` files exist and are valid JSON |
| DB not seeding | Delete app data/reinstall to trigger `seedIfEmpty()` on fresh DB |
| Build errors after pulling | Run `flutter pub get` then `build_runner build` |

---

## 📄 License

MIT — Free to use for personal and educational purposes.

Data sourced from community MH4U databases. Monster Hunter is a trademark of Capcom.
