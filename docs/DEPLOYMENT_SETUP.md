# Phase 2: Deployment Automation Setup Guide

This guide explains how to set up automated deployment for your homelab infrastructure using GitHub Actions and a self-hosted runner on your Synology NAS.

## Overview

The deployment automation consists of:
- **Self-hosted GitHub Actions runner** on Synology NAS
- **Automated deployment workflow** triggered by git pushes
- **Security gate** to prevent deploying vulnerable services
- **Automatic backup** before deployments
- **Health checks** after deployment
- **Automatic rollback** on failure

## Prerequisites

Before starting, ensure you have:

1. **Synology NAS with SSH access**
   - SSH enabled in Control Panel → Terminal & SNMP
   - Your SSH login credentials

2. **Docker & Docker Compose installed**
   - Available in Synology Package Center
   - Both should be running

3. **Repository cloned on NAS**
   - Homelab repository at `/volume2/docker/homelab`
   - `.env` file configured with all required environment variables

4. **GitHub Personal Access Token**
   - With `repo` and `workflow` permissions
   - Token will be generated during runner setup

## Step 1: Prepare Your NAS

### 1.1 Connect to Your NAS

```bash
ssh your-username@your-nas-ip
# or use Quick Connect
```

### 1.2 Verify Docker Installation

```bash
docker --version
docker-compose --version
```

Expected output:
```
Docker version 20.x.x or higher
docker-compose version 2.x.x or higher
```

### 1.3 Clone Repository (if not already done)

```bash
cd /volume2/docker
git clone https://github.com/Carl-Frederic-Nickell/homelab.git
cd homelab
```

### 1.4 Configure Environment Variables

```bash
cd /volume2/docker/homelab
cp .env.example .env
nano .env
```

Fill in all required values:
- Network IPs (NAS_IP, HA_IP, OLLAMA_HOST)
- Database passwords
- API keys
- Service-specific credentials

**Important**: Never commit the `.env` file to git!

## Step 2: Set Up GitHub Self-Hosted Runner

### 2.1 Get GitHub Runner Token

