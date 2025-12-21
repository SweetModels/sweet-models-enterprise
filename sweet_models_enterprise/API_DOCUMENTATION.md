# 📚 Sweet Models Enterprise - API REST Documentation

## Base URL
```
Production: https://api.sweetmodels.com
Staging:    https://staging-api.sweetmodels.com
Development: http://localhost:3000
```

## Authentication

### JWT Bearer Token
```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Token Refresh
```
POST /api/auth/refresh
Content-Type: application/json

Response:
{
  "token": "new_jwt_token",
  "expires_in": 86400
}
```

---

## 🔐 Authentication Endpoints

### 1. User Registration

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!@#",
  "name": "John Doe",
  "username": "johndoe",
  "profile_picture_url": "https://example.com/pic.jpg"
}

Response (201 Created):
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "username": "johndoe",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 86400,
  "created_at": "2025-12-09T14:32:00Z"
}

Error (400 Bad Request):
{
  "error": "EMAIL_ALREADY_EXISTS",
  "message": "Email already registered"
}
```

### 2. User Login

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "SecurePassword123!@#"
}

Response (200 OK):
{
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "username": "johndoe",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 86400,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "email": "user@example.com",
    "name": "John Doe",
    "username": "johndoe",
    "profile_picture_url": "https://example.com/pic.jpg",
    "followers_count": 150,
    "following_count": 200
  }
}

Error (401 Unauthorized):
{
  "error": "INVALID_CREDENTIALS",
  "message": "Invalid email or password"
}
```

### 3. Web3 Authentication (MetaMask)

```http
GET /api/auth/web3/nonce

Response (200 OK):
{
  "nonce": "random_secure_nonce_12345",
  "expires_in": 300
}

---

POST /api/auth/web3/login
Content-Type: application/json

{
  "address": "0x742d35Cc6634C0532925a3b844Bc9e7595f42bE",
  "signature": "0x...",
  "message": "Sign this message to verify your wallet..."
}

Response (200 OK):
{
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "expires_in": 86400,
  "user": {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "wallet_address": "0x742d35Cc6634C0532925a3b844Bc9e7595f42bE",
    "created_at": "2025-12-09T14:32:00Z"
  }
}
```

### 4. Logout

```http
POST /api/auth/logout
Authorization: Bearer token
Content-Type: application/json

Response (200 OK):
{
  "message": "Logged out successfully"
}
```

---

## 👤 User Endpoints

### 1. Get Current User Profile

```http
GET /api/users/profile
Authorization: Bearer token

Response (200 OK):
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "email": "user@example.com",
  "name": "John Doe",
  "username": "johndoe",
  "bio": "Professional model and photographer",
  "profile_picture_url": "https://...",
  "banner_picture_url": "https://...",
  "followers_count": 150,
  "following_count": 200,
  "posts_count": 42,
  "verified": true,
  "created_at": "2025-12-09T14:32:00Z",
  "updated_at": "2025-12-09T15:45:00Z"
}
```

### 2. Update User Profile

```http
PUT /api/users/profile
Authorization: Bearer token
Content-Type: application/json

{
  "name": "John Doe",
  "bio": "Updated bio",
  "website": "https://example.com",
  "location": "New York, NY"
}

Response (200 OK):
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "name": "John Doe",
  "bio": "Updated bio",
  "website": "https://example.com",
  "location": "New York, NY",
  "updated_at": "2025-12-09T16:00:00Z"
}
```

### 3. Get User Profile by Username

```http
GET /api/users/{username}

Response (200 OK):
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "username": "johndoe",
  "name": "John Doe",
  "bio": "Professional model",
  "verified": true,
  "followers_count": 150,
  "following_count": 200,
  "posts_count": 42,
  "is_following": false,
  "is_follower": true
}
```

### 4. Follow User

```http
POST /api/users/{user_id}/follow
Authorization: Bearer token

Response (200 OK):
{
  "following": true,
  "followers_count": 151
}
```

### 5. Unfollow User

```http
DELETE /api/users/{user_id}/follow
Authorization: Bearer token

