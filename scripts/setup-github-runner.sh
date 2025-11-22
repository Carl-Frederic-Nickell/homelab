#!/bin/bash
# GitHub Runner Setup Script for Synology NAS
# This script sets up a self-hosted GitHub Actions runner on Synology DSM

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  GitHub Runner Setup for Synology NAS${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then
  echo -e "${RED}Error: Do not run this script as root${NC}"
  exit 1
fi

# Prerequisites check
echo -e "${YELLOW}Checking prerequisites...${NC}"

# Check Docker
if ! command -v docker &> /dev/null; then
  echo -e "${RED}Error: Docker is not installed${NC}"
  echo "Please install Docker from Synology Package Center first"
  exit 1
fi

echo -e "${GREEN}✓ Docker found${NC}"

# Check Docker Compose
if ! command -v docker-compose &> /dev/null; then
  echo -e "${RED}Error: Docker Compose is not installed${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Docker Compose found${NC}"

# Get GitHub runner token
echo ""
echo -e "${YELLOW}GitHub Runner Setup${NC}"
echo ""
echo "To get your GitHub runner token:"
echo "1. Go to: https://github.com/Carl-Frederic-Nickell/homelab/settings/actions/runners/new"
echo "2. Select 'Linux' as the operating system"
echo "3. Copy the token from the './config.sh' command"
echo ""
read -p "Enter your GitHub runner token: " RUNNER_TOKEN

if [ -z "$RUNNER_TOKEN" ]; then
  echo -e "${RED}Error: Token cannot be empty${NC}"
  exit 1
fi

# Create runner directory
RUNNER_DIR="/volume2/docker/github-runner"
echo ""
echo -e "${YELLOW}Creating runner directory: $RUNNER_DIR${NC}"
mkdir -p "$RUNNER_DIR"
cd "$RUNNER_DIR"

# Download GitHub Actions runner
echo -e "${YELLOW}Downloading GitHub Actions runner...${NC}"

RUNNER_VERSION="2.311.0"  # Update this to latest version
RUNNER_FILE="actions-runner-linux-x64-${RUNNER_VERSION}.tar.gz"

if [ ! -f "$RUNNER_FILE" ]; then
  curl -O -L "https://github.com/actions/runner/releases/download/v${RUNNER_VERSION}/${RUNNER_FILE}"
fi

# Extract runner
echo -e "${YELLOW}Extracting runner...${NC}"
tar xzf "$RUNNER_FILE"

# Configure runner
echo -e "${YELLOW}Configuring runner...${NC}"
./config.sh --url https://github.com/Carl-Frederic-Nickell/homelab \
            --token "$RUNNER_TOKEN" \
            --name "synology-nas-runner" \
            --work "_work" \
            --labels "self-hosted,linux,synology" \
            --unattended

# Create systemd service (for Linux) or startup script for Synology
echo -e "${YELLOW}Creating startup script...${NC}"

cat > "${RUNNER_DIR}/start-runner.sh" << 'EOF'
#!/bin/bash
# GitHub Runner Startup Script

RUNNER_DIR="/volume2/docker/github-runner"

cd "$RUNNER_DIR"
./run.sh &

echo "GitHub Runner started"
EOF

chmod +x "${RUNNER_DIR}/start-runner.sh"

# Create stop script
cat > "${RUNNER_DIR}/stop-runner.sh" << 'EOF'
#!/bin/bash
# GitHub Runner Stop Script

RUNNER_DIR="/volume2/docker/github-runner"

# Find and kill runner process
pkill -f "Runner.Listener"

echo "GitHub Runner stopped"
EOF

chmod +x "${RUNNER_DIR}/stop-runner.sh"

# Test runner
echo ""
echo -e "${GREEN}==================================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}==================================================${NC}"
echo ""
echo "Runner installed at: $RUNNER_DIR"
echo ""
echo -e "${YELLOW}To start the runner:${NC}"
echo "  $RUNNER_DIR/start-runner.sh"
echo ""
echo -e "${YELLOW}To stop the runner:${NC}"
echo "  $RUNNER_DIR/stop-runner.sh"
echo ""
echo -e "${YELLOW}To make runner start on boot (Synology DSM):${NC}"
echo "1. Go to Control Panel → Task Scheduler"
echo "2. Create → Triggered Task → User-defined script"
echo "3. Task: 'Start GitHub Runner'"
echo "4. Event: Boot-up"
echo "5. Task Settings → User-defined script:"
echo "   $RUNNER_DIR/start-runner.sh"
echo ""
echo -e "${GREEN}Starting runner now...${NC}"
"$RUNNER_DIR/start-runner.sh"

sleep 5

# Check if runner is running
if pgrep -f "Runner.Listener" > /dev/null; then
  echo -e "${GREEN}✓ Runner is running!${NC}"
  echo ""
  echo "Check status at: https://github.com/Carl-Frederic-Nickell/homelab/settings/actions/runners"
else
  echo -e "${RED}⚠ Runner may not be running properly${NC}"
  echo "Check logs at: $RUNNER_DIR/_diag/"
fi

echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Verify runner appears in GitHub (link above)"
echo "2. Rename .github/workflows/deploy-production.yml.disabled to .yml"
echo "3. Push to GitHub to trigger deployment"
