# README

[![Build Status](https://travis-ci.org/scoulomb/sample-maven-app.svg?branch=main)](https://travis-ci.org/scoulomb/sample-maven-app)

Sample Maven app with full Dockerization.

## Generate POM file

Following this guide:
https://maven.apache.org/guides/getting-started/index.html

Created the project by doing

````shell
mvn archetype:generate -DgroupId=com.mycompany.app -DartifactId=my-app -DarchetypeArtifactId=maven-archetype-quickstart -DarchetypeVersion=1.4 -DinteractiveMode=false
````

We can modify the POM to change compiler plugin version
https://maven.apache.org/guides/getting-started/index.html#how-do-i-use-plugins
We should comment `existing maven-compiler-plugin`.
I did not keep it because in docker we have
````shell
Source option 5 is no longer supported. Use 6 or later
````


And similarly we can change `maven-jar-plugin` conf to generate an executable jar

https://stackoverflow.com/questions/32558478/how-to-make-an-executable-jar-using-maven

````xml
<plugin>
  <groupId>org.apache.maven.plugins</groupId>
  <artifactId>maven-jar-plugin</artifactId>
  <configuration>
    <archive>
      <manifest>
        <addClasspath>true</addClasspath>
        <mainClass>com.mycompany.app.App</mainClass>
      </manifest>
    </archive>
  </configuration>
</plugin>
````

So that we can run the jar by doing:

````shell
java -jar target/my-app-1.0-SNAPSHOT.jar
````

Note you can build jar on windows and run it on VM. 
However on Linux we can even do 

````shell
java -jar ./target/*.jar
````

We will leverage this in [base-service.Dockerfile](./base-service.Dockerfile).

## Note on lifecycle

A lifecycle is made of several maven phases
https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html#maven-phases

A maven Phase is Made Up of Plugin Goals
https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#a-build-phase-is-made-up-of-plugin-goals

But we can run a plugin goal alone

The default lifecycle has those phases
https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html#maven-phases

Note a higher phase includes a previous phase.

From pom file comment we can see that

- For jar binding default lifecycle phase and plugin bindings can be found here:
https://maven.apache.org/ref/current/maven-core/default-bindings.html#Plugin_bindings_for_jar_packaging
- Other life cycle and their binding can be found here:
    - clean: https://maven.apache.org/ref/current/maven-core/lifecycles.html#clean_Lifecycle
    - site: https://maven.apache.org/ref/current/maven-core/lifecycles.html#site_Lifecycle

It ia possible to change in pom file those plugin bindings.



## Run via docker

````shell
docker-compose up --build
````

See [compose file](./docker-compose.yaml).

Here we run this compose file in [Travis CI](./.travis.yaml).
But CI could be a specific docker where we also run the coverage.

<!-- in travis sync when adding new repo -->

## Some notes

- In docker we use jdk7 but should use more recent version
- in build section what is really needed is maven-jar-plugin, other line not needed.
It will take last one (or parent if defined)
- archetype generates junit 4 but could use 5  
- we could use exec plugin: https://stackoverflow.com/questions/15869784/how-to-run-a-maven-created-jar-file-using-just-the-command-line
<!-- but wanted to mimic -->
- `RUN mvn clean compile package` is not correct because package => test => compile. T1C is also very useful so:
  `mvn -T1C clean package`, where we have 2 phases of 2 different lifecycle.
  (lifecylce clean has only the phase clean)
  