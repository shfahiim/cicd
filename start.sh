#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║   Microservices Quick Start Script    ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! docker compose version &> /dev/null; then
    echo -e "${YELLOW}⚠️  Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Docker is installed${NC}"
echo -e "${GREEN}✓ Docker Compose is installed${NC}"
echo ""

# Check if we're in the right directory
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${YELLOW}⚠️  docker-compose.yml not found. Are you in the project root?${NC}"
    exit 1
fi

echo -e "${BLUE}Starting all services...${NC}"
echo ""

# Start services
docker compose up -d

# Wait for services to be ready
echo ""
echo -e "${YELLOW}Waiting for services to be ready...${NC}"
sleep 10

# Check service health
echo ""
echo -e "${BLUE}Checking service health...${NC}"
echo ""

check_service() {
    local service=$1
    local port=$2
    local url="http://localhost:${port}/health"
    
    if curl -s -f ${url} > /dev/null 2>&1; then
        echo -e "${GREEN}✓ ${service} is healthy (port ${port})${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  ${service} is not responding yet (port ${port})${NC}"
        return 1
    fi
}

check_service "User Service" 3001
check_service "Order Service" 3002
check_service "Product Service" 3003

echo ""
echo -e "${BLUE}Container Status:${NC}"
docker compose ps

echo ""
echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║     Services are up and running!       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}Service URLs:${NC}"
echo "  • User Service:    http://localhost:3001"
echo "  • Order Service:   http://localhost:3002"
echo "  • Product Service: http://localhost:3003"
echo ""
echo -e "${BLUE}Quick Commands:${NC}"
echo "  • View logs:       docker compose logs -f"
echo "  • Stop services:   docker compose down"
echo "  • Restart:         docker compose restart"
echo "  • Run API tests:   ./test-api.sh"
echo ""
echo -e "${YELLOW}📚 For more information, see:${NC}"
echo "  • README.md for overview"
echo "  • SETUP.md for detailed setup"
echo "  • API_TESTING.md for API examples"
echo "  • ARCHITECTURE.md for system design"
