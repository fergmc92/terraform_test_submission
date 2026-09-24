# Top broken things visible by inspection

These are the biggest problems in the Terraform that stood out immediately without even running it:

1. Broken IAM role reference
   - In main.tf, the ECS task definition sets `execution_role_arn = aws_iam_role.execution_role.arn`.
   - But the actual resource is named `aws_iam_role.ecs_execution_role`, not `aws_iam_role.execution_role`.
   - Result: Terraform will fail because that object does not exist.

2. Wrong variable name used in ALB tags
   - In lb.tf, the tag uses `${var.env}-alb`.
   - The project defines `variable "environment"` in variables.tf, not `var.env`.
   - Result: this will fail at plan/apply time because `var.env` is undefined.

3. ECS service is pointing at the wrong container port
   - In main.tf, the task definition exposes port 80.
   - But the ECS service load balancer block sets `container_port = 81`.
   - Result: the service tries to forward traffic to a port the container does not listen on.

4. Security group has no ingress rules
   - In main.tf, `aws_security_group.ecs-sgrp` only defines egress.
   - There is no ingress rule allowing traffic from the ALB or from the internet to the ECS task.
   - Result: the app will not be reachable even if the rest of the setup is valid.

5. Duplicate subnet CIDRs

so for a start, in the world of subnet masks, the bigger the number, the smaller the subnet. Derived from IPv4 having 2^32 possible values for an IP address. A subnet is 2^(32-$SUBNET_MASK).

   - `aws_subnet.public-1` and `aws_subnet.public-2` both use `10.0.0.0/24`.
   - `aws_subnet.web-2` and `aws_subnet.database-2` both use `10.0.6.0/24`.
   - Result: overlapping CIDR ranges are invalid and will cause VPC/subnet configuration errors.

6. Invalid subnet range in the web subnet
   - `aws_subnet.web-1` uses `10.0.2.0/16`.
   - That is not a valid subnet mask inside a /16 VPC; it should be something like `10.0.2.0/24`.
   - Result: invalid CIDR for the subnet definition.

7. Public route table is malformed
   - In main.tf, the public route uses `cidr_block = "0.0.0.0"` instead of `"0.0.0.0/0"`.
   - Result: the route is not a valid default route and will not behave as intended.

8. The ALB target group attachment is attached to the wrong thing
   - `aws_lb_target_group_attachment.nginx_target_group_attachment` uses `target_id = aws_ecs_service.nginx_service.name`.
   - For ECS target group attachments, the target should be the actual task/instance ID, not the service name, and ECS service usually handles registration itself.
   - Result: the attachment is not set up correctly for a healthy ALB-to-ECS registration.

9. The ECS task and ALB are not aligned with the same network design
   - The ECS service is placed in `aws_subnet.web-1`, while the ALB is attached to `public-1` and `public-2`.
   - The ALB and ECS task are effectively on different network patterns without a valid ingress path.
   - Result: the ALB cannot successfully route to the service.

10. Database security group is too open
   - `aws_security_group.database-sgrp` allows MySQL (3306) from `0.0.0.0/0`.
   - This exposes the database to the internet.
   - I have seen this be exploited on a system exposed to the internet, it ended up hosting a crypto miner installed through an unpatched old version of Postgres...

