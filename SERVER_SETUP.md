# 🚨 SERVER SETUP REQUIRED

Your server needs setup before deployment can work. Follow these steps:

## Step 1: SSH to Server
```bash
ssh -i connect-oracle.key ubuntu@161.118.236.136
```

## Step 2: Fix Docker Permissions
```bash
# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Activate the changes
newgrp docker

# Test docker without sudo
docker ps
```

## Step 3: Install Docker Compose V2
```bash
# Update package list
sudo apt-get update

# Install docker-compose-plugin
sudo apt-get install -y docker-compose-plugin

# Test it
docker compose version
```

## Step 4: Create Application Directory Structure
```bash
# Create main application directory
mkdir -p ~/microservices-app

# Navigate to it
cd ~/microservices-app
```

## Step 5: Create docker-compose.yml on Server
```bash
# Create the file
nano ~/microservices-app/docker-compose.yml
```

**Paste this content:**

```yaml
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
```

**Save:** Press `Ctrl+X`, then `Y`, then `Enter`

## Step 6: Create .env file
```bash
# Create .env file
nano ~/microservices-app/.env
```

**Paste this (replace YOUR_DOCKER_USERNAME):**
```bash
DOCKER_USERNAME=YOUR_DOCKER_USERNAME
```

**Save:** Press `Ctrl+X`, then `Y`, then `Enter`

## Step 7: Test Setup
```bash
# Navigate to app directory
cd ~/microservices-app

# Check files exist
ls -la

# You should see:
# - docker-compose.yml
# - .env
# - mongodb/ (directory)

# Test docker compose
docker compose config
```

## Step 8: Manual Test (Optional)
```bash
# Pull MongoDB
docker pull mongo:7.0

# Start MongoDB only
docker compose up -d mongodb

# Check it's running
docker ps

# Stop it
docker compose down
```

## Step 9: Update GitHub Workflow

The deployment script needs a fix. Exit server and return to your local machine:

```bash
exit  # Exit from server
```

## ✅ Checklist

- [ ] Docker permissions fixed (user in docker group)
- [ ] Docker Compose V2 installed
- [ ] ~/microservices-app directory created
- [ ] docker-compose.yml created with correct ports
- [ ] .env file created with DOCKER_USERNAME
- [ ] Tested `docker compose config`
- [ ] Ready to update GitHub workflow

## 🎯 Next Step

After completing server setup, we'll fix the GitHub Actions deployment script.
