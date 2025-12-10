#!/bin/bash

# Server Setup Script for Microservices Deployment
# Run this on your Ubuntu server: bash setup-server.sh

set -e

echo "=========================================="
echo "🚀 Microservices Server Setup"
echo "=========================================="
echo ""

# Check if running as ubuntu user
if [ "$USER" != "ubuntu" ]; then
    echo "⚠️  Warning: This script should be run as the 'ubuntu' user"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Step 1: Fix Docker Permissions
echo "Step 1: Fixing Docker permissions..."
if groups $USER | grep &>/dev/null '\bdocker\b'; then
    echo "✓ User already in docker group"
else
    echo "Adding $USER to docker group..."
    sudo usermod -aG docker $USER
    echo "✓ User added to docker group"
    echo "⚠️  You'll need to log out and log back in for this to take effect"
    echo "⚠️  Or run: newgrp docker"
fi

# Step 2: Install Docker Compose V2
echo ""
echo "Step 2: Installing Docker Compose V2..."
if docker compose version &>/dev/null; then
    echo "✓ Docker Compose V2 already installed"
    docker compose version
else
    echo "Installing docker-compose-plugin..."
    sudo apt-get update
    sudo apt-get install -y docker-compose-plugin
    echo "✓ Docker Compose V2 installed"
    docker compose version
fi

# Step 3: Create Application Directory
echo ""
echo "Step 3: Creating application directory..."
mkdir -p ~/microservices-app/mongodb
cd ~/microservices-app
echo "✓ Directory created: ~/microservices-app"

# Step 4: Create docker-compose.yml
echo ""
echo "Step 4: Creating docker-compose.yml..."
cat > ~/microservices-app/docker-compose.yml <<'EOF'
services:
  mongodb:
    image: mongo:7.0
    container_name: mongodb
    restart: unless-stopped
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_DATABASE: microservices
    volumes:
      - ./mongodb:/data/db
    healthcheck:
      test: echo 'db.runCommand("ping").ok' | mongosh localhost:27017/test --quiet
      interval: 10s
      timeout: 5s
      retries: 5

  user-service:
    image: ${DOCKER_USERNAME}/user-service:latest
    container_name: user-service
    restart: unless-stopped
    ports:
      - "3002:3002"
    environment:
      - PORT=3002
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - NODE_ENV=production
    depends_on:
      mongodb:
        condition: service_healthy

  order-service:
    image: ${DOCKER_USERNAME}/order-service:latest
    container_name: order-service
    restart: unless-stopped
    ports:
      - "3003:3003"
    environment:
      - PORT=3003
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - USER_SERVICE_URL=http://user-service:3002
      - PRODUCT_SERVICE_URL=http://product-service:3004
      - NODE_ENV=production
    depends_on:
      mongodb:
        condition: service_healthy

  product-service:
    image: ${DOCKER_USERNAME}/product-service:latest
    container_name: product-service
    restart: unless-stopped
    ports:
      - "3004:3004"
    environment:
      - PORT=3004
      - MONGODB_URI=mongodb://mongodb:27017/microservices
      - NODE_ENV=production
    depends_on:
      mongodb:
        condition: service_healthy
EOF
echo "✓ docker-compose.yml created"

# Step 5: Create .env file
echo ""
echo "Step 5: Creating .env file..."
read -p "Enter your Docker Hub username: " DOCKER_USER
echo "DOCKER_USERNAME=${DOCKER_USER}" > ~/microservices-app/.env
echo "✓ .env file created"

# Step 6: Test Configuration
echo ""
echo "Step 6: Testing configuration..."
if docker compose config &>/dev/null; then
    echo "✓ docker-compose.yml is valid"
else
    echo "❌ Error in docker-compose.yml"
    docker compose config
    exit 1
fi

# Step 7: Pull MongoDB
echo ""
echo "Step 7: Pulling MongoDB image..."
docker pull mongo:7.0
echo "✓ MongoDB image pulled"

# Final Summary
echo ""
echo "=========================================="
echo "✅ SERVER SETUP COMPLETED!"
echo "=========================================="
echo ""
echo "📋 Summary:"
echo "  • Docker permissions: Fixed (may need logout/login)"
echo "  • Docker Compose V2: Installed"
echo "  • Application directory: ~/microservices-app"
echo "  • docker-compose.yml: Created"
echo "  • .env file: Created"
echo "  • MongoDB image: Pulled"
echo ""
echo "📁 Files created:"
echo "  ~/microservices-app/docker-compose.yml"
echo "  ~/microservices-app/.env"
echo "  ~/microservices-app/mongodb/"
echo ""
echo "🎯 Next Steps:"
echo "  1. If you just added user to docker group, run: newgrp docker"
echo "  2. Test Docker without sudo: docker ps"
echo "  3. Configure GitHub Secrets (see README.md)"
echo "  4. Push code to trigger deployment!"
echo ""
echo "🧪 Optional: Test MongoDB startup"
echo "  docker compose up -d mongodb"
echo "  docker ps"
echo "  docker compose down"
echo ""
