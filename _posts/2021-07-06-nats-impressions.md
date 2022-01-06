---
layout: post
title:  "NATS Impressions"
date:   2021-07-06 13:00:00 +0000
user: davidlaban
author: David Laban
excerpt: Early impressions of NATS, its tooling, and how it fits into the universe
---

First impressions of technologies are quite important for driving adoption, so I've started writing down my early impressions as I explore different technologies.

NATS is a distributed messaging system.

## Protocol

NATS prides itself on its protocol's simplicity. It is a text based protocol with length-encoded payloads and a very small number of verbs, a bit like http 1.0. My first introduction to NATS was the keynote video on their website though (https://www.youtube.com/watch?v=lHQXEqyH57U), which talks about private keys and JWTs, so this initial simplicity feels like a trap.

## Reliability

> If the client reaches this internal limit, it will drop messages and continue to process new messages. This is aligned with NATS at most once delivery. It is up to your application to detect the missing messages and recover from this condition.

-- https://docs.nats.io/nats-server/nats_admin/slow_consumers

This is a different approach from other queueing systems that I have used. I am a little bit wary.

## Security

It's slightly concerning to find out that `--routes=nats://ruser:T0pS3cr3t@nats:6222` is baked into the default nats image. I wonder how many installations are running with that default exposed to the public internet. (I have heard that the security doesn't come from secrets stored in the cluster though, so this might not be important?)

## Documentation

I started reading down the sidebar of the NATS docs from https://docs.nats.io/nats-server/installation and ended up encountering NATS 2.0 auth concepts at the same as JetStream. I can't remember how that happened. I'm now cycling back around to the top of the docs sidebar, and seeing whether the learning concepts flow a bit better.

## Request-Reply

This feels like the way you do blocking-style function calls to other actors in Erlang (typically the message-sending and response-waiting logic is hidden away behind the actor's public API interface in Erlang. I expect that you would do something similar when using Request-Reply in NATS. Maybe you would wrap up the interface in an IDL and do codegen to generate an ergonomic interface?).

This feels very positive. This pattern of communication isn't really a thing in RabbitMQ-land, and I have seen people do highly questionable things like dispatching a message and then polling a database to ensure that the message was actioned before returning from a web request. Hopefully we won't see anything like this in NATS-land. I'm sure we'll find many other pathological anti-patterns though.

## Queue Groups

Their [concepts page on queue groups](https://docs.nats.io/nats-concepts/queue) says that you can do some magic with consumer groups, but doesn't really say how they're configured. I wonder whether misconfigured queue groups are a thing that you see in production. I guess I'll find out when I read their tutorial.

## Acknowledgements and Sequence Numbers

These both fall into the "we're providing you with an unreliable channel" bucket. I don't think that I would want my business logic to be worrying about things like this. I wouldn't be surprised if real-world NATS applications end up having multiple layers of abstraction on top of these concepts.

## Acronyms and glossary

The NATS ecosystem is full of bullshit acronyms. I think the maintainers think they're funny. They are also big into truncating words in their command-line tools, rather than just writing proper bash completions for them. Mostly all it does is make it harder to keep track of what everything means.

So far, we have:

- NATS: "Neural Autonomic Transport System" -- https://docs.nats.io/faq#what-does-the-nats-acronym-stand-for
- NGS: ??? (maybe "NATS Global Service"?)
- From https://docs.nats.io/nats-tools/nats-tools:
  - nats - Interact with and manage NATS
  - nk - Generate NKey - nsc - Configure Operators, Accounts and Users
  - nsc - Configure Operators, Accounts and Users **(What does NSC mean? This tool also appears to include functionality from the nats and nk tools. Feels like one or more of these tools should be deprecated)**
  - nats account server - Serve Account JWTs **(this is sometimes abbreviated as `nas` in the docs, which collides in my head with "network attached storage". This also sounds like it is a deprecated way to do auth with nats, since it is inlined)**
  - nats top - Monitor NATS Server
  - nats-bench - Benchmark NATS Server
  - prometheus-nats-exporter - Export NATS server metrics to Prometheus and a Grafana dashboard.

# NGS

Following along with https://synadia.com/ngs/signup

I quite like the `curl | python` approach. I guess maybe this is more portable than `curl | sh`?

`nsc init -o synadia -n First` - I suppose if you made the tool then you can make sure your company is in the list of preconfigured operators. I wonder who else is in that list. Would there be any pushback if a big player like AWS started offering the same service, and wanted to be included in the list of operators?

I wonder how the `ngs.echo` topic works (whether it's patched into the server, or a process that has access to that topic on all accounts). Same goes for the other things in `ngs.*`.

## Default connections and hidden context

`nsc tool pub` implicitly reaches into some configs somewhere and works out where it needs to connect. Legacy tools like `nats-pub` don't do this, and neither do client libraries (or tools that use them, like wasmcloud).

## Leaf nodes

It feels like everyone wants you to install a nats leaf node as a sidecar (wasmcloud's wash cli tool doesn't even have a way to configure it to connect directly to NGS as a control plane). Following along with https://docs.nats.io/nats-server/configuration/leafnodes#leaf-node-example-using-a-remote-global-service shows you how to do it. You need a verified email address and payment method in order to do this.

## Messaging vs Queueing systems

In its most basic configuration, NATS is not a queueing system, because it doesn't have persistence or retries. It is more reasonable to think of it as a messaging system. I suppose in some ways it's like UDP, but wrapped in TLS+auth, and with `foo.bar.baz`-style broadcast addresses. It's a good fit for writing your app cluster's backplane in, but not necessarily your job scheduler.

There is a mode in NATS (`req`) where you can send a return-address with your message, and the receiver[s] can respond to that return address. This primitive can be used to build reliable systems (like how TCP is built on top of IP packets).

On top of this NATS backplane, you can add a bunch of applications, and connect them up. The NATS server comes bundled with a JetStream application, that you can enable with the `-js` flag. This is basically rabbitmq-over-NATS, but it can get away with being a lot simpler, because its communication protocol is NATS rather than TCP.

## Conclusions

I can see why WasmCloud chose NATS for its "lattice" backplane. The basic protocol feels simple and solid. It feels like the kind of protocol that you'd expect to see described in an RFC. Once you have this communication system in place, the work of doing inter-process communication feels like it will have a lot less friction. The difference between using HTTPS and NATS is like the difference between setting up unix domain sockets for each of your process vs using D-Bus (although D-Bus is terrible in ways that NATS manages to sidestep).

It is a reasonable initial reaction that the basic NATS protocol doesn't quite get you all the way. I think that the JetStream covers some of those holes, but I'm not sure whether it belongs in the core NATS server implementation. I'm hoping that the nats-server implementation continues to gain traction without adding too much bloat (or if it does get bloated, that they release a tiny-nats-server binary that can be used as a low-overhead kubernetes sidecar).
