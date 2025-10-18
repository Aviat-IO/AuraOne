# Context Management UI Design Specification

## Overview

This document specifies the UI/UX design for person labeling, place naming, and
journal preferences in Aura One. All designs integrate seamlessly with the
existing warm peach/coral aesthetic and design system.

---

## Design System Foundation

### Colors

```dart
// Primary Actions
lightPrimary:     #E8A87C  // Warm peach
lightSecondary:   #F4C2A1  // Soft coral
lightSurface:     #FFFBF7  // Warm cream
lightOutline:     #BCAA97  // Warm gray
lightOutlineVariant: #E0D5C7  // Light warm gray

// Dark Mode
darkPrimary:      #FFB74D
darkSurface:      #1A1410
darkOutline:      #9C8F80
```

### Typography

```dart
titleLarge:       20sp, semibold
titleMedium:      18sp, medium
bodyLarge:        16sp, regular
bodyMedium:       14sp, regular
bodySmall:        12sp, regular
labelMedium:      14sp, medium
```

### Spacing

```dart
spacingXS:    4dp
spacingS:     8dp
spacingM:     12dp
spacingL:     16dp
spacingXL:    24dp
spacing2XL:   32dp
```

### Border Radius

```dart
radiusS:      8dp   // Chips, small buttons
radiusM:      12dp  // Cards, inputs
radiusL:      16dp  // Dialogs
radiusXL:     24dp  // Bottom sheets
radiusRound:  50%   // Avatars, icons
```

---

## Section 5: Person Labeling UI

### 5.1 Face Clustering Review Screen

**Purpose**: Show unlabeled faces detected in photos for batch labeling

```
┌─────────────────────────────────────┐
│  ← Label People              Skip   │  Header (E8A87C background)
├─────────────────────────────────────┤
│                                     │
│  We found 3 people in your photos   │  Title text
│  Tap to add their names             │  Subtitle (muted)
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ●●●●●●●●●●●●●●●●●●●●●     │   │  Person cluster card
│  │  ●●  Unknown  ●●            │   │  - Circular avatar grid
│  │  ●●●●●●●●●●●●●●●●●●●●●     │   │  - 12 photos max visible
│  │                             │   │  - Warm gradient border
│  │  8 photos                   │   │  - Tap to label
│  │  First seen: 3 days ago     │   │
│  │  ┌──────────────────┐       │   │
│  │  │ Label This Person│       │   │  Primary button (E8A87C)
│  │  └──────────────────┘       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ●●●●●●●●●●●●               │   │  Another cluster
│  │  ●●  Unknown  ●●            │   │
│  │  ●●●●●●●●●●●●               │   │
│  │                             │   │
│  │  5 photos                   │   │
│  │  First seen: 1 week ago     │   │
│  │  ┌──────────────────┐       │   │
│  │  │ Label This Person│       │   │
│  │  └──────────────────┘       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ I'll label these later       │  │  Skip button (outlined)
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Interactions**:

- Swipe up/down to browse unlabeled clusters
- Tap "Label This Person" → Opens person labeling dialog (5.2)
- Tap cluster card → View all photos in this cluster
- Pull to refresh → Re-detect faces

**Implementation**: `FaceClusteringScreen`

- Located in: `lib/screens/context/face_clustering_screen.dart`
- Uses: `context_manager_service.dart` for unlabeled faces
- Grid layout: 3x4 circular avatars per cluster
- Sort by: Photo count descending

---

### 5.2 Person Labeling Dialog

**Purpose**: Quick labeling interface for adding person details

```
┌─────────────────────────────────────┐
│                                     │
│     ┌─────────────────┐            │
│     │                 │            │  Circular face preview
│     │   Face Photo    │            │  Size: 120dp diameter
│     │                 │            │  Border: 2dp E8A87C
│     └─────────────────┘            │  Shadow: soft warm
│                                     │
│  ┌─────────────────────────────┐  │
│  │ Name                        │  │  Text input
│  │ [Sarah Johnson]             │  │  - Rounded (16dp)
│  └─────────────────────────────┘  │  - Focus: E8A87C underline
│                                     │
│  ┌─────────────────────────────┐  │
│  │ Relationship (Optional)     │  │  Dropdown picker
│  │ [Sister]              ▼     │  │  - Show icon based on
│  └─────────────────────────────┘  │    relationship
│                                     │
│  Privacy in Journal                │  Section header
│  ┌───────────────────────────────┐│
│  │ ○ Don't mention               ││ Radio buttons
│  │   (Excluded from journal)     ││ - Warm peach selected
│  ├───────────────────────────────┤│   state (E8A87C)
│  │ ● First name only             ││ - Icon indicators:
│  │   "Sarah"                     ││   🔒 ❌ 👤 👥
│  ├───────────────────────────────┤│
│  │ ○ Full name + relationship    ││
│  │   "Sarah (Sister)"            ││
│  └───────────────────────────────┘│
│                                     │
│  ┌──────────┐  ┌──────────┐       │
│  │  Cancel  │  │   Save   │       │  Buttons
│  └──────────┘  └──────────┘       │  Save: E8A87C filled
│                                     │  Cancel: outlined
│  👤 8 photos will be labeled        │  Confirmation text
└─────────────────────────────────────┘
```

**Interactions**:

- Auto-focus on name field when opened
- Show keyboard automatically
- Relationship dropdown → Opens picker (5.4)
- Privacy radio buttons → Tap to select
- Save → Haptic feedback, success animation
- Cancel → Confirm if name entered

**Implementation**: `PersonLabelDialog`

- Type: Bottom sheet (24dp radius)
- Animation: Slide up with spring curve
- Background: FFFBF7 with gradient overlay
- Max height: 80% of screen
- Dismissible: Tap outside or drag down

**Relationship Picker Options**:

```
Family:
  - Parent
  - Sibling (Brother/Sister)
  - Child (Son/Daughter)
  - Spouse/Partner
  - Extended Family

