# Prompt Maestro Gamification System - Implementation Summary

**Status**: ✅ Backend Complete | ✅ Flutter UI Complete | ⏳ Payroll Integration Pending

---

## Phase 1: Completed ✅

### 1. Backend Gamification Infrastructure (Rust/Axum)

#### `backend_api/src/gamification/config.rs`
- **Purpose**: Single source of truth for all gamification constants and business rules
- **Constants Defined**:
  - **INDIVIDUAL_RANKS**: 5 tiers (NOVICE→GODDESS) with XP thresholds 5k→80k
  - **GROUP_RANKS**: 5 levels (30k→500k tokens) with cash bonuses $100k→$4M
  - **FRAGILITY_RULES**: 5 XP burn scenarios with percentages (10%-100%)
- **Helper Functions**:
  - `get_individual_rank_by_xp(xp)` → Returns rank tier matching XP threshold
  - `get_fragility_rule(reason)` → Returns burn percentage for reason code
  - `calculate_xp_loss(current_xp, percentage)` → Computes XP amount to burn

#### `backend_api/src/gamification/engine.rs` (Extended)
- **New Structures**:
  - `BurnResult`: Audit record for XP burning (user_id, xp_loss, previous_xp, new_xp, percentage, description)
- **New Async Functions**:
  - `burn_xp(user_id, reason, pool)`: 
    - Queries user's current XP
    - Looks up burn % from reason code
    - Calculates loss amount
    - Updates users table (xp field decremented)
    - Inserts audit log to xp_burn_log table
    - Returns BurnResult
  - `add_xp_reward(user_id, amount, reason, pool)`:
    - Increments xp field (current balance)
    - Increments total_xp_earned field (historical tracking)
    - Logs to xp_earn_log table
- **Burn Percentages**:
  - STRIKE_1: 10%
  - STRIKE_2: 30%
  - STRIKE_3: 100%
  - DIRTY_ROOM: 20%
  - LOW_PRODUCTION: 5%

#### `backend_api/src/gamification/store.rs`
- **Models**:
  - `RewardItem`: id, name, category, xp_cost, cash_value_cop, description, image_url
  - `RedeemRequest`: rewardId, xpSpent
  - `RedeemResponse`: success, message, ticketId, remainingXp
- **Reward Catalog** (8 items across 3 categories):
  - **Bienestar** (Green):
    - Peluquería: 500 XP ($100k COP value)
    - Spa Completo: 750 XP ($150k COP value)
  - **Lujo** (Orange):
    - Uber Eats: 300 XP ($50k COP value)
    - Uber Rides: 250 XP ($40k COP value)
    - Tech Case Premium: 400 XP ($80k COP value)
  - **Jackpot** (Pink):
    - Viaje Cartagena: 5000 XP ($500k COP value)
    - Room Remodelación: 3000 XP ($300k COP value)
    - Fondo Cirugía: 10000 XP ($1M COP value)
- **HTTP Handlers**:
  - `GET /api/gamification/catalog` → Returns all 8 rewards
  - `GET /api/gamification/balance` → Returns UserBalance (current_xp, total_xp_earned, xp_available, xp_at_risk)
  - `POST /api/gamification/redeem` → Validates XP, deducts, creates reward_redemptions ticket

#### `backend_api/src/main.rs` (Routes Added)
```rust
.route("/api/gamification/catalog", get(gamification::get_catalog_handler))
.route("/api/gamification/balance", get(gamification::get_user_balance_handler))
.route("/api/gamification/redeem", post(gamification::redeem_reward_handler))
```

---

### 2. Backend Integration - XP Burn Triggers

#### `backend_api/src/operations/attendance.rs` (Modified)
- **Import**: Added `use crate::gamification;`
- **Strike Integration**:
  - Strike 1: Calls `burn_xp(user_id, "STRIKE_1", pool)` → 10% XP burn + 50% pay today
  - Strike 2: Calls `burn_xp(user_id, "STRIKE_2", pool)` → 30% XP burn + week degraded
  - Strike 3: Calls `burn_xp(user_id, "STRIKE_3", pool)` → 100% XP burn + \$1M penalty

#### `backend_api/src/operations/room.rs` (Modified)
- **Import**: Added `use crate::gamification;`
- **Dirty Room Integration**:
  - When `is_dirty == true`: For each room member, calls `burn_xp(member_id, "DIRTY_ROOM", pool)` → 20% XP burn
  - Runs in loop after penalty applied

---

### 3. Flutter Mobile App

#### Gamification Models (`mobile_app/lib/models/gamification_models.dart`)
- `RewardItem`: Dart model matching backend (id, name, category, xp_cost, cash_value_cop, description, image_url)
- `UserBalance`: Tracks current_xp, total_xp_earned, xp_available, xp_at_risk
- `RedeemRequest/Response`: Request/response DTOs for redemption flow
- `XpBurnEvent`: Audit model for burn events (xp_loss, previous_xp, new_xp, percentage, description)

