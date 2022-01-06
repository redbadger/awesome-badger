---
layout: post
title:  "wasmCloud Impressions"
date:   2021-07-06 12:00:00 +0000
user: davidlaban
author: David Laban
execerpt: Early impressions of WasmCloud
---

First impressions of technologies are quite important for driving adoption, so I've started writing down my early impressions as I explore different technologies.

WasmCloud is an application platform built on WASM (like erlang's BEAM, but you deploy WASM to it rather than erlang).

## Documentation

You start at wasmcloud.dev ("Docs Home"), and can follow a getting started guide from there, but there is also a "Home" link in the top bar that takes you to wasmcloud.com, which links out to a bunch of commercial courses. I haven't looked into the courses, but the fact that they exist feels reassuring.

The rest of the documentation is not particularly polished. There are broken links in a few places, and a handful of typos, including:

- [ ] `$ ctl link MCUDTMOOZCVAM5EBNN4U3X2OGHNIY3BKPEW66HY4RTCYYVWXOE7ESVDQ VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4A YJ5RKAX2UNSCAPHA5M wasmcloud:httpserver PORT=8080` in https://github.com/wasmcloud/examples/tree/main/echo (probably caused by copy-pasta out of the wash shell tui)
- [ ] Both Architecture sections are missing (https://wasmcloud.dev/reference/host-runtime/architecture/ and https://wasmcloud.dev/reference/lattice/architecture/). This feels like a job for excalidraw.
- [ ] s/on-premise/on-premises/ - https://wasmcloud.dev/reference/lattice/leaf-nodes/
- [ ] https://crates.io/crates/wash-cli "control-interface" links to https://github.com/wasmcloud/wasmcloud/tree/main/crates/control-interface, which is a broken link.
- [ ] Get some CI to check that they don't have any broken links?

## `wash`

The getting started guide recommends that you have wash set to 250 characters wide. This is a bit ridiculous. It also has a "REPL (Standalone)" thing that flashes in the top-left corner. Why? Can you please just not. (I ended up cloning the repo and patching this out)

Can I just run wash in a daemon mode, and inject commands into it from bash? When looking into this, I went to https://github.com/wasmCloud/wash and found a broken link to `control-interface` (looks like this has been split into the wasmCloud repo).

## wasmcloud

My instinct is always to live in the root of a git repo, so when following along with https://github.com/wasmcloud/examples/tree/main/echo, I did `wasmcloud -m echo/manifest.yaml`. This caused wasmcloud to try resolving .wasm filenames in the root of the repo rather than in the echo dir. It would be much cleaner for imports to be relative to the manifest file rather than wasmcloud's `$PWD`.

- [ ] This probably isn't a very difficult fix. I should open an issue or make a PR at some point.

## docker-compose

I like that their instructions get you to run a docker registry on localhost:5000 in their docker-compose setup. When following along with the dapr kubernetes instructions, they wanted you to use a real container registry, so you end up uploading your images and downloading them, even though you are only running things on localhost (Cedd flagged this at the time, but I couldn't remember off the top of my head what the best way to do it was). This way is much nicer.

Once you have this working, it starts a NATS server, so you end up in lattice mode. You can then leave the wash shell in a background tab and type commands like `wash ctl get hosts` and get output from stdout where you expect, which makes me want to throw up a bit less.

## zero downtime migrations

I wanted to tear down the `wash` ui entirely, because it makes me sad. Could I add a wasmcloud host on the command-line and then give it a new web server capability provider and tear down the wash node?

- Starting a new node:
  - `wasmcloud`
  - `wash ctl get hosts`
- ... there is no way to migrate actors, so create a new one
  - `wash ctl start actor localhost:5000/echo:0.2.2`
  - ... oh, that comes up with the same ID, doesn't it? Does that mean it's already linked to the http server?
  - Maybe? I'm not sure.
- What about a capability provider?
  - `wash ctl start provider wasmcloud.azurecr.io/httpserver:0.11.1`
  - the capability provider then spits out: `thread '<unnamed>' panicked at 'called `Result::unwrap()`on an`Err` value: Os { code: 48, kind: AddrInUse, message: "Address already in use" }', src/lib.rs:91:14`, which is not **hugely** surprising. This wouldn't be a problem if it was running in a docker container, I suppose. It is possible to make this work on linux using SO_REUSEPORT (https://lwn.net/Articles/542629/), but it's a huge hack, and I would not expect actix to support this out of the box.
- Okay, then bring down the original node, and see what happens:
  - `curl localhost:8080/echo`: `curl: (7) Failed to connect to localhost port 8080: Connection refused`
  - Not surprising, given the panic
- Can we kick the provider into action again?
  - `wash ctl link MDNYN4IMBBLOCOTWSRES4NLLLHAMH6UEX527K7M6HPEGRZFG3HVHTXJL VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4AYJ5RKAX2UNSCAPHA5M wasmcloud:httpserver PORT=8080`
  - `curl localhost:8080/echo`: `{"method":"GET","path":"/echo","query_string":"","headers":{"host":"localhost:8080","accept":"*/*","user-agent":"curl/7.64.1"},"body":[]}`
  - looks like that worked.

I didn't get any indication that my second capability provider was in a non-functioning state, apart from the panic in the logs. This isn't hugely encouraging.

## What next?

Probably try starting a wasmcloud host inside docker, and retry the above dance.

> In order to do this, I made an excursion into setting up the appropriate security creds for my own NATS cluster. This ended up defeating me. I might try again following a tutorial, rather than going it alone in a docker-compose sandbox. I ended up creating an NGS Developer account.

## Connecting via NGS

If you want to connect via a leaf node, follow along with this tutorial to get a leaf node set up: https://docs.nats.io/nats-server/configuration/leafnodes#leaf-node-example-using-a-remote-global-service

If you want to do it all in a single process, you can do it via command-line arguments or environment variables (thanks `structopt`):

```bash
CONTROL_HOST=connect.ngs.global \
RPC_HOST=connect.ngs.global \
CONTROL_CREDS=$HOME/.nkeys/creds/synadia/leaftest/leaftestuser.creds \
RPC_CREDS=$HOME/.nkeys/creds/synadia/leaftest/leaftestuser.creds \
wasmcloud
```

## `wash` control plane access

Connecting `wash` to a local leaf node seems to be a supported configuration. There doesn't seem to be a way to specify a control-plane credentials file.

- [x] Maybe I will make a patch for this. Done: https://github.com/wasmCloud/wash/pull/146

It seems that control plane access from the wasm host is typically passwordless via the leaf node. This makes me nervous. Control-plane access feels like it's equivalent to root access to your entire cluster. If anyone manages to compromise the wasm sandbox, or any of your capability providers then they just need to write `pub $some.topic $some.payload` to tcp localhost:4222.

- [ ] work out what `$some.topic $some.payload` needs to look like to be sufficiently scary

## Developer experience Experiment

Let's make a TodoMVC demo

https://github.com/redbadger/wasmcloud-examples/projects/1

There are a bunch of things in our backlog that were paper cuts that are probably easy to fix.

### Adding a logging capability

> [2021-07-01T12:53:03Z ERROR] The target wasmcloud:logging was not found as an actor public key, an actor call alias, or as the contract ID in an existing link from source actor MBQ3PZKT6JSEAL4UH7WPZDR2OK7WESH352XH56ORRFC6EE4YPYE5JAEX

This happened because I wrote a `warn!()` line in my `#[actor::init]` function. There could probably be some diagnostic hints for this.

### Actor ids

It's very frustrating that you have to find a way to take the actor id from `target/*/*/whatever_s.wasm` or `wasmcloud.azurecr.io/kvcounter:0.2.0` and paste it into your `manifest.yaml` (or side-loading it via `${VAR:default}` environment variable hackery)

Really, I feel like the manifest format wants a way to say "whatever id you find at the following path/container registry url", and then you could store the mappings from path to signature in a lockfile, that you can optionally check in. I should make a ticket for this.

### `wash` again

We ended up using `wash --watch` in our example's Makefile. This gave the hot-reloading experience, but also forced us to use `wash`. It makes sense that `wasmcloud --watch` isn't a thing, since it's not really a thing that you would expect to need in production, but `wash`'s TUI is really terrible. A reasonable middle-ground might be to have a mode similar to `bluetoothctl` on linux, where there is a prompt at the bottom, and logs are printed above the prompt, so `wash --no-tui` becomes a repl with streaming logs above. I think there is some black magic involved in making this work though, so I'm not expecting anything soon.

## Scaling

In wasmcloudland, the unit of scale is wasmcloud host (like it is a pod in kubernetesland). There is no way to scale actors within a single wasmcloud host. There is a ticket about this already, at https://github.com/wasmCloud/wasmCloud/issues/54. It's definitely worth waiting for them to get this right before adopting wasmcloud for real applications.

## Conclusions

(Yes: I'm introducing things in my conclusion section that don't appear anywhere else in the document. Sue me.)

I think that most of the things above are paper-cuts, and symptoms of the fact that wasmcloud isn't very mature yet. The wasmcloud team is small, and they seem to be focussing on the big architectural decisions, so we can expect a bit of a lack of polish as the big ticket items are figured out.

Architecturally, wasmcloud feels like it's what the future will look like. In the next couple of years, I expect that either wasmcloud will get there or something will come along that looks surprisingly like wasmcloud and get to a polished platform first. Either way, learning wasmcloud has given me a glimpse into the future.
