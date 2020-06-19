# Extending Istio with Rust and WebAssembly

_[Viktor Charypar](../) — 20th April 2020_

[Istio](https://istio.io) recently released version 1.5, and one of the major changes in it is the [deprecation of Mixer](https://istio.io/docs/tasks/policy-enforcement/) in favour of [WebAssembly Envoy filters](https://istio.io/blog/2020/wasm-announce/). If none of that sentence made sense to you, but you want to extend Istio or Envoy with custom behaviour, read that last link for some more context, it's a very good summary of the thinking behind the change.

I personally love the idea, partly because it's evidence for WebAssembly being a way bigger thing than it first sounds like. Envoy filters use WebAssembly as a portable, sandboxed compile target. Amazing, and nothing to do with the Web, or assembly.

When I finally decided to try and build one this weekend, it wasn't the smoothest experience, so I decided to write down the steps I used to get everything to work, in case it's useful to anyone else.

We'll use Rust (because it's lovely) to build a simple HTTP filter that injects an extra header into the upstream request, compile it to WebAssembly and deploy into a locally running Envoy.

If you're interested in a more real-world use-case, have a look at the [feature targeting](https://github.com/redbadger/feature-targeting) project I'm working on.

## Envoy WebAssembly filters and the proxy-wasm ABI

