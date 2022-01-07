---
layout: post
title:  "What's Next, After Kubernetes?"
date:   2021-01-14 12:00:00 +0000
user: stuartharris
author: Stuart Harris
excerpt: <p>Kubernetes is really good. But it does nothing to address what I think is one of the biggest problems we have with microservices — the ratio of functional code (e.g. our core business logic) to non-functional code (e.g. talking to a database) is way too low.</p><p>In this post, I first explore the Onion architecture, how it applies to microservices and how we might peel off the outer, non-functional layers of the onion, so that we can focus on the functional core.</p><p>Then we look at how Kubernetes can be augmented to support this idea (with a service mesh, and a distributed application runtime).</p><p>Finally, and most importantly we ask what comes after Kubernetes (spoiler, a WebAssembly actor runtime) that can support core business logic more natively, allowing us to write that logic in any language, run it literally anywhere, and securely connect it to capability providers that we don't have to write ourselves (but could if we needed to).</p>
---

Some _good_ things came out of 2020! An exciting one, for me, was the progress that the global collective of open source software engineers has been making towards the future of services in the Cloud.

Microservices are continuing to gain traction for Cloud applications and [Kubernetes][kubernetes] has, without question, become their de facto hosting environment. But I think that could all be about to change.

Kubernetes is really good. But it does nothing to address what I think is one of the biggest problems we have with microservices — the ratio of functional code (e.g. our core business logic) to non-functional code (e.g. talking to a database) is way too low. If you open up the code of any microservice, or ask any cross-functional team, you'll see what I mean. You can't see the functional wood for the non-functional trees. As an industry, we're spending way too much time and effort on things that really don't matter (but are still needed to get the job done). This means that we can't move fast enough (or build enough features) to provide enough _real_ value.

In this post, I first of all want to explore the Onion architecture, how it applies to microservices and how we might peel off the outer, non-functional layers of the onion, so that we can focus on the functional core.

We'll also see how Kubernetes can be augmented to support this idea (with a service mesh like [Istio][istio] or [Linkerd][linkerd], and a distributed application runtime like [Dapr][dapr]).

Finally, and most importantly we'll ask what comes after Kubernetes (spoiler: a WebAssembly actor runtime, possibly something like [WasmCloud][wasmcloud]) that can support core business logic more natively, allowing us to write that logic in any language, run it literally anywhere, and securely connect it to capability providers that we don't have to write ourselves (but could if we needed to).

## 1. The Onion Architecture

