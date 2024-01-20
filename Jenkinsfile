// Documentation to help understand what is being done here
// https://plugins.jenkins.io/openshift-client/#plugin-content-creating-objects-easier-than-you-were-expecting-hopefully
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
    // Commenting out Unit Test Due to Python Version
    // stage('Run Unit Testing') {
    //  steps {
    //    echo "Starting Unit Testing"
    //    script {
    //      try {
    //        sh "python ./testFlask/test.py"
    //      } catch (Exception e) {
    //        error("Build failed at Unittest")
    //      }
    //    echo "Unittest Passed"
    //    }
    //   }     
    // }

    //You can run steps in different containers if you choose 
    // with the container('container_name') but according to the docs it defaults to non-jnlp container which works for this use-case
    stage('Create Test Version of Application') {
     steps {
       script {
         openshift.withCluster() {
           openshift.withProject( "${DEV_PROJECT}" ){

          try {
            echo "Attempting to create secret in case it was not created"
            def mysql_secret = [
            "kind": "Secret",
            "metadata": [
                "name": "my-secret",
            ],
            "stringData": [
                "username": "${MYSQL_USER}",
                "password": "${MYSQL_PASSWORD}"
            ]
           ]
           def objs = openshift.create( mysql_secret, '--save-config', '--validate' )
          } catch ( e ) {
            "Couldn't create secret it might already exist: ${e}"
          }

          echo "Creating Mysql Application"
          def fromJSON = openshift.create( readFile( 'mysql.json' ) )
         
          echo "Creating Mysql Service"
          def fromJSON2 = openshift.create( readFile( 'mysql-svc.json' ) )

          echo "Wait until deploy/mysql is available"
          openshift.raw("rollout status deploy/mysql")")   

          echo "deploy/mysql is available"
           
           echo "Creating Main Application"
           //apply = openshift.apply(openshift.raw("new-app ${REPO} --name=${APP_NAME} -l app=${APP_NAME} --env=APP_CONFIG=${APP_CONFIG} --env=APP_MODULE=${APP_MODULE} --env=MYSQL_HOST=${MYSQL_HOST} --env=MYSQL_DATABASE=${MYSQL_DATABASE} --as-deployment-config=true --strategy=source --dry-run --output=yaml").actions[0].out)
           apply = openshift.apply(openshift.raw("new-app ${REPO} --name=${APP_NAME} -l app=${APP_NAME} --env=APP_CONFIG=${APP_CONFIG} --env=APP_MODULE=${APP_MODULE} --env=MYSQL_HOST=${MYSQL_HOST} --env=MYSQL_DATABASE=${MYSQL_DATABASE} --strategy=source --dry-run --output=yaml").actions[0].out)
           //openshift.newApp('https://github.com/MoOyeg/testFlask.git')
           echo "Created Main Application"
             
           echo "Configure Main Application"
           openshift.raw("set env deploy/${APP_NAME} --from=secret/my-secret")
           openshift.raw("expose svc/${APP_NAME}")
           openshift.raw("expose svc/mysql")
           openshift.raw("label deploy/mysql app=${APP_NAME}")
           openshift.raw("label deploy/${APP_NAME} app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("label dc/mysql app.kubernetes.io/part-of=${APP_NAME}")
           openshift.raw("annotate deploy/${APP_NAME} app.openshift.io/connects-to=mysql")
           echo "Configured Main Application"

           echo "Wait until dc/${APP_NAME} is available"
           def dcmainapp = openshift.selector('dc', "${APP_NAME}")
           dcmainapp.rollout().status()
           echo "dc/${APP_NAME} is available"

          }
         }
       }

      }     
    }
    
    stage('Run System Testing') {
     steps {
       echo "Starting System Testing"
       script {
         echo "Obtain ${APP_NAME} service"
         def svc_name = "http://${APP_NAME}.${DEV_PROJECT}.svc:8080"
        //def latestDeploymentVersion = openshift.selector('dc',"simple-python").object().status.latestVersion       
         echo "Test Application Status Code == 200"         
         status_code1 = sh (script: "curl -s -o /dev/null -w \"%{http_code}\" ${svc_name}",returnStdout: true)
         echo "${status_code1}"
         if ( "${status_code1}" == "200" ){
           echo "Application Passed Service Response Test"
         } else {
           error("Application Failed Service Response Test")
         }

       }
      }           
    } 
    
    stage('Approve Promotion to Production') {
      steps {
        timeout(time: 30, unit: 'DAYS') {
        input message: "Promote Application to Production?"
      }
     }
    }

    stage('Promoting Application Code to Production') {
     steps {
       echo "Tagging Application Code For Stable Production"
       script {
         openshift.withCluster() {
         openshift.tag( '${DEV_PROJECT}/${APP_NAME}:latest', '${PROD_PROJECT}/${APP_NAME}:latest')
         }
       echo "Application Promoted to Production"
       }
      }
    }
    // Using Openshift.raw example moved to post section below
    // stage('Remove all Deployments and Services in Testing Project') {
    //  steps {
    //    echo "Removing Deployments and Services for project ${JENKINS_NAMESPACE}"
    //    script {
    //      openshift.withCluster() {
    //        openshift.raw("delete dc/mysql -n ${JENKINS_NAMESPACE}")
    //        openshift.raw("delete svc/mysql -n ${JENKINS_NAMESPACE}")
    //        openshift.raw("delete dc/${APP_NAME} -n ${JENKINS_NAMESPACE}")
    //        openshift.raw("delete svc/${APP_NAME} -n ${JENKINS_NAMESPACE}")
    //        openshift.raw("delete route/${APP_NAME} -n ${JENKINS_NAMESPACE}")
    //      }
    //    echo "Application Promoted to Production"
    //    }
    //   }     
    //  }
  }

  post { 
    always {
      echo "Removing Deployments and Services for project ${DEV_PROJECT}"
      sh "oc delete deploy/mysql -n ${DEV_PROJECT} &> /dev/null || echo Did not delete dc/mysql or does not exist"
      sh "oc delete svc/mysql -n ${DEV_PROJECT} &> /dev/null || echo Did not delete svc/mysql or does not exist"
      sh "oc delete deploy/${APP_NAME} -n ${DEV_PROJECT} &> /dev/null || echo Did not delete dc/${APP_NAME} or does not exist"
      sh "oc delete svc/${APP_NAME} -n ${DEV_PROJECT} &> /dev/null || echo Did not delete svc/${APP_NAME} or does not exist"
      sh "oc delete route/${APP_NAME} -n ${DEV_PROJECT} &> /dev/null || echo Did not delete route/${APP_NAME} or does not exist"
      sh "oc delete route/mysql -n ${DEV_PROJECT} &> /dev/null || echo Did not delete route/mysql or does not exist"
      echo "Application Promoted to Production"
    }
  }
}
