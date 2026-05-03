package main

# What the guardrail checks: Ensures public access is disabled on mock resources.
# Where it runs: CI workflow (or locally) using Conftest.
# How to narrate: "We catch misconfigurations at the pull request stage."
# Why fast feedback: Developers get immediate feedback directly in their IDE or PR.

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    resource.change.after.triggers.public_access == "true"
    msg := "public access is not allowed"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    resource.change.after.triggers.encryption_enabled == "false"
    msg := "encryption must be enabled"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    resource.change.after.triggers.owner == ""
    msg := "owner tag is required"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    resource.change.after.triggers.environment == ""
    msg := "environment tag is required"
}
