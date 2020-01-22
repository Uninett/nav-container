#!groovy
properties([disableConcurrentBuilds()])
node {
  stage("Checkout") {
      def scmVars = checkout scm
  }

  stage("Make") {
    ansiColor('xterm') {
      sh "make"
    }
  }
  stage("Build") {
    ansiColor('xterm') {
      sh "docker-compose build"
    }
  }
}