Friends:
  - Close Friend
  - Friend
  - Acquaintance

Professional:
  - Colleague
  - Manager/Boss
  - Client
  - Mentor

Other:
  - Neighbor
  - Classmate
  - (Custom)
```

---

### 5.3 Person List Management Screen

**Purpose**: View and manage all labeled people

```
┌─────────────────────────────────────┐
│  People                    [+]  ⋮   │  Header
├─────────────────────────────────────┤
│  🔍 Search people...                │  Search bar (12dp radius)
├─────────────────────────────────────┤
│  ┌──────────────────────────────┐  │
│  │ Family  Friends  Work  All ⋮ │  │  Filter chips
│  └──────────────────────────────┘  │  - Peach background when active
│                                     │  - Horizontal scroll
│  PRIMARY PEOPLE                     │  Section header (14sp medium)
│  ┌─────────────────────────────┐   │
│  │ ●  Mom                      │   │  Person card
│  │    Parent • 67 photos       │   │  - Left: Circular avatar (48dp)
│  │    2 days ago           ⋮   │   │  - Center: Name, relationship
│  └─────────────────────────────┘   │  - Right: Menu icon
│                                     │  Swipeable:
│  ┌─────────────────────────────┐   │    Left: Edit (E8A87C)
│  │ ●  Sarah                    │   │    Right: Delete (soft red)
│  │    Sister • 45 photos       │   │
│  │    2 days ago           ⋮   │   │
│  └─────────────────────────────┘   │
│                                     │
│  FRIENDS                            │
│  ┌─────────────────────────────┐   │
│  │ ●  Mike                     │   │
│  │    Friend • 23 photos       │   │
│  │    1 week ago           ⋮   │   │
│  └─────────────────────────────┘   │
│                                     │
│  UNLABELED                          │
│  ┌─────────────────────────────┐   │
│  │ ?  Unknown Person           │   │  Different icon for unlabeled
│  │    8 photos • 3 days ago    │   │  Lighter background
│  │    [Label This Person]  ⋮   │   │
│  └─────────────────────────────┘   │
│                                     │
│  [+] Add Person Manually            │  Button at bottom
└─────────────────────────────────────┘
```

**Interactions**:

- Tap card → Person detail screen (5.7)
- Swipe left → Edit / Delete actions
- Swipe right → Quick privacy toggle
- Long press → Multi-select mode
- Pull to refresh → Update face detection
- Tap [+] → Add person manually

**Implementation**: `PeopleListScreen`

- Route: `/settings/people`
- Uses: `GroupedListContainer` for cards
- Sorting: By relationship group, then by name
- Empty state: "No people labeled yet" with illustration

---

### 5.4 Relationship Selector

**Purpose**: Choose relationship category for person

```
┌─────────────────────────────────────┐
│  ← Relationship                     │
├─────────────────────────────────────┤
│                                     │
│  FAMILY                             │
│  ┌─────────────────────────────┐   │
│  │ 👨‍👩‍👧‍👦 Parent                   │   │  List tiles
│  └─────────────────────────────┘   │  - Icon on left
│  ┌─────────────────────────────┐   │  - Text in center
│  │ 👫 Sibling                  │   │  - Chevron on right
│  └─────────────────────────────┘   │  - Tap to select
│  ┌─────────────────────────────┐   │
│  │ 👶 Child                    │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 💑 Spouse/Partner           │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 👵 Extended Family          │   │
│  └─────────────────────────────┘   │
│                                     │
│  FRIENDS                            │
│  ┌─────────────────────────────┐   │
│  │ ⭐ Close Friend              │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🤝 Friend                   │   │
│  └─────────────────────────────┘   │
│                                     │
│  PROFESSIONAL                       │
│  ┌─────────────────────────────┐   │
│  │ 💼 Colleague                │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 👔 Manager/Boss             │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ✏️ Custom...                │   │  Custom entry
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Implementation**: `RelationshipPicker`

