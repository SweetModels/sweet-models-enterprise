# Admin Dashboard UI Structure

## Visual Layout

```
┌─────────────────────────────────────────────────────────┐
│  Sweet Models - GOD MODE                        [ADMIN] │  ← AppBar
│                                              [  Logout ]  │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  Welcome, GOD                                          │
│  Sweet Models Enterprise Control Panel                │
│                                                         │
│  ┌──────────────────┬──────────────────┐              │
│  │ $ Revenue        │ 💰 Total Tokens  │              │
│  │ 2,500,000 COP    │ 50,000           │  ← Stats    │
│  │ [Verde Icon]     │ [Dorado Icon]    │    Grid     │
│  └──────────────────┴──────────────────┘              │
│  ┌──────────────────┬──────────────────┐              │
│  │ 👥 Active Models │ ⚠️ Alerts        │              │
│  │ 12               │ 0                │              │
│  │ [Rosa Icon]      │ [Rojo Icon]      │              │
│  └──────────────────┴──────────────────┘              │
│                                                         │
│  Live Activity                                         │
│  ┌──────────────────────────────────────────────────┐ │
│  │ 🟢 Alejandra Vega - Private Show      42 viewing │ │
│  │ 🟢 Isabella Santos - Group Chat       28 viewing │ │
│  │ 🟢 Sofia Marquez - Cam Show           15 viewing │ │
│  └──────────────────────────────────────────────────┘ │
│                                                         │
│                   Last updated: 2m ago                │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

## Component Hierarchy

```
AdminDashboardScreen (StatefulWidget)
├── AppBar
│   ├── Title: "Sweet Models - GOD MODE"
│   ├── ADMIN Badge (Rosa border)
│   └── Logout IconButton (Rojo)
│
├── FutureBuilder<DashboardStats>
│   ├── Loading: CircularProgressIndicator (Dorado)
│   ├── Error: Error box with retry button
│   ├── Data: RefreshIndicator
│   │   └── SingleChildScrollView
│   │       └── Column
│   │           ├── Welcome text
│   │           ├── GridView (2x2)
│   │           │   ├── StatCard (Revenue - Verde)
│   │           │   ├── StatCard (Tokens - Dorado)
│   │           │   ├── StatCard (Active Models - Rosa)
│   │           │   └── StatCard (Alerts - Rojo/Verde)
│   │           ├── "Live Activity" heading
│   │           ├── Container (Activity list)
│   │           │   └── Column
│   │           │       ├── LiveActivityItemWidget (1)
│   │           │       ├── LiveActivityItemWidget (2)
│   │           │       ├── LiveActivityItemWidget (3)
│   │           │       └── ...
│   │           └── "Last updated" timestamp
│   └── Empty: "No data available"
│
└── LogoutDialog (AlertDialog)
    ├── Title: "Confirm Logout"
    ├── Message: "Are you sure you want to logout?"
    ├── Cancel Button
    └── Logout Button (Rojo)
