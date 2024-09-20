#!/bin/bash

# Array of services to check, with name and URL
declare -A services=(
    ["Anvil"]="http://localhost:8545"
    ["Graph Node Query"]="http://localhost:8000"
    ["Graph Node Admin"]="http://localhost:8001"
    ["Graph Node Index Status"]="http://localhost:8020"
    ["Graph Node Subgraph Status"]="http://localhost:8030"
    ["Graph Node Metrics"]="http://localhost:8040"
    ["IPFS API"]="http://localhost:5001"
)

# Function to check a single service
check_service() {
    local name=$1
    local url=$2
    local response=$(curl -s -o /dev/null -w "%{http_code}" "$url")
    
    if [ "$response" = "000" ]; then
        echo -e "\e[91mError: $name ($url) is not responding\e[0m"
        log_error "$name" "Service not responding"
    else
        echo -e "\e[92m$name ($url) is active (HTTP $response)\e[0m"
    fi
}

# Function to check PostgreSQL
check_postgres() {
    if command -v pg_isready > /dev/null; then
        if pg_isready -h localhost -p 5432 -U graph-node > /dev/null 2>&1; then
            echo -e "\e[92mPostgreSQL is active and accepting connections\e[0m"
        else
            echo -e "\e[91mError: PostgreSQL is not accepting connections\e[0m"
            log_error "PostgreSQL" "Not accepting connections"
        fi
    else
        echo -e "\e[93mWarning: pg_isready not found. Unable to check PostgreSQL status\e[0m"
        log_error "PostgreSQL" "pg_isready not found"
    fi
}

# Function to log errors
log_error() {
    local service=$1
    local message=$2
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "$timestamp - $service: $message" >> error.log
}

# Main loop
while true; do
    echo "Checking services..."
    for name in "${!services[@]}"; do
        check_service "$name" "${services[$name]}"
        sleep 1
    done
    check_postgres
    echo -e "\e[94m-----------------------------------\e[0m"
    sleep 5
done