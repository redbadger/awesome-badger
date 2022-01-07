---
layout: post
title: "Guiding Principles for Agile Technology Choices"
date: 2020-07-20 12:00:00 +0000
permalink: /:categories/:slug
redirect_from: /charypar/tech-principles/
categories: charypar
author: Victor Charypar
excerpt: An attempt to capture some guiding principles for making technology choices - picking tools, tech stacks and making architecture decisions.
---

For several years now I've had a fairly strong gut feel for making technology choices. I'm talking about picking tools and tech stacks, but also making larger architecture decisions. Choices one is typically forced to make with relatively little information to use as input, which generally have a pretty big impact on the future direction of what you're building.

I've normally made those decisions "by feel" - when presented with a set of choices to make, I'd feel something between "no, that's gonna go horribly wrong" or simply "eww" to "yea that might work pretty well" about each of them, but I never really stopped to think why, and whether there's some logic behind it. That is until recently, when one of our clients asked if we could capture a set of principles for making these choices, to help them make decisions.

Initially, I thought this is going to be really hard, because that gut feel is simply an accumulation of experience of what worked in the past, but then I sat down, tried writing some guidelines down, and found there is actually a set of general rules of thumb I tend to follow. So I wrote them down and suggested them. They've gone down well not only with the client, but also with other Badgers, including some, currently attempting to make a reasoned set of big tech choices in their projects, and they seem to have helped. It made me think it might be helpful to write a slightly longer version of my thinking.

So, here are my principles for making tech decisions, in case you're looking for some guidelines that might help you.

1. Be user-centric
1. Minimise time to market
1. As simple as possible
1. Validate assumptions and adapt
1. Defer and minimise commitment
1. Buy small
1. Minimise long-term maintenance cost
1. Prefer open source software

If they resonate with you, let me know. If they raise all kinds of red flags for you, definitely let me know, I'd like to hear your thoughts! Now, let's look at them in detail.

## 1. Be user-centric

Choices should be informed by our understanding of the users and their needs. This should be the main motivation among all of the reasons to make a technical choice. There are many possible business and "architectural" reasons to go with a particular choice, especially one considered tactical: sticking with an existing vendor, because your engineers are familiar with that option, because it's considered best practice, etc. All those motivations are valid inputs into a decision, but they must not be in conflict with meeting your users' needs within a reasonable timeframe.

There will always be a large number of forces at play in these decisions, especially in large businesses, and the internal business reasons will always have louder voices behind them, because our users are not in the room. They are the easiest to ignore. They are also the most important stakeholder of all. Ignore them for too long and none of the other stakeholders will matter any more.

## 2. Minimise time to market

Pick the minimum viable toolset to get the product live.

Getting value to users is the main goal. Partly for obvious business reasons, partly because it will let us learn what we actually need to build vs. what we think we need to build. Investing more effort than is absolutely necessary before the product is live is just delaying that learning, which is very likely to radically change our perspective, including the assumed benefits, which made us consider higher-effort options.

## 3. As simple as possible

Pick the simplest solution possible to meet the needs we know today.

Complexity is the main opposing force in software development. We should be striving to minimise it at every step, because it will only ever grow. Complexity is the reason why software development slows down, as we have to navigate around existing choices and their consequences. We must do all we can to avoid building in more complexity than is absolutely necessary.

There is complexity in the product itself, some of which is inherent, and some is based on assumptions. We should challenge those assumptions to make sure we're only building what is actually needed. We should avoid our own assumptions affect technology choices, especially when picking tools which offer a lot of features out of the box. Unfortunately, those tools greatly increase complexity: for each feature we won't use, the author had to make a number of choices, which will limit our options later. We don't need those features today, we can afford to wait until we do.

## 4. Validate assumptions and adapt

Every assumption we make in making a technical choice needs to be validated.

We should constantly ask "can we get away with not doing that?" and answer honestly. The sneakiest of assumptions are "accepted best practices". It's important to understand the motivations behind them and validate whether they apply to our situation. Questioning everything all the time is certainly tedious, but not as tedious as undoing work we didn't need or constantly paying the tax for it.

The flip side to this is adapting immediately when an assumption is proven wrong. Continuing down a road we know is based on a false assumption, likely because we've already invested so much, is only digging us deeper into the hole.

Knowing this leads us to the next principle:

## 5. Defer and minimise commitment

The best choice is one not made.

If nothing forces us to make a choice, let's wait and make it later. Or never! (e.g. "Which database should I use? Actually, files or in-memory storage will be just fine"). When we have to make a choice, we should go with one that leaves as many escape routes open as possible, and be prepared to change our mind quickly when evidence shows we were wrong. We should always think of our way out of a choice.

## 6. Buy small

Avoid the lure of large feature sets.

When we decide a piece of functionality is not bespoke enough to warrant a custom build, we should prefer getting small, precise tools which deliver this functionality and nothing else, over a large, complex tool, which also gives us many other things we don't currently need. We should prefer assembling together a number of small tools over-relying on one huge one. After all, we will be responsible for all the choices which the designers of that tool made for us.

## 7. Minimise long-term maintenance cost

With all other things being equal, look at maintenance cost, especially in ongoing developer effort.

This is the reason people go for software as a service and cloud infrastructure. Only considering this _after_ the previous principles is important, because we need to take into account everything that comes with the hosted service. Sometimes it is better to go with a simpler solution, even if it means maintaining it ourselves.

## 8. Prefer open source software

Lean towards open source software with good community support over commercial software with paid support.

This is somewhat counter-intuitive, but it has everything to do with complexity and choice again. It's better to see into the 3rd party software we use, because it lets us self-serve in solving issues. Community support and documentation for popular tools is typically better than a vendor one, simply because there are more people investing effort into it. Lastly, there's already enough pressure on our choices, adding contractual obligations on top is the last thing we need, and picking a technology because "we already have a contract with the vendor" is probably top of the list of bad motivations.

## Closing thoughts

You probably noticed a lot of these overlap and say the same thing in different ways. The main motivation behind all of them is the understanding that making the wrong choice is inevitable.

We're making a choice for the future. A future we don't know, typically affected by an environment we can't predict. Even when product requirements are clear as day and a roadmap stretches out for two years, there is no guarantee that it will actually stay that way. Management changes, market changes, our users change.

The motivation behind all of this is acceptance of the fact _we're wrong_. It's so much more likely that our understanding of the situation is incorrect, that the basis of all decisions should be the assumption that _we are wrong_. What's worse, we don't know how exactly we are wrong and we will learn that at a later date, at which point we will need to adapt.

Assuming our understanding increases as time passes, the underlying motivations are:

1. Not making a choice is better than making one
1. Making a choice later is better than making one now
1. A conscious choice is better than an implicit one you're sleepwalking into

I think this is the same motivation that is behind the Lean and Agile schools of thought - optimising for course correction, not perfect planning.
