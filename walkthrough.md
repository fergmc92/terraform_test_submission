# Terraform project walkthrough

This document explains how the project developed from an intentionally broken Terraform draft into the hardened modular baseline in `iteration_4`.

I went from fixing the broken Terraform and obvious things like the overlapping CIDRs in iteration 1, through choosing a more production-style architecture in iteration 2, modularising in iteration 3, and then using Copilot to challenge the design in iteration 4.

My architectural and module-boundary choices are documented in the design notes for the relevant iterations.

The overall application pattern is:

```text
Internet -> public Application Load Balancer -> private ECS tasks -> private PostgreSQL database
```

The important design principle is that only the application entry point is internet-facing. The application tasks and database remain private.

## Starting point: the broken configuration

The original files in the project root were useful as a review exercise, but they contained both syntax/provider problems and design problems.

### Obvious technical problems

The first review found issues such as:

- An incorrect variable reference in `lb.tf`: `var.env` did not match the declared variable name.
- An unsupported or outdated argument on the EIP resource.
- An invalid RDS argument: the database name needed to use `db_name`.
- Duplicate or overlapping subnet CIDRs.
- A route table pointing at the wrong kind of target.
- Missing or incorrect ECS ingress rules.
- A target group port that did not match the application container port.
- A database security group that allowed more access than the intended private design.
- A plaintext database password in Terraform configuration.

These issues mattered for two different reasons:

1. Some would stop Terraform from validating or creating the infrastructure.
2. Others might technically work but would produce an unsafe or confusing architecture.

That distinction became an important theme in the later iterations: a configuration can be syntactically valid without being production-ready.

## Iteration 1: make the architecture valid

The first iteration created a complete, valid baseline in `iteration_1/main.tf`.

It established the main AWS components:

- A VPC
- Public and private subnets
- Internet gateway and NAT access
- An internet-facing ALB
- ECS Fargate tasks
- A private RDS database
- Security groups connecting the tiers

The immediate goal was not to solve every production concern. It was to get to a coherent configuration that could be read, explained, initialized, and validated.

### What improved

- Invalid Terraform/provider arguments were corrected.
- Subnets received unique, non-overlapping CIDRs.
- The ALB could reach the ECS service on the correct port.
- ECS tasks were placed in private subnets.
- The database was made private instead of publicly accessible.
- Security-group rules reflected the intended traffic flow.

### Trade-off

Iteration 1 still kept a lot of infrastructure in one file and used simple defaults. That made it easier to learn and validate, but it was not yet a strong production layout.

## Iteration 2: choose a sensible architecture

Iteration 2 moved from simply fixing Terraform to making an explicit architecture decision.

Several options were considered:

- Public ALB, private application, private database, multi-AZ
- Public ALB, private application, private database, single-AZ
- Public ALB, public application, private database
- A mostly public or single-subnet design

The selected approach was:

- ALB in public subnets
- ECS tasks in private application subnets
- RDS in private database subnets
- Multiple availability zones
- NAT for private outbound access

### Why this approach was chosen

It provides the clearest separation of responsibilities:

- The ALB is the only public entry point.
- ECS is isolated from direct internet traffic.
- The database is isolated from both the internet and the ALB.
- Multiple availability zones reduce the impact of an AZ failure.

This is a common production web-application pattern.

### Trade-offs accepted

The design is more expensive and more complex than a single-AZ deployment. It requires:

- More subnets
- More routing
- NAT infrastructure
- Multiple security groups
- More operational knowledge

That cost was accepted because security boundaries and availability were more important than the cheapest possible deployment for this production-style baseline.

Iteration 2 was validated with `terraform init` and `terraform validate`.

## Iteration 3: modularize by responsibility

Iteration 3 kept the architecture from iteration 2 but changed how the Terraform was organized.

The module decisions were based on logical ownership rather than extracting every individual resource.

The resulting structure became:

```text
iteration_3/
├── root.tf
└── modules/
    ├── networking/
    ├── security_groups/
    ├── ecs_app/
    ├── database/
    └── alb/
```

### Networking module

Owns:

- VPC
- Subnets
- Internet gateway
- NAT gateway
- Route tables
- Route table associations

### Security-groups module

Owns the traffic boundaries between:

- ALB and the internet
- ECS and the ALB
- RDS and ECS