#### Gamification Service (`mobile_app/lib/services/gamification_service.dart`)
- **Base URL Detection**: Platform-aware (Android emulator, iOS sim, desktop)
- **API Methods**:
  - `getCatalog()` → GET /api/gamification/catalog with Bearer token
  - `getUserBalance()` → GET /api/gamification/balance with Bearer token
  - `redeemReward(rewardId, xpSpent)` → POST /api/gamification/redeem with Bearer token
- **Helper Functions**:
  - `formatNumber(value)` → Converts 1000 → "1k", 1000000 → "1M"
  - `getCategoryColor(category)` → Returns Color (Bienestar=Green, Lujo=Orange, Jackpot=Pink)
  - `getCategoryIcon(category)` → Returns emoji (💆‍♀️, ✨, 🎁)

#### Store Screen (`mobile_app/lib/screens/store_screen.dart`)
- **Layout**: Column with AppBar, Balance Card, Category Tabs, Reward Grid
- **Balance Card**:
  - Shows current XP vs XP at risk
  - Displays percentage available
  - Linear progress bar visual
  - Gradient background (blue)
- **Category Tabs**: FilterChip tabs for All/Bienestar/Lujo/Jackpot with color coding
- **Reward Grid**: 2-column responsive grid showing:
  - Reward image (cached network image with fallback icon)
  - Name (2 lines max)
  - Description (1 line)
  - XP cost (amber badge)
  - Cash value (green badge)
- **Redemption Dialog**:
  - Confirmation UI with reward details
  - XP calculation preview (current → after)
  - Loading state on redeem button
  - Success/error SnackBar feedback
- **Riverpod Integration**:
  - `catalogProvider`: FutureProvider for reward list
  - `userBalanceProvider`: FutureProvider for balance
  - `selectedCategoryProvider`: StateProvider for active tab
  - Auto-refresh after successful redeem

#### XP Burn Alert Dialog (`mobile_app/lib/widgets/xp_burn_alert_dialog.dart`)
- **Visual**: Red fire emoji with scale animation on mount
- **Content Sections**:
  - ⚠️ Title (e.g., "Primer Aviso (Strike 1)")
  - Description (reason for burn)
  - XP loss breakdown:
    - XP Anterior: [previous value]
    - XP Quemado: -[loss amount] ([percentage]%)
    - XP Actual: [new value]
  - Reason container (blue info box)
  - "Entendido" button to dismiss
- **Helper Function**: `showXpBurnAlert(context, ...)` for easy invocation
- **Reason Map**: `XpBurnReasonMap` with predefined titles/descriptions for each burn type
- **Animation**: TweenAnimationBuilder for fire emoji scale-in effect

---

## Phase 2: Pending ⏳

### Integration with Payroll Close Week

**Location**: `backend_api/src/operations/payroll.rs` in `close_week_process()` function

**Tasks**:
1. **Individual Rank Rewards**:
   - After evaluating each user's tokens vs rank goal
   - If tokens >= goal for NOVICE→GODDESS tier
   - Call `gamification::add_xp_reward(user_id, tier_xp_reward, "WEEKLY_GOAL_MET", pool)`
   - Example: User achieves NOVICE rank (5k tokens) → Award 500 XP

2. **Group Rank Rewards**:
   - After evaluating room group tokens vs group goal
   - If tokens >= goal for level 1-5
   - Call `gamification::add_xp_reward(user_id, group_xp_reward, "GROUP_GOAL_MET", pool)` for each member
   - Distribute group XP fairly (e.g., equal split or weighted by individual contribution)

3. **Low Production Burn** (Optional Enhancement):
   - If room total tokens < GROUP_QUOTA (1500)
   - Could call `burn_xp(member_id, "LOW_PRODUCTION", pool)` → 5% burn
   - OR apply via current penalty system (recommend current method)

**Pseudocode**:
```rust
// In close_week_process(), after evaluating tokens
for user in week_users {
    // Check individual rank
    let current_xp = user.xp;
    if let Some(rank) = get_individual_rank_by_xp(user.tokens) {
        let xp_reward = get_rank_xp_reward(rank); // 500, 750, 1000, 1500, 2000
        add_xp_reward(user.id, xp_reward, "WEEKLY_GOAL_MET", pool).await?;
    }
    
    // Check group rank (for room members)
    if room_tokens >= GROUP_QUOTA {
        if let Some(group_level) = get_group_rank_by_tokens(room_tokens) {
            let group_xp = get_group_xp_reward(group_level); // 250, 500, 750, 1000, 1250
            add_xp_reward(user.id, group_xp, "GROUP_GOAL_MET", pool).await?;
        }
    }
}
```

