# Full-stack Rust

_[Stuart Harris](../) — 23rd June 2020_

For a while I've been wondering how practical it is (as of right now) to use [Rust](https://www.rust-lang.org/) for web applications and services on the server _and_ for web UI in the browser. So I've been spending quite a lot of time exploring the developer experience, whilst trying to understand whether Rust in the browser is actually a good idea!

[Viktor Chaypar](https://twitter.com/charypar) and I have been working for a while on an open source [feature targeting project](https://github.com/redbadger/feature-targeting), which currently consists of a [Web Assembly (WASM)](https://webassembly.org/) filter for [Envoy](https://www.envoyproxy.io/) sidecars in [Istio](https://istio.io/), which we've written entirely in Rust.

In this spirit, I thought it would be nice to write a demo application (also entirely in Rust) that we could use to demonstrate the feature-targeting filter in action. I make no excuses for this rather self-indulgent experiment!

The demo application expands on the ubiquitous [TODO MVC](http://todomvc.com/) application, by adding a database and user authentication. It seemed like a good idea because I wouldn't have to write much CSS, and it's simple enough not to get in the way of what I was really trying to prove – that Rust is actually a good fit, wherever you choose to use it.

This is a rough diagram of the setup (drawn in the excellent [excalidraw](https://excalidraw.com/)), where all the orange boxes are (either fully, or partially in the case of the gateway) written in Rust:

![](./architecture.svg)

- The Web UI
  - `seed`
  - `graphql-client`
  - `wasm-pack`
- The GraphQL API
  - `async-graphql`
  - `sqlx`
  - `tide`
  - `smol`
- The Web Server
  - `tide`
  - `smol`
- The Envoy filter
  - `proxy-wasm`
