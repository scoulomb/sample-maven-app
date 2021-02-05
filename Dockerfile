FROM maven:3.6-openjdk-11

WORKDIR /working_dir

COPY pom.xml /working_dir/

RUN mvn -T1C dependency:go-offline clean install

COPY src src/

RUN mvn -T1C clean install

RUN mvn clean compile package

RUN ls /working_dir/target

WORKDIR /dist

RUN cp -r /working_dir/target/my-app-1.0-SNAPSHOT.jar /dist/

# https://stackoverflow.com/questions/37254881/is-there-any-way-to-disable-a-service-in-docker-compose-yml
ENTRYPOINT ["echo", "not for run"]