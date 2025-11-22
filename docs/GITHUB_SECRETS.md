# GitHub Secrets Configuration

This document describes the GitHub Secrets required for the CI/CD pipelines.

## Required Secrets

### Network Configuration

| Secret Name | Description | Example Value |
|------------|-------------|---------------|
| `NAS_IP` | IP address of Synology NAS | `192.168.1.100` |
| `HA_IP` | IP address of Home Assistant | `192.168.1.101` |

### Database Credentials

| Secret Name | Description |
|------------|-------------|
| `POSTGRES_PASSWORD` | PostgreSQL database password |
| `MYSQL_ROOT_PASSWORD` | MySQL root password |
| `MYSQL_PASSWORD` | MySQL user password |

### Application Secrets

| Secret Name | Description |
|------------|-------------|
| `JWT_SECRET` | JWT signing secret for authentication |
| `NEXTAUTH_SECRET` | NextAuth.js secret |
| `GRAFANA_ADMIN_PASSWORD` | Grafana admin password |

### API Keys

| Secret Name | Description |
|------------|-------------|
| `OPENWEATHER_API_KEY` | OpenWeather API key for weather data |

### General Configuration

| Secret Name | Description | Default Value |
|------------|-------------|---------------|
| `TZ` | Timezone | `Europe/Berlin` |
| `DOCKER_DIR` | Docker data directory | `/volume2/docker` |

## How to Add Secrets

1. Go to your GitHub repository
2. Navigate to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Enter the secret name and value
5. Click **Add secret**

## Security Best Practices

- **Never commit** `.env` files to the repository
- **Rotate secrets** regularly (every 90 days recommended)
- **Use strong passwords**: Minimum 16 characters with mix of uppercase, lowercase, numbers, and special characters
- **Limit access**: Only grant access to secrets when necessary
- **Audit regularly**: Review who has access to secrets

## Using Secrets in GitHub Actions

Secrets are accessed in workflows using the `secrets` context:

```yaml
steps:
  - name: Deploy to NAS
    env:
      NAS_IP: ${{ secrets.NAS_IP }}
      GRAFANA_PASSWORD: ${{ secrets.GRAFANA_ADMIN_PASSWORD }}
    run: |
      echo "Deploying to $NAS_IP"
```

## Local Development

For local development, copy `.env.example` to `.env` and fill in your values:

```bash
cp .env.example .env
nano .env
```

The `.env` file is ignored by git and will not be committed.
