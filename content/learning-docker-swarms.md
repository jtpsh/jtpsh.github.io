Title: Learning Docker Swarms
Slug: learning-docker-swarms
Date: 2019-02-10 23:53:40


### Intro

This is the second part of my attempt at learning Docker. I looked at Docker swarms this time.

### The setup

I have 3 VMs running on the same network:

`ubuntu01-manager` - delegated manager  
`ubuntu02` - worker 1  
`ubuntu03` - worker 2

[A bootstrap playbook to setup Docker CE.](https://github.com/jtpsh/learning-docker/blob/master/bootstrap.yml)

`Protip: docker CLI has tab-completions, command options are available as well.`

### Creating a swarm

Creating swarm manager:

```
docker swarm init --advertise-addr <IP>
```

It is important the manager has static IP.

```
root@ubuntu01-manager:~# docker swarm init --advertise-addr 192.168.254.107
Swarm initialized: current node (jld72ruw3baib8ws6t7ap0hnj) is now a manager.

To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5hidm3k2ihs0m938oqvzpa22jt5ueezpcohi999cojeoebz279-272b0wt3h8qzgtiab447rsl9g 192.168.254.107:2377

To add a manager to this swarm, run 'docker swarm join-token manager' and follow the instructions.
```

The command output shows instructions on how to let other nodes join the swarm.

We can now add the two nodes on our swarm as workers

```
root@ubuntu02:~# docker swarm join --token SWMTKN-1-5hidm3k2ihs0m938oqvzpa22jt5ueezpcohi999cojeoebz279-272b0wt3h8qzgtiab447rsl9g 192.168.254.107:2377
This node joined a swarm as a worker.
```
```
root@ubuntu03:~# docker swarm join --token SWMTKN-1-5hidm3k2ihs0m938oqvzpa22jt5ueezpcohi999cojeoebz279-272b0wt3h8qzgtiab447rsl9g 192.168.254.107:2377
This node joined a swarm as a worker.
```

To verify nodes have been added, you have two options:

On the manager, check the `STATUS` and `AVAILABILITY` tab
```
docker node ls
```


On the workers, check the `Swarm` info
```
docker swarm info
```

### More Swarm operations

Don't worry if you forget the token as you can always view it on the manager

Worker token:

```
root@ubuntu01-manager:~# docker swarm join-token worker
To add a worker to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5hidm3k2ihs0m938oqvzpa22jt5ueezpcohi999cojeoebz279-272b0wt3h8qzgtiab447rsl9g 192.168.254.107:2377
```

Manager token:

```
root@ubuntu01-manager:~# docker swarm join-token manager
To add a manager to this swarm, run the following command:

    docker swarm join --token SWMTKN-1-5hidm3k2ihs0m938oqvzpa22jt5ueezpcohi999cojeoebz279-33y4gojorjmnj3r8i2qqlia36 192.168.254.107:2377
```

Leaving the swarm

```
root@ubuntu03:~# docker swarm leave
Node left the swarm.
root@ubuntu03:~# docker info | grep Swarm
Swarm: inactive
WARNING: No swap limit support
root@ubuntu03:~#
```

On the manager, we can see ubuntu03 as `down`

```
root@ubuntu01-manager:~# docker node ls
ID                            HOSTNAME            STATUS              AVAILABILITY        MANAGER STATUS      ENGINE VERSION
jld72ruw3baib8ws6t7ap0hnj *   ubuntu01-manager    Ready               Active              Leader              18.09.1
sb0y021yqdk92eaq41j5wq7m5     ubuntu02            Ready               Active                                  18.09.1
0y3pifnwhdopm8pdioyuj027z     ubuntu03            Down                Active                                  18.09.1
```

### Adding service on the swarm

We'll be using our static site as an example, and using below Dockerfile

```
FROM http:2.4
COPY ./static-site /usr/local/apache2/htdocs/
```

Build the docker image

```
root@ubuntu01-manager:~# docker build -t my-site .
Sending build context to Docker daemon  6.903MB
Step 1/2 : FROM httpd:2.4
 ---> 0eba3d04566e
Step 2/2 : COPY ./static-site /usr/local/apache2/htdocs/
 ---> a57a8ce77062
Successfully built a57a8ce77062
Successfully tagged my-site:latest
```

Running the service

```
root@ubuntu01-manager:~# docker service create --name my-site --replicas 1 static-site
image static-site:latest could not be accessed on a registry to record
its digest. Each node will access static-site:latest independently,
possibly leading to different nodes running different
versions of the image.

08l8qxsjxt1qijgytr5k17n9l
overall progress: 0 out of 1 tasks
1/1: No such image: static-site:latest
^COperation continuing in background.
Use `docker service ps 08l8qxsjxt1qijgytr5k17n9l` to check progress.
root@ubuntu01-manager:~# docker service ps 08l8qxsjxt1qijgytr5k17n9l
ID                  NAME                IMAGE                NODE                DESIRED STATE       CURRENT STATE             ERROR                              PORTS
uib5adqc4z3l        my-site.1           static-site:latest   ubuntu03            Ready               Preparing 2 seconds ago
0qfuufmn0ck5         \_ my-site.1       static-site:latest   ubuntu01-manager    Shutdown            Rejected 3 seconds ago    "No such image: static-site:la…"
gc9evj8hlf3p         \_ my-site.1       static-site:latest   ubuntu03            Shutdown            Rejected 8 seconds ago    "No such image: static-site:la…"
6wnpz8qt1a0j         \_ my-site.1       static-site:latest   ubuntu01-manager    Shutdown            Rejected 13 seconds ago   "No such image: static-site:la…"
1vjomd5ym3ge         \_ my-site.1       static-site:latest   ubuntu01-manager    Shutdown            Rejected 17 seconds ago   "No such image: static-site:la…"
```

Looks like we have a problem.

```
root@ubuntu01-manager:~# docker image ls
REPOSITORY          TAG                 IMAGE ID            CREATED             SIZE
my-site             latest              a57a8ce77062        4 minutes ago       139MB
```

We can see the image on manager, but somehow docker can't see it? `:thinking:`

With little bit of digging (read: a quick google search), I learned the image created on the manager is available only on itself, and not on the whole swarm. The warning message `image static-site:latest could not be accessed on a registry to record its digest` is the hint. The solution is to push the image on a registry, either on Docker Hub or setup a local service. We'll do the latter.

### Setting up a local registry

```
root@ubuntu01-manager:~# docker service create --name registry --publish published=5000,target=5000 registry:2
y7vkch2wbkq9ugrr6b73xtlf2
overall progress: 1 out of 1 tasks
1/1: running   [==================================================>]
verify: Service converged
```
```
root@ubuntu01-manager:~# docker service ps registry
ID                  NAME                IMAGE               NODE                DESIRED STATE       CURRENT STATE                ERROR               PORTS
m9bshi82ni37        registry.1          registry:2          ubuntu02            Running             Running about a minute ago
```
```
root@ubuntu01-manager:~# curl 127.0.0.1:5000/v2/
{}
```

Pushing our image to local registry

The syntax is `docker tag <local> <remote>`

```
root@ubuntu01-manager:~# docker tag my-site:latest 127.0.0.1:5000/my-site
root@ubuntu01-manager:~# docker push 127.0.0.1:5000/my-site
The push refers to repository [127.0.0.1:5000/my-site]
4a66788036dc: Pushed
8fb9d4da1d47: Pushed
679b6a350e9d: Pushed
bc313b7c45f1: Pushed
7fb2893e5a45: Pushed
0a07e81f5da3: Pushed
latest: digest: sha256:f202f0e1ded4caedc8f09a48a8c558214fbae3b495b40b20d7964786cfba5238 size: 1578
```

We can now see our image on two workers:

```
root@ubuntu02:~# curl 127.0.0.1:5000/v2/_catalog
{"repositories":["my-site"]}
```
```
root@ubuntu03:~# curl 127.0.0.1:5000/v2/_catalog
{"repositories":["my-site"]}
```

### Re-trying service creation

```
root@ubuntu01-manager:~# docker service create --name static-site --replicas 1 127.0.0.1:5000/my-site
8zq8ke8gtbgte0rfdchx4xrsp
overall progress: 1 out of 1 tasks
1/1: running   [==================================================>]
verify: Service converged
```
```
root@ubuntu01-manager:~# docker service ps static-site
ID                  NAME                IMAGE                           NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
u2xer3ok2zpn        static-site.1       127.0.0.1:5000/my-site:latest   ubuntu01-manager    Running             Running 39 seconds ago
```

The service is now running... or is it? _cue Vsauce music_

We forgot to publish a port so we can't actually verify our site is runnig without issues.

### Updating a service

```
root@ubuntu01-manager:~# docker service update --publish-add published=80,target=80 static-site
static-site
overall progress: 1 out of 1 tasks
1/1: running   [==================================================>]
verify: Service converged
```
```
root@ubuntu02:~# curl -s 127.0.0.1 | head
<!DOCTYPE html>
<html>
    <head lang="en">
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <title>jtp.sh</title>
        <link rel="stylesheet" type="text/css" href="/theme/css/main.min.css">
    </head>

    <body>
```

Hooray!

### Adding replicas

```
root@ubuntu01-manager:~# docker service update --replicas 10 static-site
static-site
overall progress: 10 out of 10 tasks
1/10: running   [==================================================>]
2/10: running   [==================================================>]
3/10: running   [==================================================>]
4/10: running   [==================================================>]
5/10: running   [==================================================>]
6/10: running   [==================================================>]
7/10: running   [==================================================>]
8/10: running   [==================================================>]
9/10: running   [==================================================>]
10/10: running   [==================================================>]
verify: Service converged
```
```
root@ubuntu01-manager:~# docker service ps static-site
ID                  NAME                IMAGE                           NODE                DESIRED STATE       CURRENT STATE            ERROR               PORTS
leydfex4rznr        static-site.1       127.0.0.1:5000/my-site:latest   ubuntu01-manager    Running             Running 3 minutes ago
u2xer3ok2zpn         \_ static-site.1   127.0.0.1:5000/my-site:latest   ubuntu01-manager    Shutdown            Shutdown 3 minutes ago
9eyoy7pi0qm7        static-site.2       127.0.0.1:5000/my-site:latest   ubuntu03            Running             Running 40 seconds ago
hhain8hzny32        static-site.3       127.0.0.1:5000/my-site:latest   ubuntu03            Running             Running 40 seconds ago
schadoh2hxy4        static-site.4       127.0.0.1:5000/my-site:latest   ubuntu03            Running             Running 39 seconds ago
zncdx54fg41l        static-site.5       127.0.0.1:5000/my-site:latest   ubuntu01-manager    Running             Running 57 seconds ago
98v66jxi5lzq        static-site.6       127.0.0.1:5000/my-site:latest   ubuntu01-manager    Running             Running 53 seconds ago
no4bywzm4fat        static-site.7       127.0.0.1:5000/my-site:latest   ubuntu01-manager    Running             Running 53 seconds ago
uxajuy9d5vo3        static-site.8       127.0.0.1:5000/my-site:latest   ubuntu02            Running             Running 39 seconds ago
glry53msfldf        static-site.9       127.0.0.1:5000/my-site:latest   ubuntu02            Running             Running 38 seconds ago
z4xnqiu9j46x        static-site.10      127.0.0.1:5000/my-site:latest   ubuntu02            Running             Running 39 seconds ago
```

Each node has at least 3 replicas running.

Service availability on a swarm shouldn't be a concern (with given enough replicas) as replicas are launched as soon as one of the workers went down or is being drained.

### References:
Swarm Tutorial: [https://docs.docker.com/engine/swarm/swarm-tutorial/](https://docs.docker.com/engine/swarm/swarm-tutorial/)  
Docker CLI reference [https://docs.docker.com/engine/reference/commandline/docker/](https://docs.docker.com/engine/reference/commandline/docker/)  
Docker swarm availability: [https://docs.docker.com/engine/swarm/swarm-tutorial/drain-node/](https://docs.docker.com/engine/swarm/swarm-tutorial/drain-node/)
