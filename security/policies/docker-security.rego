# Docker Security Policy
# Enforces best practices for Docker Compose configurations

package docker.security

import future.keywords.if
import future.keywords.in

# METADATA
# title: Docker Security Policy
# description: Validates Docker Compose files against security best practices
# authors:
#   - Carl-Frederic Nickell

# Deny containers running as root without explicit approval
deny[msg] {
    service := input.services[name]
    not service.user
    not service.security_opt

    msg := sprintf("Service '%s' should not run as root. Set 'user' field or add security_opt.", [name])
}

# Require restart policy
warn[msg] {
    service := input.services[name]
    not service.restart

    msg := sprintf("Service '%s' is missing restart policy. Recommended: 'unless-stopped'", [name])
}

# Check for privileged containers
deny[msg] {
    service := input.services[name]
    service.privileged == true

    msg := sprintf("Service '%s' is running in privileged mode, which is dangerous!", [name])
}

# Ensure no-new-privileges is set
deny[msg] {
    service := input.services[name]
    not has_no_new_privileges(service)

    msg := sprintf("Service '%s' should have 'no-new-privileges:true' in security_opt", [name])
}

has_no_new_privileges(service) {
    service.security_opt[_] == "no-new-privileges:true"
}

# Check for exposed sensitive ports
warn[msg] {
    service := input.services[name]
    port := service.ports[_]
    is_sensitive_port(port)

    msg := sprintf("Service '%s' exposes sensitive port %s. Ensure proper firewall rules.", [name, port])
}

is_sensitive_port(port) {
    sensitive_ports := ["22", "3306", "5432", "6379", "27017", "9200"]
    port_str := split(port, ":")[0]
    port_str in sensitive_ports
}

# Require named volumes instead of bind mounts for data
warn[msg] {
    service := input.services[name]
    volume := service.volumes[_]
    startswith(volume, "/")
    not is_read_only_mount(volume)

    msg := sprintf("Service '%s' uses bind mount '%s'. Consider using named volumes for data.", [name, volume])
}

is_read_only_mount(volume) {
    endswith(volume, ":ro")
}

# Check for missing resource limits
warn[msg] {
    service := input.services[name]
    not service.mem_limit
    not service.cpus

    msg := sprintf("Service '%s' has no resource limits. Consider adding mem_limit and cpus.", [name])
}

# Ensure environment variables don't contain secrets
deny[msg] {
    service := input.services[name]
    env := service.environment[key]
    contains_secret_keyword(key)
    not uses_env_var_reference(env)

    msg := sprintf("Service '%s' has hardcoded secret in environment variable '%s'", [name, key])
}

contains_secret_keyword(key) {
    secret_keywords := ["PASSWORD", "SECRET", "TOKEN", "KEY", "CREDENTIAL"]
    keyword := secret_keywords[_]
    contains(upper(key), keyword)
}

uses_env_var_reference(value) {
    startswith(value, "${")
}

# Check for latest tag usage
warn[msg] {
    service := input.services[name]
    image := service.image
    endswith(image, ":latest")

    msg := sprintf("Service '%s' uses ':latest' tag. Pin to specific version for reproducibility.", [name])
}

# Ensure logging is configured
warn[msg] {
    service := input.services[name]
    not service.logging

    msg := sprintf("Service '%s' has no logging configuration. Consider adding log rotation.", [name])
}

# Check for Docker socket mount (dangerous)
deny[msg] {
    service := input.services[name]
    volume := service.volumes[_]
    contains(volume, "/var/run/docker.sock")

    msg := sprintf("Service '%s' mounts Docker socket - this is a CRITICAL security risk!", [name])
}

# Ensure networks are defined
warn[msg] {
    service := input.services[name]
    not service.networks

    msg := sprintf("Service '%s' is not assigned to a network. Consider using custom networks.", [name])
}

# Check for health checks
warn[msg] {
    service := input.services[name]
    not service.healthcheck

    msg := sprintf("Service '%s' has no healthcheck defined. Consider adding one for better availability.", [name])
}
