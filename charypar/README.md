# Viktor Charypar

[@charypar](https://twitter.com/charypar)

> Tech Director in Cell A, puzzles and aviation nerd, [tapir](https://www.bioexpedition.com/tapir/) and pig enthusiast.

I'm on a mission to simplify DevOps workflows and remove unnecessary complexity, which we've collectively piled on  
over the years, and let us focus on creating great software experiences for the humans who use our software. I don't
really do code day to day any more, sadly, but it means it doesn't feel like work any more, and I'm happy to write
some in the evenings and on weekends 🎉.

I've switched stacks multiple times over the past 15-ish years, starting with PHP, moving to Ruby on Rails, then
node.js and React, where I've discovered the joy of functional style programming. I've done some low level stuff in C/C++ in uni, and started (and never finished) a PhD in machine learning and heuristic optimisation. I've also picked
up various kinds of infrastructure experience from Linux admin to all kinds of cloud craziness.

These days I'm mostly excited about Rust ❤️, Kubernetes and service meshes, monorepos and feature targeting. Also spreadsheets.
Spreadshets are great!

Disclaimer: I _might_ be slightly overly sensitive to certain "best" practices and bad ideas that keep popping
up 😅, so if I inadvertently launch into a huge rant, please don't take it personally. These include (but are not
limited to): Semantic Versioning, overcomplicated git workflows, waterfall process, many environments attempting
to replicate production, object oriented programming, CMS, ERP, CRM and other kinds of software that does too much and
nothing well pretending that businesses can be standardised and commoditised and off-the-shelf software will give a
competitive edge. Also acronyms.

## Open Source projects

I generally have more ideas than time (and sense) so all of these things are in various stages of incomplete,
but some of them may be usefull already. The more you harrass me about them, the more likely it is they get improved.

- [Feature targeting](https://github.com/redbadger/feature-targeting) - infrastructure support for full-stack feature targeting which we're working together on with [Stu](../stuartharris).
- [Monobuild](https://github.com/charypar/monobuild) - a lightweight build orchestration tool for monorepos, which can tell you which components to build depending on changes made on a branch.
- [Github Projects tracking for delivery](https://github.com/charypar/github-projects-reporting) - a simple service fetching staticstics about moves in GitHub projects kanban boards and exporting them as CSV, so they can be used in tracking spreadsheets.
- [Badger Map](https://github.com/redbadger/badger-map) - a map of where all the Badgers live (if they chose to share their location)
- [Immutable Versioning](https://imver.github.io/) - A proposal for a versioning scheme that is less complicated and more practically useful than SemVer.

## Writing

### [Extending Istio with Rust and WebAssembly](proxy-wasm-1)

20th April 2020

Istio recently released verion 1.5 and one of the major changes in it is the deprecation of Mixer in
favour of WebAssembly Envoy filters. Let's build one to see what it takes.
