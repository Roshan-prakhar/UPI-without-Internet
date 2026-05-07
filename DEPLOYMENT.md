# UPI Offline Mesh - Deployment Guide

## 🚀 Quick Start

### Prerequisites
- **Java 17+** installed and on PATH
- **Node.js** (for frontend server) or any static file server
- **Maven** (included via wrapper)

### Option 1: Backend + Frontend (Full Integration)

#### 1. Start Spring Boot Backend
```bash
cd UPI-without-internet
.\mvnw.cmd spring-boot:run
```
Backend will start on `http://localhost:8080`

#### 2. Start Frontend Server
```bash
# Using Node.js serve (recommended)
npx serve -s . -l 3000

# Or using Python
python -m http.server 3000

# Or using any static file server
```
Frontend will be available at `http://localhost:3000`

#### 3. Access the Demo
- **Integrated Demo**: `http://localhost:3000/index.html` (connects to backend)
- **Standalone Demo**: `http://localhost:3000/upi-mesh-demo.html` (frontend-only simulation)

---

## 📋 Available Demos

### 1. **Integrated Demo** (`index.html`)
- **Full Backend Integration**: Connects to Spring Boot APIs
- **Real Encryption**: Uses actual hybrid RSA+AES encryption
- **Live Data**: Real-time account balances and transactions
- **Production Features**: Idempotency, caching, persistence

### 2. **Standalone Demo** (`upi-mesh-demo.html`)
- **Frontend Only**: Complete simulation without backend
- **Fast Testing**: No server setup required
- **Educational**: Perfect for understanding mesh concepts
- **Portable**: Works offline, great for presentations

---

## 🛠 Architecture Overview

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Frontend      │    │   Spring Boot   │    │   H2 Database   │
│   (Browser)     │◄──►│   Backend       │◄──►│   (In-Memory)   │
│   Port 3000     │    │   Port 8080     │    │   Auto-created  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Key Components

#### Backend (Spring Boot)
- **HybridCryptoService**: RSA-OAEP + AES-256-GCM encryption
- **IdempotencyService**: Prevents duplicate transactions
- **SettlementService**: Atomic balance transfers
- **MeshSimulatorService**: Device gossip simulation
- **BridgeIngestionService**: Final settlement processing

#### Frontend (HTML/JS)
- **Device Management**: Track mesh device states
- **Payment Composition**: Create and validate transactions
- **Gossip Simulation**: Packet hopping visualization
- **Activity Logging**: Real-time event tracking
- **Ledger Display**: Transaction history and status

---

## 🔧 Configuration

### Backend Configuration
Edit `src/main/resources/application.properties`:

```properties
# Server port
server.port=8080

# Database (H2 in-memory)
spring.datasource.url=jdbc:h2:mem:upimesh
spring.datasource.driverClassName=org.h2.Driver
spring.datasource.username=sa
spring.datasource.password=

# JPA settings
spring.jpa.database-platform=org.hibernate.dialect.H2Dialect
spring.jpa.hibernate.ddl-auto=create-drop
spring.h2.console.enabled=true

# Demo settings
demo.packet.ttl=5
demo.cache.ttl.hours=24
```

### Frontend Configuration
Edit `index.html` API base URL:

```javascript
const API_BASE = 'http://localhost:8080/api';
```

---

## 📱 Demo Flow Guide

### Step 1: Compose Payment
1. Select sender (e.g., alice@demo)
2. Select receiver (e.g., bob@demo)
3. Enter amount (e.g., 500)
4. Enter PIN (demo PIN: 1234)
5. Click "📨 Inject into Mesh"

### Step 2: Gossip Round
1. Click "🔄 Run Gossip Round"
2. Watch packets hop between devices
3. Continue until bridge has packets
4. Monitor hop count in activity log

### Step 3: Bridge Upload
1. Click "🌉 Bridges Upload to Backend"
2. Bridge processes encrypted packets
3. Idempotency prevents duplicates
4. Balances update in real-time

### Step 4: Reset (Optional)
1. Click "🗑️ Reset Mesh + Cache"
2. Clear all device packets
3. Reset account balances
4. Empty transaction cache

