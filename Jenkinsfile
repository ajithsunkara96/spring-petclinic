pipeline {
    agent any

    environment {
        SONAR_TOKEN = credentials('SONAR_TOKEN')
        ACR_URL = 'project4registry.azurecr.io'
        IMAGE_NAME = 'spring-petclinic'
        IMAGE_TAG = "${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Maven Validate') {
            steps {
                sh 'mvn validate -B'
            }
        }
        stage('Maven Compile') {
            steps {
                sh 'mvn compile -B'
            }
        }
        stage('Maven Test') {
            steps {
                sh 'mvn test -B'
            }
        }
        stage('Maven Package') {
            steps {
                sh 'mvn package -B'
            }
        }
        stage('SonarCloud Analysis') {
            steps {
                sh """
                    mvn sonar:sonar -B \
                        -Dsonar.projectKey=ajithsunkara96_jenkins-project \
                        -Dsonar.organization=ajithsunkara96 \
                        -Dsonar.host.url=https://sonarcloud.io \
                        -Dsonar.login=$SONAR_TOKEN
                """
            }
        }
        stage('Publish Sonar Report') {
            steps {
                echo 'SonarCloud report published automatically after analysis.'
            }
        }
        stage('Build Docker Image') {
            steps {
                sh "docker build -t $ACR_URL/$IMAGE_NAME:$IMAGE_TAG ."
            }
        }
        stage('Trivy Scan') {
            steps {
                sh "trivy image $ACR_URL/$IMAGE_NAME:$IMAGE_TAG"
            }
        }
        stage('Login to ACR & Push Image') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'azure-sp', usernameVariable: 'SP_APP_ID', passwordVariable: 'SP_SECRET'),
                                 string(credentialsId: 'azure-tenant', variable: 'TENANT_ID')]) {
                    sh '''
                        az login --service-principal -u $SP_APP_ID -p $SP_SECRET --tenant $TENANT_ID
                        az account set --subscription "$(az account show --query id -o tsv)"
                        az acr login --name project4registry --expose-token | jq -r .accessToken | docker login $ACR_URL --username 00000000-0000-0000-0000-000000000000 --password-stdin
                        docker push $ACR_URL/$IMAGE_NAME:$IMAGE_TAG
                    '''
                }
            }
        }
        stage('Deploy to Kubernetes') {
  steps {
    withCredentials([
      usernamePassword(credentialsId: 'azure-sp', usernameVariable: 'SP_APP_ID', passwordVariable: 'SP_SECRET'),
      string(credentialsId: 'azure-tenant', variable: 'TENANT_ID')
    ]) {
      sh '''
        az login --service-principal -u $SP_APP_ID -p $SP_SECRET --tenant $TENANT_ID
        az aks get-credentials -g Project-4 -n project4-aks-cluster --overwrite-existing
        kubectl set image deployment/spring-petclinic spring-petclinic=$ACR_URL/$IMAGE_NAME:$IMAGE_TAG -n default
        kubectl rollout status deployment/spring-petclinic -n default --timeout=180s
      '''
    }
  }
}
    }
    post {
        always {
            cleanWs()
        }
    }
}