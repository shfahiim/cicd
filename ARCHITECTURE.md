# Architecture Overview

This document explains the microservices architecture and how services communicate with each other.

## System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         Client/User                          │
└──────────────────┬──────────────────────────────────────────┘
                   │
                   │ HTTP Requests
                   │
┌──────────────────▼──────────────────────────────────────────┐
│                      Load Balancer                           │
│                    (Future Enhancement)                      │
└──────┬──────────────────┬──────────────────┬────────────────┘
       │                  │                  │
       │                  │                  │
┌──────▼────────┐  ┌──────▼────────┐  ┌─────▼──────────┐
│ User Service  │  │Product Service│  │ Order Service   │
│   Port 3001   │  │  Port 3003    │  │   Port 3002     │
└───────┬───────┘  └───────┬───────┘  └────────┬────────┘
        │                  │                    │
        │                  │         ┌──────────┴─────────┐
        │                  │         │                    │
        │                  │    Inter-Service Communication
        │                  │         │                    │
        └──────────────────┴─────────┴────────────────────┘
                           │
                    ┌──────▼──────┐
                    │   MongoDB   │
                    │  Port 27017 │
                    └─────────────┘
```

## Services Description

### 1. User Service (Port 3001)
**Responsibility:** Manages user data and authentication

**Endpoints:**
- `GET /users` - Retrieve all users
- `GET /users/:id` - Get specific user
- `POST /users` - Create new user
- `PUT /users/:id` - Update user
- `DELETE /users/:id` - Delete user

**Database Schema:**
```javascript
{
  _id: ObjectId,
  name: String,
  email: String (unique),
  createdAt: Date
}
```

### 2. Product Service (Port 3003)
**Responsibility:** Manages product catalog and inventory

**Endpoints:**
- `GET /products` - Retrieve all products
- `GET /products/:id` - Get specific product
- `POST /products` - Create new product
- `PUT /products/:id` - Update product
- `PATCH /products/:id/stock` - Update stock (internal use)
- `DELETE /products/:id` - Delete product

**Database Schema:**
```javascript
{
  _id: ObjectId,
  name: String,
  price: Number,
  stock: Number,
  description: String,
  createdAt: Date
}
```

### 3. Order Service (Port 3002)
**Responsibility:** Manages orders and orchestrates inter-service communication

**Endpoints:**
- `GET /orders` - Retrieve all orders
- `GET /orders/:id` - Get specific order
- `GET /orders/user/:userId` - Get orders by user
- `POST /orders` - Create new order
- `PATCH /orders/:id/status` - Update order status
- `DELETE /orders/:id` - Delete order

**Database Schema:**
```javascript
{
  _id: ObjectId,
  userId: String,
  productId: String,
  quantity: Number,
  totalPrice: Number,
  status: String, // pending, confirmed, shipped, delivered, cancelled
  userDetails: Object, // Cached user info
  productDetails: Object, // Cached product info
  createdAt: Date
}
```

## Inter-Service Communication

### Order Creation Flow

When a client creates an order, the following happens:

```
1. Client sends POST /orders request to Order Service
   ├─ Request: { userId, productId, quantity }
   │
2. Order Service validates user
   ├─ HTTP GET → User Service (/users/:id)
   ├─ If user not found → Return 400 error
   │
3. Order Service validates product and stock
   ├─ HTTP GET → Product Service (/products/:id)
   ├─ Check if stock >= quantity
   ├─ If insufficient → Return 400 error
   │
4. Order Service calculates total price
   ├─ totalPrice = product.price * quantity
   │
5. Order Service creates order in database
   ├─ Store order with user and product details
   │
6. Order Service updates product stock
   ├─ HTTP PATCH → Product Service (/products/:id/stock)
   ├─ Deduct quantity from stock
   ├─ If update fails → Rollback: Delete order
   │
7. Return success response to client
   └─ Response: { order details with embedded user & product info }
```

### Communication Protocol

All inter-service communication uses:
- **Protocol:** HTTP/REST
- **Format:** JSON
- **Authentication:** None (future enhancement: service tokens)
- **Error Handling:** Try-catch with rollback mechanism

## Data Flow Example

### Creating an Order

**1. Client Request:**
```json
POST http://localhost:3002/orders
{
  "userId": "65abc123...",
  "productId": "65def456...",
  "quantity": 2
}
```

**2. Order Service → User Service:**
```json
GET http://user-service:3001/users/65abc123...

Response:
{
  "success": true,
  "data": {
    "_id": "65abc123...",
    "name": "John Doe",
    "email": "john@example.com"
  }
}
```

**3. Order Service → Product Service:**
```json
GET http://product-service:3003/products/65def456...