1. Go to: https://github.com/Carl-Frederic-Nickell/homelab/settings/actions/runners/new
2. Select **Linux** as the operating system
3. Copy the token from the `./config.sh` command (starts with `A...`)
4. Keep this token ready (you'll need it in the next step)

### 2.2 Run the Runner Setup Script

On your NAS, run:

```bash
cd /volume2/docker/homelab
./scripts/setup-github-runner.sh
```

When prompted, paste your GitHub runner token.

The script will:
- Download the GitHub Actions runner
- Configure it with your repository
- Create start/stop scripts
- Start the runner

### 2.3 Verify Runner is Connected

1. Go to: https://github.com/Carl-Frederic-Nickell/homelab/settings/actions/runners
2. You should see "synology-nas-runner" with status "Idle" (green)

## Step 3: Configure Auto-Start on Boot

To ensure the runner starts automatically when your NAS boots:

### 3.1 Create Task Scheduler Entry

1. Open **Control Panel** → **Task Scheduler**
2. Create → **Triggered Task** → **User-defined script**
3. Configure:
   - **Task**: Start GitHub Runner
   - **User**: Your username (not root)
   - **Event**: Boot-up
   - **Enabled**: ✓

4. In **Task Settings** tab:
   - **User-defined script**:
     ```bash
     /volume2/docker/github-runner/start-runner.sh
     ```

5. Save the task

### 3.2 Test the Task

In Task Scheduler, select your task and click **Run**.

Verify the runner is running:
```bash
pgrep -f "Runner.Listener"
```

Should return a process ID.

## Step 4: Activate Deployment Workflow

### 4.1 Rename the Workflow File

On your local machine (in your homelab repository):

```bash
cd /Users/carl/Documents/11.\ IT,\ Security/03_Repository/homelab
mv .github/workflows/deploy-production.yml.disabled .github/workflows/deploy-production.yml
```

### 4.2 Commit and Push

```bash
git add .github/workflows/deploy-production.yml
git commit -m "Enable automated deployment workflow"
git push origin main
```

### 4.3 Verify Workflow is Active

1. Go to: https://github.com/Carl-Frederic-Nickell/homelab/actions
2. You should see "Deploy to Production" workflow listed

## Step 5: Test Deployment

### 5.1 Manual Deployment Test

Trigger a manual deployment:

1. Go to: https://github.com/Carl-Frederic-Nickell/homelab/actions
2. Select "Deploy to Production"
3. Click "Run workflow"
4. Select service to deploy (or "all")
5. Click "Run workflow"

### 5.2 Monitor Deployment

Watch the workflow execution in the Actions tab. It will:
1. Run security gate check
2. Create backup
3. Deploy services
4. Run health checks
5. Report status

### 5.3 Automatic Deployment Test

Make a small change to a service:

```bash
# Example: Update grafana config
cd grafana
nano docker-compose.yml  # Make a small change
git add docker-compose.yml
git commit -m "Update grafana configuration"
git push origin main
```

The workflow should automatically trigger and deploy only the changed service.

## Step 6: Manual Deployment Scripts (Optional)

If you need to deploy services manually, you can use the provided scripts:

### 6.1 Deploy a Single Service

```bash
ssh your-username@your-nas
cd /volume2/docker/homelab
./scripts/deploy-service.sh <service-name>

# Example:
./scripts/deploy-service.sh grafana
```

This script will:
- Create a backup
- Pull latest images
- Deploy the service
- Run health checks
- Offer rollback on failure

### 6.2 Health Check All Services

```bash
./scripts/health-check.sh

# Or check a specific service:
./scripts/health-check.sh grafana
```

## Troubleshooting

### Runner Not Starting

**Check runner status:**
```bash
cd /volume2/docker/github-runner
./run.sh
```

**Check for errors:**
```bash
cat /volume2/docker/github-runner/_diag/*.log
```

**Restart runner:**
```bash
./stop-runner.sh
./start-runner.sh
```

### Deployment Failing

**Check GitHub Actions logs:**
1. Go to repository → Actions
2. Click on failed workflow run
3. Expand failed step to see error details

**Common issues:**
- Missing environment variables in `.env` file
- Docker Compose syntax errors
- Port conflicts with existing services
- Insufficient disk space

**Check container logs on NAS:**
```bash
cd /volume2/docker/homelab/<service-name>
docker-compose logs -f
```

### Security Gate Blocking Deployment

If deployment is blocked by security gate:

1. Check the security scan results in Actions tab
2. Review critical vulnerabilities found
3. Options:
   - Update base images to newer versions
   - Adjust security gate threshold (line 71 in deploy-production.yml)
   - Fix vulnerabilities before deploying

### Rollback Not Working

**Manual rollback:**
```bash
cd /volume2/docker/backups
ls -lt  # Find your backup
tar -xzf service_name_timestamp.tar.gz -C /volume2/docker
cd /volume2/docker/homelab/service_name
docker-compose up -d
```

### Runner Lost Connection

**Reconfigure runner:**
```bash
cd /volume2/docker/github-runner
./config.sh remove --token YOUR_NEW_TOKEN
./config.sh --url https://github.com/Carl-Frederic-Nickell/homelab \
            --token YOUR_NEW_TOKEN \
            --name synology-nas-runner \
            --work _work \
            --labels self-hosted,linux,synology \
            --unattended
./start-runner.sh
```

## Security Considerations

### GitHub Runner Security

- Runner has full access to your NAS Docker environment
- Only repository admins can trigger workflows
- Review workflow changes carefully before merging
- Consider using a dedicated user account for the runner

### Environment Variables

- Never commit `.env` file to repository
- Store sensitive values in `.env` only
- GitHub Secrets are separate from NAS environment variables
- Regularly rotate credentials

### Network Security

- Keep SSH access restricted (firewall rules)
- Use key-based authentication instead of passwords
- Keep Synology DSM updated
- Monitor runner activity in GitHub Actions logs

## Advanced Configuration

### Custom Deployment Triggers

Edit `.github/workflows/deploy-production.yml` to customize triggers:

```yaml
on:
  push:
    branches: [ main ]
    paths:
      - '*/docker-compose.yml'  # Only deploy on compose changes
  schedule:
    - cron: '0 3 * * 0'  # Weekly Sunday 3 AM deployment
  workflow_dispatch:  # Manual trigger
```

### Adjust Security Gate Threshold

Edit line 71 in `deploy-production.yml`:

```yaml
if [ "$CRITICAL" -gt 5 ]; then  # Change threshold here
```

Lower number = stricter security policy

### Backup Retention

Edit line 209 in `deploy-production.yml`:

```bash
ls -t | tail -n +6 | xargs -r rm -rf  # Keep last 5 backups (change 6 to keep more)
```

### Service-Specific Deployment

Deploy only specific services by pattern:

```yaml
on:
  push:
    paths:
      - 'grafana/**'      # Only grafana
      - 'monitoring/**'   # Only monitoring services
```

## Maintenance

### Update GitHub Runner

Check for new runner versions:
https://github.com/actions/runner/releases

Update runner:
```bash
cd /volume2/docker/github-runner
./stop-runner.sh
rm -rf actions-runner-linux-x64-*.tar.gz
curl -O -L https://github.com/actions/runner/releases/download/v<VERSION>/actions-runner-linux-x64-<VERSION>.tar.gz
tar xzf actions-runner-linux-x64-<VERSION>.tar.gz
./start-runner.sh
```

### Clean Up Old Backups

```bash
cd /volume2/docker/backups
# Keep only backups from last 30 days
find . -name "*.tar.gz" -mtime +30 -delete
```

### Monitor Disk Space

```bash
df -h /volume2
docker system df  # Show Docker disk usage
docker system prune -a  # Clean up unused images (careful!)
```

## Next Steps

Once deployment automation is working:

1. **Phase 3**: Add runtime security monitoring (Falco)
2. **Phase 4**: Migrate to Kubernetes (K3s)
3. **Phase 5**: Implement GitOps with ArgoCD

## Support

**Documentation:**
- Main README: `/README.md`
- Project documentation: `/docs/PROJECT.md`
- Portfolio documentation: `/docs/PORTFOLIO_DOCUMENTATION.md`

**Issues:**
- Create GitHub issue: https://github.com/Carl-Frederic-Nickell/homelab/issues

**Logs:**
- GitHub Actions: Repository → Actions tab
- Runner logs: `/volume2/docker/github-runner/_diag/`
- Service logs: `docker-compose logs -f` in service directory
