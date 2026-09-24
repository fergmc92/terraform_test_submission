# Iteration 4: hardened modular baseline

In this iteration, I used Copilot to challenge my previous design and suggest additional hardening measures. I wanted to identify what I had overlooked, compare the suggested approaches, and decide which changes were proportionate to this small application.

I recognise that some of the suggestions in this iteration, such as having two NAT gateways, are probably overkill for a small application.

This is the final hardening pass over iteration 3. It keeps the same module boundaries and traffic flow:

```text
Internet -> public ALB -> private ECS tasks -> private RDS PostgreSQL
```

## What changed

- Inputs are variables instead of being hidden in modules.
- The provider applies consistent `Environment`, `Service`, and `ManagedBy` tags.
- Public and private subnet CIDRs and availability zones are configurable.
- Each availability zone has its own NAT gateway and private route table.
- ECS tasks have no public IP addresses and accept traffic only from the ALB security group.
- The database is private, encrypted, Multi-AZ, backed up, and protected by its own security group.
- RDS manages the master password in AWS Secrets Manager instead of storing a password in Terraform configuration.
- The container image is an input and defaults to a pinned example tag rather than `latest`.
- ECS sends logs to CloudWatch with configurable retention and enables Container Insights.
- ECS uses a deployment circuit breaker with rollback.
- The ALB has a stricter TLS policy when HTTPS is enabled and can redirect HTTP to HTTPS.
- Optional ALB access logging can be enabled by supplying an existing S3 bucket name.

## Important trade-offs

- Two NAT gateways improve availability but increase cost. A cheaper non-production environment could use one NAT gateway.
- HTTPS requires an ACM certificate ARN in the same region. It is disabled by default so validation works without an existing certificate.
- ALB access logging expects an existing, correctly configured S3 bucket. Bucket creation and its policy are intentionally outside this iteration.
- The RDS master secret exists in Secrets Manager, but the sample Nginx container does not consume database credentials. A real application would receive the secret ARN and grant only the task role the `secretsmanager:GetSecretValue` permission it needs.
- The defaults are usable for a small test environment. Production values should enable HTTPS, deletion protection, a private image in ECR, and remote encrypted Terraform state with locking.

## Validation

From this directory:

```sh
terraform init
terraform validate
terraform plan -var-file=terraform.tfvars
```

Copy `terraform.tfvars.example` to `terraform.tfvars` and replace the example image and certificate values before planning an HTTPS deployment. Do not commit credentials or environment-specific secrets.