- Type: Full screen or bottom sheet
- Animation: Slide up from bottom
- Selection: Single tap → Return to parent
- Search: Optional search bar at top
- Custom: Text input dialog

---

### 5.5 Privacy Level Selector

**Purpose**: Set per-person privacy for journals

```
┌─────────────────────────────────────┐
│  Privacy for Sarah                  │
│  ─────────────────────────────────  │
│                                     │
│  How should Sarah appear in your    │
│  journal entries?                   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔒 Excluded                 │   │  Option cards
│  │ Sarah won't be mentioned    │   │  - Selected: E8A87C border
│  │                             │   │  - Unselected: E0D5C7 border
│  │ Example:                    │   │  - 16dp radius
│  │ "Spent time at the park"    │   │  - 16dp padding
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👤 First Name Only          │   │  ← Selected state
│  │ Use only Sarah's first name │   │    (has gradient bg)
│  │                             │   │
│  │ Example:                    │   │
│  │ "Spent time with Sarah"     │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 👥 Full Details             │   │
│  │ Include name + relationship │   │
│  │                             │   │
│  │ Example:                    │   │
│  │ "Spent time with Sarah      │   │
│  │  (Sister)"                  │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │        Save Changes         │   │  Save button
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Implementation**: `PrivacyLevelPicker`

- Shows in: Person detail screen
- Type: Inline cards (not dialog)
- Feedback: Haptic on selection
- Updates: Immediately on tap
- Examples: Show actual journal text

---

### 5.6 Person Editing

**Purpose**: Edit existing person details

_Same layout as 5.2 (Person Labeling Dialog) but includes:_

- Pre-filled name and relationship
- "Delete Person" button at bottom (red text)
- Photo count and statistics display
- "Merge with..." option if duplicates detected

---

### 5.7 Person Statistics Screen

**Purpose**: View photos and details for a person

```
┌─────────────────────────────────────┐
│  ← Sarah                    Edit    │  Header
├─────────────────────────────────────┤
│                                     │
│         ┌───────────┐              │  Large avatar (120dp)
│         │  Avatar   │              │  - Circular
│         └───────────┘              │  - E8A87C border (3dp)
│                                     │
│  Sarah Johnson                      │  Name (20sp semibold)
│  Sister                             │  Relationship (14sp muted)
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📸 45 photos                │   │  Stats card
│  │ 🕐 First seen: 3 months ago │   │  - FFFBF7 background
│  │ ⏱️ Last seen: 2 days ago    │   │  - 12dp radius
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔒 Privacy Settings         │   │  Privacy card
│  │ First name only             │   │  - Peach tint
│  │ [Change]                    │   │
│  └─────────────────────────────┘   │
│                                     │
│  Recent Photos                      │  Section header
│  ┌───┬───┬───┬───┐               │
│  │   │   │   │   │               │  Photo grid (3 columns)
│  ├───┼───┼───┼───┤               │  - 8dp spacing
│  │   │   │   │   │               │  - Rounded corners
│  ├───┼───┼───┼───┤               │
│  │   │   │   │   │               │
│  └───┴───┴───┴───┘               │
│                                     │
│  [View All Photos (45)]             │  Button
│                                     │
│  Delete Person                      │  Danger action (red)
└─────────────────────────────────────┘
```

**Interactions**:

- Tap "Edit" → Edit dialog
- Tap "Change" privacy → Privacy picker
- Tap photo → Full screen gallery
- Tap "Delete" → Confirmation dialog

---

## Section 6: Place Naming UI

### 6.1 Frequent Places Detection

**Purpose**: Suggest unnamed frequent locations for labeling

```
┌─────────────────────────────────────┐
│  ← Name Your Places          Skip   │
├─────────────────────────────────────┤
│                                     │
│  We noticed you visit these places  │
│  frequently. Give them names for    │
│  better journal entries.            │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ┌─────────────────────┐    │   │  Place card
│  │  │                     │    │   │  - Mini map preview (150dp)
│  │  │   [Map Preview]     │    │   │  - Shows location marker
│  │  │                     │    │   │  - Warm peach marker
│  │  └─────────────────────┘    │   │
│  │                             │   │
│  │  📍 123 Main St, Downtown    │   │  Address
│  │  12 visits • Usually 9-10am │   │  Stats + pattern
│  │                             │   │
│  │  Suggested: ☕ Coffee Shop   │   │  Smart suggestion
│  │                             │   │
│  │  ┌──────────────────┐       │   │
│  │  │  Name This Place │       │   │  Primary button
│  │  └──────────────────┘       │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  [Map Preview]              │   │  Another place
│  │  📍 456 Oak Ave             │   │
│  │  8 visits • Usually 6-7pm   │   │
│  │  Suggested: 🏋️ Gym          │   │
│  │  [Name This Place]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ I'll name these later        │  │  Skip button
│  └──────────────────────────────┘  │
└─────────────────────────────────────┘
```

**Smart Suggestions Based On**:

- Time of day (morning → cafe, midday → work, evening → home/gym)
- Dwell time (short → store, long → home/work)
- Day of week (weekday → work, weekend → recreation)
- Nearby POIs from map data

---

### 6.2 Place Naming Dialog

**Purpose**: Quick naming interface for places

```
┌─────────────────────────────────────┐
│  Name This Place                    │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │  Map preview (200dp)
│  │   [Interactive Mini Map]    │   │  - Draggable marker
│  │         📍                  │   │  - Shows radius circle
│  │                             │   │  - Warm peach accent
│  └─────────────────────────────┘   │
│                                     │
│  📍 123 Main St, Downtown           │  Address display
│                                     │
│  ┌─────────────────────────────┐   │
│  │ [Sunrise Coffee Co.]        │   │  Name input
│  └─────────────────────────────┘   │  - Rounded 16dp
│                                     │  - Focus: E8A87C underline
│  What type of place?                │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ ☕️   │ │ 🏠   │ │ 💼   │        │  Category chips
│  │ Cafe │ │ Home │ │ Work │        │  - Horizontal scroll
│  └──────┘ └──────┘ └──────┘        │  - Peach when selected
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ 🍽️   │ │ 🏋️   │ │ More │        │  More categories
│  │ Food │ │ Gym  │ │ (32) │        │  - Tap More → Full list
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  How often do you visit?            │
│  ● Daily  ○ Weekly  ○ Sometimes    │  Radio buttons inline
│                                     │
│  ┌─────────────┐  ┌─────────────┐  │
│  │   Cancel    │  │     Save    │  │  Buttons
│  └─────────────┘  └─────────────┘  │
│                                     │
│  🔒 This place stays private        │  Privacy note
└─────────────────────────────────────┘
```

**Interactions**:

- Tap map → Adjust marker position
- Pinch map → Adjust radius circle
- Type in name → Show auto-complete suggestions
- Tap category → Select (single select)
- Tap "More" → Open category picker (6.5)

**Implementation**: `PlaceNamingDialog`

- Type: Bottom sheet
- Height: 75% of screen
- Map: Interactive Google Maps widget
- Radius: Visual circle overlay (50-500m)

---

### 6.3 Place List Management Screen

**Purpose**: View and manage all named places

```
┌─────────────────────────────────────┐
│  My Places              🔍  📍  ⋮   │  Header
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │                             │   │  Compact map (200dp)
│  │      [Map Overview]         │   │  - Shows all named places
│  │    (12 places shown)        │   │  - Clustered markers
│  │    Tap to expand ↗          │   │  - Tap → Full screen map
│  └─────────────────────────────┘   │
│                                     │
│  ┌──────────────────────────────┐  │
│  │ All  Primary  Frequent  ⋮   │  │  Filter chips
│  └──────────────────────────────┘  │
│                                     │
│  PRIMARY PLACES                     │  Section header
│  ┌─────────────────────────────┐   │
│  │ 🏠 Home                      │   │  Place card
│  │ 123 Oak Street               │   │  - Icon based on category
│  │ Primary • 2.1 mi        →   │   │  - Name + address
│  └─────────────────────────────┘   │  - Significance + distance
│  ┌─────────────────────────────┐   │  - Tap → Detail screen
│  │ 💼 Work                      │   │  - Swipe → Edit/Delete
│  │ Tech Hub, Downtown           │   │
│  │ Primary • 5.3 mi        →   │   │
│  └─────────────────────────────┘   │
│                                     │
│  FREQUENT PLACES                    │
│  ┌─────────────────────────────┐   │
│  │ ☕️ Sunrise Coffee           │   │
│  │ 12 visits • 2.3 mi      →   │   │  Shows visit count
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 🏋️ Fitness First            │   │
│  │ 8 visits • 1.1 mi       →   │   │
│  └─────────────────────────────┘   │
│                                     │
│  RECENT VISITS                      │
│  ┌─────────────────────────────┐   │
│  │ 🍽️ Italian Bistro           │   │
│  │ 2 visits • 2 days ago   →   │   │  Shows recency
│  └─────────────────────────────┘   │
│                                     │
│  [+] Add New Place                  │  Add button
└─────────────────────────────────────┘
```

**Interactions**:

- Tap map → Full screen map view (6.4)
- Tap card → Place detail screen (6.8)
- Swipe left → Edit / Delete
- Pull to refresh → Update visit counts
- Tap [+] → Place picker or manual entry

**Implementation**: `PlacesListScreen`

- Route: `/settings/places`
- Uses: `GroupedListContainer`
- Sorting: By significance, then visit count
- Empty state: "No places named yet"

---

### 6.4 Full Screen Map View

**Purpose**: Explore all places on a map

```
┌─────────────────────────────────────┐
│  ← My Places Map            🔍  ⋮   │  Header (transparent)
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │                             │   │
│  │      [Full Map View]        │   │  Full screen Google Maps
│  │                             │   │  - Colored markers by category
│  │    • Home (🏠)             │   │  - Clustered when zoomed out
│  │    • Work (💼)             │   │  - Heat map overlay (optional)
│  │    • Cafes (☕️)            │   │  - Current location shown
│  │    • More places...         │   │
│  │                             │   │
│  │                             │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│  ┌──────────────────────────────┐  │
│  │ 🏠 ☕️ 🍽️ 🏋️ All         ⋮  │  │  Category filter (bottom)
│  └──────────────────────────────┘  │  - Horizontal scroll
│                                     │  - Toggle categories
│  ┌───────┐                         │
│  │   +   │                         │  FAB (bottom right)
│  └───────┘                         │  - Add new place
└─────────────────────────────────────┘
```

**Interactions**:

- Pinch → Zoom in/out
- Drag → Pan map
- Tap marker → Show place card (bottom sheet)
- Long press → Drop pin at location → Name dialog
- Tap category → Filter markers

**Map Marker Design**:

- Primary: ⭐ star icon, 40px, E8A87C
- Frequent: Category icon, 32px, category color
- Occasional: Small dot, 24px, gray
- Clustered: Number badge, size varies

---

### 6.5 Category Picker

**Purpose**: Choose place category

```
┌─────────────────────────────────────┐
│  ← Place Category                   │
├─────────────────────────────────────┤
│  🔍 Search categories...            │  Search bar
│                                     │
│  PERSONAL                           │  Section header
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ 🏠   │ │ 💼   │ │ 🏫   │        │  Grid layout (3 columns)
│  │ Home │ │ Work │ │School│        │  - Icon + label
│  └──────┘ └──────┘ └──────┘        │  - Peach border when selected
│  ┌──────┐ ┌──────┐                 │
│  │ 👨‍👩‍👧‍👦 │ │ 🏥   │                 │
│  │Family│ │Health│                 │
│  └──────┘ └──────┘                 │
│                                     │
│  SOCIAL                             │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ ☕️   │ │ 🍽️   │ │ 🍺   │        │
│  │ Cafe │ │ Food │ │ Bar  │        │
│  └──────┘ └──────┘ └──────┘        │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ 🎭   │ │ 🎵   │ │ 🛍️   │        │
│  │ Arts │ │Music │ │ Shop │        │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  ACTIVITIES                         │
│  ┌──────┐ ┌──────┐ ┌──────┐        │
│  │ 🏋️   │ │ 🌳   │ │ ✈️   │        │
│  │Fitness│ │Nature│ │Travel│       │
│  └──────┘ └──────┘ └──────┘        │
│                                     │
│  ┌─────────────────────────────┐   │
│  │  ✏️ Custom Category         │   │  Custom entry
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Implementation**: `CategoryPickerSheet`

