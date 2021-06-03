# Infrastructure Musings

_[David Laban](../) — June 2021_

By contributing to open source projects, I get to see how other people set up their projects. Over time, I have seen communities gradually migrate towards continuous integration pipelines like Github Actions.

Recently, I've been writing patches to Excalidraw, which takes things a step further. On every pull request, it builds everything and deploys it to vercel, so you get a message like [this](https://github.com/excalidraw/excalidraw/pull/3655#issuecomment-849654197) in every PR, with a url where your reviewer can preview your work.

This is my infrastructure nirvana.

### Where are we now?

At my previous company, we had a set of "pre-live" web servers that you could deploy your frontend changes to, for testing against production data. This was always a manual step though (I will explore why later).

<!-- TODO:
* Explore why you need "scale-to-zero" in order for automatic deployment of preview servers to be a reasonable thing.
* Explore the problem of populating a staging environment with reasonable data.

* My dad's problem solving checklist:
  * ~Where are we now?~
  * Where could we be?
  * Where should we be?
  * How do we get there?


 -->
