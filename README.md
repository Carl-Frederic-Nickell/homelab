# 🏠 Homelab - Infrastructure as Code

[![Security Scan](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/security-scan.yml/badge.svg)](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/security-scan.yml)
[![SBOM Generation](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/sbom-generation.yml/badge.svg)](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/sbom-generation.yml)
[![Policy Validation](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/policy-validation.yml/badge.svg)](https://github.com/Carl-Frederic-Nickell/homelab/actions/workflows/policy-validation.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> Production-grade homelab infrastructure with automated security scanning, container orchestration, and comprehensive monitoring.

**🔗 Quick Links**: [Project Documentation](docs/PROJECT.md) | [Security Policy](SECURITY.md) | [GitHub Secrets Guide](docs/GITHUB_SECRETS.md)

## 📊 Overview

This repository contains Docker Compose configurations and infrastructure code for my personal homelab, running on Synology NAS (DS1821+) with automated CI/CD pipelines.

### 🎯 Key Features

- **Container Orchestration**: 20+ services managed with Docker Compose
- **Security-First**: Automated vulnerability scanning and SBOM generation
- **Monitoring Stack**: Grafana, Prometheus, Loki for comprehensive observability
- **Log Management**: Graylog and Filebeat for centralized logging
- **Media Services**: Plex, Jellyfin, Paperless-ngx for document management
- **Home Automation**: Homebridge integration for Apple HomeKit
- **Network Security**: Pi-hole for DNS-level ad blocking

## 🚀 Quick Start

### Prerequisites

- Docker & Docker Compose
- Synology NAS or similar infrastructure
- Basic understanding of networking and containers

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/Carl-Frederic-Nickell/homelab.git
   cd homelab
   ```

2. **Configure environment variables**
   ```bash
   cp .env.example .env
   # Edit .env with your actual values
   nano .env
   ```

3. **Deploy a service**
   ```bash
   cd <service-name>
   docker-compose up -d
   ```

## 📂 Repository Structure

```
homelab/
├── .github/
│   └── workflows/          # CI/CD pipelines (coming soon)
├── agrar-dashboard/        # Custom agriculture dashboard
├── ansible/                # Ansible automation
├── anomaly-detector/       # ML-based anomaly detection
├── cadvisor/              # Container monitoring
├── dashy/                 # Service dashboard
├── filebeat/              # Log shipping
├── grafana/               # Metrics visualization
├── graylog/               # Log management
├── homebridge/            # Apple HomeKit bridge
├── jellyfin/              # Media server
├── loki/                  # Log aggregation
├── mariadb/               # Database
├── matomo/                # Web analytics
├── openwebui/             # AI interface
├── paperless/             # Document management
├── pihole/                # DNS ad blocker
├── plex/                  # Media server
├── portainer/             # Container management UI
├── prometheus/            # Metrics collection
├── wireshark/             # Network analysis
├── .env.example           # Environment template
├── .gitignore
├── LICENSE
├── README.md
└── SECURITY.md
```

## 🔧 Services

### Monitoring & Observability
- **Grafana** (`:3003`) - Visualization and dashboards
- **Prometheus** (`:9090`) - Metrics collection
- **Loki** (`:3100`) - Log aggregation
- **cAdvisor** (`:8070`) - Container metrics
- **Anomaly Detector** (`:5005`) - ML-based anomaly detection

### Security & Logging
- **Graylog** (`:9001`) - Centralized log management
- **Filebeat** - Log shipping agent
- **Pi-hole** (`:8080`) - DNS-level ad blocking

### Media & Documents
- **Plex** - Media library and streaming
- **Jellyfin** (`:8096`) - Open-source media server
- **Paperless-ngx** (`:8010`) - Document management system

### Infrastructure
- **Portainer** (`:9000`) - Docker management UI
- **Ansible** - Infrastructure automation
- **Matomo** (`:8597`) - Web analytics

### Home Automation
- **Homebridge** (`:8581`) - Apple HomeKit integration

### Development
- **Dashy** - Service dashboard
- **Open WebUI** (`:31000`) - AI interface
- **MariaDB** - Database services

## 🔐 Security

This homelab follows security best practices:

- All sensitive data is stored in environment variables (`.env`)
- Regular security scanning via CI/CD (implementation in progress)
- Network segmentation via Docker networks
- Security policies enforced with Open Policy Agent (planned)
- Automated SBOM generation (planned)

See [SECURITY.md](./SECURITY.md) for detailed security information.

## 🛠️ Technologies

- **Container Runtime**: Docker & Docker Compose
- **Orchestration**: Docker Compose (Kubernetes planned)
- **Monitoring**: Prometheus, Grafana, Loki
- **Logging**: Graylog, Filebeat, Promtail
- **Automation**: Ansible, GitHub Actions
- **Security**: Trivy, OPA (planned)

## 📈 Roadmap

### Phase 1: Security Foundation ✅
- [x] Implement CI/CD security scanning pipeline
- [x] Add SBOM generation for all containers
- [x] Implement Policy-as-Code with OPA
- [x] Secret scanning automation
- [x] Docker Compose validation

### Phase 2: Deployment Automation 🚧
- [ ] Set up self-hosted GitHub runner on NAS
- [ ] Automated deployment to production
- [ ] Implement rollback mechanisms
- [ ] Add deployment notifications

### Phase 3: Advanced Features 📅
- [ ] Migrate to Kubernetes (K3s)
- [ ] Add automated backup strategies
- [ ] Implement GitOps with ArgoCD
- [ ] Add automated testing framework
- [ ] Runtime security monitoring with Falco

**📊 See [Project Documentation](docs/PROJECT.md) for detailed progress and metrics.**

## 🤝 Contributing

This is a personal homelab project, but suggestions and improvements are welcome! Feel free to open an issue or submit a pull request.

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

- **GitHub**: [@Carl-Frederic-Nickell](https://github.com/Carl-Frederic-Nickell)
- **Website**: [carl.photo](https://www.carl.photo)

---

**Note**: This homelab is continuously evolving. Some services may be in active development or testing phase.
