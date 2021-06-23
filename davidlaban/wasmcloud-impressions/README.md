# Early impressions of WasmCloud

_[David Laban](../) — June 2021_

First impressions of technologies are quite important for driving adoption, so I've started writing down my early impressions as I explore different technologies

## Documentation

You start at wasmcloud.dev ("Docs Home"), and can follow a getting started guide from there, but there is also a "Home" link in the top bar that takes you to wasmcloud.com, which links out to a bunch of commercial courses. I haven't looked into the courses, but the fact that they exist feels reassuring.

The rest of the documentation is not particularly polished. There are broken links in a few places, and a handful of typos, including:

- `$ ctl link MCUDTMOOZCVAM5EBNN4U3X2OGHNIY3BKPEW66HY4RTCYYVWXOE7ESVDQ VAG3QITQQ2ODAOWB5TTQSDJ53XK3SHBEIFNK4A YJ5RKAX2UNSCAPHA5M wasmcloud:httpserver PORT=8080` in https://github.com/wasmcloud/examples/tree/main/echo (probably caused by copy-pasta out of the wash shell tui)
- Both Architecture sections are missing (https://wasmcloud.dev/reference/host-runtime/architecture/ and https://wasmcloud.dev/reference/lattice/architecture/). This feels like a job for excalidraw.
- s/on-premise/on-premises/ - https://wasmcloud.dev/reference/lattice/leaf-nodes/

## `wash`

The getting started guide recommends that you have wash set to 250 characters wide. This is a bit ridiculous. It also has a "REPL (Standalone)" thing that flashes in the top-left corner. Why? Can you please just not. (I ended up cloning the repo and patching this out)

Can I just run wash in a daemon mode, and inject commands into it from bash? When looking into this, I went to https://github.com/wasmCloud/wash and found a broken link to `control-interface` (looks like this has been split into the wasmCloud repo).

## wasmcloud

my instinct is always to live in the root of a git repo, so when following along with https://github.com/wasmcloud/examples/tree/main/echo, I did `wasmcloud -m echo/manifest.yaml`. When I got to the point where you

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
