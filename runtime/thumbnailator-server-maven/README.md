# Thumbnailator HTTP Server

## Build
You can build the whole project running just a maven command as below:

```bash
mvn clean install
```

## Run
After running maven and build the project you can run the server running the jar file. Some environment variables definition are required.  See an example as follow.

```bash
scale=0.1 image_url=http://s3.amazonaws.com/wallpapers2/wallpapers/images/000/000/408/thumb/375.jpg?1487671636 java -Xms128m -Xmx128m -XX:+UseG1GC -jar target/thumbnailator-server-maven-0.0.1-SNAPSHOT.jar
```
