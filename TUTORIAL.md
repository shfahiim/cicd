# Complete Learning Tutorial: Microservices with CI/CD

Welcome! This tutorial will guide you step-by-step through understanding and deploying this microservices project. Perfect for beginners learning DevOps, Docker, and CI/CD.

## 📚 Table of Contents
1. [Understanding the Basics](#1-understanding-the-basics)
2. [Project Structure](#2-project-structure)
3. [Understanding Each Service](#3-understanding-each-service)
4. [Docker Fundamentals](#4-docker-fundamentals)
5. [Local Development](#5-local-development)
6. [Understanding CI/CD](#6-understanding-cicd)
7. [GitHub Actions](#7-github-actions)
8. [Server Deployment](#8-server-deployment)
9. [Testing and Validation](#9-testing-and-validation)
10. [Common Issues and Solutions](#10-common-issues-and-solutions)

---

## 1. Understanding the Basics

### What are Microservices?
Microservices are small, independent services that work together. Instead of one big application, you have multiple small applications that communicate with each other.

**Example:**
- **User Service**: Handles everything about users
- **Product Service**: Handles everything about products  
- **Order Service**: Handles orders and talks to both User and Product services

### Why Microservices?
✅ Each service can be updated independently
✅ Easier to scale specific parts
✅ Teams can work on different services
✅ One service failure doesn't crash everything

### What is CI/CD?
**CI (Continuous Integration)**: Automatically test code when you push to GitHub
**CD (Continuous Deployment)**: Automatically deploy code to your server

**Simple flow:**
```
You push code → GitHub Actions runs tests → Builds Docker images → Deploys to server
```

---

## 2. Project Structure

```
microservice-ci-cd/
├── user-service/           # Manages users
│   ├── server.js          # Main application code
│   ├── package.json       # Dependencies
│   ├── Dockerfile         # How to build Docker image
│   └── .env              # Environment variables
│
├── product-service/       # Manages products
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env
│
├── order-service/         # Manages orders
│   ├── server.js
│   ├── package.json
│   ├── Dockerfile
│   └── .env
│
├── .github/workflows/     # CI/CD pipeline
│   └── deploy.yml         # GitHub Actions configuration
│
├── docker-compose.yml     # Run all services together
├── README.md              # Project overview
├── SETUP.md              # Detailed setup guide
├── API_TESTING.md        # API examples
├── ARCHITECTURE.md       # System design
└── CHEATSHEET.md         # Quick commands
```

---

## 3. Understanding Each Service

### User Service (Port 3001)

**What it does:** Stores and manages user information

**Database:** MongoDB collection called "users"

**Key code explanation:**
```javascript
// This defines what a user looks like
const userSchema = new mongoose.Schema({
  name: String,      // User's name
  email: String,     // User's email (must be unique)
  createdAt: Date    // When user was created
});

// This creates a user
app.post('/users', async (req, res) => {
  const user = new User({ name, email });
  await user.save();  // Save to database
});
```

### Product Service (Port 3003)

**What it does:** Manages product catalog and inventory

**Database:** MongoDB collection called "products"

**Key features:**
- Track product stock
- Update stock when order is placed
- Prevent selling out-of-stock items

### Order Service (Port 3002)

**What it does:** Creates orders and coordinates with other services

**The magic:** This service talks to User and Product services!

**How it works:**
```javascript
// When creating an order:
1. Check if user exists (call User Service)
2. Check if product exists and has stock (call Product Service)
3. Create the order
4. Update product stock (call Product Service again)
5. If anything fails, roll back (undo changes)
```

---

## 4. Docker Fundamentals

### What is Docker?
Docker packages your application with everything it needs to run (code, libraries, dependencies) into a "container".

**Think of it like:**
- Shipping container for your code
- Works the same everywhere (your laptop, server, cloud)

### Key Docker Concepts

**1. Dockerfile** - Instructions to build an image
```dockerfile
FROM node:18-alpine          # Start with Node.js
WORKDIR /app                 # Create /app directory
COPY package*.json ./        # Copy package files
RUN npm ci                   # Install dependencies
COPY . .                     # Copy application code
CMD ["node", "server.js"]    # Start the app
```

**2. Docker Image** - Blueprint for your container
- Like a "photo" of your application
- Can be shared and reused

**3. Docker Container** - Running instance of an image
- Your actual application running

**4. Docker Compose** - Run multiple containers together
```yaml
services:
  user-service:    # Start user service
  product-service: # Start product service
  order-service:   # Start order service
  mongodb:         # Start database
```

---

## 5. Local Development

### Step 1: Install Docker

```bash
# On Ubuntu/Linux
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and log back in
```

### Step 2: Start Services Locally

```bash
# Navigate to project
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd

# Start all services
./start.sh

# OR manually
docker compose up -d
```

**What happens:**
1. Docker downloads MongoDB image
2. Docker builds images for our 3 services
3. Starts all 4 containers
4. Sets up networking so they can talk

### Step 3: Verify Services

```bash
# Check if containers are running
docker ps

# Check health
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

### Step 4: Test the APIs

```bash
# Create a user
curl -X POST http://localhost:3001/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Test User","email":"test@example.com"}'

# You'll get a response with user ID - copy it!

# Create a product  
curl -X POST http://localhost:3003/products \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","price":999.99,"stock":10}'

# Copy the product ID from response

# Create an order (replace USER_ID and PRODUCT_ID)
curl -X POST http://localhost:3002/orders \
  -H "Content-Type: application/json" \
  -d '{"userId":"USER_ID","productId":"PRODUCT_ID","quantity":2}'
```

---

## 6. Understanding CI/CD

### The CI/CD Pipeline Flow

```
Developer pushes code to GitHub
           ↓
GitHub Actions is triggered
           ↓
Step 1: Checkout code
           ↓
Step 2: Build Docker images
           ↓
Step 3: Run tests (if any)
           ↓
Step 4: Push images to Docker Hub
           ↓
Step 5: SSH into server
           ↓
Step 6: Pull new images
           ↓
Step 7: Restart containers
           ↓
Deployment complete! 🎉
```

### Why is this useful?
- ✅ No manual deployment steps
- ✅ Consistent deployments every time
- ✅ Fast - deploys in minutes
- ✅ Automatic rollback if tests fail

---

## 7. GitHub Actions

### Understanding the Workflow File

Location: `.github/workflows/deploy.yml`

```yaml
# When to run
on:
  push:
    branches: [ main ]  # Run on push to main

# What to do
jobs:
  build-and-push:       # Job 1: Build Docker images
    steps:
      - Checkout code
      - Login to Docker Hub
      - Build images
      - Push to Docker Hub
  
  deploy:               # Job 2: Deploy to server
    needs: build-and-push  # Wait for Job 1
    steps:
      - SSH into server
      - Pull new images
      - Restart services
```

### Setting Up GitHub Actions

**Step 1: Create Docker Hub Account**
- Go to https://hub.docker.com
- Sign up (free)
- Create access token in Account Settings → Security

**Step 2: Add GitHub Secrets**
Go to: https://github.com/shfahiim/cicd/settings/secrets/actions

Click "New repository secret" and add:

```
Name: DOCKER_USERNAME
Value: your-dockerhub-username

Name: DOCKER_TOKEN  
Value: your-dockerhub-access-token

Name: SERVER_HOST
Value: 161.118.236.136

Name: SERVER_USER
Value: ubuntu

Name: SERVER_SSH_KEY
Value: (paste entire content of connect-oracle.key file)
```

**Step 3: Push to GitHub**
```bash
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd

git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/shfahiim/cicd.git
git branch -M main
git push -u origin main
```

**Step 4: Watch the Magic!**
- Go to https://github.com/shfahiim/cicd/actions
- You'll see your workflow running
- Click on it to see detailed logs

---

## 8. Server Deployment

### Step 1: Connect to Server

```bash
# Make sure key has correct permissions
chmod 400 connect-oracle.key

# Connect
ssh -i connect-oracle.key ubuntu@161.118.236.136
```

### Step 2: Install Docker on Server

```bash
# Update system
sudo apt-get update

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker ubuntu

# Log out and log back in
exit
ssh -i connect-oracle.key ubuntu@161.118.236.136

# Verify
docker --version
```

### Step 3: Create Application Directory

```bash
# Create directory
mkdir -p ~/microservices-app
cd ~/microservices-app
```

### Step 4: Create docker-compose.yml

**Important:** Replace `YOUR_DOCKERHUB_USERNAME` with your actual Docker Hub username!

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
```

### Step 5: First Manual Deploy

```bash
cd ~/microservices-app

# Start MongoDB first
docker compose up -d mongodb

# Wait 10 seconds
sleep 10

# Start all services
docker compose up -d

# Check status
docker ps
```

### Step 6: Verify Deployment

```bash
# Check logs
docker logs user-service
docker logs product-service
docker logs order-service

# Test services
curl http://localhost:3001/health
curl http://localhost:3002/health
curl http://localhost:3003/health
```

---

## 9. Testing and Validation

### From Your Local Machine

Test the production server:

```bash
SERVER_IP="161.118.236.136"

# Health checks
curl http://${SERVER_IP}:3001/health
curl http://${SERVER_IP}:3002/health
curl http://${SERVER_IP}:3003/health

# Create a user
curl -X POST http://${SERVER_IP}:3001/users \
  -H "Content-Type: application/json" \
  -d '{"name":"Production User","email":"prod@example.com"}'
```

### Using the Test Script

```bash
# From your local machine
cd /home/fahim/Desktop/devops-cuet/microservice-ci-cd
./test-api.sh 161.118.236.136
```

### Understanding Test Results

**✅ Green** = Success
**❌ Red** = Failed
**⚠️ Yellow** = Warning

---

## 10. Common Issues and Solutions

### Issue 1: Docker command not found

**Problem:** `docker: command not found`

**Solution:**
```bash
# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Log out and back in
```

### Issue 2: Permission denied on Docker

**Problem:** `permission denied while trying to connect to Docker`

**Solution:**
```bash
sudo usermod -aG docker $USER
# Log out and back in
```

### Issue 3: Port already in use

**Problem:** `port is already allocated`

**Solution:**
```bash
# Find what's using the port
sudo netstat -tulpn | grep 3001

# Kill it
sudo kill -9 <PID>

# OR use different ports in docker-compose.yml
```

### Issue 4: Services not communicating

**Problem:** Order service can't reach User/Product service

**Solution:**
```bash
# Check all containers are on same network
docker network inspect microservices-network

# Restart services
docker compose restart
```

### Issue 5: MongoDB connection failed

**Problem:** `MongoServerError: connection refused`

**Solution:**
```bash
# Check MongoDB is running
docker ps | grep mongodb

# Check MongoDB logs
docker logs mongodb

# Restart MongoDB
docker restart mongodb

# Wait and restart services
docker compose restart
```

### Issue 6: GitHub Actions failing

**Problem:** Workflow fails in GitHub Actions

**Solutions:**

**Check Docker Hub credentials:**
- Verify DOCKER_USERNAME secret
- Verify DOCKER_TOKEN is valid
- Check Docker Hub repositories exist

**Check SSH connection:**
- Verify SERVER_SSH_KEY is complete (including BEGIN and END lines)
- Test SSH: `ssh -i connect-oracle.key ubuntu@161.118.236.136`

**Check Docker Hub image names:**
```yaml
# In docker-compose.yml on server
# Should match: YOUR_DOCKERHUB_USERNAME/service-name:latest
```

### Issue 7: Services start but return 500 errors

**Problem:** Services are running but APIs return errors

**Solution:**
```bash
# Check service logs
docker logs user-service
docker logs product-service
docker logs order-service

# Usually it's a MongoDB connection issue
# Check MONGODB_URI environment variable
docker inspect user-service | grep MONGODB_URI
```

---

## 🎓 Learning Exercises

### Exercise 1: Add a New Endpoint
Add a `GET /users/count` endpoint to User Service that returns the total number of users.

<details>
<summary>Solution</summary>

```javascript
// In user-service/server.js
app.get('/users/count', async (req, res) => {
  try {
    const count = await User.countDocuments();
    res.json({
      success: true,
      count: count
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});
```
</details>

### Exercise 2: Add Email Validation
Add validation to ensure emails are in correct format when creating users.

<details>
<summary>Solution</summary>

```javascript
// In user-service/server.js
app.post('/users', async (req, res) => {
  try {
    const { name, email } = req.body;
    
    // Email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }
    
    // ... rest of the code
  }
});
```
</details>

### Exercise 3: Add Logging
Add timestamp logging to all API requests.

<details>
<summary>Solution</summary>

```javascript
// Add middleware in server.js
app.use((req, res, next) => {
  console.log(`[${new Date().toISOString()}] ${req.method} ${req.path}`);
  next();
});
```
</details>

---

## 🚀 Next Steps

Now that you understand the basics:

1. **Add Authentication**: Implement JWT tokens
2. **Add Tests**: Write unit tests with Jest
3. **Add Monitoring**: Set up Prometheus + Grafana
4. **Add API Gateway**: Use nginx for routing
5. **Add Rate Limiting**: Protect against abuse
6. **Add Caching**: Use Redis for performance
7. **Add Load Balancing**: Scale horizontally

---

## 📖 Additional Resources

- **Docker Tutorial**: https://docs.docker.com/get-started/
- **MongoDB Basics**: https://www.mongodb.com/basics
- **Node.js Best Practices**: https://github.com/goldbergyoni/nodebestpractices
- **GitHub Actions Docs**: https://docs.github.com/en/actions
- **Microservices Pattern**: https://microservices.io/

---

## 💡 Key Takeaways

✅ **Microservices** = Small, independent services
✅ **Docker** = Package your app with all dependencies
✅ **CI/CD** = Automate testing and deployment
✅ **GitHub Actions** = Free CI/CD platform
✅ **Inter-service communication** = Services talk via HTTP
✅ **Docker Compose** = Run multiple containers together

---

## ❓ Need Help?

If you're stuck:

1. Check the logs: `docker logs <container-name>`
2. Review this tutorial again
3. Check SETUP.md for detailed steps
4. Check CHEATSHEET.md for quick commands
5. Google the error message
6. Ask on Stack Overflow

**Remember:** Everyone starts somewhere. Keep experimenting and learning! 🎓

---

Happy Learning! 🚀

Made with ❤️ for DevOps learners
