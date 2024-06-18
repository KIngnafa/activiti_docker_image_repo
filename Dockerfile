FROM tomcat:9-jre8
ENV JAVA_OPTS="-Xms512m -Xmx1024m -XX:MaxPermSize=256m -XX:MaxMetaspaceSize=128m"
WORKDIR /usr/local/tomcat/webapps/
RUN mv /usr/local/tomcat/webapps /usr/local/tomcat/webapps2
RUN mv /usr/local/tomcat/webapps.dist /usr/local/tomcat/webapps
RUN rm -rf /usr/local/tomcat/webapps/*
COPY ./activiti-app.war /usr/local/tomcat/webapps/activiti-app.war
EXPOSE 8080
CMD ["catalina.sh", "run"]