Similar to [Hexagonal Architecture][hexagonal-architecture] (also known as "Ports and Adapters") and [Uncle Bob's Clean Architecture][clean-architecture], the [Onion Architecture][onion-architecture] advocates a structure for our application that allows us to segregate core business logic.

Imagine the concentric layers of an onion where you can only call inwards (i.e. from an outer layer to an inner layer). Let's see how this might work by starting at its core.

I've augmented each layer's description with a simple code example. I've used [Rust][rust] for this, because it's awesome! [Fight me][rust-post]. Even if you don't know Rust, it should be easy to understand this example, but I've added a commentary that may help, just in case. You can try out the example from this [Github repository][onion-code].

![Onion Architecture](/assets/stuartharris/onion.svg)

The _core_ is pure in the functional sense, i.e. it has no side-effects. This is where our business logic resides. It is exceptionally easy to test because its pure functions only take and return values. In our example, our _core_ is just a single function that takes 2 integers and adds them together. In the _core_, we don't think about IO at all.

```rust
/// 1. Pure. Don't think about IO at all
mod core {
    pub fn add(x: i32, y: i32) -> i32 {
        x + y
    }
}
```

Surrounding the _core_ is the _domain_, where we do think about IO, but not its implementation. This layer orchestrates our logic, providing hooks to the outside world, whilst having no knowledge of that world (databases etc.).

In our code example, we have to use an asynchronous function. Calling out to a database (or something else, we actually don't care yet) will take some milliseconds, so it's not something we want to stop for. The `async` keyword tells the compiler to return a `Future` which may complete at some point. The `Result` is implicitly wrapped in this `Future`.

Importantly, our function takes another function as an argument. It's this latter function that will actually do the work of going to the database, so it will also need to return a `Future` and we will need to `await` for it to be completed. Incidentally, the question mark after the `await` allows the function to exit early with an error if something went wrong.

```rust
/// 2. think about IO but not its implementation
mod domain {
    use super::core;
    use anyhow::Result;
    use std::future::Future;

    pub async fn add<Fut>(get_x: impl Fn() -> Fut, y: i32) -> Result<i32>
    where
        Fut: Future<Output = Result<i32>>,
    {
        let x = get_x().await?;
        Ok(core::add(x, y))
    }
}
```

Those 2 inner layers are where all our application logic resides. Ideally we wouldn't write any other code. However, in real life, we have to talk to databases, an event bus, or another service, for example. So the outer 2 layers of the onion are, sadly, necessary.

The _infra_ layer is where our IO code goes. This is the code that knows how to do things like calling a database.

```rust
/// 3. IO implementation
mod infra {
    use anyhow::Result;

    pub async fn get_x() -> Result<i32> {
        // call DB, which returns 7
        Ok(7)
    }
}
```

And, finally, the _api_ layer is where we interact with our users. We present an API and wire up dependencies (in this example, by passing our _infra_ function into our _domain_ function):

```rust
/// 4. inject dependencies
mod api {
    use super::{domain, infra};
    use anyhow::Result;

    pub async fn add(y: i32) -> Result<i32> {
        let result = domain::add(infra::get_x, y).await?;
        Ok(result)
    }
}
```

We'll need an entry-point for our service:

```rust
fn main() {
    async_std::task::block_on(async {
        println!(
            "When we add 3 to the DB value (7), we get {:?}",
            api::add(3).await
        );
    })
}
```

Then, when we run it we see it works!

```bash
cargo run
    Finished dev [unoptimized + debuginfo] target(s) in 0.06s
     Running `target/debug/onion`
When we add 3 to the DB value (7), we get Ok(10)
```

Ok, now we have that out of the way, let's see how we can shed the outer 2 layers, so that when we write a service, we only need to worry about our _domain_ and our _core_ (i.e. what really matters).

## 2. Microservices in Kubernetes

So today, we typically host our microservices in Kubernetes, something like this:

![Microservices in Kubernetes](/assets/stuartharris/microservices.svg)

If each microservice talks to its own database, say in a cloud hosted service such as Azure CosmosDB, then each would include the same libraries and similar glue code in order to talk to the DB. Even worse, if each service is written in a different language, then we would be including (and maintaining) different libraries and glue code for each language.

This problem is addressed today, for networking-related concerns, by a Service Mesh such as [Istio][istio] or [Linkerd][linkerd]. These products abstract away traffic, security, policy and instrumentation into a sidecar container in each pod. This helps a lot because we now no longer need to implement this functionality in each service (and in each service's language).

![Microservices with Service Mesh](/assets/stuartharris/servicemesh.svg)

But, and this is where the fun starts, we can also apply the same logic to abstracting away other application concerns such as those in the outer 2 layers of our onion.

Amazingly, there is an open source product available today that does just this! It's called [Dapr][dapr] (Distributed Application Runtime). It's from the Microsoft stable and is currently approaching its 1.0 release (v1.0.0-rc.2). Although it's only a year old, it has a very active community and has come a long way already with many community-built components that interface with a wide variety of popular cloud products.

Dapr abstracts away IO-related concerns (i.e. those in our _infra_ and _api_ layers) and adds distributed application capabilities. If you use Dapr in Kubernetes, it is also implemented as a sidecar:

![Microservices with Dapr](/assets/stuartharris/dapr.svg)

In fact, we can use Dapr and a Service Mesh together, ending up with 2 sidecars and our service (with no networking or IO concerns) in each pod:

![Microservices with Service Mesh and Dapr](/assets/stuartharris/servicemesh_and_dapr.svg)

Now we're getting somewhere! Our service becomes business logic and nothing else! This is incredibly important! Now, when we look at the source code for our service, we can see the wood — because all the non-functional, non-core, non-business-logic, dull, repetitive, boilerplate code is no longer there.

What's more, our service is now much more portable. It can literally run anywhere, because how it connects to the world around it is the responsibility of Dapr, and is configured declaratively (in Yaml files, just like a service mesh). If you wanted to move the service from Azure to AWS, or even to the edge, you could, without _any_ code changes.

## 3. The Actor model

Once the outer layers have been shed, we're left with a much smaller service, that concerns itself only with doing a job. It's beginning to look a bit like an Actor. Incidentally, Dapr has support for Virtual Actors as well as the services that we already described. This gives us a flexible deployment model for our core logic.

So what is the [Actor Model][actor-model]? Briefly, it's an architectural pattern that allows small pieces of business logic to run (and maintain own state) by receiving and sending messages. Actors are inherently concurrent because they process messages in series. They can only process messages, send messages to other actors, create other actors, and determine how to handle the next message (e.g. by keeping state). The canonical example is an actor that represents your bank account. When you send it a withdrawal message, it deducts from your balance. The way that the next message is handled will depend on the new balance.

[Erlang OTP][erlang-otp] is probably the most famous example of an actor (or "process") runtime organised in supervisor trees. Processes are allowed to crash and errors propagate up the tree. It turns out that this pattern is reliable, safe, and massively concurrent. Which is why it's been so good, for so long, in telecoms applications.

The Dapr Virtual Actor building block can place actors on suitable nodes, hydrating and dehydrating them (with their state) as required. There may be thousands of actors running (or memoised) at any one time.

Depending on what type of application we are building, we can run our logic as a service behind the Dapr sidecar, or as actors supervised by the runtime. Or both. Either way, we have written the logic in the language that is most appropriate for the job, and we haven't had to pollute our code with concerns about how it talks with the outside world.

## 4. WebAssembly

There's one thing that can make our code even more portable: [WebAssembly][webassembly] (Wasm). In December 2019 WebAssembly [became a W3C recommendation][wasm-w3c] and is now the fourth language of the Web (alongside HTML, CSS and JS).

Wasm is great in the browser; all modern browsers support it. But, in my opinion, it becomes really useful on the server, where there are already [tens of different Wasm runtimes][awesome-wasm-runtimes] that we can choose from, each with different characteristics (such as just-in-time vs ahead-of-time compilation, etc). Arguably, the most popular runtime is [Wasmtime][wasmtime], which implements a specification called [WebAssembly System Interface (WASI)][wasi] from the [Bytecode Alliance][bytecode-alliance] that is specifically designed to run untrusted code safely in a Wasm sandbox on the server.

This safety is important — modern microservices are assembled from multiple open source libraries and frameworks and it seems irresponsible to run this code as though we trust it. Yet that's what we do, all the time. Docker containers everywhere could be hosting malicious code that is just hanging around, hiding, and waiting for someone with a black hat to trigger its exploit.

We should be building security _in_, rather than building it _on_. Today, we wrap our containerised microservices with a CyberSecurity industry, instead of making it impossible, in the first instance, for code to do anything that we haven't specifically said it can do. Shifting security left, like this, is called [DevSecOps][devsecops], which is more than just [DevOps][devops] — it's about designing security into our applications from the ground up.

## 5. WasmCloud

So to recap, we want to reduce our code to just the functional business logic — the _core_ — without having to worry about how it talks with the outside world. We want to run this, safely, in a sandbox — e.g. Wasmtime. We need a reliable, secure orchestration framework to supervise and manage our small code components (or Actors). We want location transparency and full portability, so we don't have to worry about whether we're deploying to the cloud, on-prem, or at the edge. And we want to design all this security in, from the ground up.

I think [WasmCloud][wasmcloud] (in the process of being renamed from [waSCC][wasmcloud] – the WebAssembly Secure Capabilities Connector) is heading in this direction. Something like this will be what comes next, after Kubernetes.

![A waSCC host](/assets/stuartharris/wascc-host.svg)

A WasmCloud (or waSCC) host securely connects cryptographically signed Wasm actors to the declared capabilities of well-known providers. The actors are placed and managed by the host nodes, which can self-form a Lattice when connected as [NATs][nats] leaf nodes. Actors can be placed near to suitable providers or distributed across heterogeneous networks that span on-prem, Cloud, edge, IoT, embedded devices, etc.

![A waSCC Lattice](/assets/stuartharris/wascc-lattice.svg)

WasmCloud is not the only thing out there that is following this path. [Lunatic][lunatic] is also interesting (and also written in Rust). Go check it out.

It may be a while before the Wasm actor model becomes viable for production applications, but it's definitely one to watch. Personally, I can't wait for the time when we can literally write distributed applications by just concentrating on the real work we need to do. In the meantime, we can get going now by using [Dapr][dapr], which is good for production workloads today.

By the way, [I made a small side-project][side-project] that creates a WasmCloud Lattice across my MacBook and a Raspberry Pi, and wrote a Wasm actor that controls an OLED display via a native provider running on the Pi host. WasmCloud is moving fast and I will try to keep this up to date, but if you fancy it, have a play, and raise an issue if you want to chat.

[actor-model]: https://en.wikipedia.org/wiki/Actor_model
[awesome-wasm-runtimes]: https://github.com/appcypher/awesome-wasm-runtimes
[bytecode-alliance]: https://bytecodealliance.org/
[clean-architecture]: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
[dapr]: https://dapr.io/
[devops]: https://en.wikipedia.org/wiki/DevOps
[devsecops]: https://www.redhat.com/en/topics/devops/what-is-devsecops
[erlang-otp]: https://en.wikipedia.org/wiki/Erlang_(programming_language)
[hexagonal-architecture]: https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)
[istio]: https://istio.io/
[kubernetes]: https://kubernetes.io
[linkerd]: https://linkerd.io/
[lunatic]: https://github.com/lunatic-lang/lunatic
[nats]: https://nats.io/
[onion-architecture]: https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/
[onion-code]: https://github.com/StuartHarris/onion
[rust-post]: https://blog.red-badger.com/now-is-a-really-good-time-to-make-friends-with-rust
[rust]: https://www.rust-lang.org/
[side-project]: https://github.com/redbadger/rpi-wascc-demo
[wasi]: https://wasi.dev/
[wasm-w3c]: https://www.w3.org/2019/12/pressrelease-wasm-rec.html.en
[wasmcloud]: https://wascc.dev/
[wasmtime]: https://github.com/bytecodealliance/wasmtime
[webassembly]: https://webassembly.org/