Response:
{
  "success": true,
  "data": {
    "_id": "65def456...",
    "name": "Laptop",
    "price": 999.99,
    "stock": 10
  }
}
```

**4. Order Service → Product Service (Stock Update):**
```json
PATCH http://product-service:3003/products/65def456.../stock
{
  "quantity": 2
}

Response:
{
  "success": true,
  "message": "Stock updated successfully",
  "data": {
    "_id": "65def456...",
    "stock": 8  // 10 - 2
  }
}
```

**5. Final Response to Client:**
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "_id": "65ghi789...",
    "userId": "65abc123...",
    "productId": "65def456...",
    "quantity": 2,
    "totalPrice": 1999.98,
    "status": "pending",
    "userDetails": {
      "name": "John Doe",
      "email": "john@example.com"
    },
    "productDetails": {
      "name": "Laptop",
      "price": 999.99
    }
  }
}
```

## Network Configuration

### Docker Network
- **Name:** `microservices-network`
- **Driver:** bridge
- **Purpose:** Allows containers to communicate using service names

### Service Discovery
Services communicate using Docker's internal DNS:
- User Service: `http://user-service:3001`
- Product Service: `http://product-service:3003`
- Order Service: `http://order-service:3002`
- MongoDB: `mongodb://mongodb:27017`

## Scalability Considerations

### Current Architecture
- Single instance of each service
- Shared MongoDB database
- Direct service-to-service HTTP calls

### Future Enhancements

1. **API Gateway**
   - Central entry point for all client requests
   - Rate limiting, authentication, request routing

2. **Service Mesh**
   - Istio or Linkerd for advanced traffic management
   - Automatic retries, circuit breakers, mutual TLS

3. **Message Queue**
   - RabbitMQ or Kafka for asynchronous communication
   - Event-driven architecture for better decoupling

4. **Load Balancing**
   - Multiple instances of each service
   - Nginx or HAProxy for load distribution

5. **Service Registry**
   - Consul or Eureka for dynamic service discovery
   - Health checks and automatic failover

6. **Caching Layer**
   - Redis for frequently accessed data
   - Reduce database load and improve response times

7. **Database per Service**
   - Separate MongoDB instance for each service
   - Better data isolation and scalability

## Error Handling

### Retry Mechanism
Currently, services don't retry failed requests. Future enhancement:
```javascript
// Exponential backoff retry
async function retryRequest(fn, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await fn();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await sleep(Math.pow(2, i) * 1000);
    }
  }
}
```

### Circuit Breaker
Prevent cascading failures when a service is down:
```javascript
// Future implementation
const circuitBreaker = {
  failureThreshold: 5,
  cooldownPeriod: 60000,
  // ... implementation
};
```

## Monitoring and Observability

### Current State
- Health check endpoints on each service
- Docker logs for debugging

### Recommended Additions
1. **Distributed Tracing** - Jaeger or Zipkin
2. **Metrics** - Prometheus + Grafana
3. **Centralized Logging** - ELK Stack or Loki
4. **APM** - New Relic or DataDog

## Security Considerations

### Current Implementation
- CORS enabled for cross-origin requests
- Input validation for required fields
- MongoDB injection prevention via Mongoose

### Future Security Enhancements
1. **Authentication & Authorization**
   - JWT tokens for user authentication
   - Service-to-service authentication

2. **Rate Limiting**
   - Prevent API abuse
   - DDoS protection

3. **HTTPS/TLS**
   - Encrypt data in transit
   - SSL certificates

4. **Secrets Management**
   - HashiCorp Vault or AWS Secrets Manager
   - Never store secrets in code

5. **API Versioning**
   - Support multiple API versions
   - Backward compatibility

## Performance Optimization

### Database Indexing
```javascript
// Add indexes for frequently queried fields
userSchema.index({ email: 1 });
productSchema.index({ name: 1, price: 1 });
orderSchema.index({ userId: 1, createdAt: -1 });
```

### Caching Strategy
```javascript
// Cache user and product data in Order Service
const cache = new Map();
const CACHE_TTL = 300000; // 5 minutes
```

### Connection Pooling
```javascript
// MongoDB connection pool
mongoose.connect(MONGODB_URI, {
  maxPoolSize: 10,
  minPoolSize: 2
});
```

## Deployment Architecture

```
GitHub Repository
       ↓
GitHub Actions CI/CD
       ↓
   Docker Hub
       ↓
Ubuntu Server (161.118.236.136)
       ↓
Docker Compose
       ↓
[User Service] [Product Service] [Order Service] [MongoDB]
```

## Summary

This microservices architecture demonstrates:
- ✅ Service independence
- ✅ Inter-service communication
- ✅ Data validation across services
- ✅ Transaction-like operations (with rollback)
- ✅ Containerization with Docker
- ✅ Automated CI/CD pipeline
- ✅ Health monitoring

The architecture is designed to be simple for learning but includes patterns that can scale to production environments.
