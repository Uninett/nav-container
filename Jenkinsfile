#!groovy
properties([disableConcurrentBuilds()])
node {
  stage("Checkout") {
      def scmVars = checkout scm
  }

  stage("Build") {
    ansiColor('xterm') {
      sh "docker-compose build"
    }
  }
}
