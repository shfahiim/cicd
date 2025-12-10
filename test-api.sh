#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Server details (change these to your server IP)
SERVER_IP="${1:-161.118.236.136}"

echo -e "${YELLOW}🧪 Testing Microservices API${NC}"
echo "================================="
echo ""

# Function to make API calls
make_request() {
    local method=$1
    local url=$2
    local data=$3
    local description=$4
    
    echo -e "${YELLOW}Testing: ${description}${NC}"
    echo "URL: ${url}"
    
    if [ -z "$data" ]; then
        response=$(curl -s -w "\n%{http_code}" -X ${method} ${url})
    else
        response=$(curl -s -w "\n%{http_code}" -X ${method} ${url} \
            -H "Content-Type: application/json" \
            -d "${data}")
    fi
    
    http_code=$(echo "$response" | tail -n1)
    body=$(echo "$response" | head -n-1)
    
    if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
        echo -e "${GREEN}✓ Success (HTTP ${http_code})${NC}"
        echo "Response: ${body}"
    else
        echo -e "${RED}✗ Failed (HTTP ${http_code})${NC}"
        echo "Response: ${body}"
    fi
    echo ""
}

# Health checks
echo -e "${YELLOW}=== Health Checks ===${NC}"
make_request "GET" "http://${SERVER_IP}:3002/health" "" "User Service Health"
make_request "GET" "http://${SERVER_IP}:3003/health" "" "Order Service Health"
make_request "GET" "http://${SERVER_IP}:3004/health" "" "Product Service Health"

# Create a user
echo -e "${YELLOW}=== User Service Tests ===${NC}"
user_response=$(curl -s -X POST http://${SERVER_IP}:3002/users \
    -H "Content-Type: application/json" \
    -d '{"name":"Test User","email":"test@example.com"}')

user_id=$(echo $user_response | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$user_id" ]; then
    echo -e "${GREEN}✓ User created with ID: ${user_id}${NC}"
else
    echo -e "${YELLOW}Note: User might already exist, trying to fetch existing users...${NC}"
fi
echo ""

make_request "GET" "http://${SERVER_IP}:3002/users" "" "Get All Users"

# Create a product
echo -e "${YELLOW}=== Product Service Tests ===${NC}"
product_response=$(curl -s -X POST http://${SERVER_IP}:3004/products \
    -H "Content-Type: application/json" \
    -d '{"name":"Test Laptop","price":1299.99,"stock":50,"description":"A powerful laptop"}')

product_id=$(echo $product_response | grep -o '"_id":"[^"]*"' | cut -d'"' -f4)

if [ ! -z "$product_id" ]; then
    echo -e "${GREEN}✓ Product created with ID: ${product_id}${NC}"
else
    echo -e "${YELLOW}Note: Fetching existing products...${NC}"
fi
echo ""

make_request "GET" "http://${SERVER_IP}:3004/products" "" "Get All Products"

# Get actual IDs if creation failed
if [ -z "$user_id" ]; then
    users=$(curl -s http://${SERVER_IP}:3002/users)
    user_id=$(echo $users | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

if [ -z "$product_id" ]; then
    products=$(curl -s http://${SERVER_IP}:3004/products)
    product_id=$(echo $products | grep -o '"_id":"[^"]*"' | head -1 | cut -d'"' -f4)
fi

# Create an order (with inter-service communication)
echo -e "${YELLOW}=== Order Service Tests (Inter-service Communication) ===${NC}"
if [ ! -z "$user_id" ] && [ ! -z "$product_id" ]; then
    make_request "POST" "http://${SERVER_IP}:3003/orders" \
        "{\"userId\":\"${user_id}\",\"productId\":\"${product_id}\",\"quantity\":2}" \
        "Create Order (validates user & product via inter-service calls)"
else
    echo -e "${RED}✗ Cannot create order: Missing user_id or product_id${NC}"
    echo ""
fi

make_request "GET" "http://${SERVER_IP}:3003/orders" "" "Get All Orders"

echo -e "${GREEN}==================================${NC}"
echo -e "${GREEN}✓ API Testing Complete!${NC}"
echo ""
echo "To run this script: ./test-api.sh [server_ip]"
echo "Example: ./test-api.sh 161.118.236.136"
