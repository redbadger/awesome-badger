# Early impressions of Dapr

_[David Laban](../) — June 2021_

It's worth writing down some impressions about dapr, and especially its tooling.

Dapr is intended to sit on top of kubernetes for production deployment, but it also has a "self-hosted" mode that can be accessed via the dapr cli.

`dapr init` installs redis, zipkin and something called the "placement service" as docker containers by default. If you aren't in the mood for running docker, you can `dapr init --slim` and it works fine without (you will need to nuke your ~/.dapr/components first though).

## `dapr run`

`dapr run` has a `--app-port` argument, but the value of this argument is not handed down to the underlying app in any way. I feel like this is a missed opportunity. In a 12-factor app, or something running in a PaaS like heroku, you would typically pass down a PORT environment variable, and the server would listen on that port. I wonder if we could add a `--app-port-environment-variable=PORT` flag, so that you don't have to pass it down via a side-channel (you could even make it dynamically allocate a port, if you don't specify `--app-port`). I suppose you could flip this around by always exporting a static PORT environment variable in the layer above, and always calling `dapr run` with `--app-port=$PORT`.

## Comparison to `docker-compose`

docker-compose adds your project name as a prefix when creating containers, so you get something approximating namespaces. Dapr does not appear to have anything like this, so everything running on your machine lives in the same namespace, as far as I can tell. If dapr becomes popular for open-source projects, I can imagine this causing problems.

dapr is intended to be bolted on to kubernetes pods as sidecars, so it defers the job of process supervision to kubernetes in production. This means that `dapr run` needs to be combined with some other kind of process supervision when used locally.
