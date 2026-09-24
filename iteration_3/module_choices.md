# Iteration 3: Module boundaries

This is the point where the root Terraform starts to become too large. The big question is not whether to use modules, but which parts are worth extracting.

## Candidate modules

### 1. networking
This module would own:
- VPC
- public/private subnets
- route tables
- internet gateway
- NAT gateway
- route table associations

Upsides:
- Keeps the network layout in one place
- Easy to reuse across environments
- Makes the VPC design more explicit and consistent

Downsides:
- More moving parts for a small project
- It can be overkill if the topology never changes

### 2. security_groups
This module would own:
- ALB security group
- ECS security group
- DB security group

Upsides:
- Easy to reason about access boundaries
- Keeps least-privilege rules together
- Very important for clean review

Downsides:
- A small project may not need a dedicated module yet
- Easy to over-engineer if only one app is involved

### 3. alb
This module would own:
- ALB
- target group
- listener

Upsides:
- Clean separation of traffic entry point
- Easy to reuse in other services
- Clearer architecture

Downsides:
- Not always worth splitting out for a single app
- Could be a little abstract if the project is very small

### 4. ecs_app
This module would own:
- ECS cluster
- task definition
- ECS service
- IAM roles for ECS

Upsides:
- This is a natural unit of reuse
- Keeps app orchestration separate from networking
- Makes it easier to deploy multiple services later

Downsides:
- More complexity when first learning Terraform
- If you only have one service, it can feel unnecessary

### 5. database
This module would own:
- DB subnet group
- RDS instance
- DB-specific security group

Upsides:
- Makes the data layer explicit
- Helps isolate database concerns
- Good for consistency across environments

Downsides:
- For a simple app, the DB is not such a large complexity spike
- More module files to manage

### 6. iam
This module would own:
- task role
- execution role
- policy attachments

Upsides:
- Good separation of concerns
- Makes security review easier
- Reduces duplication later

Downsides:
- Unclear value in a tiny, single-service setup
- Easy to over-split the project for no gain

## What should not be a module yet?
These are usually not worth extracting in a first pass:
- provider configuration
- variables and locals
- outputs
- a single tiny resource group that will never be reused

The goal is to split by responsibility, not by every resource.

## Decision required

Pick the modules you think belong in iteration 3 and explain why.

Use this format:

- My chosen modules: 
1. network-adjacent, 1 group consisting of [network, security_groups, alb]
2. ECS
3. databases
IAM/security should stay with their respective functionalities
- Why these are the right boundaries: 
I think separating out into logical concerns, but not too granular that you are constantly importing things, and it's too easy to make a change that could impact lots of things in one module by accident
- What I am leaving in the root module: things like the DB definitions, passwords (actually whilst I'm here - put this into AWS secrets manager), the basic app functionality that ECS runs
- Trade-offs I am accepting: 
not putting IAM/security as its own module, having modules for apps means having to pass round lots of variables potentially. also lots of back-and-forth with root module.
- What I would split later if this grew: 
I may split out the different types of databases if we have a lot, plus ALBs if we have a lot of different types for different things
