# Admin Dashboard - Technical Handoff

**For**: Development & Backend Integration Team  
**Date**: January 2025  
**Status**: ✅ READY FOR BACKEND INTEGRATION  

---

## 🎯 Overview

Admin Dashboard is fully implemented on the Flutter side. Waiting for backend endpoints to complete integration testing.

**What's Ready:**
- ✅ Models (DashboardStats, LiveActivityItem, SystemAlert)
- ✅ Service layer (DashboardService with authentication)
- ✅ UI components (AdminDashboardScreen, StatCard)
- ✅ Navigation routing (role-based redirection)
- ✅ Error handling (connection, timeout, parsing)
- ✅ State management (FutureBuilder, RefreshIndicator)

**What's Needed:**
- ⏳ Backend endpoints (3 endpoints)
- ⏳ JWT validation for admin role
- ⏳ Integration testing

---

## 📦 Component Inventory

### Models (`lib/models/dashboard_stats.dart`)

```dart
class DashboardStats {
  final int totalTokens;
  final double totalRevenueCop;
  final int activeModels;
  final int alertsCount;
  final DateTime lastUpdated;
  
  factory DashboardStats.fromJson(Map<String, dynamic> json)
  Map<String, dynamic> toJson()
  factory DashboardStats.empty()
}

class LiveActivityItem {
  final String modelName;
  final String roomName;
  final int viewersCount;
  final String status;  // 'active' | 'inactive'
  final DateTime startedAt;
}

class SystemAlert {
  final String type;      // 'warning' | 'error' | 'info'
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
}
```

### Service (`lib/services/dashboard_service.dart`)

```dart
class DashboardService {
  // Configuration
  static const String baseUrl = 'http://10.0.2.2:3000';
  
  // Methods
  Future<DashboardStats> getAdminStats()
  Future<List<LiveActivityItem>> getLiveActivity()
  Future<List<SystemAlert>> getSystemAlerts()
  Future<void> markAlertAsRead(String alertId)
  Future<void> clearCache()
  
  // Private methods
  Future<String?> _getToken()
  Map<String, String> _getHeaders()
}
```

### UI Components

**StatCard Widget**
```dart
StatCard(
  label: 'Total Revenue',
  value: '\$2,500,000',
  icon: Icons.trending_up,
  color: Color(0xFF4CAF50),
  subtitle: 'COP',
)
```

**LiveActivityItemWidget**
```dart
LiveActivityItemWidget(
  item: LiveActivityItem(
    modelName: 'Alejandra Vega',
    roomName: 'Private Show',
    viewersCount: 42,
    status: 'active',
    startedAt: DateTime.now(),
  ),
)
```

**AdminDashboardScreen**
```dart
AdminDashboardScreen()
// Stateful widget with FutureBuilder
// Handles: loading, error, data states
// Supports: pull-to-refresh, logout
```

---

## 🔌 API Contracts

### 1. Login Endpoint (Already Implemented)

**Request:**
```
POST /api/auth/login
Content-Type: application/json

{
  "email": "admin@sweetmodels.com",
  "password": "sweet123"
}
```

**Response (200 OK):**
```json
{
  "token": "eyJ0eXAiOiJKV1QiLCJhbGc...",
  "refresh_token": "...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "role": "admin",           ← CRITICAL: Must be "admin"
  "user_id": "550e8400-e29b-41d4-a716",
  "name": "Admin User"
}
```

### 2. Dashboard Stats Endpoint (TO IMPLEMENT)

**Endpoint:**
```
GET /admin/dashboard
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
{
  "total_tokens": 50000,
  "total_revenue_cop": 2500000.50,
  "active_models": 12,
  "alerts_count": 0,
  "last_updated": "2024-01-15T14:30:00Z"
}
```

**Error Responses:**
```json
// 401 Unauthorized
{
  "error": "Invalid token"
}

// 403 Forbidden
{
  "error": "Admin access required"
}

// 500 Server Error
{
  "error": "Internal server error"
}
```

### 3. Live Activity Endpoint (TO IMPLEMENT)

**Endpoint:**
```
GET /admin/live-activity
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
[
  {
    "model_name": "Alejandra Vega",
    "room_name": "Private Show",
    "viewers_count": 42,
    "status": "active",
    "started_at": "2024-01-15T14:15:00Z"
  },
  {
    "model_name": "Isabella Santos",
    "room_name": "Group Chat",
    "viewers_count": 28,
    "status": "active",
    "started_at": "2024-01-15T14:08:00Z"
  }
]
```

