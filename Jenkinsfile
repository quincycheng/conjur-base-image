pipeline {
  agent { label 'executor-v2' }

  parameters {
    booleanParam(name: 'PUBLISH_DOCKERHUB', defaultValue: false,
                 description: 'Publish images to DockerHub')
  }

  triggers {
    cron(getDailyCronString())
  }

  environment {
    TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD | tr -d '\n'")
  }

  stages {
    stage ('Build and push openssl-builder image') {
      steps {
        sh "./openssl-builder/build.sh"
      }
    }
    stage ('Build and push subsequent builder images') {
      parallel {
        stage ('Build and push phusion-ruby-builder image') {
          steps {
            sh "./phusion-ruby-builder/build.sh"
          }
        }
        stage ('Build and push ubuntu-ruby-builder image') {
          steps {
            sh "./ubuntu-ruby-builder/build.sh"
          }
        }
        stage ('Build and push ubi-ruby-builder image') {
          steps {
            sh "./ubi-ruby-builder/build.sh"
          }
        }
        stage ('Build and tag postgres-client-builder image') {
          steps {
            sh "./postgres-client-builder/build.sh"
          }
        }
        stage ('Build and tag openldap-builder image') {
          steps {
            sh "./phusion-openldap-builder/build.sh"
          }
        }
      }
    }
    stage ('Build, Test, and Scan images') {
      parallel {
        stage ('Build, Test, and Scan phusion-ruby-fips image') {
          steps {
            buildTestAndScanImage('phusion-ruby-fips')
          }
        }
        stage ('Build, Test, and Scan ubuntu-ruby-fips image') {
          steps {
            buildTestAndScanImage('ubuntu-ruby-fips')
          }
        }
        stage ('Build, Test, and Scan ubi-ruby-fips image') {
          steps {
            buildTestAndScanImage('ubi-ruby-fips')
          }
        }
        stage ('Build, Test, and Scan ubi-nginx image') {
          steps {
            buildTestAndScanImage('ubi-nginx')
          }
        }
      }
    }
    stage ('Push internal images') {
      steps {
        sh "./phusion-ruby-fips/push.sh ${TAG} registry.tld"
        sh "./ubuntu-ruby-fips/push.sh ${TAG} registry.tld"
        sh "./ubi-ruby-fips/push.sh ${TAG} registry.tld"
        sh "./ubi-nginx/push.sh ${TAG} registry.tld"
      }
    }
    stage ('Publish images') {
      when {
        branch "master"
        anyOf {
          triggeredBy 'TimerTrigger'
          expression { params.PUBLISH_DOCKERHUB }
        }
      }

      steps {
        sh "./phusion-ruby-fips/push.sh ${TAG}"
        sh "./ubuntu-ruby-fips/push.sh ${TAG}"
        sh "./ubi-ruby-fips/push.sh ${TAG}"
        sh "./ubi-nginx/push.sh ${TAG}"
      }
    }
  }

  post {
    always {
      archiveArtifacts allowEmptyArchive: true, artifacts: 'test-results/**/*.json', fingerprint: true
      cleanupAndNotify(currentBuild.currentResult, "#development")
    }
  }
}

def buildTestAndScanImage(name) {
  sh "./${name}/build.sh ${TAG}"
  sh "./${name}/test.sh ${TAG}"
  scanAndReport("${name}:${TAG}", "HIGH", false)
  scanAndReport("${name}:${TAG}", "NONE", true)
}
