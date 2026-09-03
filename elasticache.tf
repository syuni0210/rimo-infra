# =========================================================
# ElastiCache Subnet Group
# =========================================================

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.project_name}-redis-subnet-group"

  subnet_ids = [
    aws_subnet.private_cache.id
  ]

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}


# =========================================================
# ElastiCache Redis
# Single Node
# =========================================================

resource "aws_elasticache_cluster" "redis" {
  cluster_id = "${var.project_name}-redis"

  engine          = "redis"
  node_type       = "cache.t3.micro"
  num_cache_nodes = 1
  port            = 6379

  subnet_group_name = aws_elasticache_subnet_group.redis.name
  security_group_ids = [
    aws_security_group.redis.id
  ]

  tags = {
    Name = "${var.project_name}-redis"
  }
}
