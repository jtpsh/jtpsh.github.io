# readme

Static generator for https://jtp.sh


### Build status
[![CircleCI](https://circleci.com/gh/jtpsh/jtpsh.github.io/tree/static-generator.svg?style=svg)](https://circleci.com/gh/jtpsh/jtpsh.github.io/tree/static-generator)


### Building
```
git clone git@github.com:jtpsh/jtpsh.github.io.git
git fetch
git checkout static-generator
source local_setup.sh

make cssminify && make html && \
    make validate && \
    make serve
```

### Updating gh-pages
Every commits pushed to this branch are automatically fed on CirclCI.
See `.circleci/config.yml`


## Docker from base image (Manual)
Since I'm trying to learn Docker, I tried creating image from scratch. Creating base Ubuntu image is straightforward using `deboostrap`.


```
sudo apt install debootstrap
sudo debootstrap bionic bionic
```

Once complete we can now import the image:

```
sudo tar -C bionic -c . | docker import - bionic
```

(You can safely remove the files created from the previous command.)

### Creating Dockerfile

```
# We'll use the image we create earlier
FROM bionic:latest

# Install Apache
RUN apt-get update && apt-get install -y apache2

# Create documentroot
RUN mkdir /var/www/jtp.sh

# Remove default vhost
RUN rm /etc/apache2/sites-enabled/000-default.conf

# Copy of own vhost
COPY apache/jtp.sh.conf /etc/apache2/sites-enabled/jtp.sh.conf

# Copy our static files
COPY output/ /var/www/jtp.sh

# Apache runs on 80 so we'll have to expose that

EXPOSE 80

# To keep docker running, the process has be kept on foreground
# otherwise it will just exit as soon as the command is done
# That is why it's not advisable to use
# `service apache2 start`
CMD apachectl -D FOREGROUND
```

Build the image with `docker build -f Dockerfile.base -t jtp.sh:1.0 .`

`-f` Use a specific Dockerfile.base (default is Dockerfile)
`-t` Give our image a `name:tag`


```
docker build -f Dockerfile.base -t jtp.sh:1.0 .
Sending build context to Docker daemon   54.6MB
Step 1/8 : FROM bionic:latest
 ---> 278a86f574bb
Step 2/8 : RUN apt-get update && apt-get install -y apache2
 ---> Using cache
 ---> ab1c385bfc47
Step 3/8 : RUN mkdir /var/www/jtp.sh
 ---> Using cache
 ---> 36a30a5a9f23
Step 4/8 : RUN rm /etc/apache2/sites-enabled/000-default.conf
 ---> Using cache
 ---> 7d1db1fd3f50
Step 5/8 : COPY apache/jtp.sh.conf /etc/apache2/sites-enabled/jtp.sh.conf
 ---> Using cache
 ---> da8ba0ce5cd9
Step 6/8 : COPY output/ /var/www/jtp.sh
 ---> 698bdade8eb5
Step 7/8 : EXPOSE 80
 ---> Running in 4e21cb556f5e
Removing intermediate container 4e21cb556f5e
 ---> a2b900c04e10
Step 8/8 : CMD apachectl -D FOREGROUND
 ---> Running in 80c128065876
Removing intermediate container 80c128065876
 ---> f2ec0e584d5d
Successfully built f2ec0e584d5d
Successfully tagged jtp.sh:1.0
```

We can confirm the new image has been created:

```
docker image ls jtp.sh:1.0
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
jtp.sh              1.0                 f2ec0e584d5d        46 seconds ago      364MB
```

Running the container:

```
docker container run -p 8000:80 -d jtp.sh:1.0
ebce0f19de8df6bcfd3b998dac0637e7e80843e0b512b99f1e74f6e150fb7ca9

docker container ls
CONTAINER ID        IMAGE               COMMAND                  CREATED              STATUS              PORTS                  NAMES
ebce0f19de8d        jtp.sh:1.0          "/bin/sh -c 'apachec…"   About a minute ago   Up About a minute   0.0.0.0:8000->80/tcp   inspiring_volhard
```

`-p` Setup port-forwarding
`-d` Run in background
