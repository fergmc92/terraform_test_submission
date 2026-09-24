## First-draft choice

This is the design we will use as the baseline for the first pass.

### My choice:
 public ALB, private app, private database.

### Why:
- Only the app tier should be internet-facing.
- The database should remain private.
- Everything should be private unless a port is explicitly required for a real function.
- This keeps the attack surface small while still supporting normal internet traffic to the app.
- It matches a sensible AWS web-application structure without overengineering the first draft.

### Intended network layout:
- One VPC with a private IP range such as 10.0.0.0/16
- Public subnets for the ALB only
- Private subnets for the ECS tasks
- Private subnets for the RDS instance
- Public route table with Internet Gateway for the ALB
- Private route table with NAT Gateway for outbound internet access if needed
- All non-public resources should communicate only over required ports

### Intended traffic flow:
- Internet -> ALB on 80/443
- ALB -> ECS tasks on port 80
- ECS tasks -> RDS on 5432 or the required database port
- Private resources should not be directly internet-accessible
- Outbound internet access is allowed only when necessary for the app to function

### Intended security model:
- ALB security group: allow inbound 80/443 from the internet
- ECS security group: allow inbound from the ALB security group only
- RDS security group: allow inbound only from the ECS security group on the required DB port
- Deny broad open access to the database
- No unnecessary public access to internal tiers
- Least-privilege rules rather than wide CIDR allowances

### Assumptions for this first draft:
- Single region
- Single environment, simple deployment
- ECS tasks live in private subnets
- The database is private and only reachable by the app tier
- This is a starting point; production hardening can come later
- If this becomes multi-region or multi-account, we would revisit the network design and connectivity model

### Notes for later hardening:
- Add TLS termination at the ALB with proper certificate management
- Consider multi-AZ deployment for resilience
- Add more specific security-group rules and NACLs
- Review whether NAT is needed for every private workload
- Add environment-specific naming, tagging, and least-privilege IAM policies
