package main

# What the guardrail checks:
# - public access must be disabled
# - encryption must be enabled
# - owner tag must be present
# - environment tag must be present
#
# Where it runs:
# - locally or in CI using Conftest against Terraform plan JSON
#
# Demo narration:
# "This policy checks the plan before anything is applied."

is_missing(value) if {
    value == null
}

is_missing(value) if {
    value == ""
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    public_access := object.get(resource.change.after.triggers, "public_access", "")
    public_access == "true"
    msg := "public access is not allowed"
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    encryption_enabled := object.get(resource.change.after.triggers, "encryption_enabled", "")
    encryption_enabled == "false"
    msg := "encryption must be enabled"
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    owner := object.get(resource.change.after.triggers, "owner", "")
    is_missing(owner)
    msg := "owner tag is required"
}

deny contains msg if {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    environment := object.get(resource.change.after.triggers, "environment", "")
    is_missing(environment)
    msg := "environment tag is required"
}