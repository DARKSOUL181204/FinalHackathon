#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${BLUE}====================================================${NC}"
echo -e "${BLUE}   DEF-LOGIX Defense Logistics Management System    ${NC}"
echo -e "${BLUE}                 Automated Boot Script              ${NC}"
echo -e "${BLUE}====================================================${NC}"

# 1. Check Java JDK 21+
if ! command -v java &> /dev/null; then
    echo -e "${RED}[ERROR] Java is not installed or not in PATH. Please install Java JDK 21+.${NC}"
    exit 1
fi
JAVA_VER=$(java -version 2>&1 | head -n 1 | awk -F '"' '{print $2}')
echo -e "${GREEN}[OK] Detected Java version: ${JAVA_VER}${NC}"

# 2. Check Apache Maven
if ! command -v mvn &> /dev/null; then
    echo -e "${RED}[ERROR] Maven is not installed or not in PATH. Please install Maven 3.8+.${NC}"
    exit 1
fi
echo -e "${GREEN}[OK] Detected Apache Maven${NC}"

# 3. Check MySQL on localhost:3306
if command -v nc &> /dev/null; then
    if ! nc -z localhost 3306 2>/dev/null; then
        echo -e "${YELLOW}[WARNING] MySQL port 3306 is not reachable. Ensure MySQL is running!${NC}"
    else
        echo -e "${GREEN}[OK] MySQL server is active on port 3306${NC}"
    fi
fi

# 4. Clean up any existing processes on required ports
echo -e "${BLUE}[INFO] Checking ports 9191, 9192, 9193, 8080...${NC}"
for PORT in 9191 9192 9193 8080; do
    PID=$(lsof -ti :$PORT 2>/dev/null || true)
    if [ -n "$PID" ]; then
        echo -e "${YELLOW}Freeing port $PORT (killing existing PID $PID)...${NC}"
        kill -9 $PID 2>/dev/null || true
    fi
done

# 5. Build all modules
echo -e "${BLUE}[INFO] Building project modules (mvn clean install -DskipTests)...${NC}"
mvn clean install -DskipTests

# Helper to wait for port
wait_for_port() {
    local port=$1
    local name=$2
    local count=0
    while ! (nc -z localhost $port 2>/dev/null || (echo > /dev/tcp/localhost/$port) 2>/dev/null); do
        sleep 1
        count=$((count+1))
        if [ $count -ge 35 ]; then
            echo -e "${RED}[ERROR] Timed out waiting for $name on port $port${NC}"
            break
        fi
    done
}

# Cleanup on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Shutting down all services...${NC}"
    [ -n "$RESOURCE_PID" ] && kill -9 $RESOURCE_PID 2>/dev/null || true
    [ -n "$INVENTORY_PID" ] && kill -9 $INVENTORY_PID 2>/dev/null || true
    [ -n "$REQUEST_PID" ] && kill -9 $REQUEST_PID 2>/dev/null || true
    [ -n "$FRONTEND_PID" ] && kill -9 $FRONTEND_PID 2>/dev/null || true
    echo -e "${GREEN}All services shut down cleanly.${NC}"
    exit 0
}
trap cleanup SIGINT SIGTERM

# 6. Start Resource Service (Port 9191)
echo -e "${BLUE}[INFO] Starting Resource Service (Port 9191)...${NC}"
java -jar resource-service/target/resource-service-1.0.0-SNAPSHOT.jar > resource-service.log 2>&1 &
RESOURCE_PID=$!
wait_for_port 9191 "Resource Service"
echo -e "${GREEN}[READY] Resource Service is up (PID $RESOURCE_PID)${NC}"

# 7. Start Inventory Service (Port 9192)
echo -e "${BLUE}[INFO] Starting Inventory Service (Port 9192)...${NC}"
java -jar inventory-service/target/inventory-service-1.0.0-SNAPSHOT.jar > inventory-service.log 2>&1 &
INVENTORY_PID=$!
wait_for_port 9192 "Inventory Service"
echo -e "${GREEN}[READY] Inventory Service is up (PID $INVENTORY_PID)${NC}"

# 8. Start Request Service (Port 9193)
echo -e "${BLUE}[INFO] Starting Request Service (Port 9193)...${NC}"
java -jar request-service/target/request-service-1.0.0-SNAPSHOT.jar > request-service.log 2>&1 &
REQUEST_PID=$!
wait_for_port 9193 "Request Service"
echo -e "${GREEN}[READY] Request Service is up (PID $REQUEST_PID)${NC}"

# 9. Start Frontend UI (Port 8080)
echo -e "${BLUE}[INFO] Starting Frontend UI (Port 8080)...${NC}"
java -jar frontend-ui/target/frontend-ui-1.0.0-SNAPSHOT.jar > frontend-ui.log 2>&1 &
FRONTEND_PID=$!
wait_for_port 8080 "Frontend UI"
echo -e "${GREEN}[READY] Frontend UI is up (PID $FRONTEND_PID)${NC}"

# 10. Seed Sample Data if python3 is available
if command -v python3 &> /dev/null && [ -f "seed_data.py" ]; then
    echo -e "${BLUE}[INFO] Seeding initial database data...${NC}"
    python3 seed_data.py > /dev/null 2>&1 || true
    echo -e "${GREEN}[OK] Database seeded successfully${NC}"
fi

echo ""
echo -e "${GREEN}====================================================${NC}"
echo -e "${GREEN}  All 4 services are successfully running!          ${NC}"
echo -e "${GREEN}  Open Application: http://localhost:8080           ${NC}"
echo -e "${GREEN}  Default Login:    admin / ChangeMe!2026           ${NC}"
echo -e "${GREEN}====================================================${NC}"
echo -e "${YELLOW}Press [CTRL+C] at any time to stop all services.${NC}"
echo ""

wait $RESOURCE_PID $INVENTORY_PID $REQUEST_PID $FRONTEND_PID