Response (200 OK):
{
  "following": false,
  "followers_count": 150
}
```

### 6. Get User Followers

```http
GET /api/users/{user_id}/followers?limit=20&offset=0

Response (200 OK):
{
  "total": 150,
  "items": [
    {
      "id": "...",
      "username": "follower1",
      "name": "Follower One",
      "profile_picture_url": "..."
    },
    // ... more followers
  ]
}
```

---

## 📱 Posts Endpoints

### 1. Create Post

```http
POST /api/posts
Authorization: Bearer token
Content-Type: application/json

{
  "content": "Beautiful sunset photo 🌅",
  "media": ["https://cdn.example.com/image1.jpg"],
  "visibility": "public",
  "tags": ["photography", "nature"]
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440001",
  "user_id": "550e8400-e29b-41d4-a716-446655440000",
  "content": "Beautiful sunset photo 🌅",
  "media": ["https://cdn.example.com/image1.jpg"],
  "likes_count": 0,
  "comments_count": 0,
  "shares_count": 0,
  "visibility": "public",
  "created_at": "2025-12-09T16:15:00Z"
}
```

### 2. Get Feed

```http
GET /api/posts/feed?limit=20&offset=0
Authorization: Bearer token

Response (200 OK):
{
  "total": 156,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440001",
      "user": {
        "id": "...",
        "username": "johndoe",
        "name": "John Doe",
        "profile_picture_url": "..."
      },
      "content": "Beautiful sunset photo 🌅",
      "media": ["..."],
      "likes_count": 42,
      "comments_count": 8,
      "liked": false,
      "created_at": "2025-12-09T16:15:00Z"
    },
    // ... more posts
  ]
}
```

### 3. Like Post

```http
POST /api/posts/{post_id}/like
Authorization: Bearer token

Response (200 OK):
{
  "liked": true,
  "likes_count": 43
}
```

### 4. Unlike Post

```http
DELETE /api/posts/{post_id}/like
Authorization: Bearer token

Response (200 OK):
{
  "liked": false,
  "likes_count": 42
}
```

### 5. Add Comment

```http
POST /api/posts/{post_id}/comments
Authorization: Bearer token
Content-Type: application/json

{
  "content": "Amazing shot! 📸"
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440002",
  "post_id": "550e8400-e29b-41d4-a716-446655440001",
  "user": {
    "id": "...",
    "username": "johndoe",
    "name": "John Doe"
  },
  "content": "Amazing shot! 📸",
  "likes_count": 0,
  "created_at": "2025-12-09T16:20:00Z"
}
```

### 6. Get Post Comments

```http
GET /api/posts/{post_id}/comments?limit=20&offset=0

Response (200 OK):
{
  "total": 8,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440002",
      "user": {...},
      "content": "Amazing shot! 📸",
      "likes_count": 5,
      "liked": false,
      "created_at": "2025-12-09T16:20:00Z"
    },
    // ... more comments
  ]
}
```

---

## 💬 Chat Endpoints

### 1. Send Message

```http
POST /api/chat/messages
Authorization: Bearer token
Content-Type: application/json

{
  "recipient_id": "550e8400-e29b-41d4-a716-446655440003",
  "content": "Hey, how are you?",
  "media": []
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440004",
  "sender_id": "550e8400-e29b-41d4-a716-446655440000",
  "recipient_id": "550e8400-e29b-41d4-a716-446655440003",
  "content": "Hey, how are you?",
  "read": false,
  "created_at": "2025-12-09T16:30:00Z"
}
```

### 2. Get Conversation

```http
GET /api/chat/conversations/{user_id}?limit=50&offset=0
Authorization: Bearer token

Response (200 OK):
{
  "total": 120,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440004",
      "sender": {...},
      "recipient": {...},
      "content": "Hey, how are you?",
      "read": true,
      "created_at": "2025-12-09T16:30:00Z"
    },
    // ... more messages
  ]
}
```

### 3. Mark Messages as Read

```http
PUT /api/chat/messages/{message_id}/read
Authorization: Bearer token

