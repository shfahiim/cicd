# Microservices CI/CD Project

A complete microservices architecture with GitHub Actions CI/CD pipeline.

## Architecture
This project consists of 3 microservices:
- **User Service** (Port 3002) - Manages user data
- **Order Service** (Port 3003) - Manages orders (communicates with User & Product services)
- **Product Service** (Port 3004) - Manages products

## Tech Stack
- Node.js & Express
- MongoDB
- Docker & Docker Compose
- GitHub Actions for CI/CD

## Services Overview

### User Service (Port 3002)
- `GET /users` - Get all users
- `POST /users` - Create a new user
- `GET /health` - Health check

### Order Service (Port 3003)
- `GET /orders` - Get all orders
- `POST /orders` - Create a new order (validates user and product)
- `GET /health` - Health check

### Product Service (Port 3004)
- `GET /products` - Get all products
- `POST /products` - Create a new product
- `GET /health` - Health check

## Quick Start

### Prerequisites
- Docker and Docker Compose installed
- Node.js 18+ (for local development)
- MongoDB running locally or via Docker

### Local Development
```bash
# Install dependencies for all services
cd user-service && npm install && cd ..
cd order-service && npm install && cd ..
cd product-service && npm install && cd ..

# Start MongoDB
docker-compose up -d mongodb

# Start services (in separate terminals)
cd user-service && npm start
cd order-service && npm start
cd product-service && npm start
```

### Using Docker Compose
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop all services
docker-compose down
```

## API Testing

### Create a User
```bash
curl -X POST http://localhost:3002/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'
```

### Create a Product
```bash
curl -X POST http://localhost:3004/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'
```

### Create an Order
```bash
curl -X POST http://localhost:3003/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"<user_id>","productId":"<product_id>","quantity":2}'
```

## CI/CD Pipeline
The GitHub Actions workflow automatically:
1. Runs tests on push/PR
2. Builds Docker images
3. Pushes images to Docker Hub
4. Deploys to Ubuntu server via SSH

## Deployment
See [SETUP.md](./SETUP.md) for detailed setup instructions.