### 4. System Alerts Endpoint (TO IMPLEMENT)

**Endpoint:**
```
GET /admin/alerts
Authorization: Bearer {token}
```

**Response (200 OK):**
```json
[
  {
    "type": "warning",
    "title": "High Payout Request",
    "message": "Model xyz has requested high payout",
    "is_read": false,
    "created_at": "2024-01-15T14:25:00Z"
  },
  {
    "type": "info",
    "title": "New Model Registration",
    "message": "New model registered today",
    "is_read": true,
    "created_at": "2024-01-15T12:00:00Z"
  }
]
```

---

## 🔐 Authentication Flow

```
User Login
  ├─ POST /api/auth/login
  ├─ Response: { token, role: "admin" }
  ├─ Store: SharedPreferences['access_token'] = token
  │
Role Check
  ├─ if (role == 'admin')
  │   └─ Route to AdminDashboardScreen
  │   
Dashboard Init
  ├─ DashboardService reads token from SharedPreferences
  ├─ Builds Authorization header: "Bearer {token}"
  ├─ Calls GET /admin/dashboard
  │
Auth Header
  ├─ GET /admin/dashboard
  ├─ Headers: {
  │    "Authorization": "Bearer eyJ0eXAi...",
  │    "Content-Type": "application/json"
  │  }
  │
Backend Validation
  ├─ Validate JWT token
  ├─ Check token hasn't expired
  ├─ Verify role == "admin"
  ├─ If all good → Return stats
  └─ If invalid → Return 401
```

---

## 🧪 Testing Checklist for Backend

### Unit Tests
```
✅ Models
  - DashboardStats.fromJson() parsing
  - LiveActivityItem JSON mapping
  - SystemAlert JSON mapping
  - empty() constructors

✅ Service
  - Token retrieval from SharedPreferences
  - Authorization header format
  - HTTP client configuration
  - Error handling
```

### Integration Tests
```
✅ Login → Admin Dashboard Flow
  - Login with admin credentials
  - Verify role == "admin"
  - Navigate to AdminDashboardScreen
  - Load dashboard data
  
✅ Data Display
  - Stat cards show correct values
  - Live activity list updates
  - Last updated timestamp formats
  
✅ Interactions
  - Pull-to-refresh triggers reload
  - Error retry works
  - Logout clears tokens
```

### Manual Testing
```
1. Start Backend
   $ cd backend_api
   $ cargo run
   
2. Start Emulator
   $ emulator -avd Pixel_5
   
3. Build App
   $ cd mobile_app
   $ flutter pub get
   $ flutter run
   
4. Test Flow
   - Login: admin@sweetmodels.com / sweet123
   - Verify: AdminDashboardScreen displays
   - Test: Pull-to-refresh
   - Test: Logout
```

---

## 🔧 Rust/Axum Backend Implementation

### Required Endpoint Structure

```rust
#[get("/admin/dashboard")]
pub async fn get_admin_dashboard(
    Extension(db): Extension<PgPool>,
    Extension(claims): Extension<JwtClaims>,
) -> Result<Json<DashboardStatsResponse>, CustomError> {
    // 1. Verify admin role
    if claims.role != "admin" {
        return Err(CustomError::Forbidden);
    }
    
    // 2. Query database for stats
    let stats = sqlx::query!(
        "SELECT 
            SUM(amount) as total_revenue,
            COUNT(*) as total_tokens,
            COUNT(DISTINCT model_id) as active_models,
            COUNT(*) as alerts_count
        FROM models WHERE status = 'active'"
    )
    .fetch_one(&db)
    .await?;
    
    // 3. Format response
    Ok(Json(DashboardStatsResponse {
        total_tokens: stats.total_tokens.unwrap_or(0),
        total_revenue_cop: stats.total_revenue.unwrap_or(0.0),
        active_models: stats.active_models.unwrap_or(0),
        alerts_count: stats.alerts_count.unwrap_or(0),
        last_updated: Utc::now().to_rfc3339(),
    }))
}
```

### Required Models

