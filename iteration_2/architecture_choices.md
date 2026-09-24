# Iteration 2: Architecture choices

This is the next pass for a slightly more realistic design discussion. The goal is not to pick the single best production answer, but to compare reasonable patterns and force a choice with a clear justification.

This is the closest to a standard production web application pattern:

- Public subnets: ALB only
- Private subnets: ECS tasks
- Private subnets: RDS
- NAT gateway for outbound access from private resources
- HTTPS on the ALB
- Multi-AZ for resilience

Upsides:
- Best security posture
- Database is not public
- Fits a typical web app model
- More resilient than a single-AZ design

Downsides:
- More moving parts
- More cost
- More complexity in routing and security groups
- Requires more thought around NAT, routing, and health checks

Best for:
- real production workloads
- systems that need resilience and clearer isolation


- Why I'm picking this: 

this is a secure and resilient choice for a production system


- What trade-offs I am accepting:

this is going to be more expensive to run and more difficult to monitor and debug should there be issues, compared to simpler architecture

- What I would add later for production: 

ECS replication of tasks for higher availability, depending on what the application actually is. Maybe database clustering, again if it's an application that's constantly being hammered with lots of data... or maybe some sort of cache in front of the DB if there are lots of reads too, so that we don't have to constantly hit it.

