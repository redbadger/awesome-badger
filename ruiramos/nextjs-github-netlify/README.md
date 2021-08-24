# Next.js deployment on Netlify through Github Actions

## Introduction

Recently, I've been involved in a couple of projects where we've had to quickly
deliver proof-of-concepts of web applications or simple products, and I've been
trying to converge on a standard tech stack and setup that would allow a team to
hit the ground running and deliver web apps in a quick, productive way.

As you might have guessed by the title of this post, this will include
[Next.js](https://nextjs.org), a framework for serverless full-stack apps using
React and deployments on [Netlify](https://netlify.com), using the CI/CD offering of
Github, [Github Actions](https://github.com/features/actions). I'll talk briefly
about the reasoning behind each one next.

Next.js is currently the quickest way to bootstrap a full-stack web app using
React (specially using [create-next-app](https://nextjs.org/docs/api-reference/create-next-app)). It's a quite powerful framework supporting different architectures, from
completely staticly generated sites to server-side rendered ones. It also has a
convention for serverless routes that can easily be deployed to popular
serverless functions FaaS providers -- this seems to be my prefered way of using
it, the "JAM stack" way, where you have a completely static single-page
application front-end backed by serverless functions when you need them.

There's currently a couple of options on where to deploy such an app - from AWS
(using for instance the [serverless
plugin](https://www.serverless.com/blog/serverless-nextjs)) to
[Heroku](https://levelup.gitconnected.com/deploy-your-next-js-app-to-heroku-in-5-minutes-255e829a9966),
but for our use case, static hosting providers with some sort of FaaS offering
work well, and Netlify is one of the best players there, with a huge community
and decent tooling. Netlify supports Next.js deployments out of the box by
converting API routes (and server-side rendered pages) into [Netlify
Functions](https://www.netlify.com/products/functions/), something that's done
behind the scenes via a
[plugin](https://www.npmjs.com/package/@netlify/plugin-nextjs). Basically, it
just works: create a Next.js app, push it to a Github repository, connect that
repository with a Netlify site and you'll have a working continuous delivery
pipeline, including branch and preview (pull request) deployments.

Although this works quite well, it's often better to take control of the build and deploy
process and have it run on a CI/CD pipeline you manage - like Github Actions! This way, you have
flexibility to run whatever other steps your site requires - from code
formatting and linting tools to tests and other 3rd party services configuration. This presents the problem of us having to recreate some of that Netlify magic, but as we'll see it's quite manageable.

We'll create a new Next.js site, deploy it to Github, connect it to Netlify and
finally implement the needed Github Action workflows to get our continuous
deployment ball rolling!

## Demo
