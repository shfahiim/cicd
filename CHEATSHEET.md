# Quick Start Cheatsheet

## 🚀 Initial Setup (One-time)

### 1. Install Docker & Docker Compose
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and log back in for group changes
```

### 2. Clone and Setup
```bash
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd
```

## 🎯 Local Development

### Start All Services
```bash
./start.sh
# OR
docker compose up -d
```

### Stop All Services
```bash
docker compose down
```

### View Logs
```bash
# All services
docker compose logs -f

# Specific service
docker logs -f user-service
docker logs -f order-service
docker logs -f product-service
```

### Restart Services
```bash
# All services
docker compose restart

# Specific service
docker restart user-service
```

## 🧪 Testing APIs

### Quick Test
```bash
./test-api.sh
```

### Manual Tests
```bash
# Health checks
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health

# Create user
curl -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Create product
curl -X POST http://localhost:3003/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'

# Create order (replace IDs)
curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"USER_ID","productId":"PRODUCT_ID","quantity":2}'
```

## 📦 Git Commands

### Initial Setup
```bash
git init
git add .
git commit -m "Initial commit: Microservices with CI/CD"
git remote add origin https://github.com/shfahiim/cicd.git
git branch -M main
git push -u origin main
```

### Regular Updates
```bash
git add .
git commit -m "Your commit message"
git push
```

## 🔐 GitHub Secrets Setup

Go to: https://github.com/shfahiim/cicd/settings/secrets/actions

Add these secrets:
- `DOCKER_USERNAME` - Your Docker Hub username
- `DOCKER_TOKEN` - Docker Hub access token
- `SERVER_HOST` - 161.118.236.136
- `SERVER_USER` - ubuntu
- `SERVER_SSH_KEY` - Content of connect-oracle.key file

## 🖥️ Server Deployment

### Connect to Server
```bash
ssh -i connect-oracle.key ubuntu@161.118.236.136
```

### Setup Server (One-time)
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker ubuntu

# Create app directory
mkdir -p ~/microservices-app
cd ~/microservices-app
```

### Create docker-compose.yml on Server
```bash
cat > ~/microservices-app/docker-compose.yml << 'EOF'
version: '3.8'

services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
    restart: always
    ports:
      - "27017:27017"
    volumes:
      - ./mongodb-data:/data/db
    environment:
      MONGO_INITDB_DATABASE: microservices
    networks:
      - microservices-network

  user-service:
    image: YOUR_DOCKERHUB_USERNAME/user-service:latest
    container_name: user-service
    restart: always
    ports:
      - "3001:3001"
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - PORT=3001
    depends_on:
      - mongodb
    networks:
      - microservices-network

  order-service:
    image: YOUR_DOCKERHUB_USERNAME/order-service:latest
    container_name: order-service
    restart: always
    ports:
      - "3002:3002"
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - PORT=3002
      - USER_SERVICE_URL=http://user-service:3001
      - PRODUCT_SERVICE_URL=http://product-service:3003
    depends_on:
      - mongodb
      - user-service
      - product-service
    networks:
      - microservices-network

  product-service:
    image: YOUR_DOCKERHUB_USERNAME/product-service:latest
    container_name: product-service
    restart: always
    ports:
      - "3003:3003"
    environment:
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - PORT=3003
    depends_on:
      - mongodb
    networks:
      - microservices-network

networks:
  microservices-network:
    driver: bridge
EOF

# Replace YOUR_DOCKERHUB_USERNAME with your actual username
```

### Start Services on Server
```bash
cd ~/microservices-app
docker compose up -d
```

### Check Server Status
```bash
# Check containers
docker ps

# Check logs
docker logs user-service
docker logs order-service
docker logs product-service

# Test services
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

## 🔍 Troubleshooting

### Services not starting
```bash
# Check Docker is running
sudo systemctl status docker

# Check logs
docker compose logs

# Restart Docker
sudo systemctl restart docker
```

### Port already in use
```bash
# Check what's using the port
sudo netstat -tulpn | grep 3001

# Kill the process
sudo kill -9 <PID>
```

### MongoDB connection issues
```bash
# Restart MongoDB
docker restart mongodb

# Check MongoDB logs
docker logs mongodb
```

### Reset everything
```bash
# Stop and remove everything
docker compose down -v

# Start fresh
docker compose up -d
```

## 📊 Monitoring

### Check Service Health
```bash
curl http://161.118.236.136:3001/health
curl http://161.118.236.136:3002/health
curl http://161.118.236.136:3003/health
```

### View Resource Usage
```bash
docker stats
```

### Check Disk Space
```bash
df -h
docker system df
```

## 🔄 CI/CD Pipeline

### Trigger Deployment
```bash
git add .
git commit -m "Deploy changes"
git push origin main
```

### Watch Pipeline
Go to: https://github.com/shfahiim/cicd/actions

### Manual Deployment (if pipeline fails)
```bash
# On server
cd ~/microservices-app
docker compose pull
docker compose up -d
```

## 📝 Useful Docker Commands

```bash
# Remove all stopped containers
docker container prune

# Remove unused images
docker image prune -a

# View all images
docker images

# Remove specific image
docker rmi <image_id>

# Execute command in container
docker exec -it user-service sh

# Copy file from container
docker cp user-service:/app/package.json ./
```

## 🔗 Important URLs

- **GitHub Repo**: https://github.com/shfahiim/cicd
- **Docker Hub**: https://hub.docker.com
- **Local Services**:
  - User: http://localhost:3001
  - Order: http://localhost:3002
  - Product: http://localhost:3003
- **Production Services**:
  - User: http://161.118.236.136:3001
  - Order: http://161.118.236.136:3002
  - Product: http://161.118.236.136:3003
