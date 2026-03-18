pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "apoorvar12/product-catalog"
        DOCKER_TAG = "${BUILD_NUMBER}"
        FULL_IMAGE = "${DOCKER_IMAGE}:${DOCKER_TAG}"
        DOCKER_BUILDKIT = "1"
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Cloning the git repository'
                git branch: 'main', url: 'https://github.com/apoorvaramesh11/eks-microservices-devops.git'
            }
        }

        
        stage('Build') {
            steps {
                sh '''
                cd my-microservices/src/product-catalog
                go mod download
                go build -o product-catalog-service main.go
                '''
            }
        }

        
        stage('Docker Build') {
            steps {
                sh '''
                export DOCKER_BUILDKIT=1
                docker build -t ${FULL_IMAGE} my-microservices/src/product-catalog
                '''
            }
        }

        
        stage('Push') {
            steps {
                echo 'Pushing the image to DockerHub'
                withCredentials([usernamePassword(
                    credentialsId: 'DOCKER_ID',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {

                    sh '''
                    echo $DOCKER_PASS | docker login -u $DOCKER_USER --password-stdin
                    echo "Login Successful"
                    docker push ${FULL_IMAGE}
                    '''
                }
            }
        }

        
        stage('Update Kubernetes Manifest') {
            steps {
                sh '''
                sed -i "s|image: .*|image: ${FULL_IMAGE}|" manifests/productcatalog/deployment.yaml
                '''
            }
        }
    }
}
