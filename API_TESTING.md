# API Testing Guide

This document provides examples of how to test all the microservices APIs.

## Prerequisites
- All services must be running
- Use `curl` or any API testing tool like Postman

## Base URLs
- User Service: http://localhost:3001 (or http://161.118.236.136:3001 for production)
- Product Service: http://localhost:3003 (or http://161.118.236.136:3003 for production)
- Order Service: http://localhost:3002 (or http://161.118.236.136:3002 for production)

---

## User Service API

### Health Check
```bash
curl http://localhost:3001/health
```

### Get All Users
```bash
curl http://localhost:3001/users
```

### Create a User
```bash
curl -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "email": "john@example.com"
  }'
```

### Get User by ID
```bash
curl http://localhost:3001/users/{user_id}
```

### Update User
```bash
curl -X PUT http://localhost:3001/users/{user_id} \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Smith",
    "email": "johnsmith@example.com"
  }'
```

### Delete User
```bash
curl -X DELETE http://localhost:3001/users/{user_id}
```

---

## Product Service API

### Health Check
```bash
curl http://localhost:3003/health
```

### Get All Products
```bash
curl http://localhost:3003/products
```

### Create a Product
```bash
curl -X POST http://localhost:3003/products \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MacBook Pro",
    "price": 2499.99,
    "stock": 25,
    "description": "16-inch MacBook Pro with M3 chip"
  }'
```

### Get Product by ID
```bash
curl http://localhost:3003/products/{product_id}
```

### Update Product
```bash
curl -X PUT http://localhost:3003/products/{product_id} \
  -H "Content-Type: application/json" \
  -d '{
    "name": "MacBook Pro Updated",
    "price": 2399.99,
    "stock": 30,
    "description": "Updated description"
  }'
```

### Delete Product
```bash
curl -X DELETE http://localhost:3003/products/{product_id}
```

---

## Order Service API (with Inter-Service Communication)

### Health Check
```bash
curl http://localhost:3002/health
```

### Get All Orders
```bash
curl http://localhost:3002/orders
```

### Create an Order
**Note:** This endpoint validates the user and product by calling User Service and Product Service internally.

```bash
# First, get a user ID and product ID from the respective services
# Then create an order:

curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId": "65abc123...",
    "productId": "65def456...",
    "quantity": 2
  }'
```

**What happens internally:**
1. Order Service calls User Service to validate the user exists
2. Order Service calls Product Service to validate the product exists and has sufficient stock
3. If both validations pass, the order is created
4. Product Service stock is automatically updated

### Get Order by ID
```bash
curl http://localhost:3002/orders/{order_id}
```

### Update Order Status
```bash
curl -X PATCH http://localhost:3002/orders/{order_id}/status \
  -H "Content-Type: application/json" \
  -d '{
    "status": "shipped"
  }'
```

Valid statuses: `pending`, `confirmed`, `shipped`, `delivered`, `cancelled`

### Get Orders by User
```bash
curl http://localhost:3002/orders/user/{user_id}
```

### Delete Order
```bash
curl -X DELETE http://localhost:3002/orders/{order_id}
```

---

## Complete Workflow Example

### 1. Create a User
```bash
curl -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Alice Johnson","email":"alice@example.com"}'
```

Response:
```json
{
  "success": true,
  "message": "User created successfully",
  "data": {
    "_id": "65abc123def456...",
    "name": "Alice Johnson",
    "email": "alice@example.com",
    "createdAt": "2025-12-10T10:00:00.000Z"
  }
}
```

### 2. Create a Product
```bash
curl -X POST http://localhost:3003/products \
  -H "Content-Type: application/json" \
  -d '{"name":"iPhone 15","price":999.99,"stock":100,"description":"Latest iPhone"}'
```

Response:
```json
{
  "success": true,
  "message": "Product created successfully",
  "data": {
    "_id": "65def456ghi789...",
    "name": "iPhone 15",
    "price": 999.99,
    "stock": 100,
    "description": "Latest iPhone",
    "createdAt": "2025-12-10T10:01:00.000Z"
  }
}
```

### 3. Create an Order (Inter-Service Communication)
```bash
curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{
    "userId":"65abc123def456...",
    "productId":"65def456ghi789...",
    "quantity":3
  }'
```

Response:
```json
{
  "success": true,
  "message": "Order created successfully",
  "data": {
    "_id": "65ghi789jkl012...",
    "userId": "65abc123def456...",
    "productId": "65def456ghi789...",
    "quantity": 3,
    "totalPrice": 2999.97,
    "status": "pending",
    "userDetails": {
      "_id": "65abc123def456...",
      "name": "Alice Johnson",
      "email": "alice@example.com"
    },
    "productDetails": {
      "name": "iPhone 15",
      "price": 999.99
    },
    "createdAt": "2025-12-10T10:02:00.000Z"
  }
}
```

---

## Testing with the Automated Script

Run the automated test script:

```bash
chmod +x test-api.sh
./test-api.sh localhost
```

For production server:
```bash
./test-api.sh 161.118.236.136
```

---

## Error Scenarios

### Order with Invalid User
```bash
curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"invalid_id","productId":"65def456ghi789...","quantity":1}'
```

Response:
```json
{
  "success": false,
  "error": "User not found"
}
```

### Order with Insufficient Stock
```bash
# If product has only 5 items in stock but you order 10:
curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"65abc123def456...","productId":"65def456ghi789...","quantity":10}'
```

Response:
```json
{
  "success": false,
  "error": "Insufficient stock"
}
```

---

## Using Postman

1. Import the following base URLs as environment variables:
   - `user_service`: http://localhost:3001
   - `product_service`: http://localhost:3003
   - `order_service`: http://localhost:3002

2. Create a collection with all the endpoints above

3. Use the "Tests" tab to automatically extract IDs from responses for chaining requests

---

## Monitoring

Check service logs:
```bash
# Using Docker
docker logs user-service
docker logs product-service
docker logs order-service

# Using Docker Compose
docker-compose logs -f
```