- Type: Bottom sheet or full screen
- Grid: 3 columns
- Icons: SF Symbols / Material Icons
- Search: Filter by category name
- Custom: Text input for unique categories

**Category Colors** (subtle tints):

- Home: Warm peach (E8A87C)
- Work: Cool blue (8AAEE0)
- Food: Soft red (E88A8A)
- Social: Purple (B88AE8)
- Fitness: Green (8AE8B8)
- Nature: Light green (8AE88A)

---

### 6.6 Significance Level Selector

**Purpose**: Set place importance

```
┌─────────────────────────────────────┐
│  How often do you visit?            │
│  ─────────────────────────────────  │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ ⭐ PRIMARY                   │   │  Option card
│  │ Places you visit daily      │   │  - Selected: E8A87C background
│  │                             │   │  - Icon + title
│  │ Examples: Home, Work        │   │  - Description
│  │ • Always mentioned in       │   │  - Benefits list
│  │   journal entries           │   │
│  │ • Quick access              │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 🔄 FREQUENT                  │   │  ← Selected state
│  │ Places you visit weekly     │   │     (gradient bg)
│  │                             │   │
│  │ Examples: Gym, Favorite Cafe│   │
│  │ • Mentioned when visited    │   │
│  │ • Shows visit patterns      │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📍 OCCASIONAL                │   │
│  │ Places you visit sometimes  │   │
│  │                             │   │
│  │ Examples: Restaurants       │   │
│  │ • Mentioned on request      │   │
│  │ • Searchable history        │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Implementation**: Inline in place editor

- Type: Radio buttons styled as cards
- Selection: Single tap
- Feedback: Haptic + animation
- Examples: Context-specific

---

### 6.7 Custom Place Description

**Purpose**: Add personal notes about a place

_Simple text area in place editor:_

```
┌─────────────────────────────────┐
│ Notes (Optional)                │
│ ┌─────────────────────────────┐ │
│ │ My favorite spot for         │ │  Multi-line text area
│ │ morning coffee. Great        │ │  - Rounded corners
│ │ wifi and quiet atmosphere.   │ │  - Light background
│ │                              │ │  - 150 char limit
│ └─────────────────────────────┘ │
│ 42 / 150 characters             │  Character counter
└─────────────────────────────────┘
```

---

### 6.8 Place Statistics Screen

**Purpose**: View visit history and details

```
┌─────────────────────────────────────┐
│  ← Sunrise Coffee Co.       Edit    │  Header
├─────────────────────────────────────┤
│  ┌─────────────────────────────┐   │
│  │                             │   │  Map (200dp)
│  │   [Location Map]            │   │  - Shows place marker
│  │        📍                   │   │  - Nearby landmarks
│  └─────────────────────────────┘   │
│                                     │
│  ☕ Cafe & Coffee Shop              │  Category
│  123 Main St, Downtown              │  Address
│                                     │
│  ┌─────────────────────────────┐   │
│  │ 📊 Visit Statistics         │   │  Stats card
│  │ 12 total visits             │   │  - Clean layout
│  │ Usually 9-10am              │   │  - Icons for each stat
│  │ Avg. 45 min per visit       │   │
│  │ 🔄 Frequent Place            │   │
│  └─────────────────────────────┘   │
│                                     │
│  Visit History                      │  Section header
│  ┌─────────────────────────────┐   │
│  │ Today, 9:15am               │   │  Visit list
│  │ 42 minutes                  │   │  - Date + time
│  └─────────────────────────────┘   │  - Duration
│  ┌─────────────────────────────┐   │
│  │ Yesterday, 8:45am           │   │
│  │ 38 minutes                  │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ 3 days ago, 10:00am         │   │
│  │ 1 hour 15 minutes           │   │
│  └─────────────────────────────┘   │
│                                     │
│  [View All Visits (12)]             │  Button
│                                     │
│  Delete Place                       │  Danger action (red)
└─────────────────────────────────────┘
```

**Interactions**:

- Tap "Edit" → Place editor
- Tap map → Full screen map
- Tap visit → Show journal entry for that day
- Tap "Delete" → Confirmation dialog

---

## Section 7: Journal Preferences UI

### 7.1 Journal Preferences Screen

**Purpose**: Customize journal generation settings

```
┌─────────────────────────────────────┐
│  ← Journal Preferences              │  Header
├─────────────────────────────────────┤
│                                     │
│  WRITING STYLE                      │  Section header
│  ┌─────────────────────────────┐   │
│  │ Detail Level                │   │  Setting tile
│  │ High                    →   │   │  - Title
│  └─────────────────────────────┘   │  - Current value →
│  ┌─────────────────────────────┐   │
│  │ Tone                        │   │
│  │ Casual                  →   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Entry Length                │   │
│  │ Medium                  →   │   │
│  └─────────────────────────────┘   │
│                                     │
│  PRIVACY                            │
│  ┌─────────────────────────────┐   │
│  │ Default Privacy Level       │   │
│  │ Balanced                →   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Include Unknown People      │   │  Toggle switch
│  │                         ◯   │   │  - Peach when on
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Include Health Data         │   │
│  │                         ●   │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │ Include Weather             │   │
│  │                         ●   │   │
│  └─────────────────────────────┘   │
│                                     │
│  LOCATION                           │
│  ┌─────────────────────────────┐   │
│  │ Location Specificity        │   │
│  │ Neighborhood            →   │   │
│  └─────────────────────────────┘   │
│                                     │
│  MEASUREMENTS                       │
│  ┌─────────────────────────────┐   │
│  │ Units                       │   │
│  │ Imperial (mi, ft)       →   │   │
│  └─────────────────────────────┘   │
│                                     │
│  ┌─────────────────────────────┐   │
│  │    Reset to Defaults        │   │  Reset button
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

