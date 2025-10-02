# Security Policies

This directory contains Open Policy Agent (OPA) policies for enforcing security best practices across the homelab infrastructure.

## Available Policies

### `docker-security.rego`

Validates Docker Compose configurations against security best practices.

**Checks include:**

#### Critical (Deny)
- ❌ Containers running as root without security options
- ❌ Privileged containers
- ❌ Missing `no-new-privileges` security option
- ❌ Hardcoded secrets in environment variables
- ❌ Docker socket mounts (critical security risk)

#### Warnings
- ⚠️ Missing restart policy
- ⚠️ Exposed sensitive ports (22, 3306, 5432, etc.)
- ⚠️ Bind mounts instead of named volumes
- ⚠️ Missing resource limits (CPU/memory)
- ⚠️ Using `:latest` tag instead of pinned versions
- ⚠️ Missing logging configuration
- ⚠️ Missing network configuration
- ⚠️ Missing health checks

## Usage

### Install OPA

```bash
# macOS
brew install opa

# Linux
curl -L -o opa https://openpolicyagent.org/downloads/latest/opa_linux_amd64
chmod +x opa
sudo mv opa /usr/local/bin/
```

### Validate a Docker Compose file

```bash
# Convert docker-compose.yml to JSON
docker-compose -f <service>/docker-compose.yml config --format json > compose.json

# Test against policy
opa eval --data security/policies/docker-security.rego \
         --input compose.json \
         --format pretty \
         "data.docker.security.deny"
```

### Run all checks

```bash
# Check for denies (violations)
opa eval --data security/policies/docker-security.rego \
         --input compose.json \
         --format pretty \
         "data.docker.security"
```

## CI/CD Integration

The security policies are automatically enforced in GitHub Actions workflows:

```yaml
- name: Validate with OPA
  run: |
    docker-compose config --format json > compose.json
    opa eval --data security/policies/docker-security.rego \
             --input compose.json \
             --format pretty \
             "data.docker.security.deny"
```

## Policy Development

### Testing policies locally

```bash
# Run OPA in interactive mode
opa run security/policies/

# Test a specific rule
opa eval --data security/policies/docker-security.rego \
         --input test-data.json \
         "data.docker.security.deny[x]"
```

### Adding new rules

1. Edit `docker-security.rego`
2. Add your rule following the pattern:

```rego
deny[msg] {
    # Your condition here
    service := input.services[name]
    service.some_field == "bad_value"

    msg := sprintf("Service '%s' violates policy", [name])
}
```

3. Test the rule with sample data
4. Update this README with the new rule

## Best Practices

### Security Levels

- **Deny**: Critical security issues that must be fixed
- **Warn**: Best practices that should be followed but won't block deployment

### Environment Variables

Always use environment variable references for sensitive data:

```yaml
# ❌ Bad
environment:
  PASSWORD: mysecretpassword123

# ✅ Good
environment:
  PASSWORD: ${DB_PASSWORD}
```

### Container Security

```yaml
# ✅ Good security configuration
services:
  app:
    image: nginx:1.25.0  # Pinned version
    user: "1000:1000"    # Non-root user
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    mem_limit: 512m
    cpus: 1.0
    logging:
      driver: "json-file"
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - app-network
```

## References

- [OPA Documentation](https://www.openpolicyagent.org/docs/latest/)
- [Docker Security Best Practices](https://docs.docker.com/engine/security/)
- [CIS Docker Benchmark](https://www.cisecurity.org/benchmark/docker)

## Contributing

When adding new policies:

1. Document the rationale
2. Provide examples of violations
3. Include remediation steps
4. Update this README
5. Test with actual Docker Compose files
