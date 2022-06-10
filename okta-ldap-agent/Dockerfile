FROM centos:7

RUN yum install -y https://downloads.okta.com/artifacts/JAVA_LDAP/05.12.00/OktaLDAPAgent-05.12.00-08cac936966b.x86_64.rpm \
    && yum clean all

ADD run-agent.sh /run-agent.sh

ENTRYPOINT /run-agent.sh