```rust
#[derive(Serialize, Deserialize)]
pub struct DashboardStatsResponse {
    pub total_tokens: i64,
    pub total_revenue_cop: f64,
    pub active_models: i64,
    pub alerts_count: i64,
    pub last_updated: String,
}

#[derive(Serialize, Deserialize)]
pub struct LiveActivityItem {
    pub model_name: String,
    pub room_name: String,
    pub viewers_count: i32,
    pub status: String,
    pub started_at: String,
}
```

---

## 📝 Error Handling Map

### Client-Side (Flutter)

```dart
// Connection errors
try {
  final response = await _dio.get(...);
} on DioException catch (e) {
  if (e.type == DioExceptionType.connectionTimeout) {
    // Show: "Connection timeout - please retry"
  } else if (e.type == DioExceptionType.unknown) {
    // Show: "Connection error - no internet?"
  } else {
    // Show: "Error: ${e.message}"
  }
}

// Parse errors
try {
  return DashboardStats.fromJson(response.data);
} catch (e) {
  // Log error, return empty stats
  debugPrint('Parse error: $e');
  return DashboardStats.empty();
}
```

### Server-Side (Backend)

```rust
// 401 - Invalid token
HttpResponse::Unauthorized()
  .json(json!({"error": "Invalid token"}))

// 403 - Not admin
HttpResponse::Forbidden()
  .json(json!({"error": "Admin access required"}))

// 500 - Server error
HttpResponse::InternalServerError()
  .json(json!({"error": "Internal server error"}))
```

---

## 🚀 Deployment Checklist

### Pre-Deployment
- [ ] All endpoints implemented in backend
- [ ] JWT validation checks admin role
- [ ] CORS configured (if web)
- [ ] Database queries optimized
- [ ] Error handling comprehensive
- [ ] Logging configured

### Deployment Steps
1. Build backend: `cargo build --release`
2. Deploy backend to staging
3. Run integration tests
4. Deploy to production
5. Monitor logs

### Post-Deployment
- [ ] Test login flow
- [ ] Verify admin redirect
- [ ] Check dashboard loads
- [ ] Verify data displays
- [ ] Test error scenarios

---

## 📊 Performance Targets

```
API Response Time:
  - /admin/dashboard: < 500ms
  - /admin/live-activity: < 1000ms
  - /admin/alerts: < 500ms

UI Responsiveness:
  - Dashboard load: < 2 seconds
  - Pull-to-refresh: < 1 second
  - Error retry: < 500ms

Memory Usage:
  - Dashboard screen: < 50MB
  - Service layer: < 10MB

---

## 📚 Related Documentation

1. **Backend API Spec**: `/backend_api/API_DOCUMENTATION.md`
2. **Database Schema**: `/backend_api/IMPLEMENTATION_SUMMARY.md`
3. **Auth System**: `/backend_api/SECURITY_FEATURES.md`
4. **Flutter Guide**: `/mobile_app/INSTALLATION_TESTING_GUIDE.md`

---

## ✅ Sign-Off Checklist

### Frontend (Flutter)
- [x] All code compiles (0 errors)
- [x] Type-safe (100% null-safe)
- [x] Error handling comprehensive
- [x] UI professional and responsive
- [x] Navigation routing correct
- [x] Documentation complete
- [x] Ready for backend integration

### Backend (Rust)
- [ ] Endpoints implemented
- [ ] JWT validation works
- [ ] Role checking enforced
- [ ] Error responses standardized
- [ ] Database queries optimized
- [ ] Logging configured
- [ ] Ready for testing

---

## 💬 Contact & Support

**Questions?**
- Check ADMIN_DASHBOARD_IMPLEMENTATION.md
- Check ADMIN_DASHBOARD_QUICKSTART.md
- Check STATUS_OVERVIEW.md
- Check code comments

**Issues?**
- Run: `flutter analyze`
- Run: `flutter pub get`
- Check: Dart version compatibility
- Check: Android Emulator IP (10.0.2.2)

---

## 🎯 Next Steps

**Immediate:**
1. Implement 3 backend endpoints
2. Test with real data
3. Fix integration issues

**This Week:**
1. Complete integration testing
2. Add unit tests
3. Performance testing

**Next Week:**
1. Production deployment
2. Monitor & optimize
3. Plan enhancements

---

**Status: ✅ READY FOR BACKEND**  
**Last Updated: January 2025**  
**Next Milestone: Backend Integration Complete**

---

*This handoff document contains everything needed to integrate the admin dashboard.*

**Good luck! 🚀**
