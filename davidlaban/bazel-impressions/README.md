# Early impressions of Bazel

_[David Laban](../) — June 2021_

Bazel is a buildsystem from google, based on their internal `blaze` buildsystem. I decided to take a look and see how it fits into the landscape, and which things tripped me up while I was exploring.

## iOS tutorial

I decided to follow along with their iOS tutorial: https://docs.bazel.build/versions/4.1.0/tutorial/ios-app.html. I have never done any iOS development before, but it seems like a reasonable place to start.

## xcode license

There was a warning about me not having accepted the license for xcode. This is because I'd not launched xcode before, and had accepted the license command-line utils only. In the end, I switched to xcode and accepted the license, but the bazel build server was spawned before me changing over, so it cached the failure. It might be worth adding some more explanatory text about nuking the server here.

## Old versions in the tutorial

The tutorial asks you to install a bunch of ancient versions of the apple build rules. These trigger deprecated behavior, so you have to add `--incompatible_run_shell_command_string=false` to your command-line arguments to make the build work.

In general, I don't like this style of copy-paste-from-a-webpage tutorial. They are a pain to maintain, because you can't easily run them in CI, and as a result they get out of date easily.

In the end, I found some examples in the repo was causing the error (https://github.com/bazelbuild/rules_apple/blob/master/examples/ios/HelloWorld/BUILD) and built that instead. This worked fine.

## Hot Reloading?

The developer experience doesn't seem fantastic:

> ### Run and debug the app in the simulator
>
> You can now run the app from Xcode using the iOS Simulator. First, generate an Xcode project using Tulsi.
>
> Then, open the project in Xcode, choose an iOS Simulator as the runtime scheme, and click Run.
>
> Note: If you modify any project files in Xcode (for example, if you add or remove a file, or add or change a dependency), you must rebuild the app using Bazel, re-generate the Xcode project in Tulsi, and then re-open the project in Xcode.

The tutorial has a link to http://tulsi.bazel.io, when it should be https://tulsi.bazel.build/

I'm not sure how willing people will be to install an xcode plugin to do their builds. In practice, maybe it's fine.

## bazel test examples/...

This manages to start two iphone emulators and then only use one of them.

## Monorepos

It's slightly funky that some of the apple platform support lives out-of-tree in bazelbuild/rules_apple, but the main bazel cli has a bunch of ios-related command-line flags. I feel like it would make their lives easier to merge it all into a single monorepo. The downside of a monorepo would be that they would be tempted to be more lazy about getting their plugin architecture right.

## Automatically skipping tests that aren't relevant

You can tell that Bazel and Go both come from Google, because they both skip tests by default if the code for them hasn't changed.

## Watcher

A file-watcher is table-stakes for me. Bazel has a thing called ibazel that's a go program but is built using bazel and distributable via NPM (if you don't want to use homebrew). This feels a bit like how you ship rust binaries via the python package index for datascience.

There are two file-watchers that I found for bazel. One is ibazel and the other is rebazel. Both of them derive their list of files to watch by shelling out to `bazel query`, and both of them ignore the exit code of `bazel query`, and plough on with an empty files-to-watch list if it fails (which it does on the rules_apple examples that I found). This is a bit unfortunate, but it turns out that `bazel build` is super-quick at recognizing no-op builds, so it's not the end of the world if you have a high false-positive rate when triggering builds due to filesystem changes. This means that you can probably get away with running `watchexec -- bazel build` in the tree that you care about.

## Daemon

One of the ways that bazel manages to achieve this speed is by having a client-server architecture. This allows it to avoid spidering out across the whole dependency tree for every build, parsing all BUILD configs and calculating checksums for source files.

In Javascript-land, build-tools typically have a --watch mode, that keeps this in-memory behavior and also triggers the recompiles for you whenever you save. The js watchers typically live in the foreground. (Interestingly, the Flow compiler takes a daemon+frontend approach that is like a hybrid between the two approaches.)

