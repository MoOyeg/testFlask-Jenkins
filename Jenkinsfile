pipeline {
agent {
  kubernetes {
    label "python-agent"
    cloud "openshift"
    containerTemplate {
      name "jnlp"
      image "image-registry.openshift-image-registry.svc:5000/$JENKINS_NAMESPACE/python-jenkins:latest"  
      resourceRequestMemory "500Mi"
      resourceLimitMemory "500Mi"
      resourceRequestCpu "300m"
      resourceLimitCpu "300m"
      alwaysPullImage "True"
    }
  }
}

  stages {

    stage('Checkout Pipeline Source') {
     steps {
       echo "Checking out Code}"
       checkout scm
      }     
    }


    stage('Checkout Application Source') {
     steps {
       echo "Checking out Application Source Code}"
       script {             
             sh "git checkout ${REPO}"
             sh "ls ./"
          }
      }     
    }

   
  }
}

