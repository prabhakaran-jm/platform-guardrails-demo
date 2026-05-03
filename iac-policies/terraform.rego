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
# Rego dialect: expects Conftest aligned with Rego v1 (e.g. >= 0.50).
# `.github/workflows/iac-policy-check.yml` installs a matching release.

is_missing(value) {
    value == null
}

is_missing(value) {
    value == ""
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    public_access := object.get(resource.change.after.triggers, "public_access", "")
    public_access == "true"
    msg := "public access is not allowed"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    encryption_enabled := object.get(resource.change.after.triggers, "encryption_enabled", "")
    encryption_enabled == "false"
    msg := "encryption must be enabled"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    owner := object.get(resource.change.after.triggers, "owner", "")
    is_missing(owner)
    msg := "owner tag is required"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "null_resource"
    environment := object.get(resource.change.after.triggers, "environment", "")
    is_missing(environment)
    msg := "environment tag is required"
}

# AWS S3 (terraform plan fixtures / real aws_s3_bucket plans)
has_s3_sse(after) {
    sse := object.get(after, "server_side_encryption_configuration", null)
    sse != null
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    acl := object.get(resource.change.after, "acl", "private")
    acl == "public-read"
    msg := "public access is not allowed"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    not has_s3_sse(resource.change.after)
    msg := "encryption must be enabled"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    tags := object.get(resource.change.after, "tags", {})
    owner := object.get(tags, "owner", "")
    is_missing(owner)
    msg := "owner tag is required"
}

deny[msg] {
    resource := input.resource_changes[_]
    resource.type == "aws_s3_bucket"
    tags := object.get(resource.change.after, "tags", {})
    environment := object.get(tags, "environment", "")
    is_missing(environment)
    msg := "environment tag is required"
}
