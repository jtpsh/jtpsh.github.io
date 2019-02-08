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