Response (200 OK):
{
  "read": true
}
```

### 4. WebSocket Chat Connection

```javascript
// Connect to WebSocket
const ws = new WebSocket('ws://localhost:3000/api/chat/ws?user_id=550e8400-e29b-41d4-a716-446655440000&token=jwt_token');

// Listen for messages
ws.onmessage = (event) => {
  const message = JSON.parse(event.data);
  console.log('New message:', message);
};

// Send message via WebSocket
ws.send(JSON.stringify({
  type: 'message',
  content: 'Hello!',
  recipient_id: '550e8400-e29b-41d4-a716-446655440003'
}));

// Typing indicator
ws.send(JSON.stringify({
  type: 'typing',
  recipient_id: '550e8400-e29b-41d4-a716-446655440003'
}));
```

---

## 💳 Payments Endpoints

### 1. Create Payment Intent

```http
POST /api/payments/intent
Authorization: Bearer token
Content-Type: application/json

{
  "amount": 9999,  // cents
  "currency": "usd",
  "description": "Model portfolio package"
}

Response (200 OK):
{
  "client_secret": "pi_test_...",
  "amount": 9999,
  "currency": "usd",
  "status": "requires_payment_method"
}
```

### 2. Get Payment Methods

```http
GET /api/payments/methods
Authorization: Bearer token

Response (200 OK):
{
  "items": [
    {
      "id": "pm_test_...",
      "type": "card",
      "card": {
        "brand": "visa",
        "last4": "4242",
        "exp_month": 12,
        "exp_year": 2026
      },
      "is_default": true
    },
    // ... more methods
  ]
}
```

### 3. Add Payment Method

```http
POST /api/payments/methods
Authorization: Bearer token
Content-Type: application/json

{
  "payment_method_id": "pm_test_...",
  "set_as_default": true
}

Response (201 Created):
{
  "id": "pm_test_...",
  "type": "card",
  "is_default": true,
  "created_at": "2025-12-09T16:45:00Z"
}
```

### 4. Get Transactions

```http
GET /api/payments/transactions?limit=20&offset=0
Authorization: Bearer token

Response (200 OK):
{
  "total": 15,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440005",
      "amount": 9999,
      "currency": "usd",
      "status": "succeeded",
      "description": "Model portfolio package",
      "created_at": "2025-12-09T14:20:00Z"
    },
    // ... more transactions
  ]
}
```

---

## 🔔 Notifications Endpoints

### 1. Register Device Token

```http
POST /api/notifications/devices
Authorization: Bearer token
Content-Type: application/json

{
  "fcm_token": "device_fcm_token_from_firebase",
  "platform": "android|ios|web",
  "device_name": "iPhone 13"
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440006",
  "platform": "ios",
  "created_at": "2025-12-09T16:50:00Z"
}
```

### 2. Get Notifications

```http
GET /api/notifications?limit=20&offset=0&unread_only=false
Authorization: Bearer token

Response (200 OK):
{
  "total": 25,
  "unread": 3,
  "items": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440007",
      "type": "like",
      "title": "John liked your post",
      "body": "Beautiful sunset photo 🌅",
      "actor": {...},
      "read": false,
      "created_at": "2025-12-09T17:00:00Z"
    },
    // ... more notifications
  ]
}
```

### 3. Mark Notification as Read

```http
PUT /api/notifications/{notification_id}/read
Authorization: Bearer token

Response (200 OK):
{
  "read": true
}
```

### 4. Mark All as Read

```http
PUT /api/notifications/read-all
Authorization: Bearer token

Response (200 OK):
{
  "marked_count": 3
}
```

---

## 📊 Analytics Endpoints

### 1. Get User Analytics

```http
GET /api/analytics/user?start_date=2025-12-01&end_date=2025-12-09
Authorization: Bearer token

Response (200 OK):
{
  "period": {
    "start": "2025-12-01",
    "end": "2025-12-09"
  },
  "followers_gained": 12,
  "posts_published": 8,
  "total_likes": 156,
  "total_comments": 23,
  "total_shares": 5,
  "engagement_rate": 15.3,
  "top_post": {...}
}
```

### 2. Get Financial Analytics

```http
GET /api/analytics/financial?period=monthly
Authorization: Bearer token

