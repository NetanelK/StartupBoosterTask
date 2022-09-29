# Home Assignment

## Flask App

A simple _'Hello World'_ flask app listening on `0.0.0.0:8888`

Build and run on docker with

```
$ cd app/
$ docker build -t hello_world .
$ docker run -dp 8888:8888 -t hello_world
```

Image can be push to a container registry
