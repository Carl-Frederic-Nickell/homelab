#!/bin/bash
# Manual Service Deployment Script for Synology NAS
# Usage: ./deploy-service.sh <service_name>

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

SERVICE_NAME="$1"
HOMELAB_DIR="/volume2/docker/homelab"
BACKUP_DIR="/volume2/docker/backups"

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  Service Deployment: $SERVICE_NAME${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Validate service name
if [ -z "$SERVICE_NAME" ]; then
  echo -e "${RED}Error: Service name required${NC}"
  echo "Usage: $0 <service_name>"
  echo ""
  echo "Available services:"
  ls -d "$HOMELAB_DIR"/*/ 2>/dev/null | xargs -n1 basename || echo "  (run from NAS to see available services)"
  exit 1
fi

SERVICE_DIR="$HOMELAB_DIR/$SERVICE_NAME"

if [ ! -d "$SERVICE_DIR" ]; then
  echo -e "${RED}Error: Service directory not found: $SERVICE_DIR${NC}"
  exit 1
fi

if [ ! -f "$SERVICE_DIR/docker-compose.yml" ]; then
  echo -e "${RED}Error: docker-compose.yml not found in $SERVICE_DIR${NC}"
  exit 1
fi

# Check for .env file
if [ ! -f "$HOMELAB_DIR/.env" ]; then
  echo -e "${YELLOW}Warning: .env file not found at $HOMELAB_DIR/.env${NC}"
  echo "Make sure environment variables are configured!"
  read -p "Continue anyway? (y/N): " CONTINUE
  if [ "$CONTINUE" != "y" ] && [ "$CONTINUE" != "Y" ]; then
    exit 1
  fi
fi

# Create backup
echo -e "${YELLOW}Creating backup...${NC}"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_PATH="$BACKUP_DIR/${SERVICE_NAME}_${TIMESTAMP}.tar.gz"

mkdir -p "$BACKUP_DIR"

if docker-compose -f "$SERVICE_DIR/docker-compose.yml" ps -q | grep -q .; then
  cd "$SERVICE_DIR"
  tar -czf "$BACKUP_PATH" -C "$HOMELAB_DIR" "$SERVICE_NAME" 2>/dev/null || echo "  (no existing data to backup)"
  echo -e "${GREEN}✓ Backup created: $BACKUP_PATH${NC}"
else
  echo -e "${YELLOW}  No running containers, skipping backup${NC}"
fi

# Pull latest images
echo ""
echo -e "${YELLOW}Pulling latest images...${NC}"
cd "$SERVICE_DIR"
docker-compose pull || echo -e "${YELLOW}  Some images could not be pulled${NC}"

# Deploy service
echo ""
echo -e "${YELLOW}Deploying $SERVICE_NAME...${NC}"
if docker-compose up -d; then
  echo -e "${GREEN}✓ Service deployed successfully${NC}"
else
  echo -e "${RED}✗ Deployment failed${NC}"

  # Offer rollback
  if [ -f "$BACKUP_PATH" ]; then
    echo ""
    read -p "Rollback to previous version? (y/N): " ROLLBACK
    if [ "$ROLLBACK" = "y" ] || [ "$ROLLBACK" = "Y" ]; then
      echo -e "${YELLOW}Rolling back...${NC}"
      docker-compose down || true
      tar -xzf "$BACKUP_PATH" -C "$HOMELAB_DIR"
      docker-compose up -d
      echo -e "${GREEN}✓ Rollback complete${NC}"
    fi
  fi

  exit 1
fi

# Health check
echo ""
echo -e "${YELLOW}Waiting for service to start (30s)...${NC}"
sleep 30

echo ""
echo -e "${YELLOW}Health check:${NC}"
CONTAINERS=$(docker-compose ps -q)

ALL_HEALTHY=true
for container in $CONTAINERS; do
  STATUS=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")
  HEALTH=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}no-healthcheck{{end}}' "$container" 2>/dev/null || echo "unknown")
  CONTAINER_NAME=$(docker inspect --format='{{.Name}}' "$container" 2>/dev/null | sed 's/^\/*//')

  if [ "$STATUS" = "running" ]; then
    if [ "$HEALTH" = "healthy" ] || [ "$HEALTH" = "no-healthcheck" ]; then
      echo -e "  ${GREEN}✓${NC} $CONTAINER_NAME: $STATUS ($HEALTH)"
    else
      echo -e "  ${YELLOW}⚠${NC} $CONTAINER_NAME: $STATUS ($HEALTH)"
      ALL_HEALTHY=false
    fi
  else
    echo -e "  ${RED}✗${NC} $CONTAINER_NAME: $STATUS"
    ALL_HEALTHY=false
  fi
done

echo ""
if [ "$ALL_HEALTHY" = true ]; then
  echo -e "${GREEN}==================================================${NC}"
  echo -e "${GREEN}  Deployment Complete - All Containers Healthy${NC}"
  echo -e "${GREEN}==================================================${NC}"
else
  echo -e "${YELLOW}==================================================${NC}"
  echo -e "${YELLOW}  Deployment Complete - Check Container Status${NC}"
  echo -e "${YELLOW}==================================================${NC}"
  echo ""
  echo "Check logs with:"
  echo "  cd $SERVICE_DIR"
  echo "  docker-compose logs -f"
fi

echo ""
echo "View running containers:"
echo "  docker-compose ps"
echo ""
echo "Stop service:"
echo "  docker-compose down"