### ECS application module

Owns:

- ECS cluster
- Task definition
- ECS service
- ECS IAM roles
- Target group

IAM stayed with ECS because the roles exist specifically to support the ECS workload.

### Database module

Owns:

- RDS subnet group
- RDS instance

### ALB module

Owns:

- Application load balancer
- Listener

The target group is created with the ECS application because it represents the ECS service, while the ALB listener forwards traffic to it.

### Why these boundaries were chosen

The goal was to separate logical concerns without creating a module for every small resource.

The chosen boundaries make the code easier to reason about while avoiding an excessive amount of cross-module wiring.

### Trade-offs accepted

Modules create cleaner ownership, but they also require values to be passed through the root module:

- VPC IDs
- Subnet IDs
- Security-group IDs
- Target-group ARNs
- Application settings

That extra wiring is worthwhile when the project grows, but it would be unnecessary complexity for a very small one-file experiment.

## Iteration 4: harden the modular baseline

In the fourth iteration, I used Copilot to challenge my design and identify additional hardening opportunities. I then reviewed those changes and documented the trade-offs.

The root module is in `iteration_4/root.tf`, inputs are in `iteration_4/variables.tf`, and the design notes are in `iteration_4/README.md`.

### More explicit configuration

Important settings are now variables instead of being hidden inside modules:

- AWS region
- Environment and service name
- VPC and subnet CIDRs
- Availability zones
- Application and database ports
- Container image
- ECS task count and sizing
- Database size and backup settings
- HTTPS and certificate settings
- Deletion protection
- Log retention

This makes the same modules usable across environments without editing their internals.

### More resilient networking

Iteration 3 used one NAT gateway. Iteration 4 creates one NAT gateway per availability zone and gives each AZ its own private route table.

That reduces the chance that a failure in one AZ will prevent private workloads in another AZ from reaching the outside world.

The trade-off is cost: NAT gateways are billed resources, so a low-cost development environment may deliberately use only one.

### Better database protection

The database now uses:

- PostgreSQL 16
- Encrypted GP3 storage
- Automatic storage growth
- Multi-AZ deployment
- Automated backups
- Private subnets
- `publicly_accessible = false`
- A database security group that only accepts traffic from ECS

The database password is no longer hardcoded. RDS manages the master password in AWS Secrets Manager through:

```hcl
manage_master_user_password = true
```

The secret ARN is exposed as an output. The sample Nginx container does not consume the database, so the ECS task role does not yet need permission to read that secret. A real application would add that permission narrowly to the task role.

### Safer application deployments

The ECS task definition now accepts a configurable image and defaults to a pinned Nginx tag instead of `latest`.

The ECS service also uses:

- Two tasks by default
- Private subnets
- No public IP addresses
- CloudWatch logging
- 30-day log retention
- Container Insights
- Deployment circuit breaker
- Automatic rollback on failed deployments

The ALB target group checks the application health endpoint before sending traffic to a task.

### HTTPS support

HTTPS is optional in the default configuration because an ACM certificate must already exist in the AWS region.

When enabled:

- Port 80 redirects to port 443.
- Port 443 uses the supplied ACM certificate.
- A stricter TLS security policy is applied.

For an actual production deployment, HTTPS should be enabled.

### ALB logging and deletion protection

The ALB can send access logs to an existing S3 bucket. The bucket and its policy are intentionally not created in this iteration because they are separate infrastructure concerns.

ALB and database deletion protection are separate variables. They default to disabled to make a test deployment easier to destroy, but production values should enable them.

### Consistent tagging

The provider applies these tags to resources:

- `Environment`
- `Service`
- `ManagedBy = terraform`

This improves cost allocation, ownership, and operational discovery.

## What is still deliberately outside iteration 4

This is still an assessment, not a complete enterprise platform. It does not yet create:

- A remote encrypted Terraform backend with state locking
- An ECR repository and image pipeline
- An ACM certificate
- The S3 bucket and policy for ALB access logs
- AWS WAF rules
- CloudWatch alarms and alerting routes
- Route 53 DNS records
- ECS auto scaling policies
- Application-specific database secret integration
- Strict per-destination egress rules

Those would be sensible follow-up improvements, but adding all of them would make the exercise harder to explain and would blur the original architecture choices.
