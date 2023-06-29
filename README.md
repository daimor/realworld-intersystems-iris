![CI](https://github.com/daimor/realworld-intersystems-iris/workflows/CI/badge.svg) [![codecov](https://codecov.io/gh/daimor/realworld-intersystems-iris/branch/master/graph/badge.svg)](https://codecov.io/gh/daimor/realworld-intersystems-iris)


# ![RealWorld Example App](https://raw.githubusercontent.com/daimor/realworld-intersystems-iris/master/logo.png)

> ### InterSystems IRIS codebase containing real world examples (CRUD, auth, advanced patterns, etc) that adheres to the [RealWorld](https://github.com/gothinkster/realworld) spec and API.


### [Demo](https://github.com/gothinkster/realworld)&nbsp;&nbsp;&nbsp;&nbsp;[RealWorld](https://github.com/gothinkster/realworld)


This codebase was created to demonstrate a fully fledged fullstack application built with [InterSystems IRIS Data Platform](https://www.intersystems.com/products/intersystems-iris/) including CRUD operations, authentication, routing, pagination, and more.

We've gone to great lengths to adhere to the [InterSystems IRIS Data Platform](https://www.intersystems.com/products/intersystems-iris/) community styleguides & best practices.

For more information on how to this works with other frontends/backends, head over to the [RealWorld](https://github.com/gothinkster/realworld) repo.

# InterSystems IRIS Data Platform

[InterSystems IRIS Data Platform](https://www.intersystems.com/products/intersystems-iris/) makes it easier to build high-performance, machine learning-enabled applications that connect data and application silos.

It provides high performance database management, interoperability, and analytics capabilities, all built-in from the ground up to speed and simplify your most demanding data-intensive applications.

As a complete, cloud-first data platform, InterSystems IRIS eliminates the need to integrate multiple technologies, resulting in less code, fewer system resources, less maintenance, and higher ROI.

# How it works

REST API and data storage realized on InterSystems IRIS.

```
.
├── docker-compose.yml  // docker-compose configuration
│
│                       // backend and data server on InterSystems IRIS
├── src                 // source code
├── test                // unit-tests for IRIS
├── Installer.cls       // backend installer in InterSystems IRIS
│
└── web                 // any dockerized frontend
                        // with proxy for `/api` 
                        // to backend http://server:52773/conduit internally
```

Backend on InterSystems IRIS available by default port on `http://server:52773/conduit`. In docker-compose configuration uses port `12000`, and will be available by http://localhost:12000/conduit

# Getting started


## Install docker and docker-compose


https://docs.docker.com/engine/install/

https://docs.docker.com/compose/install/


## Build images


```
docker-compose build 
```

## Start

```
docker-compose up -d
```

Open URL http://localhost/

## Testing


Run Postman/newman tests for REST API. Requires `npm` and `npx` package installed (`npm i -g npx`)

```
APIURL=http://localhost/api ./run-api-tests.sh
```

Run UnitTests with ZPM

```
$ docker-compose exec server iris session iris

CONDUIT> zpm "test realworld -v"
```

## Testing with different frontend


By default it uses [vue](https://github.com/gothinkster/vue-realworld-example-app) frontend, but prepared to use with [angular](https://github.com/gothinkster/angular-realworld-example-app) and [react](https://github.com/gothinkster/react-redux-realworld-example-app) frontends.
Command to switch to another frontend. Select one of the following command

```
web=react docker-compose build web
web=angular docker-compose build web
web=vuew docker-compose build web
```
And start selected fronted by command
```
docker-compose up -d web
```
