pipeline {
    agent any

    environment {
        AWS_REGION   = 'ap-northeast-2'
        EKS_CLUSTER  = 'rimo-eks'

        AUTH_REPO     = 'rimo/auth-api'
        MEMBER_REPO   = 'rimo/member-api'
        TRACKING_REPO = 'rimo/tracking-api'
        ROUTE_REPO    = 'rimo/route-api'
        DATA_REPO     = 'rimo/data-api'
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('AWS Info') {
            steps {
                script {
                    env.AWS_ACCOUNT_ID = sh(
                        script: "aws sts get-caller-identity --query Account --output text",
                        returnStdout: true
                    ).trim()

                    env.ECR_REGISTRY = "${env.AWS_ACCOUNT_ID}.dkr.ecr.${env.AWS_REGION}.amazonaws.com"

                    env.IMAGE_TAG = sh(
                        script: "git rev-parse --short HEAD",
                        returnStdout: true
                    ).trim()
                }

                echo "AWS Account: ${AWS_ACCOUNT_ID}"
                echo "ECR Registry: ${ECR_REGISTRY}"
                echo "Image Tag: ${IMAGE_TAG}"
            }
        }

        stage('ECR Login') {
            steps {
                sh '''
                    aws ecr get-login-password \
                      --region $AWS_REGION \
                    | docker login \
                      --username AWS \
                      --password-stdin $ECR_REGISTRY
                '''
            }
        }

        stage('Build Images') {
            parallel {

                stage('Build auth-api') {
                    steps {
                        sh '''
                            docker build \
                              -t $ECR_REGISTRY/$AUTH_REPO:$IMAGE_TAG \
                              ./auth-api
                        '''
                    }
                }

                stage('Build member-api') {
                    steps {
                        sh '''
                            docker build \
                              -t $ECR_REGISTRY/$MEMBER_REPO:$IMAGE_TAG \
                              ./member-api
                        '''
                    }
                }

                stage('Build tracking-api') {
                    steps {
                        sh '''
                            docker build \
                              -t $ECR_REGISTRY/$TRACKING_REPO:$IMAGE_TAG \
                              ./tracking-api
                        '''
                    }
                }

                stage('Build route-api') {
                    steps {
                        sh '''
                            docker build \
                              -t $ECR_REGISTRY/$ROUTE_REPO:$IMAGE_TAG \
                              ./route-api
                        '''
                    }
                }

                stage('Build data-api') {
                    steps {
                        sh '''
                            docker build \
                              -t $ECR_REGISTRY/$DATA_REPO:$IMAGE_TAG \
                              ./data-api
                        '''
                    }
                }
            }
        }

        stage('Push Images') {
            parallel {

                stage('Push auth-api') {
                    steps {
                        sh '''
                            docker push \
                              $ECR_REGISTRY/$AUTH_REPO:$IMAGE_TAG
                        '''
                    }
                }

                stage('Push member-api') {
                    steps {
                        sh '''
                            docker push \
                              $ECR_REGISTRY/$MEMBER_REPO:$IMAGE_TAG
                        '''
                    }
                }

                stage('Push tracking-api') {
                    steps {
                        sh '''
                            docker push \
                              $ECR_REGISTRY/$TRACKING_REPO:$IMAGE_TAG
                        '''
                    }
                }

                stage('Push route-api') {
                    steps {
                        sh '''
                            docker push \
                              $ECR_REGISTRY/$ROUTE_REPO:$IMAGE_TAG
                        '''
                    }
                }

                stage('Push data-api') {
                    steps {
                        sh '''
                            docker push \
                              $ECR_REGISTRY/$DATA_REPO:$IMAGE_TAG
                        '''
                    }
                }
            }
        }

        stage('Configure EKS') {
            steps {
                sh '''
                    aws eks update-kubeconfig \
                      --region $AWS_REGION \
                      --name $EKS_CLUSTER
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                    kubectl set image deployment/auth-api \
                      auth-api=$ECR_REGISTRY/$AUTH_REPO:$IMAGE_TAG

                    kubectl set image deployment/member-api \
                      member-api=$ECR_REGISTRY/$MEMBER_REPO:$IMAGE_TAG

                    kubectl set image deployment/tracking-api \
                      tracking-api=$ECR_REGISTRY/$TRACKING_REPO:$IMAGE_TAG

                    kubectl set image deployment/route-api \
                      route-api=$ECR_REGISTRY/$ROUTE_REPO:$IMAGE_TAG

                    kubectl set image deployment/data-api \
                      data-api=$ECR_REGISTRY/$DATA_REPO:$IMAGE_TAG
                '''
            }
        }

        stage('Rollout Check') {
            steps {
                sh '''
                    kubectl rollout status deployment/auth-api --timeout=180s
                    kubectl rollout status deployment/member-api --timeout=180s
                    kubectl rollout status deployment/tracking-api --timeout=180s
                    kubectl rollout status deployment/route-api --timeout=180s
                    kubectl rollout status deployment/data-api --timeout=180s
                '''
            }
        }
    }

    post {
        success {
            echo 'RIMO backend deployment succeeded.'
        }

        failure {
            echo 'RIMO backend deployment failed.'
        }

        always {
            sh 'docker image prune -f || true'
        }
    }
}