---

## Key Features Implemented

✅ **XP Burning (Fragilidad System)**:
- Automatic XP deduction on infractions
- Percentage-based loss (5%-100%)
- Audit logging (xp_burn_log table)
- Integrated with strike system and dirty room penalties

✅ **Reward Store**:
- 8 curated rewards spanning 3 categories
- Category-based filtering
- XP cost display with cash value equivalents
- Redemption validation and ticket generation

✅ **User Balance Tracking**:
- Current XP (spendable balance)
- Total XP Earned (historical)
- XP Available (current - at risk)
- XP At Risk (pending penalties)

✅ **Mobile UI**:
- Responsive grid layout for rewards
- Real-time balance display with risk indicator
- Smooth redemption flow
- Fire alert animation for burn events

---

## Database Tables Required

### Existing Tables (Modified)
- `users`: Add/ensure fields: `xp` (INT, default 0), `total_xp_earned` (INT, default 0)

### New Tables
```sql
-- Audit log for XP burns
CREATE TABLE xp_burn_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    previous_xp INT NOT NULL,
    xp_loss INT NOT NULL,
    new_xp INT NOT NULL,
    percentage INT NOT NULL,
    reason_code VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Reward redemption tickets
CREATE TABLE reward_redemptions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    reward_id VARCHAR(50) NOT NULL,
    xp_spent INT NOT NULL,
    status VARCHAR(20) DEFAULT 'pending', -- pending, approved, claimed, cancelled
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    claimed_at TIMESTAMP,
    UNIQUE(user_id, reward_id, created_at)
);

-- XP earnings audit log
CREATE TABLE xp_earn_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    xp_amount INT NOT NULL,
    reason_code VARCHAR(50) NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## Testing Checklist

### Backend (Rust)
- [ ] `cargo build` compiles without errors
- [ ] `POST /api/gamification/catalog` returns 8 rewards
- [ ] `GET /api/gamification/balance` returns UserBalance with correct calculations
- [ ] `POST /api/gamification/redeem` validates XP and creates ticket
- [ ] Strike in attendance triggers `burn_xp` with correct percentage
- [ ] Dirty room in operations triggers `burn_xp` for all members

### Frontend (Flutter)
- [ ] StoreScreen loads catalog and displays grid
- [ ] Category tabs filter rewards correctly
- [ ] Balance card displays accurate XP values
- [ ] Redeem dialog validates XP and shows confirmation
- [ ] Successful redeem refreshes balance and shows SnackBar
- [ ] XpBurnAlertDialog shows with animation
- [ ] All network calls include Bearer token

### Integration
- [ ] User gets XP burn alert when app opens after strike
- [ ] User can see reduced XP in store
- [ ] Reward redemption deducts XP correctly
- [ ] Payroll close_week adds XP for goal achievement

---

## File Manifest

### Backend Files
```
backend_api/src/
├── gamification/
│   ├── mod.rs (modified: added config, store exports)
│   ├── config.rs (new: constants, helpers)
│   ├── engine.rs (modified: added burn_xp, add_xp_reward, BurnResult)
│   └── store.rs (new: catalog, handlers, models)
├── operations/
│   ├── attendance.rs (modified: added strike XP burns)
│   └── room.rs (modified: added dirty room XP burns)
└── main.rs (modified: added 3 gamification routes)
```

### Frontend Files
```
mobile_app/lib/
├── models/
│   └── gamification_models.dart (new: RewardItem, UserBalance, etc.)
├── services/
│   └── gamification_service.dart (new: API client, helpers)
├── screens/
│   └── store_screen.dart (new: StoreScreen + _RedeemDialog)
└── widgets/
    └── xp_burn_alert_dialog.dart (new: Alert + reason mapping)
```

---

## Next Steps

1. **Database Setup**: Create xp_burn_log, reward_redemptions, xp_earn_log tables
2. **Payroll Integration**: Wire close_week_process to call add_xp_reward for goal achievements
3. **App Integration**: Call showXpBurnAlert() in main.dart or splash screen on app launch
4. **Testing**: Run full test suite (backend + frontend)
5. **Deployment**: Deploy to staging, verify end-to-end flows

---

## Technical Notes

- **XP Burning**: Automatic, non-reversible. Logged to xp_burn_log for audit trail.
- **XP Earning**: Only via rewards (goal achievement, bonuses) or store redemption reversals.
- **At-Risk XP**: Calculated as total_xp_earned - current_xp (cumulative losses).
- **Rate Limiting**: Consider adding rate limits on /api/gamification/redeem to prevent abuse.
- **Error Handling**: All async operations include error handling with user-friendly messages.