In order for Envoy to load a WebAssembly plugin and be able to call into it, and be called by the plugin, we need a stable interface. This is where [proxy-wasm](https://github.com/proxy-wasm) comes in. It defines an Application Binary Interface - a set of functions exported from the WebAssembly module and callable in the runtime. In essence, this is no different from a dynamically linked library (and we'll see that's what it looks like in code as well). If you want to know exactly how this works,
the [docs have got you covered](https://github.com/proxy-wasm/spec/blob/master/docs/WebAssembly-in-Envoy.md).

From ten thousand feet, we need to do three things:

1. Build a piece of Rust code, which implements and uses the ABI
2. Compile the code to WebAssembly
3. Deploy this into an Envoy proxy and test it.

To test, we'll proxy to <http://httpbin.org/headers>, which will just reflect request headers back at us.

## Toolchain

For the first step, proxy-wasm helpfully provides [an SDK](https://github.com/proxy-wasm/proxy-wasm-rust-sdk), which lets us skip all the exporting of functions for dynamic linking and just talk to familiar looking Rust code.

Rust can compile into WebAssembly, we just need to add a new target. Lets use [Rustup](https://rustup.rs/) to do that now:

```sh
$ rustup update
$ rustup target add wasm32-unknown-unknown
```

The deployment of a WASM module is probably the most complicated step. To simplify things, Istio partnered up with Solo.io to streamline the management and deployment of WebAssembly proxy filters and make it feel a bit like building and managing Docker images.

Like Docker, there is an image storage service called [WebAssembly Hub](https://docs.solo.io/web-assembly-hub/latest/) (it uses OCI images too!) and it comes with a CLI called [wasme](https://docs.solo.io/web-assembly-hub/latest/reference/cli/). You can [install it](https://docs.solo.io/web-assembly-hub/latest/installation/) with

```sh
$ curl -sL https://run.solo.io/wasme/install | sh
```

make sure it's in `$PATH` as well, by adding the following to your shell startup script (e.g. `~/.zshrc`).

```sh
export PATH=$HOME/.wasme/bin:$PATH
```

## Rust code

Let's start by making a new rust project with [cargo]

```sh
$ cargo init --lib
     Created library package
```

We'll need to edit `Cargo.toml` a little bit. First, add dependencies:

```toml
[dependencies]
log = "0.4.8"
proxy-wasm = "0.1.0" # The Rust SDK for proxy-wasm
```

We also need to change the crate type to build a dynamically linked library:

```toml
[lib]
path = "src/lib.rs"
crate-type = ["cdylib"]
```

Now we're ready to build the module itself:

```rust
use log::info;
use proxy_wasm as wasm;

#[no_mangle]
pub fn _start() {
    proxy_wasm::set_log_level(wasm::types::LogLevel::Trace);
    proxy_wasm::set_http_context(
        |context_id, _root_context_id| -> Box<dyn wasm::traits::HttpContext> {
            Box::new(HelloWorld { context_id })
        },
    )
}

struct HelloWorld {
    context_id: u32,
}

impl wasm::traits::Context for HelloWorld {}

impl wasm::traits::HttpContext for HelloWorld {
    fn on_http_request_headers(&mut self, num_headers: usize) -> wasm::types::Action {
        info!("Got {} HTTP headers in #{}.", num_headers, self.context_id);
        let headers = self.get_http_request_headers();
        let mut authority = "";

        for (name, value) in &headers {
            if name == ":authority" {
                authority = value;
            }
        }

        self.set_http_request_header("x-hello", Some(&format!("Hello world from {}", authority)));

        wasm::types::Action::Continue
    }
}
```

That's it, only about 40 lines. First we defined a special function called `_start` which is part of the ABI (we use the `no_mangle` macro to preserve the name) and lets us initialise things. In it we set the log level to trace and register a `HttpContext` defined later. HTTP context is one of the three context types available, used to build HTTP filters, along with `RootContext` and `StreamContext`, which you can use for configuration and working with timers, and TCP filters, respectively. You can read the [available APIs](https://github.com/proxy-wasm/proxy-wasm-rust-sdk/blob/master/src/traits.rs), they are fairly straightforward.

The rest of the code defines our `HelloWorld` extension, implements the required `Context` trait and the `HttpContext` trait, which lets us finally implement the `on_http_request_headers` callback. This gets called whenever the proxy is processing HTTP headers. Inside, we `get_http_request_headers`, find one called `:authority` (which holds a `[hostname]:[port]` combination) and then `set_http_request_header` called `x-hello`. Finally we tell Envoy to continue.

That's it for Rust. It was nice while it lasted.

## Building a WebAssembly filter module

The `wasme` CLI supports generating a skeleton code for AssemblyScript and C++, but with Rust, we need to do things manually. Fortunately, `wasme` can build images from pre-compiled `wasm` modules.

First we need to compile our Rust code into a wasm module:

```sh
$ cargo build --target wasm32-unknown-unknown --release
```

This produces a `.wasm` binary inside the `target` folder, which we can copy out:

```sh
cp target/wasm32-unknown-unknown/release/hello_world.wasm ./
```

Next, we'll need a manifest file for a WebAssembly Hub image. Make a new file called `runtime-config.json`:

```json
// runtime-config.json
{
  "type": "envoy_proxy",
  "abiVersions": [
    "v0-541b2c1155fffb15ccde92b8324f3e38f7339ba6",
    "v0-097b7f2e4cc1fb490cc1943d0d633655ac3c522f"
  ],
  "config": {
    "rootIds": ["hello_world"]
  }
}
```

(I got the contents of this file by using `wasme init` with one of the supported languages.)

Now we're ready to build an image:

```sh
$ wasme build precompiled hello_world.wasm --tag hello_world:v0.1
```

You can confirm this succeeded by running

```sh
$ wasme list
NAME                          TAG   SIZE   SHA      UPDATED
docker.io/library/hello_world v0.1  1.9 MB 2968f6d0 12 Apr 20 22:32 BST
```

That's it. For what we're doing, we don't need to push the image to the Hub, we can use the local one, which is nice, no need to register for an account either.

## Deploying and testing with Envoy

This is where I ran into trouble. It should be possible to test the filter [in a locally running Envoy](https://docs.solo.io/web-assembly-hub/latest/tutorial_code/deploy_tutorials/deploying_with_local_envoy/) with `wasme deploy envoy` but this didn't work for me. This works by downloading a Docker image of Envoy and running it with the filter injected. It looks like the version of envoy used by default doesn't support the ABI version implemented by the Rust SDK.

Thankfully, we can change what envoy docker image to use. I decided to go for Istio's proxy

```sh
$ wasme deploy envoy hello_world:v0.1 --envoy-image=istio/proxyv2:1.5.1
```

You should get a lot of logs from a running Envoy. You can now visit <http://localhost:8080/> and you should see the front page of [JSON Placeholder](https://jsonplaceholder.typicode.com/).

You should also see logs from the extension in the Envoy logs:

```
...
[2020-04-13 16:54:28.008][14][info][wasm] [external/envoy/source/extensions/common/wasm/context.cc:1089] wasm log hello_world hello_world : Got 16 HTTP headers in #2.
...
```

Proxying to JSON Placeholder is the default configuration of Envoy, that `wasme` uses for testing. It's kind of useful for API testing, but we're interested in headers. We can change that as well.

Make a file called `envoy-bootstrap.yml` with the following:

```yaml
# envoy-bootstrap.yml
admin:
  access_log_path: /dev/null
  address:
    socket_address:
      address: 0.0.0.0
      port_value: 19000
static_resources:
  listeners:
    - name: listener_0
      address:
        socket_address: { address: 0.0.0.0, port_value: 8080 }
      filter_chains:
        - filters:
            - name: envoy.http_connection_manager
              config:
                codec_type: AUTO
                stat_prefix: ingress_http
                route_config:
                  name: test
                  virtual_hosts:
                    - name: httpbin.com
                      domains: ["*"]
                      routes:
                        - match: { prefix: "/" }
                          route:
                            cluster: static-cluster
                            auto_host_rewrite: true
                http_filters:
                  - name: envoy.router
  clusters:
    - name: static-cluster
      connect_timeout: 0.25s
      type: LOGICAL_DNS
      lb_policy: ROUND_ROBIN
      dns_lookup_family: V4_ONLY
      hosts:
        - socket_address:
            address: httpbin.org
            port_value: 80
            ipv4_compat: true
```

Now start the proxy again, supplying the bootstrap config:

```sh
$ wasme deploy envoy hello_world:v0.1 --envoy-image=istio/proxyv2:1.5.1 --bootstrap=envoy-bootstrap.yml
```

and open <http://localhost:8080/headers>. Among the headers, you should see

```
"X-Hello": "Hello world from localhost:8080"
```

Tadaa! It worked! Next step: ...profit?

## Next steps

And that's it. This is just a toy demo. If you want to see the code, I've [published it on GitHub](http://github.com/charypar/proxy-wasm-demo) complete with a `Makefile` automating the whole thing. You can also check out a slightly more complex wasm
filter in the [feature targeting project](https://github.com/redbadger/feature-targeting) which led me down this rabbit hole.

You can [explore the APIs](https://github.com/proxy-wasm/proxy-wasm-rust-sdk/blob/master/src/traits.rs) in the Rust SDK and read [the latest ABI spec](https://github.com/proxy-wasm/spec/tree/master/abi-versions/vNEXT) to see what else is possible.

WebAssembly filters for Envoy are a great example of where WebAssembly can be extremely useful as a compile target and runtime platform. There are plans to [include proxy-wasm into WASI](https://stackoverflow.com/questions/60969344/what-is-the-relationship-between-wasi-and-proxy-wasm) which is a whole another exciting beast.

If you decide to build an Envoy filter with WebAssembly, I'd love to [hear about it](https://twitter.com/charypar)!
