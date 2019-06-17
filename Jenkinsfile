pipeline {
    agent { label 'master' }
    triggers {
        githubPush()
        pollSCM('* * * * *')
    }
    parameters {
        string(name: 'FORK',      defaultValue: 'Fidor-FZCO',   description: "Fork  of the git repository")
        string(name: 'BRANCH',    defaultValue: 'develop', description: "Branch to build")
        string(name: 'NAMESPACE', defaultValue: 'loanservice',   description: "Namespace for the Docker Image")
    }
    stages {
       /*  Checkout the desired git branch */
        stage('Checkout SCM') {
        steps {
            checkout scm: [$class: 'GitSCM', branches: [[name: '${BRANCH}']], userRemoteConfigs: [[credentialsId: '68795a3a-52da-4d31-a0b5-84639e760a63', url: 'git@github.com:Fidor-FZCO/express_gateway.git']]]
        }
    }
        /* Package the gems * /
        stage('Package the gems') {
            steps {
                sh '''#!/bin/bash -le
                BRANCH=$BRANCH make config
                '''
            }
        }

        /* Build Docker container image */
        stage('Build the container image') {
            steps {
                sh '''#!/bin/bash -le
                NAMESPACE=$NAMESPACE BRANCH=$BRANCH make build
                '''
            }
        }

        /* Push the build container image to the Docker registry */
        stage('Push the container image to the Docker registry') {
            steps {
                script {
                    sh 'NAMESPACE=$NAMESPACE BRANCH=$BRANCH make push'
                    sh 'make get_commit_hash > .git/commit-id'
                    env.GIT_COMMIT = readFile('.git/commit-id').trim()
                }
            }
        }
    }
    post {
        always {
            // clean up our workspace
            sh 'NAMESPACE=$NAMESPACE BRANCH=$BRANCH make clean'
            deleteDir()
        }
    }
}