---

## 🔍 Testing Guide

### Unit Tests
```bash
# Run all tests
.\mvnw.cmd test

# Run specific test
.\mvnw.cmd test -Dtest=IdempotencyConcurrencyTest
```

### Integration Tests
1. **Payment Flow**: Test complete inject → gossip → settlement
2. **Idempotency**: Verify duplicate prevention
3. **Encryption**: Test packet encryption/decryption
4. **Concurrent**: Multiple bridges uploading simultaneously

### Manual Testing Checklist
- [ ] Payment injection creates packet in phone-alice
- [ ] Gossip rounds move packets between devices
- [ ] Bridge upload settles transactions correctly
- [ ] Idempotency prevents duplicate settlements
- [ ] Reset clears all state properly
- [ ] Activity log shows all events
- [ ] Transaction ledger updates correctly

---

## 🚀 Production Deployment

### Backend Deployment

```bash
# Build JAR (includes prod profile resources)
.\mvnw.cmd clean package

# Run production JAR with prod profile
java -jar target/upi-offline-mesh-0.0.1-SNAPSHOT.jar \
  --spring.profiles.active=prod
```

### Environment Variables
```bash
export SERVER_PORT=8080
export DB_URL=jdbc:postgresql://localhost/upimesh
export DB_USER=upimesh
export DB_PASSWORD=secure_password
export LOG_FILE=/var/log/upimesh/application.log
export IDEMPOTENCY_TTL_SECONDS=86400
export PACKET_MAX_AGE_SECONDS=86400
export RSA_KEY_PATH=/path/to/rsa/private.key
```

### Production Changes Required
1. **Database**: Replace H2 with PostgreSQL/MySQL
2. **RSA Keys**: Use HSM or secure key storage
3. **Redis**: Replace in-memory cache with Redis
4. **Authentication**: Add bridge node certificates
5. **Monitoring**: Add structured logging and metrics
6. **Rate Limiting**: Implement per-bridge rate limits

---

### Frontend Packaging & Hosting

1. **Build Artifact**: The frontend is static HTML/JS. Copy `index.html`, `upi-mesh-demo.html`, `enhanced-dashboard.html`, and the `/assets` folder (if added) into your web root.
2. **API Endpoint**: Update `const API_BASE` in `index.html` to the deployed backend URL (e.g., `https://api.example.com/api`).
3. **Static Hosting Options**:
   - Nginx/Apache serving `/var/www/upimesh`
   - S3/CloudFront or Azure Static Web Apps for CDN-backed hosting
   - Docker container based on `nginx:alpine` with files copied to `/usr/share/nginx/html`
4. **Cache Policy**: Enable gzip/brotli and set `Cache-Control: max-age=300` for HTML (short) and `max-age=86400` for JS/CSS.

Example Nginx snippet:

```nginx
server {
    listen 80;
    server_name mesh.example.com;

    root /var/www/upimesh;
    index index.html;

    location /api/ {
        proxy_pass https://api.example.com/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
```

---

### Container Deployment (Docker / Render)

#### Build & test locally

```bash
# Build multi-stage image (uses Dockerfile)
docker build -t upi-mesh-backend:latest .

# Run locally; Render injects PORT so mirror that behaviour
docker run --rm -e PORT=8080 -p 8080:8080 upi-mesh-backend:latest
```

#### Deploy on Render

1. Push the repo (with `Dockerfile` + `.dockerignore`) to GitHub.
2. In Render dashboard → **New** → **Web Service** → pick the repo.
3. Environment: **Docker** (Render will run the `Dockerfile`).
4. Set Environment Variables:
   - `SPRING_PROFILES_ACTIVE=prod` *(already defaulted in image but can override)*
   - `PORT=8080` *(Render injects automatically; Spring reads `PORT` → `server.port`)*
   - `DB_URL`, `DB_USER`, `DB_PASSWORD`, `LOG_FILE`, `IDEMPOTENCY_TTL_SECONDS`, etc., as needed.
5. Deploy. Render builds the image, runs `java -jar app.jar`, and exposes the service at the provided URL.