**Implementation**: `JournalPreferencesScreen`

- Route: `/settings/journal-preferences`
- Auto-save on change
- Uses: `ContextManagerService.setPreference()`
- Validation: Ensure valid values

---

### 7.2-7.5 Preference Pickers

#### Detail Level Picker

```
┌─────────────────────────────────┐
│  ← Detail Level                 │
│                                 │
│  ○ Low                          │  Radio list
│    Brief, concise entries       │  - Description under each
│                                 │
│  ● Medium                       │  ← Selected
│    Balanced detail              │
│                                 │
│  ○ High                         │
│    Rich, detailed entries       │
└─────────────────────────────────┘
```

#### Tone Picker

```
┌─────────────────────────────────┐
│  ← Tone                         │
│                                 │
│  ● Casual                       │
│    Friendly, relaxed            │
│                                 │
│  ○ Reflective                   │
│    Thoughtful, introspective    │
│                                 │
│  ○ Professional                 │
│    Formal, structured           │
└─────────────────────────────────┘
```

#### Length Picker

```
┌─────────────────────────────────┐
│  ← Entry Length                 │
│                                 │
│  ○ Short                        │
│    1-2 paragraphs               │
│                                 │
│  ● Medium                       │
│    2-3 paragraphs               │
│                                 │
│  ○ Long                         │
│    3-5 paragraphs               │
└─────────────────────────────────┘
```

