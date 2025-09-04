cluster_name             = "petclinic-cluster"
cluster_version          = "1.33"
vpc_id                   = "vpc-07dae74282dee13b0"
subnet_ids               = ["subnet-05a076ad8b842baa3", "subnet-036d31855d1c3432c"]
control_plane_subnet_ids = ["subnet-0b7270abff2fc7924", "subnet-01e7e2c9d5acc9f21"]

# Using t3.medium (free tier eligible) and t3a.medium (AMD-based, cheaper) for spot instances
node_group_instance_types = ["t3.medium", "t3a.medium"]
node_group_min_size       = 1
node_group_max_size       = 3
node_group_desired_size   = 2

environment = "production"
