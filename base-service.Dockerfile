FROM openjdk:7

ARG WORKING_DIR=working_dir
ENV WORKING_DIR=${WORKING_DIR}
# look like k8s shell expansion
# https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d-other-applications.md#note-on-exec-from-and-kubernetes-shell-expansion

WORKDIR /working_dir

ENTRYPOINT ["sh", "-c", "java -jar /$WORKING_DIR/*.jar"]
# And not
# ENTRYPOINT ["java",  "-jar", "/$WORKING_DIR/my-app-1.0-SNAPSHOT.jar"]
# as we need shell substitution
# See https://github.com/scoulomb/myDNS/blob/master/2-advanced-bind/5-real-own-dns-application/6-use-linux-nameserver-part-d.md