#### Location Specificity

```
┌─────────────────────────────────┐
│  ← Location Specificity         │
│                                 │
│  ○ Exact Address                │
│    "123 Main St"                │
│                                 │
│  ● Neighborhood                 │
│    "Downtown"                   │
│                                 │
│  ○ City Only                    │
│    "Salt Lake City"             │
│                                 │
│  ○ Generic                      │
│    "a park"                     │
└─────────────────────────────────┘
```

---

## Navigation Integration

### Settings Screen Updates

Add new items to existing Settings screen:

```dart
// In settings_screen.dart, add to "Journal" section:

GroupedListContainer(
  isLight: isLight,
  children: [
    // Existing items...
    
    _buildSettingsTile(
      icon: Icons.person,
      title: 'People',
      subtitle: '12 people labeled',
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => context.push('/settings/people'),
    ),
    
    _buildSettingsTile(
      icon: Icons.location_on,
      title: 'Places',
      subtitle: '8 places named',
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => context.push('/settings/places'),
    ),
    
    _buildSettingsTile(
      icon: Icons.tune,
      title: 'Journal Preferences',
      subtitle: 'Customize writing style',
      trailing: Icon(Icons.arrow_forward_ios),
      onTap: () => context.push('/settings/journal-preferences'),
    ),
  ],
),
```