```

## StatCard Widget Details

```
┌─ StatCard ────────────────────────┐
│ Label (12px, grey)                 │
│ "Total Revenue"                    │
│                                    │
│ Value (28px, bold, white)          │ Icon
│ "$2,500,000"    ┌──────────────┐   │ (Verde)
│                 │ 📈           │   │
│                 │ [Verde color]│   │
│                 └──────────────┘   │
│                                    │
│ Subtitle (11px, italic, grey)      │
│ "COP"                              │
│                                    │
│ Border: 2px Verde with 0.3 opacity │
│ Shadow: Verde glow 0.1 opacity     │
└────────────────────────────────────┘
```

## LiveActivityItem Details

```
┌─ Live Activity Item ──────────────────┐
│ 🟢 (Alejandra Vega)  (Private Show)  42 watching
│    ├─ Status indicator (green dot)    └─ Viewer count
│    ├─ Model name (13px, bold, white)   (14px, dorado, bold)
│    └─ Room name (11px, grey)           "watching" (10px, grey)
│
│ Pink left border (4px)
│ Dark card background (#1E1E1E)
│ 12px margin at bottom
└───────────────────────────────────────┘
```

## Color Usage Map

```
🎨 Text & Typography:
   - Title/Labels: White (#FFFFFF)
   - Subtitles/Hints: Grey (#B0B0B0)
   - Links/Accents: Dorado (#D4AF37)

🎨 Backgrounds:
   - Screen: Dark (#121212)
   - Cards: Card-Dark (#1E1E1E)
   - Inputs: Darker (#111328)

🎨 Stat Card Colors:
   1. Revenue → Verde (#4CAF50) - Success/Financial
   2. Tokens → Dorado (#D4AF37) - Premium/Gold
   3. Active Models → Rosa (#E91E63) - Brand/Alert
   4. Alerts → Rojo (#F44336) if > 0, Verde if = 0

🎨 Interactive:
   - Borders: Color-specific at 0.3 opacity
   - Shadows: Color-specific at 0.1 opacity
   - Hover: Lighter shade of accent color

🎨 Status Indicators:
   - Active stream: Verde dot (#4CAF50)
   - Inactive stream: Rojo dot (#F44336)
```

## Data Flow Diagram

```
┌─────────────────────┐
│   LoginScreen       │
│  (role == 'admin')  │
└──────────┬──────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  AdminDashboardScreen                │
│  - Initializes DashboardService      │
│  - Calls _dashboardService.getAdminStats()
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  DashboardService                    │
│  - Retrieves token from SharedPrefs  │
│  - Builds Authorization header       │
│  - Makes HTTP GET request            │
│  - Endpoint: /admin/dashboard        │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  Backend API                         │
│  GET /admin/dashboard                │
│  (Requires Authorization header)     │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  JSON Response                       │
│  {                                   │
│    "total_tokens": 50000,           │
│    "total_revenue_cop": 2500000,    │
│    "active_models": 12,              │
│    "alerts_count": 0,                │
│    "last_updated": "2024-01-15..."   │
│  }                                   │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  DashboardStats.fromJson()           │
│  (Parses response to typed model)    │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  FutureBuilder                       │
│  - Receives DashboardStats           │
│  - Updates UI with data              │
│  - Handles loading/error states      │
└──────────┬──────────────────────────┘
           │
           ↓
┌──────────────────────────────────────┐
│  AdminDashboardScreen UI             │
│  - StatCards display values          │
│  - Live Activity updates             │
│  - Last updated timestamp            │
└──────────────────────────────────────┘
```

## State Management Flow

```
AdminDashboardScreen State:
├── _dashboardService: DashboardService
├── _statsFuture: Future<DashboardStats>
└── Lifecycle:
    ├── initState()
    │   └─ Initialize DashboardService
    │   └─ Call _dashboardService.getAdminStats()
    │
    ├── build()
    │   └─ FutureBuilder listens to _statsFuture
    │
    └─ _logout()
        ├─ Show confirmation dialog
        ├─ Clear SharedPreferences
        ├─ Call dashboardService.clearCache()
        └─ Navigate to LoginScreen
```

## Error Handling UI

```
When error occurs:
┌─────────────────────────────────────┐
│        Connection Error             │
│        ❌ [Large error icon]        │
│                                     │
│  "Connection Error"                 │
│  "[Error message from server]"      │
│                                     │
│           [RETRY Button]            │
└─────────────────────────────────────┘

User actions:
- Click RETRY: Calls setState(() { _statsFuture = ... })
- Automatically refetches data
```

## Loading State

```
When loading data:
┌─────────────────────────────────────┐
│                                     │
│                                     │
│       ⟲ Loading Dashboard...       │
│       (CircularProgressIndicator   │
│        with Dorado color)          │
│                                     │
│                                     │
└─────────────────────────────────────┘
```

## Logout Dialog

```
┌─ Logout Confirmation ─────────────────┐
│                                       │
│  "Confirm Logout"                    │
│                                       │
│  "Are you sure you want to logout?"  │
│                                       │
│      [Cancel]        [Logout]        │
│       (Dorado)        (Rojo)          │
│                                       │
└───────────────────────────────────────┘

Actions:
- Cancel: Close dialog, return to dashboard
- Logout: 
  ├─ Remove 'access_token' from SharedPreferences
  ├─ Call dashboardService.clearCache()
  └─ Navigate to LoginScreen with pushReplacementNamed
```

## Responsive Design

```
Mobile (360px wide):
- Cards stack vertically in responsive grid
- StatCards adjust font sizes
- Full-width elements

Tablet (1024px wide):
- 2x2 grid maintains proportions
- Larger fonts
- Better spacing

Desktop (1600px+ wide):
- Could expand to 4-column grid
- Sidebar navigation possible
- Extended statistics panel
```

## Typography Details

```
Theme: Google Fonts (Poppins)

Heading:     "Welcome, GOD" (28px, bold, white)
Subtitle:    "Sweet Models Enterprise..." (12px, grey)
Label:       "Total Revenue" (12px, bold, grey)
Value:       "$2,500,000" (28px, bold, white)
Subvalue:    "COP" (11px, italic, grey)
Text:        Default body (14px, grey)
Small:       "watching" (10px, grey)
```

## Interactions

```
RefreshIndicator:
- Swipe down on content area
- Triggers _statsFuture refresh
- Shows loading spinner
- Updates all stat cards
- Shows "Last updated" timestamp

Tap on Logout:
- Shows confirmation dialog
- Clears all session data
- Returns to LoginScreen

Long tap on card:
- No action (designed for future)

Status indicator (green dot):
- Visual indicator of stream status
- Green = Active
- Red = Inactive
```

---

**UI Component Reference**: All components use material design 3 with custom Sweet Models Enterprise theming.
