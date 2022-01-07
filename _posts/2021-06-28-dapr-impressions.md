---
layout: post
title:  "Dapr Impressions"
date:   2021-06-28 12:00:00 +0000
permalink: /:slug
user: davidlaban
author: David Laban
excerpt: Early impressions of dapr, its tooling, and how it fits into the universe
---

It's worth writing down some impressions about dapr, and especially its tooling.

Dapr is intended to sit on top of kubernetes for production deployment, but it also has a "self-hosted" mode that can be accessed via the dapr cli.

`dapr init` installs redis, zipkin and something called the "placement service" as docker containers by default. If you aren't in the mood for running docker, you can `dapr init --slim` and it works fine without (you will need to nuke your ~/.dapr/components first though).

## `dapr run`

`dapr run` has a `--app-port` argument, but the value of this argument is not handed down to the underlying app in any way. I feel like this is a missed opportunity. In a 12-factor app, or something running in a PaaS like heroku, you would typically pass down a PORT environment variable, and the server would listen on that port. I wonder if we could add a `--app-port-environment-variable=PORT` flag, so that you don't have to pass it down via a side-channel (you could even make it dynamically allocate a port, if you don't specify `--app-port`). I suppose you could flip this around by always exporting a static PORT environment variable in the layer above, and always calling `dapr run` with `--app-port=$PORT`.

## Comparison to `docker-compose`

docker-compose adds your project name as a prefix when creating containers, so you get something approximating namespaces. Dapr does not appear to have anything like this, so everything running on your machine lives in the same namespace, as far as I can tell. If dapr becomes popular for open-source projects, I can imagine this causing problems.

dapr is intended to be bolted on to kubernetes pods as sidecars, so it defers the job of process supervision to kubernetes in production. This means that `dapr run` needs to be combined with some other kind of process supervision when used locally.

## Distributed tracing

Having a local dev environment that hooks into zipkin by default is really promising. On the FutureNHS project, we ended up struggling with our distributed tracing setup because we weren't using it for local debugging, so when we found a bug on the deployed cluster, we couldn't debug it very easily, because the tracing hadn't been set up correctly.

It turns out that having distributed tracing enabled in the Dapr load balancer isn't a magic bullet. You still need to thread the tracing context through your app (which will take you a day or two to work out how to do, because the opentelemetry libraries want to give you control of **everything**, rather than giving you a simple entrypoint function that will Just Work).

## Placement

Placement has to do with dapr virtual actors. In our badger-brian investigations, we don't really use actors, but the service is up anyway. As I start reading into it, the dapr virtual actors concept is actually really interesting.

## http bindings

Why have they decided to use json-over-http to describe http requests when they could just proxy http