### Routes (GoRouter)

```dart
// Add to router configuration:

GoRoute(
  path: '/settings/people',
  builder: (context, state) => const PeopleListScreen(),
),

GoRoute(
  path: '/settings/places',
  builder: (context, state) => const PlacesListScreen(),
),

GoRoute(
  path: '/settings/journal-preferences',
  builder: (context, state) => const JournalPreferencesScreen(),
),
```

---

## Component Library

### Reusable Components

1. **PersonAvatar**
   - Circular avatar with border
   - Supports placeholder for unlabeled
   - Size variants: 48dp, 64dp, 120dp

2. **PlaceMarker**
   - Map marker with category icon
   - Color-coded by significance
   - Size variants based on zoom level

3. **CategoryChip**
   - Icon + label
   - Selected/unselected states
   - Warm peach accent

4. **SignificanceBadge**
   - ⭐ Primary, 🔄 Frequent, 📍 Occasional
   - Inline or overlay

5. **PrivacyIndicator**
   - 🔒 Excluded, 👤 First name, 👥 Full
   - Color-coded

6. **VisitStat**
   - Visit count, frequency, patterns
   - Icon + text layout

---

## Animation Specifications

### Micro-interactions

1. **Success Feedback** (Person/Place saved)
   - Scale: 1.0 → 1.05 → 1.0 (300ms)
   - Opacity: Checkmark fade in (200ms)
   - Haptic: Light impact
   - Color: Warm glow around element