> **Note:** If you continue using the in-memory H2 database for demos, you can omit the DB vars. For production, point `DB_URL` at Render’s managed PostgreSQL instance and seed credentials accordingly.

---

## 🔒 Security Considerations

### Encryption
- **RSA-2048**: Server private key for packet encryption
- **AES-256-GCM**: Symmetric encryption for payload
- **Hybrid Pattern**: RSA encrypts AES key, AES encrypts data

### Idempotency
- **SHA-256 Hash**: Unique identifier per ciphertext
- **Atomic Operations**: Compare-and-set prevents duplicates
- **TTL Protection**: 24-hour expiration for replay protection

### Network Security
- **HTTPS Required**: All bridge communications encrypted
- **Certificate Validation**: Mutual TLS for bridge nodes
- **Rate Limiting**: Prevent DoS attacks on endpoints

---

## 🐛 Troubleshooting

### Common Issues

#### Backend Won't Start
```bash
# Check Java version
java -version

# Clean and rebuild
.\mvnw.cmd clean
.\mvnw.cmd spring-boot:run
```

#### Frontend Can't Connect
```bash
# Verify backend is running
curl http://localhost:8080/api/accounts

# Check CORS settings
# Add @CrossOrigin annotation to controllers
```

#### Port Conflicts
```bash
# Change backend port
server.port=8081

# Change frontend port
npx serve -s . -l 3001
```

#### Database Issues
```bash
# Access H2 console
http://localhost:8080/h2-console

# JDBC URL: jdbc:h2:mem:upimesh
# Username: sa
# Password: (empty)
```

---

## 📊 Monitoring & Logging

### Application Logs
```bash
# View live logs
tail -f logs/upimesh.log

# Search for transactions
grep "SETTLED" logs/upimesh.log
```

### Key Metrics to Monitor
- **Transaction Success Rate**: Target >95%
- **Average Settlement Time**: Target <5 seconds
- **Idempotency Hit Rate**: Duplicate prevention effectiveness
- **Packet Loss Rate**: Mesh network reliability
- **Bridge Upload Latency**: Network performance

### Health Endpoints
```bash
# Application health
GET /actuator/health

# Metrics (if enabled)
GET /actuator/metrics

# Database status
GET /actuator/db
```

---

## 📚 API Reference

### Core Endpoints

| Method | Path | Description |
|--------|------|-------------|
| GET | `/api/server-key` | Get RSA public key |
| GET | `/api/accounts` | List all accounts |
| GET | `/api/transactions` | Recent transactions |
| GET | `/api/mesh/state` | Device states |
| POST | `/api/demo/send` | Create payment packet |
| POST | `/api/mesh/gossip` | Run gossip round |
| POST | `/api/mesh/flush` | Bridge upload |
| POST | `/api/mesh/reset` | Reset mesh state |

### Request/Response Examples

#### Create Payment
```json
POST /api/demo/send
{
  "sender": "alice@demo",
  "receiver": "bob@demo", 
  "amount": 500,
  "pin": "1234"
}
```

#### Bridge Upload Response
```json
{
  "outcome": "SETTLED",
  "packetHash": "a3f8c9...",
  "reason": null,
  "transactionId": 42
}
```

---

## 🎯 Performance Optimization

### Backend Optimizations
1. **Connection Pooling**: Configure database connections
2. **Caching**: Redis for idempotency cache
3. **Async Processing**: Non-blocking bridge uploads
4. **Batch Operations**: Bulk transaction processing

### Frontend Optimizations
1. **Lazy Loading**: Load transaction history on demand
2. **Debouncing**: Throttle UI updates
3. **WebSockets**: Real-time updates (optional)
4. **Service Worker**: Offline capability

---

## 📞 Support

### Getting Help
1. **README.md**: Project overview and concepts
2. **Code Comments**: Detailed implementation notes
3. **Test Cases**: Usage examples and edge cases
4. **Logs**: Detailed error messages and stack traces

### Contributing
1. Fork the repository
2. Create feature branch
3. Add tests for new functionality
4. Submit pull request with description

---

## 📄 License

Demo code, no license. Use it however you want for learning and development.

---

**🎉 Happy Mesh Networking!**
