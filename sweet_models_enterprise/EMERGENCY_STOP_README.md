# Emergency Stop System - Sweet Models Enterprise

## Overview
The Emergency Stop system provides a global kill switch that allows Super Admins to immediately freeze the entire platform in case of critical bugs or security issues.

## Features

### 1. Global Freeze Endpoint
**Endpoint:** `POST /api/admin/emergency/freeze`

**Authentication:** Requires `SUPER_ADMIN` role (highest privilege level)

**Request Body:**
```json
{
  "active": true,
  "message": "Platform frozen due to payment processing bug"
}
```

**Response:**
- **200 OK:** Emergency status updated successfully
  ```json
  {
    "status": "Emergency stop activated",
    "active": true,
    "message": "Platform frozen due to payment processing bug"
  }
  ```
- **401 Unauthorized:** Missing or invalid authentication token
- **403 Forbidden:** User does not have SUPER_ADMIN role

### 2. Status Check Endpoint
**Endpoint:** `GET /api/admin/emergency/status`

**Authentication:** None required (public endpoint)

**Response:**
```json
{
  "active": false,
  "message": null
}
```

### 3. Global Middleware Protection

When emergency mode is **active**, all endpoints (except health and emergency management) return:

**Status:** `503 Service Unavailable`

**Response:**
```json
{
  "error": "System is in emergency maintenance mode",
  "message": "Platform frozen due to payment processing bug"
}
```

**Bypassed Endpoints:**
- `/health` - Always available for health checks
- `/api/admin/emergency/status` - Check emergency status
- `/api/admin/emergency/freeze` - Super Admin can deactivate
- OPTIONS requests - For CORS preflight

## State Persistence

Emergency status is persisted in **Redis** with key `emergency:status` to survive server restarts:

```rust
// Redis key structure
"emergency:status" -> EmergencyStatus {
    active: bool,
    message: Option<String>,
}
```

## Use Cases

### Scenario 1: Critical Payment Bug Detected
```bash
# Freeze the platform immediately
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Authorization: Bearer <SUPER_ADMIN_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"active": true, "message": "Payment processor charging double - fixing now"}'

# Fix the bug...

# Unfreeze the platform
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Authorization: Bearer <SUPER_ADMIN_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"active": false, "message": null}'
```

### Scenario 2: Security Breach
```bash
# Immediately stop all operations
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Authorization: Bearer <SUPER_ADMIN_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"active": true, "message": "Security incident - investigating"}'
```

### Scenario 3: Check If System Is Frozen (Mobile App)
```dart
// Flutter mobile app code
final response = await http.get(
  Uri.parse('https://api.sweetmodels.com/api/admin/emergency/status'),
);

if (response.statusCode == 200) {
  final status = json.decode(response.body);
  if (status['active']) {
    // Show maintenance screen to users
    showMaintenanceDialog(status['message']);
  }
}
```

## Implementation Details

### File Structure
```
backend_api/src/
├── emergency.rs          # Emergency stop module
├── lib.rs                # Exports emergency module
└── main.rs               # Routes + middleware integration
```

### Code Flow

1. **Request arrives** → Axum router
2. **Middleware checks** → `enforce_emergency_stop`
3. **If emergency active** → Return 503 (unless bypassed endpoint)
4. **If emergency inactive** → Continue to handler
5. **Handler executes** → Normal business logic

### Middleware Implementation
```rust
pub async fn enforce_emergency_stop<B>(
    State(state): State<AppState>,
    req: Request<B>,
    next: Next<B>,
) -> Response {
    let path = req.uri().path();
    
    // Bypass certain endpoints
    if path == "/health" || path.starts_with("/api/admin/emergency") {
        return next.run(req).await;
    }

    // Check emergency status
    match get_status(&state.redis).await {
        Ok(status) if status.active => {
            // Return 503 maintenance mode
            let message = status.message.unwrap_or_else(|| 
                "System is in emergency maintenance mode".to_string()
            );
            (StatusCode::SERVICE_UNAVAILABLE, Json(json!({
                "error": "System is in emergency maintenance mode",
                "message": message
            }))).into_response()
        }
        _ => next.run(req).await,
    }
}
```

## Testing

### Manual Testing with cURL

```bash
# 1. Check current status (should be inactive initially)
curl http://localhost:3000/api/admin/emergency/status

# 2. Try to freeze without auth (should fail 401)
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Content-Type: application/json" \
  -d '{"active": true, "message": "Test freeze"}'

# 3. Activate emergency with Super Admin token
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Authorization: Bearer <SUPER_ADMIN_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"active": true, "message": "Testing emergency mode"}'

# 4. Try to access regular endpoint (should get 503)
curl http://localhost:3000/api/finance/balance

# 5. Health check still works
curl http://localhost:3000/health

# 6. Deactivate emergency
curl -X POST http://localhost:3000/api/admin/emergency/freeze \
  -H "Authorization: Bearer <SUPER_ADMIN_JWT>" \
  -H "Content-Type: application/json" \
  -d '{"active": false}'
```

### Automated Testing Script

Run the PowerShell script:
```powershell
.\test_emergency.ps1
```

## Security Considerations

1. **Super Admin Only:** Only users with `SUPER_ADMIN` role can activate/deactivate
2. **JWT Validation:** Requires valid, non-expired JWT token
3. **Audit Logging:** All freeze/unfreeze actions should be logged (TODO)
4. **Redis Persistence:** State survives server crashes/restarts
5. **Public Status:** Anyone can check if system is frozen (transparency)

## Monitoring & Alerts

### Recommended Alerts
- **Emergency Activated:** Send Slack/email to all admins immediately
- **Emergency Active > 1 hour:** Escalate to CTO
- **Frequent Activations:** Alert if activated more than 3x in 24 hours

### Metrics to Track
- Number of emergency activations per day/week
- Average duration of emergency mode
- Endpoints blocked during emergency
- Failed access attempts during emergency

## Future Enhancements

- [ ] Audit log for all emergency actions
- [ ] Configurable bypass list (e.g., allow specific user IDs)
- [ ] Auto-deactivate after X minutes
- [ ] Webhook notifications when emergency toggled
- [ ] Admin dashboard showing emergency history
- [ ] Gradual rollout (freeze only certain features)

## Contact

For emergency issues, contact:
- **CTO:** [Emergency Contact]
- **DevOps Lead:** [Emergency Contact]
- **On-Call Engineer:** [PagerDuty/Opsgenie]