2. **Selection States**
   - Border: 0dp → 2dp with E8A87C (150ms)
   - Background: Fade to peach tint (150ms)
   - Scale: 1.0 → 1.02 (100ms)

3. **Card Swipe Actions**
   - Reveal: Slide with spring curve (300ms)
   - Icons: Fade in at 70% reveal
   - Colors: Edit (E8A87C), Delete (soft red)

4. **Dialog/Sheet Transitions**
   - Slide up: From bottom with ease-out (250ms)
   - Backdrop: Fade in (200ms)
   - Dismiss: Slide down with ease-in (200ms)

5. **Map Marker Drops**
   - Bounce: Scale 0 → 1.2 → 1.0 (400ms)
   - Shadow: Expand during bounce
   - Color: Pulse once after landing

---

## Accessibility

### Screen Reader Support

- All images have semantic labels
- Cards announce: "Person: Sarah, Sister, 45 photos"
- Places announce: "Sunrise Coffee, Cafe, 12 visits"

### Contrast Ratios

- All text meets WCAG AA (4.5:1)
- Icons paired with labels
- Color not sole indicator

### Touch Targets

- Minimum 48dp for all buttons
- Adequate spacing between elements
- Large swipe areas for cards

### Keyboard Navigation

- Tab order follows visual flow
- Enter/Space for selection
- Escape to dismiss dialogs

---

## Next Steps

1. **Create component library** (PersonAvatar, PlaceMarker, etc.)
2. **Implement Section 5** (Person UI) - Priority 1
3. **Implement Section 6** (Place UI) - Priority 2
4. **Implement Section 7** (Preferences UI) - Priority 3
5. **User testing** with 5-10 beta users
6. **Iterate** based on feedback
7. **Polish** animations and micro-interactions

---

## Files to Create

### Screens

```
lib/screens/context/
  ├── face_clustering_screen.dart
  ├── people_list_screen.dart
  ├── person_detail_screen.dart
  ├── places_list_screen.dart
  ├── place_detail_screen.dart
  ├── places_map_screen.dart
  └── journal_preferences_screen.dart
```

### Dialogs

```
lib/widgets/context/
  ├── person_label_dialog.dart
  ├── place_naming_dialog.dart
  ├── relationship_picker.dart
  ├── category_picker.dart
  ├── privacy_level_picker.dart
  └── significance_picker.dart
```

### Components

```
lib/widgets/context/components/
  ├── person_avatar.dart
  ├── person_card.dart
  ├── place_marker.dart
  ├── place_card.dart
  ├── category_chip.dart
  ├── significance_badge.dart
  ├── privacy_indicator.dart
  └── visit_stat.dart
```

---

End of UI Design Specification
