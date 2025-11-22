#!/bin/bash
# Health Check Script for All Homelab Services
# Usage: ./health-check.sh [service_name]

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

HOMELAB_DIR="/volume2/docker/homelab"
SERVICE_NAME="$1"

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  Homelab Health Check${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Function to check a single service
check_service() {
  local service_dir="$1"
  local service_name=$(basename "$service_dir")

  if [ ! -f "$service_dir/docker-compose.yml" ]; then
    return
  fi

  cd "$service_dir"

  local containers=$(docker-compose ps -q 2>/dev/null)

  if [ -z "$containers" ]; then
    echo -e "${YELLOW}⚠ $service_name${NC}: No containers running"
    return
  fi

  echo -e "${BLUE}$service_name:${NC}"

  local all_healthy=true

  for container in $containers; do
    local status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
    local health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown")
    local name=$(docker inspect --format='{{.Name}}' "$container" 2>/dev/null | sed 's/^\/*//')
    local uptime=$(docker inspect --format='{{.State.StartedAt}}' "$container" 2>/dev/null)

    # Calculate uptime in human-readable format
    if [ "$status" = "running" ]; then
      local start_seconds=$(date -d "$uptime" +%s 2>/dev/null || date -j -f "%Y-%m-%dT%H:%M:%S" "${uptime%%.*}" +%s 2>/dev/null || echo "0")
      local current_seconds=$(date +%s)
      local uptime_seconds=$((current_seconds - start_seconds))
      local uptime_human="unknown"

      if [ "$uptime_seconds" -gt 0 ]; then
        local days=$((uptime_seconds / 86400))
        local hours=$(((uptime_seconds % 86400) / 3600))
        local minutes=$(((uptime_seconds % 3600) / 60))

        if [ "$days" -gt 0 ]; then
          uptime_human="${days}d ${hours}h"
        elif [ "$hours" -gt 0 ]; then
          uptime_human="${hours}h ${minutes}m"
        else
          uptime_human="${minutes}m"
        fi
      fi
    else
      uptime_human="N/A"
    fi

    # Determine status icon and message
    if [ "$status" = "running" ]; then
      if [ "$health" = "healthy" ]; then
        echo -e "  ${GREEN}✓${NC} $name: $status (healthy) - up $uptime_human"
      elif [ "$health" = "no-healthcheck" ]; then
        echo -e "  ${GREEN}✓${NC} $name: $status (no healthcheck) - up $uptime_human"
      elif [ "$health" = "starting" ]; then
        echo -e "  ${YELLOW}⟳${NC} $name: $status (starting) - up $uptime_human"
        all_healthy=false
      else
        echo -e "  ${RED}✗${NC} $name: $status ($health) - up $uptime_human"
        all_healthy=false
      fi
    else
      echo -e "  ${RED}✗${NC} $name: $status"
      all_healthy=false
    fi

    # Show restart count if > 0
    local restart_count=$(docker inspect --format='{{.RestartCount}}' "$container" 2>/dev/null || echo "0")
    if [ "$restart_count" -gt 0 ]; then
      echo -e "    ${YELLOW}⚠ Restart count: $restart_count${NC}"
    fi
  done

  echo ""
}

# Check specific service or all services
if [ -n "$SERVICE_NAME" ]; then
  SERVICE_DIR="$HOMELAB_DIR/$SERVICE_NAME"

  if [ ! -d "$SERVICE_DIR" ]; then
    echo -e "${RED}Error: Service not found: $SERVICE_NAME${NC}"
    exit 1
  fi

  check_service "$SERVICE_DIR"
else
  # Check all services
  for service_dir in "$HOMELAB_DIR"/*/; do
    check_service "$service_dir"
  done
fi

# Summary
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  System Resources${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Docker info
echo -e "${BLUE}Docker:${NC}"
if command -v docker &> /dev/null; then
  RUNNING_CONTAINERS=$(docker ps -q | wc -l)
  TOTAL_CONTAINERS=$(docker ps -aq | wc -l)
  IMAGES=$(docker images -q | wc -l)

  echo "  Running containers: $RUNNING_CONTAINERS / $TOTAL_CONTAINERS"
  echo "  Images: $IMAGES"
else
  echo "  Docker not available"
fi

echo ""

# Disk usage (if df available)
if command -v df &> /dev/null; then
  echo -e "${BLUE}Disk Usage:${NC}"
  df -h /volume2 2>/dev/null | tail -1 | awk '{print "  " $5 " used (" $3 " / " $2 ")"}'
fi

echo ""

# Memory usage (if free available)
if command -v free &> /dev/null; then
  echo -e "${BLUE}Memory Usage:${NC}"
  free -h | grep Mem | awk '{print "  " $3 " / " $2 " (" int($3/$2 * 100) "%)"}'
fi

echo ""
echo "Check completed: $(date)"
