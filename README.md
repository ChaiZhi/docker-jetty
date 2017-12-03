# docker-jetty

Dockerfile to run Jetty on Oracle Java8 for self-customization.

## How to build & run

Clone git repository.

```
$ git clone https://github.com/megmogmog1965/docker-jetty.git
$ cd docker-jetty/
```

You can add \*.war files or nothing before building image.

```
$ cp /path/to/your.war deployment/
```

Build the image from the Dockerfile.

```
$ docker build -t docker-jetty .
```

Run a container.

```
$ docker run -d -p 8080:8080 -p 8585:8585 -p 1099:1099 -v `pwd`/webapps:/var/lib/jetty/webapps docker-jetty
```

You can see a running container.

```
$ docker ps

CONTAINER ID        IMAGE               COMMAND                  CREATED             STATUS              PORTS                                                                    NAMES
3bfac8d93e10        docker-jetty        "/etc/init.d/jetty..."   59 seconds ago      Up 58 seconds       0.0.0.0:1099->1099/tcp, 0.0.0.0:8080->8080/tcp, 0.0.0.0:8585->8585/tcp   wizardly_knuth
```

## Container logs

Use ``docker logs ...`` command. Java process writes logs to stdout.

```
$ docker logs CONTIANER_NAME
```

## Deploy \*.war at runtime

Put \*.war files into ``./webapps`` mounted volume.

```
docker run ... -v `pwd`/webapps:/var/lib/jetty/webapps ...
```

## Exposed ports

|Ports|What for                     |
|:----|:----------------------------|
|8080 |Jetty provides http service. |
|8585 |Java remote debugging port.  |
|1099 |RMI, JMX port for VisualVM.  |

## Author

[Yusuke Kawatsu]


[Yusuke Kawatsu]:https://github.com/megmogmog1965
