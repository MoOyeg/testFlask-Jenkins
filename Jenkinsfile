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
          }
      }     
    }

    stage('Run Unit Testing') {
     steps {
       echo "Starting Unit Testing}"
       script {
         try {
           sh "python ./testFlask/test.py"
         } catch (Exception e) {
           error("Build failed at Unittest")
         }
       echo "Unittest Passed"
       }
      }     
    }

    stage('Create Test Version of Application') {
     steps {
       script {
         openshift.withCluster() {
           openshift.withProject( "${DEV_PROJECT}" ){
             def app = openshift.newApp('mysql')  
             def dc = app.narrow('dc')
             def dcmap = dc.object()           
             openshift.apply(dcmap)
           }
         }
       }

      }     
    }
    
    
   
  }
}