Response (200 OK):
{
  "revenue": 29997,
  "transactions": 3,
  "average_transaction": 9999,
  "currency": "usd",
  "chart_data": [
    {
      "date": "2025-12-01",
      "amount": 9999
    },
    // ... more data
  ]
}
```

---

## 🎥 Video Calling Endpoints (WebRTC)

### 1. Initiate Call

```http
POST /api/calls/initiate
Authorization: Bearer token
Content-Type: application/json

{
  "recipient_id": "550e8400-e29b-41d4-a716-446655440003"
}

Response (200 OK):
{
  "call_id": "550e8400-e29b-41d4-a716-446655440008",
  "recipient_id": "550e8400-e29b-41d4-a716-446655440003",
  "status": "ringing",
  "created_at": "2025-12-09T17:15:00Z"
}
```

### 2. Get Call Status

```http
GET /api/calls/{call_id}
Authorization: Bearer token

Response (200 OK):
{
  "id": "550e8400-e29b-41d4-a716-446655440008",
  "caller": {...},
  "recipient": {...},
  "status": "active|ringing|ended",
  "duration": 120,
  "created_at": "2025-12-09T17:15:00Z"
}
```

### 3. WebRTC Signal Exchange

```http
POST /api/calls/{call_id}/signal
Authorization: Bearer token
Content-Type: application/json

{
  "type": "offer|answer|candidate",
  "payload": {
    "sdp": "...",  // for offer/answer
    "candidate": "...",  // for ICE candidate
    "sdpMid": "0",
    "sdpMLineIndex": 0
  }
}

Response (200 OK):
{
  "received": true
}
```

---

## 📤 Upload Endpoints

### 1. Upload Image

```http
POST /api/uploads/images
Authorization: Bearer token
Content-Type: multipart/form-data

{
  "file": <binary image data>
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440009",
  "url": "https://cdn.example.com/images/abc123.jpg",
  "size": 2048576,
  "mime_type": "image/jpeg",
  "created_at": "2025-12-09T17:30:00Z"
}
```

### 2. Upload Video

```http
POST /api/uploads/videos
Authorization: Bearer token
Content-Type: multipart/form-data

{
  "file": <binary video data>
}

Response (201 Created):
{
  "id": "550e8400-e29b-41d4-a716-446655440010",
  "url": "https://cdn.example.com/videos/xyz789.mp4",
  "duration": 45.5,
  "size": 104857600,
  "mime_type": "video/mp4",
  "created_at": "2025-12-09T17:35:00Z"
}
```

---

## 🐛 Error Handling

### Standard Error Response

```json
{
  "error": "ERROR_CODE",
  "message": "Human readable error message",
  "status": 400,
  "timestamp": "2025-12-09T17:45:00Z",
  "path": "/api/posts",
  "details": {
    "field": "content",
    "issue": "Field is required"
  }
}
```

### Common Error Codes

| Code | Status | Description |
|------|--------|-------------|
| `INVALID_REQUEST` | 400 | Request validation failed |
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Access denied |
| `NOT_FOUND` | 404 | Resource not found |
| `CONFLICT` | 409 | Resource already exists |
| `RATE_LIMITED` | 429 | Too many requests |
| `INTERNAL_ERROR` | 500 | Server error |

---

## 📝 Rate Limiting

- **Limit**: 100 requests per minute per API key
- **Header**: `X-RateLimit-Remaining`
- **Reset**: `X-RateLimit-Reset`

```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 87
X-RateLimit-Reset: 1702190400
```

---

## 🔒 Security Best Practices

1. Always use HTTPS in production
2. Store JWT tokens securely
3. Implement token refresh before expiration
4. Use CORS properly
5. Validate all inputs
6. Implement rate limiting
7. Use secure password requirements
8. Enable 2FA for admin accounts

---

**Last Updated**: December 9, 2025  
**Version**: 1.0.0  
**Status**: Production Ready
