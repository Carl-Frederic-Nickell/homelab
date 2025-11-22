# Authentik - Enterprise Identity Provider & SSO Platform

## 🔐 Overview

Authentik is an open-source Identity Provider focused on flexibility and security. This deployment provides enterprise-grade authentication and authorization for all your applications.

## ✨ Key Features

### Authentication Methods
- **Username/Password**: Traditional authentication with password policies
- **OAuth2/OIDC**: Modern authentication protocols
- **SAML 2.0**: Enterprise SSO standard
- **LDAP**: Directory service integration
- **Social Login**: Google, Facebook, GitHub, etc.
- **Multi-Factor Authentication**: TOTP, WebAuthn, SMS
- **Passwordless**: Magic links, passkeys

### Authorization & Access Control
- **RBAC**: Role-Based Access Control
- **Groups & Permissions**: Fine-grained access management
- **Dynamic Policies**: Python-based policy engine
- **IP Whitelisting**: Network-based restrictions
- **Device Trust**: Trusted device management

### Integration Capabilities
- **Traefik Forward Auth**: Protect any application
- **Kubernetes**: Native ingress integration
- **Proxmox**: Virtual environment SSO
- **NextCloud**: File sharing SSO
- **GitLab**: DevOps platform SSO
- **Custom Applications**: SDK and API support

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Applications                         │
│        (NextCloud, GitLab, Grafana, Custom Apps)         │
└────────────────────┬────────────────────────────────────┘
                     │ Authentication Requests
┌────────────────────┴────────────────────────────────────┐
│                   Authentik Server                       │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   OAuth2/    │  │    SAML      │  │     LDAP     │  │
│  │    OIDC      │  │   Provider   │  │   Provider   │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
│                                                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │   User       │  │   Policy     │  │    Audit     │  │
│  │ Management   │  │   Engine     │  │    Logs      │  │
│  └──────────────┘  └──────────────┘  └──────────────┘  │
└────────────┬───────────────────────┬────────────────────┘
             │                       │
    ┌────────┴────────┐     ┌───────┴────────┐
    │   PostgreSQL    │     │     Redis       │
    │   (Database)    │     │    (Cache)      │
    └─────────────────┘     └────────────────┘
```

## 🚀 Quick Start

### Installation

1. **Clone the repository**
```bash
git clone <repository>
cd homelab/authentik
```

2. **Configure environment**
```bash
cp .env.example .env
# Generate secret key
echo "AUTHENTIK_SECRET_KEY=$(openssl rand -base64 32)" >> .env
# Edit other values
nano .env
```

3. **Start the stack**
```bash
docker-compose up -d
```

4. **Access Authentik**
```
https://localhost:9000
# If bootstrap password is set, use that
# Otherwise, use akadmin as username for initial setup
```

## 🔧 Configuration Examples

### Traefik Forward Authentication

Protect any application with Authentik:

```yaml
# In your application's docker-compose.yml
labels:
  - "traefik.http.routers.app.middlewares=authentik@docker"
```

### OAuth2 Application Setup

1. Create new application in Authentik
2. Create OAuth2 provider
3. Configure redirect URIs
4. Use in your application:

```javascript
// Example Node.js configuration
const config = {
  clientId: 'your-client-id',
  clientSecret: 'your-client-secret',
  authorizationURL: 'https://auth.example.com/application/o/authorize/',
  tokenURL: 'https://auth.example.com/application/o/token/',
  userInfoURL: 'https://auth.example.com/application/o/userinfo/'
}
```

### LDAP Configuration

Enable LDAP provider for legacy applications:

```
LDAP Server: ldap://authentik-server:389
Base DN: dc=example,dc=com
Bind DN: cn=admin,dc=example,dc=com
```

## 🛡️ Security Best Practices

1. **Strong Secret Key**: Generate a unique secret key for production
2. **Database Security**: Use strong PostgreSQL passwords
3. **Redis Security**: Enable Redis password authentication
4. **TLS/SSL**: Always use HTTPS in production
5. **MFA Enforcement**: Require MFA for admin accounts
6. **Session Security**: Configure appropriate session timeouts
7. **Audit Logging**: Enable and monitor audit logs
8. **Regular Updates**: Keep Authentik updated

## 📊 Monitoring & Maintenance

### Health Checks
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs -f authentik-server

# Database backup
docker-compose exec authentik-postgresql pg_dump -U authentik authentik > backup.sql
```

### Metrics
Authentik exposes Prometheus metrics at `/metrics` endpoint.

## 🔍 Common Use Cases

### 1. Single Sign-On (SSO)
Provide seamless authentication across all applications.

### 2. Multi-Factor Authentication
Enhance security with TOTP, WebAuthn, or SMS verification.

### 3. Social Login
Allow users to authenticate with existing social accounts.

### 4. B2B SaaS
Multi-tenant authentication for SaaS applications.

### 5. Zero Trust Architecture
Implement continuous authentication and authorization.

## 📚 Resources

- [Official Documentation](https://goauthentik.io/docs/)
- [Integration Examples](https://goauthentik.io/integrations/)
- [API Reference](https://goauthentik.io/developer-docs/api/)
- [Community Forum](https://github.com/goauthentik/authentik/discussions)

## 🤝 Contributing

Contributions welcome! Please follow the contributing guidelines.

## 📄 License

Provided for educational and portfolio demonstration purposes.

---

**Note**: This is a sanitized configuration. Customize all credentials and settings for production use.