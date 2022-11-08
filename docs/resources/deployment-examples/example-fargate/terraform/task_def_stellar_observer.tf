resource "aws_ecs_task_definition" "stellar_observer" {
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  family                   = "${var.environment}-stellar-observer"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  volume {
    name = "config"
  }
  
  container_definitions = jsonencode([{
   name        = "${var.environment}-stellar-observer-config"
   image       = "${var.aws_account}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.anchor_config.name}:latest"
   entryPoint  = ["/copy_config.sh"]
   
   essential   = false
   "mountPoints": [
      {
        "readOnly": false,
        "containerPath": "/anchor_config",
        "sourceVolume": "config"
      }
    ],    
   logConfiguration = {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "anchorplatform",
                    "awslogs-region": "${var.aws_region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "stellar-observer",
                    "awslogs-multiline-pattern": "^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3} \\w+ -", 
                }
            }
  },{
   name        = "${var.environment}-stellar-observer" 
   image       = "stellar/anchor-platform:${var.image_tag}"
   dependsOn =  [ {
     containerName = "${var.environment}-stellar-observer-config"
     condition = "START"
   }]
   #entryPoint = ["/anchor_config/sep.sh"]
   entryPoint  = ["java", "-jar", "/app/anchor-platform-runner.jar", "--stellar-observer"]
   essential   = true
   secrets = [
      {
        "name": "SQS_ACCESS_KEY",
        "valueFrom": data.aws_ssm_parameter.sqs_access_key.arn
      },
      {
        "name": "SQS_SECRET_KEY",
        "valueFrom": data.aws_ssm_parameter.sqs_secret_key.arn
      },
      {
        "name": "SQLITE_USERNAME",
        "valueFrom": data.aws_ssm_parameter.sqlite_username.arn
      },
      {
        "name": "SQLITE_PASSWORD",
        "valueFrom": data.aws_ssm_parameter.sqlite_password.arn
      },
      {
        "name": "SEP_10_SIGNING_SEED",
        "valueFrom": data.aws_ssm_parameter.sep10_signing_seed.arn
      },
      {
        "name": "JWT_SECRET",
        "valueFrom": data.aws_ssm_parameter.jwt_secret.arn
      },
      {
        "name": "PLATFORM_TO_ANCHOR_SECRET",
        "valueFrom": data.aws_ssm_parameter.platform_to_anchor_secret.arn
      },
      {
        "name": "ANCHOR_TO_PLATFORM_SECRET",
        "valueFrom": data.aws_ssm_parameter.anchor_to_platform_secret.arn
      }
   ]

   "mountPoints": [
      {
        "readOnly": true,
        "containerPath": "/anchor_config",
        "sourceVolume": "config"
      }
    ]
    "environment": [
        {
            "name": "STELLAR_ANCHOR_CONFIG",
            "value": "file:/anchor_config/anchor_config.yaml"
        }
    ],
       logConfiguration = {
                "logDriver": "awslogs",
                "options": {
                    "awslogs-group": "anchorplatform",
                    "awslogs-region": "${var.aws_region}",
                    "awslogs-create-group": "true",
                    "awslogs-stream-prefix": "stellar-observer",
                    "awslogs-multiline-pattern": "^[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3} \\w+ -", 
                }
            
            }
   portMappings = [{
     protocol      = "tcp"
     containerPort = 8083
     hostPort      = 8083
   }]
  }
  ])
}