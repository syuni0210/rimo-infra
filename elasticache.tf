# =========================================================
# ElastiCache Subnet Group
# =========================================================

resource "aws_elasticache_subnet_group" "redis" {
  name = "${var.project_name}-redis-subnet-group"

  subnet_ids = [
    aws_subnet.private_cache_a.id,
    aws_subnet.private_cache_b.id
  ]

  tags = {
    Name = "${var.project_name}-redis-subnet-group"
  }
}


# =========================================================
# ElastiCache Redis
# Multi-AZ / Primary-Replica (이중화)
# =========================================================

resource "aws_elasticache_replication_group" "redis" {
  replication_group_id = "${var.project_name}-redis-group"
  description          = "Redis Replication Group for RIMO"

  engine               = "redis"
  engine_version       = "7.1"
  node_type            = "cache.t3.micro"
  port                 = 6379
  parameter_group_name = "default.redis7"

  # 여기서 노드 개수를 2개로 지정합니다 (Primary 1 + Replica 1)
  num_cache_clusters = 2

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]

  # 이중화 및 자동 승격(Failover) 핵심 옵션
  automatic_failover_enabled = true
  multi_az_enabled           = true

  tags = {
    Name = "${var.project_name}-redis-replica"
  }
}
