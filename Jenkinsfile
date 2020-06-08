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


    stage('Clone Application Source') {
     steps {
       echo "Clone our Application Source Code}"
       script {             
             sh "git clone ${REPO}"
             sh "ls ./"
          }
      }     
    }

    stage('Run the Code Unit Testing') {
     steps {
       echo "Starting Unit Testing}"
       script {             
             sh "python ./testFlask/test.py"
          }
      }     
    }

    if (fileExists('error.txt')) {
      echo 'Yes'
    } else {
      echo 'No' 
    }
   
  }
}

