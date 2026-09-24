# Technical exercise 

Here is my take on the technical exercise.

I have done 4 iterations on this - the first being to fix any glaring broken Terraform and patch up the conflicting/invalid subnets, missing ingress rules and anything that would generally prevent it from being able to work in the first place. 
The second iteration focused on choosing a sensible production-style architecture: a public ALB, private ECS tasks, and a private database across multiple availability zones. The third iteration modularised that design.

In the fourth iteration, I used Copilot to challenge my design and identify additional hardening opportunities. It helped me develop a hardened, production-style design.
This includes things like having a NAT gateway per AZ, defining the private ECS tasks, private DB subnets, more tightly scoped security groups, automated backups, and logging.
These things are expensive and time-consuming, and I would not necessarily introduce all of them at the start without first getting a PoC of the system running. This iteration was also an opportunity to see what I had missed in my original choices.

Full details in walkthrough.md.
