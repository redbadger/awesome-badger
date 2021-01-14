# Stuart Harris

[@stuartharris](https://twitter.com/stuartharris)

Hello! I'm [Stu](https://red-badger.com/people/stuart-harris/), one of 3 founders (along with [Dave](https://red-badger.com/people/david-wynne/) and [Cain](https://red-badger.com/people/cain-ullah/)), and Chief Scientist at Red Badger. I'm a long-time software engineer, but I don't have any management responsibilities 😇, which allows me to stay close to the ground and to concentrate fully on charting technical direction for our company and our clients.

I am a proud Rustacean...

<img src="./rustacean-flat-happy.svg" width="80"/>

...which means I like [Rust](https://www.rust-lang.org/). A lot!

Over the last year or so we've been using Rust extensively with our clients – proving that the much talked-about steep learning curve is worth every second that we invested in it. For the first time, it seems, it's straightforward to write safe and reliable software, which is also fast and lightweight and especially suited to Cloud Native applications and services running in Kubernetes. It's not only fun and very satisfying to work with, but it is also making a massive impact in almost every area of software engineering.

I'm also passionate about empowering organisations to create great software in domain-aligned, cross-functional (and DevOps focused) teams using Continuous Delivery.

---

## Open Source projects

### [feature-targeting](https://github.com/feature-targeting)

Infrastructure support to enable feature targeting in microservices based web systems (and mobile apps).

---

## Writing

### [What's next, after Kubernetes?](./wasmcloud/README.md)

14th January 2021

Kubernetes is really good. But it does nothing to address what I think is one of the biggest problems we have with microservices — the ratio of functional code (e.g. our core business logic) to non-functional code (e.g. talking to a database) is way too low. 

In this post, I first explore the Onion architecture, how it applies to microservices and how we might peel off the outer, non-functional layers of the onion, so that we can focus on the functional core.

Then we look at how Kubernetes can be augmented to support this idea (with a service mesh, and a distributed application runtime).

Finally, and most importantly we ask what comes after Kubernetes (spoiler: a WebAssembly actor runtime) that can support core business logic more natively, allowing us to write that logic in any language, run it literally anywhere, and securely connect it to capability providers that we don't have to write ourselves (but could if we needed to).

### [Full-stack Rust](./full-stack-rust-1/README.md)

23rd June 2020

For a while now, I've been wondering how practical it is (as of right now) to use [Rust](https://www.rust-lang.org/) for web applications and services on the server _and_ for web UI in the browser. So I've been spending quite a lot of time exploring the developer experience, whilst trying to understand whether Rust in the browser is actually a good idea!

### [Microplatforms - Product platforms as code](https://github.com/redbadger/microplatforms-whitepaper/blob/master/paper.pdf)

25th July 2018

Microplatforms are an automation-based approach to provisioning and operating platforms running digital products and services, which emphasises autonomy of cross-functional product teams. We discuss the traditional approach of building a large-scale, shared platform and explore the resulting cost to the organisation, chief of which is the cost of coordination between teams. Instead, we offer the concept of each cross-functional team owning and operating a separate, self-contained platform. A key enabler for this approach is full automation - capturing all aspects of the product and the platform from provisioning to service orchestration and policy as source code. This approach results in significantly increased team autonomy and enables agile architecture, continuous deployment to production and ongoing innovation. Microplatforms allow organisations to move engineering effort higher up the value chain and focus on using technology to solve customer problems.
