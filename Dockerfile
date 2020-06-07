FROM registry.redhat.io/openshift4/ose-jenkins-agent-base
USER root
RUN yum install -y git python && curl -O https://bootstrap.pypa.io/get-pip.py && python get-pip.py
USER 1001