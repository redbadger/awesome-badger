# What comes after Kubernetes?

_[Stuart Harris](../) — 4th January 2021_

Some _good_ things came out of 2020! One of the most exciting, for me, was the progress that the global collective of open source software engineers has been making towards the future of services in the Cloud.

Microservices are continuing to gain traction for Cloud applications and Kubernetes has, without question, become their de facto hosting environment. But I think that is all about to change.

Kubernetes is really good. But it does nothing to address what I think is one of the biggest problems we have with microservices — the ratio of functional code, e.g. our core business logic, to non-functional code, e.g. talking to a database, is way too low. If you open up the code of any microservice, or ask any cross-functional team, you'll see what I mean. You can't see the wood for the trees around it. As an industry, we're spending way too much time and effort on things that really don't matter (but are still needed to get the job done). This means that we can't move fast enough (or build enough features) to outpace our competitors.

In this post, I first of all want to explore the Onion architecture, how it applies to microservices and how we might peel off the outer layers of the onion, so that we can focus on the core.

We'll also see how Kubernetes can be augmented to support this idea (with a service mesh like Istio or Linkerd, and a distributed application runtime like DAPR).

Finally, and most importantly we'll ask what comes after Kubernetes (e.g. a WebAssembly actor system) that can support core business logic more natively, allowing us to write that logic in any language and securely connect it to capability providers that we don't have to write ourselves.

## 1. The Onion Architecture

Similar to [Hexagonal Architecture][hexagonal-architecture] (also known as "Ports and Adapters") and [Uncle Bob's Clean Architecture][clean-architecture], the [Onion Architecture][onion-architecture] advocates a structure for our application that allows us to segregate core business logic.

Imagine the concentric layers of an onion where you can only call inwards (i.e. from an outer layer to an inner layer). Let's see how this might work by starting at its core.

I've augmented each layer's description with the simplest code example possible. I've used Rust for this, because it's awesome! Fight me. Even if you don't know Rust, it should be easy to understand this example, but I've added a commentary that may help, just in case. You can try out the example from this [Github repository][onion-code].

![Onion Architecture](./onion.svg)

The "core" is pure in the functional sense, i.e. has no side-effects. This is where our business logic resides. It is exceptionally easy to test because its pure functions only take and return values. In the core, we don't think about IO at all.

```rust
/// 1. Pure. Don't think about IO at all
mod core {
    pub fn add(x: i32, y: i32) -> i32 {
        x + y
    }
}
```

Surrounding the "core" is the "domain", where we _do_ think about IO, but not its implementation. This layer orchestrates our logic, providing hooks to the outside world, whilst having no knowledge of that world (databases etc.).

In this code example, we have to use an asynchronous function. Calling out to a database (or somewhere else, we don't care yet) will take some milliseconds, so it's not something we want to stop for. The `async` keyword tells the compiler to return a `Future` which may complete at some point. The `Result` is implicitly wrapped in this `Future`.

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

Those 2 layers are where all our application logic resides. Ideally we wouldn't write any other code. However, in real life, we have to talk to databases, an event bus, or another service. So the outer 2 layers of the onion are, sadly, necessary.

The "infra" layer is where our IO code goes. This is the code that knows how to call the database, for example.

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

And, finally, the "api" layer is where we interact with our users. We present an API and wire up dependencies (in this example, by passing our "infra" function into our "domain" function):

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

We'll need an entrypoint for our service:

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

Ok, now we have that out of the way, let's see how we can shed the outer 2 layers, so that when we write a service, we only need to worry about our "domain" and our "core" (i.e. what really matters).

## 2. Microservices in Kubernetes

So today, we typically host our microservices in Kubernetes, something like this:

![Microservices in Kubernetes](./microservices.svg)

If each microservice talks to its own database in a cloud hosted service such as Azure CosmosDB, then each would include the same libraries and similar glue code in order to talk to the DB. Worse, if each service is written in a different language, then we would be including (and maintaining) different libraries and glue code for each language.

This problem is addressed today for networking-related concerns by a Service Mesh such as [Istio][istio] or [Linkerd][linkerd]. These products abstract traffic, security, policy and instrumentation into a sidecar container in each pod. This helps a lot because we now no longer need to implement this functionality in each service (and in each service's language).

![Microservices with Service Mesh](./servicemesh.svg)

But, and this is where the fun starts, we can also apply the same logic to abstracting away other application concerns such as those in the outer 2 layers of our onion.

Amazingly, there is an open source product available today that does just this! It's called [Dapr][dapr] (Distributed Application Runtime) from the Microsoft stable and is approaching its 1.0 release. It abstracts away IO-related concerns (i.e. those in our "infra" and "api" layers) and adds distributed application capabilities. If you use Dapr in Kubernetes, it is also implemented as a sidecar:

![Microservices with DAPR](./dapr.svg)

In fact, we can use Dapr and a Service Mesh together, ending up with 2 sidecars and our service (with no networking or IO concerns) in each pod:

![Microservices with Service Mesh and DAPR](./servicemesh_and_dapr.svg)

Now we're getting somewhere! Our service becomes business logic and nothing else!

## 3. The Actor model

Once the outer layers have been shed, you can imagine that the inner layers become a little more suited to the Actor model.

[clean-architecture]: https://blog.cleancoder.com/uncle-bob/2012/08/13/the-clean-architecture.html
[hexagonal-architecture]: https://en.wikipedia.org/wiki/Hexagonal_architecture_(software)
[istio]: https://istio.io/
[linkerd]: https://linkerd.io/
[onion-architecture]: https://jeffreypalermo.com/2008/07/the-onion-architecture-part-1/
[onion-code]: https://github.com/StuartHarris/onion
[dapr]: https://dapr.io/
