---
layout: post
title:  "Infrastructure Musings"
date:   2021-06-09 12:00:00 +0000
permalink: /:slug
user: davidlaban
author: David Laban
excerpt: Semi-structured musings about what my vision of infrastructure nirvana is, and what's available at the moment to help us on our way there
---

## Where are we now?

At my previous company, we had a set of "pre-live" web servers that you could deploy your frontend changes to, for testing against production data. This was always a manual step though, because the pre-live servers used the same nginx+gunicorn architecture as our production servers. These had a roughly fixed number of worker processes, and the memory footprint of our python servers on startup was ~300MB/process. We also had the pre-live servers on their own ECS cluster, with fixed capacity, so there were a limited number of slots for deploying pre-live servers into.

<!-- Aaron points out that the pre-live servers were initially just a proof-of-concept of using ECS for our web tier, and ended up being the one of the most popular things he ever built. -->

Even with these limitations, the pre-live web servers were extremely popular. They reduced the friction of reviewing PRs (developers were responsible for doing QA for each other), and made it easy to share work-in-progress with designers/product-owners for feedback. I have been on the look-out for equivalents ever since.

Recently, I've been writing patches to Excalidraw, which takes things a step further. On each pull request, it builds everything and deploys it to vercel, so you get a message like [this](https://github.com/excalidraw/excalidraw/pull/3655#issuecomment-849654197) in each PR, with a url where your reviewer can preview your work.

This is now my infrastructure nirvana.

Excalidraw is using Vercel for their deployments, but Vercel isn't the only service that offers this capability. The ~Talent Compass~ SoMo team has been using Render with [a very similar workflow](https://github.com/redbadger/skills-database/pull/52#issuecomment-853287319). I found an article that lists a bunch of other options [here](https://bejamas.io/blog/jamstack-hosting-deployment/).

The thing that all of these providers have in common is the ability to scale to zero (like how e.g. Amazon Lambda does). This is crucial. If you are providing this as a free-tier service, you can't afford to be wasting resources on PRs that stay open forever without anyone looking at them.

### Aside on Function as a Service

The most prominent example of a service that will allow you to scale to zero is Amazon Lambda. The generic term for this is Function as a Service (FaaS). There are many implementations of this idea, including an open-source one called OpenFaaS.

<!-- As a further aside, when I was reading up on faas-cli, I noticed that both `faas-cli` and `dapr` cli both have an `invoke` method. I will have to explore what they have in common. -->

<!-- I also noticed that openfaas relies on NATS for its queue, which is the same thing that Stu's Rust London wascc demo used. I should look into this more as well. There is already a demo of OpenFaaS+wascc, and the cold start times sound promising. -->

### Is this suitable for every project?

It depends how your state is managed. In Excalidraw, all of the state is managed in the browser, so this is perfect. It gets more complicated as soon as you need to interact with databases, job queues and external services.

<!-- TODO: talk to Carlos about how their state is managed --> If your service only ever reads from a database then you can probably get away with handing out read-only access to a DB that's shared between all preview sites.

If your database migrations are enough to bring up a minimal database, and you have scripts that can populate it with example data, you're also in a good place, because you can create an empty database for each preview deployment, and write a script to delete old databases. Small unused databases don't cost much. That said, you're already pushing the limits of reasonableness at this point.

In general, this problem is harder to set up than the "give me a development environment on my local laptop" problem (you should **definitely** get local development working first), but reduces friction once you have it. The difficulty arises mostly because it needs to be multi-tenant, and it's not allowed to have any manual steps in it. You have to decide whether this is worth it.

It's also worth mentioning that if you're following the recommendations in "Accelerate", you will be doing something close to trunk-based development anyway, and your pull requests will not diverge from the main branch very much, so they can reasonably be tested on localhost or staging (or even prod, if you're confident with your automated testing and feature flagging infrastructure, but at least one person smoke-testing on localhost is probably a good idea).

Talking to Sam Taylor about this, he convinced me that it's fine for stateless web components in a PaaS, but should probably be avoided for anything more complex. He also made the point that it doesn't help you at all with async services like queue consumers, or the interaction between web tier and async tier code. I would argue that you probably don't want to deploy any risky frontend-backend interactions as part of a single pull request anyway.

### Could you build something like this on your own infrastructure?

I think this is what I want to find out.

Assuming you have already bought into kubernetes, I wonder whether you could get your ingress to cooperate with OpenFaaS and give you subdomain-per-pull-request previews. I also wonder whether it would be reasonable to dump this into your production cluster, with appropriate resource limits.

Maybe this is how I will spend my bench time.

### First stab at this

Note that OpenFaaS only gives you a single endpoint per docker image. This is probably fine if you're using graphql, but might be awkward if you're trying to serve a richer REST api.

<!-- Dapr has a better story for exposing multiple endpoints, but I'm not so sure about scaling to zero. -->

I think what you need to do is:

- Decide on a mapping between pull request and function name
- For each pull request:

  - `faas-cli build --image $PREFIX/$IMAGE:$PR_ID-$COMMIT` docker image for the function
  - `faas-cli push --image $PREFIX/$IMAGE:$PR_ID-$COMMIT`
  - `faas-cli deploy --image $PREFIX/$IMAGE:$PR_ID-$COMMIT --name $PR_ID`
  - Build and deploy static assets to CDN
  - Make a new subdomain for the preview url
  - Fiddle with your ingress configs:
    - Arrange for the preview subdomain's static assets point at the CDN.
    - Arrange for the preview subdomain's graphql url to point to `/function/$PR_ID`

<!-- TODO: how do we clean this up when the PR is merged/closed? -->

To scale to zero:

<!-- This functionality is also available via faas-idler if you are using OpenFaaS PRO, but the logic is pretty simple, and is described here if you want to implement it yourself: https://www.openfaas.com/blog/zero-scale/ -->

- Keep track of invocation count for each function (prometheus-style). This can be done with the `/system/functions` endpoint.
- If a function has not been used for $timeout, scale it down by POSTing `{"replicas: 0}` to `/system/scale-function/${function}`.

<!-- TODO:
* My dad's problem solving checklist:
  * ~Where are we now?~
  * ~Where could we be?~
  * ~Where should we be?~
  * ~How do we get there?~
 -->
