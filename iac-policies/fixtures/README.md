These files are trimmed `terraform show -json` style inputs for **conftest**.

- `plan-s3-good.json` — passes the Rego bundle in [`../terraform.rego`](../terraform.rego).
- `plan-s3-bad.json` — violates the same rules (public ACL, missing encryption/tags).

To regenerate from a live plan: run `terraform plan -out=tfplan && terraform show -json tfplan`, then retain only the `resource_changes` entry for `aws_s3_bucket.demo` plus top-level scaffolding.
