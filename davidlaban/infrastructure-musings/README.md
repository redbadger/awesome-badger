# Infrastructure Musings

_[David Laban](../) — June 2021_

By contributing to open source projects, I get to see how other people set up their projects. Over time, I have seen communities gradually migrate towards continuous integration pipelines like Github Actions.

Recently, I've been writing patches to Excalidraw, which takes things a step further. On every pull request, it builds everything and deploys it to vercel, so you get a message like [this](https://github.com/excalidraw/excalidraw/pull/3655#issuecomment-849654197) in every PR, with a url where your reviewer can preview your work.

This is my infrastructure nirvana.

## Where are we now?

At my previous company, we had a set of "pre-live" web servers that you could deploy your frontend changes to, for testing against production data. This was always a manual step though (I will explore why later).

Excalidraw is using Vercel for their deployments, but Vercel isn't the only service that offers this capability. The ~Talent Compass~ SoMo team has been using Render with [a very similar workflow](https://github.com/redbadger/skills-database/pull/52#issuecomment-853287319). I found an article that lists a bunch of other options [here](https://bejamas.io/blog/jamstack-hosting-deployment/).

The thing that all of these providers have in common is the ability to scale to zero. This is crucial. If you are providing this as a free-tier service, you can't afford to be wasting resources on PRs that stay open forever without anyone looking at them.

The most prominent example of a service that will allow you to scale to zero is Amazon Lambda. The generic term for this is Function as a Service (FaaS). There are many implementations of this idea, including an open-source one called OpenFaaS.

### Could you build something like this on your own infrastructure?

Kind-of.

The go-to solution for private clouds is usually kubernetes. "One kubernetes cluster per pull request" is not something that will be able to scale to zero. Just running the kubernetes backplane with no services will probably use more resources than the services that you're deploying to it, especially at the start of the project<!-- [citation needed] -->.

<!-- I tried to push in this direction at FutureNHS, and we got to "One cluster per developer" before realising that it was a terrible idea, because it cost too much and overcomplicated everything. -->

Assuming that we're not going to hand out a kubernetes cluster per pull request, what other options do we have?

If your web services and queue consumers were written in the FaaS style, you could potentially deploy your static web assets to CDN and then deploy OpenFaaS into your cluster and route traffic from each preview site into the appropriate function.

### Is this suitable for every project?

<!-- TODO: Explore the problem of populating a staging environment with reasonable data. -->

<!-- TODO:
* My dad's problem solving checklist:
  * ~Where are we now?~
  * Where could we be?
  * Where should we be?
  * How do we get there?
 -->
