FROM anapsix/alpine-java
COPY target/spring-petclinic-5.0.0-SNAPSHOT.jar /home/
ENTRYPOINT ["java", "-jar", "/home/spring-petclinic-5.0.0-SNAPSHOT.jar"]
