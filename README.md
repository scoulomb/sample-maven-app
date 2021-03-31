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

## Run directly

````shell
mvn -T1C clean install
java -jar ./target/*.jar
````

<!-- we did this to mimic a java framework behavior in Docker as done below -->

## Run via docker

````shell
docker-compose up --build
````

See [compose file](./docker-compose.yaml).

Here we run this compose file in [Travis CI](.travis.yml).
But CI could be a specific docker where we also run the coverage.

<!-- in travis sync when adding new repo -->

## Alternative to `java -jar`: use `exec:java`

We can execute with maven exec rather than doing `java -jar ./target/*.jar`.
See https://stackoverflow.com/questions/15869784/how-to-run-a-maven-created-jar-file-using-just-the-command-line

You need to
- Add to your pom file (in `pluginManagement` or `plugins` see https://stackoverflow.com/questions/10483180/what-is-pluginmanagement-in-mavens-pom-xml)

````xml
 <build>
    <pluginManagement>
      <plugins>
        <plugin>
          <groupId>org.codehaus.mojo</groupId>
          <artifactId>exec-maven-plugin</artifactId>
          <version>1.2.1</version>
          <configuration>
            <mainClass>com.mycompany.app.App</mainClass>
          </configuration>
        </plugin>
      </plugins>
    </pluginManagement>
</build>
````
- and do the `install` before

So the command becomes

````shell
mvn clean install 
mvn exec:java
````

or 

````shell
mvn clean install exec:java
````

This is used here: https://github.com/scoulomb/effective-java

## Note on lifecycle

### Hierarchy

A build lifecycle (Clean, Default, Site) is made of several Maven build phases.
https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html#maven-phases

A Maven build Phase is Made Up of Plugin Goals.
See https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#a-build-phase-is-made-up-of-plugin-goals

But we can run a plugin goal alone as above with exec.

In short
- `Maven` has  3 `lifecycles`
 - which are attached to `phases`
 - which executes `plugin goals`. 

### Lifecycles and their phase

- Clean has phases:
  - `pre-clean`,
  - `clean`,
  - `post-clean`.
- Default has phases:
  - `validate`,
  - `initialize`,
  - `generate-sources`,
  - `process-sources`,
  - `generate-resources`,
  - `process-resources`,
  - `compile`,
  - `process-classes`,
  - `generate-test-sources`,
  - `process-test-sources`,
  - `process-test-resources`,
  - `test-compile`,
  - `process-test-classes`,
  - `test`,
  - `prepare-package`,
  - `package`,
  - `pre-integration-test`,
  - `integration-test`,
  - `post-integration-test`,
  - `verify`,
  - `install`,
  - `deploy`.
- Site has phases:
  - `pre-site`,
  - `site`,
  - `post-site`,
  - `site-deploy`.

See
- https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#lifecycle-reference
- https://maven.apache.org/guides/getting-started/maven-in-five-minutes.html#maven-phases


Note a higher phase includes a previous phase.

The phases named with hyphenated-words (pre-*, post-*, or process-*) are not usually directly called from the command line.
Command line is calling phase of a lifecycle.

See ttps://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#some-phases-are-not-usually-called-from-the-command-line

### Builtin lifecycle bindings (Lifecycle's phase and plugin goal)

Those phases are by default attached to plugin-goals: https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#built-in-lifecycle-bindings

### But we can attach new plugin goal to a phase


https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#plugins

> Plugins are artifacts that provide goals to Maven


There are 2 ways:
- we use plugin's default phase
- we explicitly define the phase

Here is a **fictional** example given in the doc
````xml
<plugin>
   <groupId>com.mycompany.example</groupId>
   <artifactId>display-maven-plugin</artifactId>
   <version>1.0</version>
   <executions>
     <execution>
       <phase>clean</phase>
       <goals>
         <goal>time</goal>
       </goals>
     </execution>
   </executions>
 </plugin>
````

We will add the following plugin goal to following phase using explicit phase definition. 
- `exec:run` plugin in compile phase 
- `jacoco:check` plugin in compile phase

````xml
<project>
  [...]
  <build>
    <pluginManagement>
    [...]
      <plugins>
        <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <version>3.0.0</version>
          </plugin>
      </plugins>      
    </pluginManagement>
    <plugins>
      <plugin>
        <groupId>org.codehaus.mojo</groupId>
        <artifactId>exec-maven-plugin</artifactId>
        <executions>
          <execution>
            <phase>compile</phase>
            <id>exec</id>
            <goals>
              <goal>java</goal>
            </goals>
            <configuration>
              <mainClass>com.mycompany.app.App</mainClass>
            </configuration>
          </execution>
        </executions>
        <configuration>
          <mainClass>com.mycompany.app.App</mainClass>
        </configuration>
      </plugin>
      <plugin>
        <groupId>org.jacoco</groupId>
        <artifactId>jacoco-maven-plugin</artifactId>
        <version>0.7.9</version>
        <executions>
          <execution>
            <id>prepare-agent</id>
            <goals>
              <goal>prepare-agent</goal>
            </goals>
          </execution>
          <execution>
            <phase>compile</phase>
            <id>check</id>
            <goals>
              <goal>check</goal>
            </goals>
            <configuration>
              <rules>
                <rule implementation="org.jacoco.maven.RuleConfiguration">
                  <element>BUNDLE</element>
                  <limits>
                    <limit implementation="org.jacoco.report.check.Limit">
                      <counter>INSTRUCTION</counter>
                      <value>COVEREDRATIO</value>
                      <minimum>0.02</minimum>
                    </limit>
                  </limits>
                </rule>
              </rules>
            </configuration>
          </execution>
          <execution>
            <id>report</id>
            <goals>
              <goal>report</goal>
            </goals>
          </execution>
        </executions>
      </plugin>
    </plugins>
    [...]
  </build>
</project>
````

Be careful to define the plugin in `build/plugins` and not `build/pluginManagement/plugins` otherwise it won't work.
From https://stackoverflow.com/questions/10483180/what-is-pluginmanagement-in-mavens-pom-xml

> pluginManagement: is an element that is seen along side plugins. Plugin Management contains plugin elements in much the same way, except that rather than configuring plugin information for this particular project build, it is intended to configure project builds that inherit from this one. However, this only configures plugins that are actually referenced within the plugins element in the children. The children have every right to override pluginManagement definitions.

So we can specify a global version in `pluginManagement` we show an example of this for `exec` plugin.
But we could set the version  in `build/plugins`.

<!-- equivalent made in 
core/pull-requests/156/diff
-->
After adding this `mvn clean install`, which include the compile phase, will output

````shell
[INFO] --- exec-maven-plugin:3.0.0:java (exec) @ my-app ---
        Hello World!
[...]
[INFO] --- jacoco-maven-plugin:0.7.9:report (report) @ my-app ---
[INFO] Loading execution data file C:\Users\scoulombel\dev\sample-maven-app\target\jacoco.exec
[INFO] Analyzed bundle 'my-app' with 1 classes

````

Other intersting plugin is the docker plugin:
https://codefresh.io/howtos/using-docker-maven-maven-docker/

### It is also possible to add bindings to default binding

#### Example 1

We had seen here:  https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#built-in-lifecycle-bindings.
For instance the `clean` plugin works like any other plugin.
We can define in plugin management section (for version lock), but we can also specify additional binding!

````xml
<build>
  <pluginManagement>
  [...]
  </pluginManagement>
  <plugins> 
    <plugin>
      <artifactId>maven-clean-plugin</artifactId>
      <version>3.1.0</version>
      <executions>
        <execution>
          <phase>compile</phase>
          <id>report</id>
          <goals>
            <goal>clean</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>
````
Then if running 

````shell
mvn compile
````

output is 

````shell
[INFO]
[INFO] --- maven-compiler-plugin:3.8.0:compile (default-compile) @ my-app ---
[INFO] Changes detected - recompiling the module!
[INFO] Compiling 1 source file to C:\Users\scoulombel\dev\sample-maven-app\target\classes
[INFO]
[INFO] --- maven-clean-plugin:3.1.0:clean (report) @ my-app ---
[INFO] Deleting C:\Users\scoulombel\dev\sample-maven-app\target
````

It will clean what has just been compiled.

`mvn clean` constinue working.

#### Second example

````xml
<build>
  <pluginManagement>
  [...] 
  </pluginManagement>
  <plugins>
    <plugin>
      <artifactId>maven-install-plugin</artifactId>
      <executions>
        <execution>
          <phase>validate</phase>
          <id>yop</id>
          <goals>
            <goal>help</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
    <plugin>
      <artifactId>maven-install-plugin</artifactId>
      <version>2.5.1</version>
      <executions>
        <execution>
          <phase>package</phase>
          <id>yop</id>
          <goals>
            <goal>install</goal>
          </goals>
        </execution>
      </executions>
    </plugin>
  </plugins>
</build>

````

````shell
mvn clean install
````

will output

````shell
[INFO] --- maven-install-plugin:2.5.1:install (yop) @ my-app ---
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\target\my-app-1.0-SNAPSHOT.jar to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.jar
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\pom.xml to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.pom
[INFO]
[INFO] --- maven-install-plugin:2.5.1:help (yop) @ my-app ---
[INFO] Apache Maven Install Plugin 2.5.1
  Copies the project artifacts to the user's local repository.

This plugin has 3 goals:

install:help
  Display help information on maven-install-plugin.
  Call mvn install:help -Ddetail=true -Dgoal=<goal-name> to display parameter
  details.

install:install
  Installs the project's main artifact, and any other artifacts attached by
  other plugins in the lifecycle, to the local repository.

install:install-file
  Installs a file in the local repository.


[INFO]
[INFO] --- maven-install-plugin:2.5.1:install (default-install) @ my-app ---
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\target\my-app-1.0-SNAPSHOT.jar to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.jar
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\pom.xml to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.pom
[INFO] ------------------------------------------------------------------------
[INFO] BUILD SUCCESS
[INFO] ------------------------------------------------------------------------
[INFO] Total time:  2.742 s
[INFO] Finished at: 2021-03-31T20:55:22+02:00
[INFO] ------------------------------------------------------------------------
````

We can we have:
- goal`install:install` of the default binding install phase 
- goal `install:help` (`validate` additional binding made in pom)
- goal `install:install` (`package` additional binding made in pom).

Note for all cases it took version of `build/plugins`.

If we change, goal `install:install`  and bind it to `install` phase, it will be runned twice (`default-install` + `yop`):

````shell
[INFO] --- maven-install-plugin:2.5.1:install (default-install) @ my-app ---
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\target\my-app-1.0-SNAPSHOT.jar to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.jar
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\pom.xml to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.pom
[INFO]
[INFO] --- maven-install-plugin:2.5.1:install (yop) @ my-app ---
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\target\my-app-1.0-SNAPSHOT.jar to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.jar
[INFO] Installing C:\Users\scoulombel\dev\sample-maven-app\pom.xml to C:\Users\scoulombel\.m2\com\mycompany\app\my-app\1.0-SNAPSHOT\my-app-1.0-SNAPSHOT.pom
````


### Same setup can be done in a profile

````xml
<project>
  [...]
  <profiles>
    <profile>
      <id>cov</id>
      <build>
        <plugins>
          <plugin>
            <groupId>org.codehaus.mojo</groupId>
            <artifactId>exec-maven-plugin</artifactId>
            <executions>
              <execution>
                <phase>compile</phase>
                <id>exec</id>
                <goals>
                  <goal>java</goal>
                </goals>
                <configuration>
                  <mainClass>com.mycompany.app.App</mainClass>
                </configuration>
              </execution>
            </executions>
            <configuration>
              <mainClass>com.mycompany.app.App</mainClass>
            </configuration>
          </plugin>
          <plugin>
            <groupId>org.jacoco</groupId>
            <artifactId>jacoco-maven-plugin</artifactId>
            <version>0.7.9</version>
            <executions>
              <execution>
                <id>prepare-agent</id>
                <goals>
                  <goal>prepare-agent</goal>
                </goals>
              </execution>
              <execution>
                <phase>compile</phase>
                <id>check</id>
                <goals>
                  <goal>check</goal>
                </goals>
                <configuration>
                  <rules>
                    <rule implementation="org.jacoco.maven.RuleConfiguration">
                      <element>BUNDLE</element>
                      <limits>
                        <limit implementation="org.jacoco.report.check.Limit">
                          <counter>INSTRUCTION</counter>
                          <value>COVEREDRATIO</value>
                          <minimum>0.02</minimum>
                        </limit>
                      </limits>
                    </rule>
                  </rules>
                </configuration>
              </execution>
              <execution>
                <id>report</id>
                <goals>
                  <goal>report</goal>
                </goals>
              </execution>
            </executions>
          </plugin>
        </plugins>
      </build>
    </profile>
  </profiles>
</project>

````

Covergae will be runned only if we launch the right provile

````shell
mvn clean install  -Pcov
````

<!-- result is core/pull-requests/156/ -->

## plugin version 

Set last version for plugin, see maven central.
We coud use use renovate!! 


## Some notes

- In docker we use jdk7 but should use more recent version
- archetype generates junit 4 but could use 5  
- we can exec plugin: https://stackoverflow.com/questions/15869784/how-to-run-a-maven-created-jar-file-using-just-the-command-line
or modify `maven-jar-plugin` setup and execute the jar as shown in this doc.
- `RUN mvn clean compile package` is not correct because package => test => compile. T1C is also very useful so:
 `mvn -T1C clean package`, where we have 2 phases of 2 different lifecycle.
(lifecycle clean has only 1 phase which has for  default plugin goal binding `clean:clean`: https://maven.apache.org/guides/introduction/introduction-to-the-lifecycle.html#built-in-lifecycle-bindings)
- when doing `mvn clean:clean` or `mvn clean:help`, we run the clean plugin goal directly.  

<!-- ALL ABOVE IS CLEAR AND OK -->

## Links

- This is applied here: https://github.com/scoulomb/effective-java
<!-- I retrofit exec OK, different project tracked -->
- Link to renovate: https://github.com/renovatebot/renovate or https://dependabot.com/
<!-- different project tracked -->

## Skipping test 

https://maven.apache.org/surefire/maven-surefire-plugin/examples/skipping-tests.html

````shell
mvn clean install -DskipTests # skip test run only but compile
mvn clean install -Dmaven.test.skip=true # skip test run + test compile
````

<!-- working correctyl here,
ccm issue as run test  -DskipTests (SUITE-7816) and thus in deliver build. tracked outside --> 
