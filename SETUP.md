# Complete Setup Guide for Microservices CI/CD

This guide will walk you through setting up the entire CI/CD pipeline from scratch.

## Table of Contents
1. [Local Development Setup](#1-local-development-setup)
2. [GitHub Repository Setup](#2-github-repository-setup)
3. [Docker Hub Setup](#3-docker-hub-setup)
4. [Server Setup (Ubuntu)](#4-server-setup-ubuntu)
5. [GitHub Actions Secrets Configuration](#5-github-actions-secrets-configuration)
6. [Testing the Pipeline](#6-testing-the-pipeline)

---

## 1. Local Development Setup

### Install Prerequisites
```bash
# Install Node.js (if not installed)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Docker (if not installed)
curl -fssl https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo apt-get install docker-compose-plugin
```

### Clone and Setup Project
```bash
# Navigate to your project directory
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd

# Install dependencies for each service
cd user-service && npm install && cd ..
cd order-service && npm install && cd ..
cd product-service && npm install && cd ..
```

### Test Locally
```bash
# Start all services with Docker Compose
docker-compose up -d

# Check if services are running
docker-compose ps

# Test the APIs
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

---

## 2. GitHub Repository Setup

### Initialize Git Repository
```bash
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Initial commit: Microservices with CI/CD"

# Add remote repository
git remote add origin https://github.com/shfahiim/cicd.git

# Rename branch to main
git branch -M main

# Push to GitHub
git push -u origin main
```

---

## 3. Docker Hub Setup

### Create Docker Hub Account
1. Go to https://hub.docker.com
2. Sign up for a free account
3. Verify your email

### Create Docker Hub Repositories
1. Log in to Docker Hub
2. Click "Create Repository"
3. Create three repositories:
   - `your-username/user-service`
   - `your-username/order-service`
   - `your-username/product-service`
4. Set them as **Public** (free tier)

### Generate Docker Hub Access Token
1. Go to Account Settings → Security
2. Click "New Access Token"
3. Name it "GitHub Actions"
4. Copy the token (you'll need it for GitHub Secrets)

---

## 4. Server Setup (Ubuntu)

### Connect to Your Server
```bash
# Make sure your key has correct permissions
chmod 400 connect-oracle.key

# Connect to server
ssh -i connect-oracle.key ubuntu@161.118.236.136
```

### Install Docker on Server
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add ubuntu user to docker group
sudo usermod -aG docker ubuntu

# Log out and log back in for group changes to take effect
exit

# Connect again
ssh -i connect-oracle.key ubuntu@161.118.236.136

# Verify Docker installation
docker --version
docker ps
```

### Install Docker Compose on Server
```bash
# Install Docker Compose
sudo apt-get install docker-compose-plugin -y

# Verify installation
docker compose version
```

### Create Application Directory
```bash
# Create directory for the application
mkdir -p ~/microservices-app
cd ~/microservices-app

# Create directory for MongoDB data
mkdir -p ~/microservices-app/mongodb-data
```

### Setup MongoDB (Persistent Storage)
```bash
# Create docker-compose.yml for MongoDB
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
    image: shfahiim/user-service:latest
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
    image: shfahiim/order-service:latest
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
    image: shfahiim/product-service:latest
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

# Start MongoDB
docker compose up -d mongodb
```

### Configure Firewall (if UFW is enabled)
```bash
# Check if UFW is active
sudo ufw status

# If active, allow necessary ports
sudo ufw allow 3001/tcp
sudo ufw allow 3002/tcp
sudo ufw allow 3003/tcp
sudo ufw allow 22/tcp
```

---

## 5. GitHub Actions Secrets Configuration

### Add SSH Key to Server
```bash
# On your LOCAL machine, copy the public key content
cat connect-oracle.key

# On the SERVER, add GitHub Actions access
# We'll use the same key for simplicity
```

### Configure GitHub Secrets
1. Go to your GitHub repository: https://github.com/shfahiim/cicd
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add the following secrets:

#### Required Secrets:

**DOCKER_USERNAME**
- Value: Your Docker Hub username (e.g., `shfahiim`)

**DOCKER_TOKEN**
- Value: Your Docker Hub access token (from Step 3)

**SERVER_HOST**
- Value: `161.118.236.136`

**SERVER_USER**
- Value: `ubuntu`

**SERVER_SSH_KEY**
- Value: Complete content of your `connect-oracle.key` file
- Open the key file and copy ALL content including:
  ```
  -----BEGIN OPENSSH PRIVATE KEY-----
  ... (all the key content)
  -----END OPENSSH PRIVATE KEY-----
  ```

---

## 6. Testing the Pipeline

### Trigger the CI/CD Pipeline
```bash
# Make a small change to test the pipeline
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd

# Create a test change
echo "# Test change" >> README.md

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### Monitor the Pipeline
1. Go to your GitHub repository
2. Click on **Actions** tab
3. You should see the workflow running
4. Click on the workflow to see detailed logs

### Verify Deployment on Server
```bash
# Connect to server
ssh -i connect-oracle.key ubuntu@161.118.236.136

# Check running containers
docker ps

# Check logs
docker logs user-service
docker logs order-service
docker logs product-service

# Test the services
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

### Test the APIs
```bash
# From your local machine (or server)
SERVER_IP="161.118.236.136"

# Create a user
curl -X POST http://${SERVER_IP}:3001/users \
  -H "Content-Type: application/json" \
  -d '{"name":"John Doe","email":"john@example.com"}'

# Get all users
curl http://${SERVER_IP}:3001/users

# Create a product
curl -X POST http://${SERVER_IP}:3003/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'

# Get all products
curl http://${SERVER_IP}:3003/products

# Create an order (use actual IDs from above responses)
curl -X POST http://${SERVER_IP}:3002/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"<user_id_here>","productId":"<product_id_here>","quantity":2}'

# Get all orders
curl http://${SERVER_IP}:3002/orders
```

---

## Troubleshooting

### Pipeline Fails at Build Stage
- Check Docker Hub credentials in GitHub Secrets
- Ensure repository names match in docker-compose.yml

### Pipeline Fails at Deploy Stage
- Verify SSH key is correct in GitHub Secrets
- Check server is accessible: `ssh -i connect-oracle.key ubuntu@161.118.236.136`
- Verify Docker is installed on server

### Services Not Starting on Server
```bash
# Check logs
docker compose logs

# Check if ports are already in use
sudo netstat -tulpn | grep -E '3001|3002|3003'

# Restart services
docker compose down
docker compose up -d
```

### MongoDB Connection Issues
```bash
# Check MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs mongodb

# Restart MongoDB
docker compose restart mongodb
```

---

## Understanding the CI/CD Pipeline

### What Happens When You Push Code?

1. **Trigger**: Push to `main` branch triggers GitHub Actions
2. **Checkout**: GitHub Actions checks out your code
3. **Build**: Builds Docker images for all 3 services
4. **Test**: Runs tests (if configured)
5. **Push**: Pushes images to Docker Hub
6. **Deploy**: SSH into server and pulls latest images
7. **Restart**: Restarts services with new images

### Workflow File Location
`.github/workflows/deploy.yml`

### Continuous Deployment
Every push to `main` automatically deploys to production!

---

## Next Steps

1. **Add Tests**: Implement unit and integration tests
2. **Add Staging Environment**: Create a staging branch and environment
3. **Add Monitoring**: Implement logging and monitoring (Prometheus, Grafana)
4. **Add API Gateway**: Use nginx or API Gateway service
5. **Add Authentication**: Implement JWT authentication
6. **Add Rate Limiting**: Protect your APIs
7. **Add Database Backups**: Schedule MongoDB backups

---

## Additional Resources

- [Docker Documentation](https://docs.docker.com/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [MongoDB Documentation](https://docs.mongodb.com/)
- [Node.js Best Practices](https://github.com/goldbergyoni/nodebestpractices)

---

## Support

If you encounter any issues, check:
1. GitHub Actions logs
2. Server logs: `docker compose logs`
3. Individual service logs: `docker logs <service-name>`

Happy Learning! 🚀
