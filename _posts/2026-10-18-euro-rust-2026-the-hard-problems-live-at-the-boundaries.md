---
layout: post
title: 'EuroRust 2026: the hard problems live at the boundaries'
date: 2026-10-18 12:00:00 +0000
category: pataruco
author: Pedro Martin
excerpt: "EuroRust 2026 my notes and takeaways: the compiler fulfils most of Rust's promises, but at each boundary the guarantees turn into contracts which you have to keep"
---

On 15 and 16 October 2026, I spent two days in Barcelona at [EuroRust](https://eurorust.eu), the Rust conference organised by [Mainmatter](https://mainmatter.com/).

Here are my notes and thoughts from the conference.

## Day one

### Oli Scherer: Move your problems to compile-time and get new capabilities out of it

[Oli](https://github.com/oli-obk/) opened the conference with a history lesson that turned into a roadmap. Rust 1.0 came with _two_ constant evaluators: one for static values, one for constants, and they didn't agree on which programs were valid. When `const fn` arrived in Rust 1.31, instead of fixing both, the team added a third evaluator, sharing its core with [Miri](https://github.com/rust-lang/miri), and removed the other two. It was so powerful they had to add code to limit it.

Every slow update since follows the same pattern. Mutable references in `const` took about fifty releases because "we are either fixing the tricky cases or banning the tricky cases".

The roadmap now is compile-time reflection and the current design is called "type info". But it turns [`TypeId`](https://doc.rust-lang.org/std/any/struct.TypeId.html) into a main value you can explore during compilation: names, variants, fields, and field types. Once you can do that, you can convert anything into a format for storage, and therefore debug anything, without needing a `derive`.

What was incredible to hear is that coming soon: a JSON config read by the compiler directly into a fixed value on an embedded device.

And the feature I keep thinking about is "comptime-only" functions—things that have no runtime result, like allocating memory at compile time and turning the result into a fixed value, or loading an entire asset folder into the binary.

### Benedikt Wiethof & Theophil Spiegeler Castañeda: The future of unmanned systems is built on Rust

A sponsored talk from [Quantum Systems](https://quantum-systems.com/).

They have the following problem: every old ground-control station assumes one operator and one vehicle. Theophil and Benedikt's team is building Mosaic, a ground-control system for multiple operators, vehicles, and stations.

The first version was in C++. It passed its tests but was fragile and then rewrite in Rust started with "basically zero developers" and took twelve to thirteen months.

The design uses a [hexagonal](https://en.wikipedia.org/wiki/Hexagonal_architecture_%28software%29) core for each station. Vehicles connect through [gRPC](https://grpc.io/) drivers that list their abilities upfront, so the system rejects any mission plan the drone can't handle before take-off. Operators get role-based access from a local identity system. Cores communicate as equals over secure connections using [mTLS](https://en.wikipedia.org/wiki/Mutual_authentication) on [QUIC](https://en.wikipedia.org/wiki/QUIC), so "no leader, no follower", with exactly one owner per entity and read-only copies everywhere else. Video is intentionally compressed and reaches the operator over [WebRTC](https://webrtc.org/) on the final step.

Now, strip away the drones and this is the shape of [Crux](https://redbadger.github.io/crux/), the framework we build at [Red Badger](https://red-badger.com/): a pure core that owns the state and the decisions, side effects pushed out to the edges and capabilities declared rather than assumed. Victor and Stu did that pattern to keep an app testable across iOS, Android and the Web.

Some patterns are resilient enough to run at military grade.

### Jana Dönszelmann: Optimizing rustc's next trait solver

[Jana](https://donsz.nl) works full-time on improving the speed of rustc's new trait solver, and this was the clearest explanation of what a trait solver _is_ that I've heard. It's a system that checks proofs.

The analogy is [Prolog](https://en.wikipedia.org/wiki/Prolog):

> Prolog is intended primarily as a declarative programming language: the program is a set of facts and rules, which define relations. A computation is initiated by running a query over the program.

Compiling the standard library checks `Sized` about 800,000 times. And because an `impl` with an associated type works like a function from types to types, the solver can do any computation. On this [`typenum`](https://crates.io/crates/typenum) does math with it, and a single query can take a very long time, so small improvements reduce the compile time.

Now, the key is caching, and the smart part is [canonicalisation](https://en.wikipedia.org/wiki/Canonicalization): making a goal more general so two queries that differ only in the names of their type parameters use the same cache entry. The success rate is now about 80%.

All these improvements are aimed at Rust [1.101](https://releases.rs/docs/1.101.0/)

### Timo Bachmann: Rebuilding the Tower of Babel: write your own language server with Tree-sitter

[Timo](https://github.com/tfachmann), who is a robotics researcher at the German Aerospace Center, has to deal with a problem that is wonderfully specific. A colleague developed a process manager by creating his own language and currently the configuration language is being used by thirteen robots and around 200 users, on his words "That's quite a number, but still not enough to allow for tooling.", so all the editors display it in black and white.

The solution is a single [Tree-sitter](https://tree-sitter.github.io/tree-sitter/) consisting of about thirty lines of JavaScript, which serves as the main source of truth; based on it, syntax highlighting is provided, formatting is carried out using [Topiary](https://topiary.tweag.io/), and a language server is built on top of [`tower-lsp-server`](https://crates.io/crates/tower-lsp-server) making syntax tree the server's model.

The various intelligent feature that you expect in a text editor: hover, diagnostics, completion, go-to-definition, and rename—work by matching the node under the cursor with its parent. Since the keywords are generated when the program is compiled, altering the grammar causes the server to fail during the building process. Which is exactly in the way tehy would expect it to be.

I was very interested in this project. I maintain [`zed-mjml`](https://github.com/pataruco/zed-mjml), a Zed extension for [MJML](https://mjml.io), and I [wrote an article](https://pataruco.dev/blog/wasm-beyond-the-browser-and-back-again) about building it back in March 2026. I took the same approach but used shortcuts: I used the `tree-sitter-html` grammar and only prepared the query files since MJML is just HTML with different tag names; and the diagnostics are provided by [`mrml`](https://github.com/jdrouet/mrml), which is an actual MJML parser, not by the syntax tree.

### Filip Petkovski: Running safely with scissors: lock-free concurrency for maximum throughput

[Filip](https://fpetkovski.github.io/) builds the internal observability platform at Shopify, and the case study was the in-memory buffer of their metrics database where one writer appending at a constant rate and many readers scanning.

They started with an [`RwLock`](https://doc.rust-lang.org/std/sync/struct.RwLock.html). So when readers scanned ranges of 1,024 entries, the writer degraded, and the readers stalled.

They redesigned with two key principles:

1. Each memory area has only one writer,
2. New data is only added at the end.

In a fixed-size array, the array stays in place, and its items never change, so readers don't need a lock; the writer just updates a marker in one step, so **Readers never stop the writer**.

Then the part I was interested in. All of this requires `unsafe` code, but "performance should not sacrifice safety."

The system is not checked by the borrow checker, so safety depends on three things working together:

1. The types (the writer cannot be copied, `push` requires exclusive access, storage is a fixed-size boxed array that cannot grow),
2. The API (readers cannot change data),
3. How the API works (write the value, then update the length with `Release`; readers read it with `Acquire`).

### Johan Rosengren & Sergio Gonzalez Martin: Image codecs rustification in Chromium

[Johan](https://eurorust.eu/talks/image-codecs-rustification-in-chromium/) and [Sergio](https://github.com/telecos) are on the Microsoft Edge security team, working with Chromium/

They talked about **Why image decoders?** saying that:

> The browser doesn't choose the input. The attacker does.

Vulnerability patterns are similar in the way a wrong size calculation followed by a memory copy that trusts it.

So in Rust, **"the bug is still a bug, but it's not an exploitable one."**

They found that working on Google's PNG port was the icebreaker after about two years, mostly spent fixing Chromium's Rust infrastructure rather than decoding PNGs. Just using the [`image`](https://crates.io/crates/image) crate meant they squash so many vulnerabilities.

## Day two

### Cristián Maureira-Fredes: Rust's influence on C++ and Python: shaping the future of three communities

Day two opened with a keynote from outside the Rust ecosystem. [Cristián](https://maureira.dev) works on PySide, the Python bindings for Qt, and was just elected vice chair of the Python Software Foundation.

He started by stating that:

> Much of what is coming in Rust is most likely being shaped outside the Rust ecosystem.

Most of them from C++ and Python.

The C++ half because legislation and guidelines saying "do not use unsafe languages" (NSA, CISA, the White House and the EU's [Cyber Resilience Act](https://en.wikipedia.org/wiki/Cyber_Resilience_Act)).

So three responses came in:

- Profiles (opt-in, missed C++26),
- [Circle](https://safecpp.org/) (a real borrow checker, rejected),
- [Carbon](https://github.com/carbon-language/carbon-lang)

Which makes Rust bindings the main thing:

- [bindgen](https://github.com/rust-lang/rust-bindgen),
- [CXX](https://cxx.rs/),
- [autocxx](https://github.com/google/autocxx),
- [Crubit](https://github.com/google/crubit),
- [Zngur](https://github.com/HKalbasi/zngur),
- [Diplomat](https://github.com/rust-diplomat/diplomat).

So there are six ways, but which binding should C++ use?

The Python half: [PyO3](https://pyo3.rs/) and [Maturin](https://www.maturin.rs/) made Rust the easy choice for native extensions. The `rpds` crate has modest download numbers on crates.io; its Python binding, [`rpds-py`](https://pypi.org/project/rpds-py/), hit roughly 470 million downloads in thirty days the moment [`jsonschema`](https://pypi.org/project/jsonschema/) adopted it.

He joked saying

> Surprise, now you have almost half a billion users more. And who is paying that maintainer?

### Sanskar Jaiswal: Designing state machines for streaming proxies in Rust

[Sanskar](https://sanskarjaiswal.net) builds serverless API gateways at [Kong](https://konghq.com/), and the running example was a 4GB upload answered mid-stream by a `413`.

The textbook request-response model is deceptive: the upstream answers as soon as it sees the first chunks, so both directions stream at once. Now the proxy has to forward the `413`, stop reading the body, and decide whether each connection is clean enough to reuse because a dirty buffer corrupts the next request.

What makes it hard in async Rust is that futures can be cancelled at any moment, so partial progress evaporates, and some steps are irreversible: once response headers hit the socket, you can't send a `502` later. So invariants fall out of that:

- partial progress survives cancellation
- committed output is recorded
- only protocol-clean connections are reused
- request and response are separate exchanges with causality between them

> It's okay to say no to [typestate](https://cliffle.com/blog/rust-typestate/) sometimes.

Typestate suits linear flows; But not with bidirectional IO it becomes a mess. Instead: three small enums (`request-progress`, `response-progress`, `commitment`), one durable `ProxyState` that governs them, and a [`select!`](https://docs.rs/tokio/latest/tokio/macro.select.html) loop where the branches only read and the write happens afterwards, outside any `await`.

### Francois Mockers: Supply chain attacks, and how to protect ourselves

[Francois](https://vleue.com) maintains [Bevy](https://bevy.org/) and writes Rust at a fintech

This made me cackle

> As we handle money, it's kind of important not to get attacked

He started `cargo add` with four acts of trust: identity, authenticity, integrity, and the maintainer, and for each, he shows examples of how has been broken.

He advised using:

- [cargo-audit](https://crates.io/crates/cargo-audit) and [cargo-deny](https://crates.io/crates/cargo-deny) for advisories and bans,
- [cargo-vet](https://crates.io/crates/cargo-vet) and [cargo-crev](https://crates.io/crates/cargo-crev) for borrowed trust,
- [cargo-supply-chain](https://crates.io/crates/cargo-supply-chain) and [cargo-cyclonedx](https://crates.io/crates/cargo-cyclonedx) for inventory,
- [cargo-machete](https://crates.io/crates/cargo-machete) and [cargo-udeps](https://crates.io/crates/cargo-udeps) for pruning, and
- [cargo-auditable](https://crates.io/crates/cargo-auditable) to bake the SBOM, which the Cyber Resilience Act will soon want, into the binary itself.

> A check that you have to remember to run is a check that doesn't run.

He suggests a minimum publish age of seven days in a committed `.cargo/config.toml`, the only thing that protects local runs.

```toml
[registry]
min-publish-age = "7 days"
```

He also suggested:

- Commit the lockfile and let CI run `cargo update`
- Pin in `Cargo.lock`, never in `Cargo.toml`.
- Give Dependabot a seven-day cooldown.
- Publish only from CI, with [trusted publishing](https://crates.io/docs/trusted-publishing).
- Longer term: proc macros in a WASM sandbox, the way Zed runs its extensions by theway. I've been on the other side of that sandbox with zed-mjml.

He closed with:

> Make the secure path the default path.

### Albert Lockett: Building a high-performance, thread-per-core, zero-copy OpenTelemetry engine in Rust

[Albert](https://github.com/albertlockett) maintains [OTel Arrow](https://github.com/open-telemetry/otel-arrow) at F5, and the whole talk was one principle several three times:

> Telemetry engine's job is throughput per unit of compute, so design around the hardware.

- OTLP ships telemetry as protobuf rows; OTAP, the OTel Arrow Protocol, ships it as [Apache Arrow](https://arrow.apache.org/) columns. Every log's severity sits next to every other log's severity: cache locality, SIMD, better compression and Arrow IPC's wire bytes _are_ the in-memory buffers, so serialisation is zero-copy.

- One copy of the entire pipeline per core, each on its own single-threaded Tokio runtime. They share nothing and never synchronise. Tokio's work-stealing scheduler would do this for you. Still, a stolen task's data lives in another core's cache or [NUMA](https://en.wikipedia.org/wiki/Non-uniform_memory_access) node, and when every worker runs identical code on similar data, stealing buys little. The "mysterious advantage" is because tasks never migrate, so futures don't need to be `Send`.

- The usual route is Prost decodes protobuf into a struct that creates _"an intermediate representation only to go then throw it away"_. Instead, view traits with lifetime-carrying associated types, so a `LogRecordView` over raw bytes decodes a field only when the Arrow builder asks for it.

## My insight

I work mostly on the web, where the platform does the heavy lifting and my job is to get out of its way. I expected a conference about a language with a famously strict compiler to be about the compiler doing the same.

It was, partly. Jana, Arya, lcnr and Oli are rebuilding its foundations so it can prove more, faster. But the other talks were about how to scape lines the compiler can't see across.

So the compiler keeps its promises. The rest are ours to keep if we work on the boundaries.