If I'm to guess why bazel decided not to go down this route, I'd guess that watching the entire Google monolith is not feasible, and engineers are expected to use specific queries to trigger builds. This will have influenced the design of the blaze daemon, so it _has_ to load things into memory lazily and maintain a best-effort cache of built artifacts.

## Aside: Incremental Compilation in other build systems and programming languages

Reading https://developers.facebook.com/blog/post/2021/07/01/future-of-buck/, I noticed:

> As for the big changes, our next-gen build system is built on a single incremental computation framework. This provides fine-grained tracking of computation dependencies and very high performance for incremental computations. It is heavily inspired by research like Adapton and implementations like Salsa, Skip and the Shake build system.

Salsa is the query-based incremental compilation engine behind `rust-analyzer`. There is vague talk of porting the rust compiler over to use salsa, but progress is slow. Instinctively, incremental compilation engines make a lot of sense as daemons, where results can be kept in memory, and are less effective if they have to serialize their state to disk between queries [Note: I have no way to back this up. It may be that the overhead can be made insignificant here].

Niko has a bunch of interesting videos about how salsa works in theory and in practice. My favourite surprising thing that I learned was that sometimes it's beneficial to compute a query and then only store its _hash_, and not store its _value_ in the query cache. An example of this would be when you want to ask "what is the type of the value under my cursor?", you ask a bunch of queries, and a bunch of them rely on "what is the source code of the file I'm in?". As soon as you run that query and realise that the file hasn't changed, you know that your cached value for the query "which names are in scope under my cursor?" is still valid. You don't actually need to store the value of the file anywhere, and you can also throw away the computed values of a bunch of intermediate results in your query tree, as long as you have enough information to prove that the expensive-to-compute results are still valid, you're golden. When you do end up making an edit to the file and invalidating your caches, the cost of rebuilding the tree of results often ends up being cheap, and you often end up short-circuiting ("what is the source code of the function I'm in?" will be the same if all you did was trim a trailing newline at the end of the file).

My assumption is that all bazel-like build-systems will have some kind of query system at their heart, where most of the queries eventually boil down to "run this program with these inputs and record its output from this location". I've not looked into Buck enough to know how what they're currently doing differs from a "single incremental computation framework". Their next-gen repo is also expected to be private for another year, and I'm not going to dig into what they're up to in the dark.

I wonder how something like bazel would interact with a compiler that holds its own query cache in memory. If it wanted to be hermetically sealed, it would need to throw away any speed-up gained by a compiler in this daemon mode. It sounds like it can still do useful things with on-disk incremental compilation caches if it knows about them (although in non-sandboxed mode, they mention that the typescript compiler will get confused by any incremental compilation cache files that are left lying around).

[edit: I did a bit of digging, and found that bazel does have a concept of [persistent workers](https://docs.bazel.build/versions/main/persistent-workers.html), and uses them by default where it makes sense.]

<!-- TODO: discuss the tricks that pnpm/parcel2 do, that might/might not work with bazel? -->

<!-- TODO: look into distributed build cache. Could you abuse github-releases || ghcr.io for cached build artifacts like cargo-quickinstall/homebrew do? -->

## Conclusions

Bazel is definitely an improvement over the `make`-style systems that it replaces. As you dig deeper into language-specific integrations, you start to find that `bazel` is able to wrap `make`-style compilation behavior really well, and has useful opinions about what `make test` should do. It also has reasonable tooling for converting language-specific build files into BUILD dependency rules. [edit: after reading about persistent workers, this bit of the conclusion might not be valid ~At the end of the day, it is closely wedded to the make model of compilation, and I am not expecting it to integrate with all of the clever tricks that these language tools use to make incremental recompilation fast. Maybe this is an okay trade-off if you want to use a distributed build cache, and have Jenkins builds that are fast and that you can trust.~ ]

Also, build systems are hard.
