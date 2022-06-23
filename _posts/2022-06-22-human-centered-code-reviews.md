---
layout: post
title: "Human-centered Code Reviews"
date: 2022-06-22 12:00:00 +0000
category: niall-rb
author: Niall Bambury
excerpt: An examination of the practices, values and ways of working that underpin effective code reviews
---

For the uninitiated a code review is basically when a developer presents their code to another for comments and feedback. If the code passes the review it is typically merged or if it doesn’t then the submitter has some changes to make before submitting it for review again. They can come at the end when the feature is complete or more commonly will have multiple reviews along the way.

In all but the smallest of teams code reviews are a commonplace practice. The primary purpose of them is to ensure that the code is of good quality and meets the team’s technical standards of fitness.

Some of the things a reviewer could look for could include:
- Proper grammar and syntax
- Efficient algorithms
- No duplicate code
- Adherence to naming conventions
- Test coverage

… and so forth. 

I think everything I’ve described above is pretty uncontroversial yet In spite of all of this I think code reviews today are (with some justification) a somewhat maligned practice.

Code reviews and their efficacy rely heavily on the existing relationships between the team members. Unhappiness with technical direction and personal animosities can spill over into the review process and end up harming team performance. 

Conversely, teams that get along and have a solid and agreed vision of what good code looks like never seem to suffer these pitfalls and the process is a routine and effective guarantor of code quality. 

To explore some of the complexities around code reviews we first need to examine its origins and recall how software used to be shipped.


## How things were
In the past releasing new software was a chore. Preparing the release candidate, notifying internal stakeholders and users about it, weeks of manual regression testing and warnings of downtime on the day of release were all part and parcel of the process. Fear of what could go wrong loomed large over the whole process. 

Since the cost of change was so high, *getting things right the first time* was of cardinal importance. A botched deployment meant kicking off the same lengthy process all over again to revert the failed change.

Developers were constrained by the tools and methodologies of the time - being totally confident in the success of a deployment was near impossible. Test driven development, a now widely accepted practice for writing resilient code wasn’t developed till the late 90’s by Kent Beck yet code was already written for devices large and small long before this.

In these times code reviews were a vital tool to ensure code quality. Seasoned engineers would pour over the proposed changes looking for syntax errors, potential compilation issues or any other gaps in code quality that could derail a release and result in a bunch of upset customers or users. It was manual, laborious and the stakes were high if something slipped through.


## How things are now
The tools and methodologies used to ensure quality code have gone from sparse to abundant.

Developers have their choice of rich IDE’s that offer access to a vast plugin ecosystem for most any active programming language, providing convenience features like syntax highlighting and code formatting and more advanced features like code completion. 

Testing frameworks are faster and more feature rich. With a solid testing strategy, developers can have a high degree of confidence that their new code has the intended effect without new bugs or regressions cropping up.

Today’s devs can even provision production-like services on their development machines through techniques like containerisation, providing lean standalone services - the kind of thing that would have been unimaginable for complicated subsystem teams of the past.

For companies that have leaned into continuous delivery and continuous integration as practices, code deployments that once took hours or days could be achieved in mere minutes. Tools like Github Actions can run automated checks against our bundled software before deploying it to production. Some of these checks can include automated tests (unit, e2e, contract etc..), static analysis tools, vulnerability scans just to name a few.

So what does this all mean? 

The code review has gone from being one of a handful of practices to ensure code quality to just one amongst many. Verifying that our code can be safely merged is now also possible through another rival practice - pair programming.


## Shifting left
The traditional way in engineering teams would solve coding problems was pretty straight forward - analyse the problem, write code to fix it then test the code. This is an approach which fits neatly into the roles of business analyst, developer and QA. Actual testing only came at the end.

The problem with this approach was that oftentimes requirements were poorly understood or missed entirely and too often devs would end up building the wrong thing. This left QA’s in an unenviable position of either sending time sensitive work back to developers to fix, potentially risking a deliverable, or letting it slide and creating a separate bug to track whatever got missed.

In 2001 Larry Smith proposed a different approach. He coined the term “shift left testing” to describe testing in smaller iterations. Instead of writing code and only testing it once it was done, he advocated for testing during development, in smaller iterations, so together the dev and QA could both be more confident that what's being built would match what was asked for. 

Around the same time, the Extreme Programming (XP) philosophy was gaining popularity. It challenged teams to take ownership of the software they ship, and to not view their role in the team as being siloed just to their job title. Far from just being on the shoulders of QAs and testers, ensuring the quality of the final product was becoming a whole team concern.

Baking in quality from the start would prove to be a powerful idiom and expanded to other areas of software delivery, particularly around non functional requirements. Testing, accessibility, observability, security - all of these that were traditionally regarded as something that was considered “once development was done” but are now seen as critical requirements that have to be considered up front.

Pair programming was conceived in the same spirit. 

Having two developers working at the same terminal has existed for quite a while but true pairing - where the design, problem analysis and writing of code is conducted by peers that discuss approaches and alternate roles - would take time to grow in acceptance. 

While controversial to some, pairing represents a shift left in the approval process. 

Instead of having discrete write-code, review-code blocks - the two phases are merged into a single process where code is co-authored by two devs. This satisfies the “two pairs of eyes” principle and so any code they write could go to production - which is why it’s often used in conjunction with trunk based development. 

In spite of the difficulty introducing pairing and trunk based development to engineering teams that haven’t used them before the benefits can be huge - with automated testing and CI/CD pipelines, teams can ship quality code many times a day with high confidence and none of the waiting around and context switching that characterises the humble code review.

## What’s wrong with code reviews?
Before exploring how we can do code reviews better we need some appreciation of what are the practical drawbacks using code reviews as a means of safeguarding code quality in the first place. 

I’ll group my critique of code reviews into two broad categories:
- The process itself
- Developer attitudes towards them

### Code reviews as a process
Utilising code reviews means developer workflows are habitually broken. 

If you’re writing code then you need to put out a request for a review and await the outcome of it before resuming work. If you’re the reviewer then your work is potentially being interrupted by being asked to conduct a review. These shifting and exchanging responsibilities are a form of context switching - dropping what you were doing before and focusing on something else. 

Proponents of code reviews would argue the original submitter could just do something else while the review is ongoing but this too isn’t ideal. Having devs split their attention between multiple streams of work is inefficient and risks the quality of one or both being compromised. 

Code reviews also contain within them an innate antagonism, forcing teams to choose between one undesirable consequence and another - and that is what is the ideal size of a pull request?

Small commits are generally considered to be good practice in coding. They encourage developers to be deliberate in their choices and result in more focused changes. Having pull requests with fewer commits mean they reveal their intention more clearly too, which makes reviewing them far more straightforward.

However, pull requests consisting of only one or two commits don’t gel very well with the manual nature of code reviews. If I produce multiple pull requests in a day then I’ll require a lot of reviews, which means lots of context switching for those on my team who have to review my work (and maybe some desensitisation towards my repeated entreaties for a review too)

But what about batching together many commits so instead of many small ones you just have one big one? You can do this but it has a cost attached. 

Blending many commits into a single pull request means that the surface area of change is much greater, leading to a proportionally higher review time. While good test names and commit messages can mitigate this, the overall goal of what’s being achieved can become blurred, mandating a slower line-by-line approach to reviewing code to see what's changed and where. Overly stuffed pull requests do not clearly reveal their intention like their smaller counterparts.

Or even worse if the surface area of change is massive then something could just slip by entirely e.g. renaming a file while also making business logic changes that could be lost in the revision comparison tool. Being “too big to review” is a risk too.

Ultimately teams need to come to their own conclusions about how big or small code reviews should be but either way there’s a cost involved regardless.


### Developer attitudes to code reviews
Prevailing attitudes within engineering teams towards the review process itself can help or hinder the process as a whole. We understand that code reviews are primarily a technical assessment to assess the fitness of some code though I would argue it has a psychosocial facet to it too. 

What does good code look like? Who is in a position to judge good from bad? What technologies or technical practices are desirable or not? 

These are all subjective questions that don’t have hard answers. In the absence of some socialised view of what “good” looks like, developers will bring their experience to bear on the review - they also bring their biases, subjectivities and sometimes their egos too. 

Commercial software development is a time consuming and expensive process. Meeting milestones on product roadmaps can take a long time to hit and forecasting can be like crystal ball gazing at best of times. For businesses continuous feature delivery is incredibly important, if not essential to their survival. 

However this urgency is not always reflected in the spirit with which code is reviewed. Spurious or ineffectual review comments go beyond simply being annoying and if unchecked can be harmful and erode team trust. 

## Is there a better way?
Despite all these drawbacks I do think code reviews can be made to work.  

However I think doing them effectively means engineering teams re-evaluating governance of the review process. Useful new tools can also help as previous tedious manual checks and be neatly automated away. 

We also need to evaluate the human impact of the review process so we’ll touch on how giving effective feedback can guide us to a better, more empathetic review process.

## Team owned quality
Some of the drawbacks of code reviews can seem quite apparent but others are much more subtle. One such subtlety is who owns code quality? The natural answer seems to be the senior most developers and technical leaders with the engineering teams. Their experience makes them natural arbiters of code quality and so it’s natural to assume that they should play an oversized role in making sure the code is up to scratch. 

While this all seems quite reasonable I think this is a backward and self-defeating approach.

It’s somewhat uncommon for engineering teams to be staffed entirely with experienced developers. The commercial demands placed on organisations mean that there is always more work to be done than developers to do the work. 

For this reason we see the emergence of leveraged teams - that is to say teams with one or two highly experienced developers, some with moderate experience and then some more junior developers to round out the team.

I would propose that having code quality owned by a handful of experienced developers is harmful to both the experienced devs and the mid/junior developers they are seeing to grow and teach:

Tech leads and principal developers often have responsibilities that lie outside the immediate concerns of the delivery team. Some include: delivery assurance discussions, product discovery, line management and cultivation concerns, tech analysis sessions, engineering working groups, tech visioning discussions and so forth. In short, they have a lot on their plate outside of coding (if indeed they have time to code at all). 

On top of all this, if they alone are required to approve the code their team generates then it’s easy for them to become a single point of failure. Code reviews take time to effectively review and delay is expensive. Equally as someone that isn’t writing much code they might actually have less context on the codebase should be doing than other engineers that do nothing but write code all day. 

This format is harmful for less experienced developers too. Being unable to influence coding standards risks them becoming disengaged and seeing quality as something that is the responsibility of QA’s and senior developers, not themselves. Why care about standards you have no agency to change? This is also harmful to their growth and could prompt talented developers to actively look for opportunities somewhere else where they can have more autonomy and influence.

The solution to these problems is team owned quality. 

Engineering teams should get together early after forming and talk about coding standards in a collaborative and inclusive way. This should continue for the life of the team. The meeting should be a discussion where everyone has a chance to contribute and debate what makes for good code. 

Senior developers should help guide the conversation but not act as gatekeepers of what is good and what isn’t and should approach discussions with an open mind. Though junior developers are new to their career, they can produce useful insights and fresh perspectives.

These sessions should be repeated weekly or fortnightly, with discussion points brought in eg. “can we adopt this new technology?”, “does this approach seem off to anyone else”,  “Is it just me or are our pipeline tests flaky?”. As with all well run meetings, notes should be taken and actions assigned to individuals to follow up on before the next meeting where they recap their progress.

The offshoot of this is that everyone has an equal responsibility to ensure the quality of the software the team writes. If indeed a bug is released, it can be included as a discussion point in the next meeting (in a candid but blame-free way) and the team can come up with actions on how to prevent a similar event from happening in the future. 

This approach to communally owned coding standards means anyone in the team can be an approver. This frees up experienced developers from being gatekeepers of quality while giving more challenging and engaging opportunities for growth to less experienced developers as they’re forced to contemplate broader sets of criteria their code must adhere to beyond simply “does it work?”

## Automate where possible
When approaching a code review there is usually some kind of coding standard to which the team adheres to. Critically assessing code can be time consuming and laborious so any way we can reduce cognitive load should be explored. 

Simply put, if we can automate part of the review process effectively then we should. This could include things like maximum line length, indentation size, spaces after function name etc… Abstracting away these minor aspects of code style means reviewers can focus their attention on higher level concerns. 

This can be accomplished using linters like eslint. Code formatters can be implemented as a pre-commit hook or even integrated with the developers IDE so that when they save a file the code is automatically formatted - this means that we can have linter config files as part of the codebase so that the same formatting rules are always applied regardless of who has checked out the code. 

Automation isn’t just for linting though, we can use static analysis tools to catch missing code coverage or any security vulnerabilities that our changes to the project dependencies might miss out on. 

Automation is one of the simplest ways to bake quality into our development process for a relatively modest initial investment.

## Empathetic feedback
The process of giving feedback, let alone technical feedback is at times poorly understood.

When giving feedback of any kind there are a couple of things to keep in mind:
- Am I acknowledging the subjectivity of my feedback? Eg. making conclusions without room for disagreement
- Have I left my own biases and preferences at the door?
- Have I thought about how the person who asked might receive my feedback?
- Are my critiques actionable?

This stuff all seems basic but too often it’s missing completely. Ineffective developers may seize on code reviews as a chance to exert undue influence over their peers, requiring changes that have no material impact on the outcome.

The best developers use code reviews as teachable moments, where the problem domain is explored in partnership with the person who asked for the review, if indeed something needs to be fixed. The experience or title gap between them is immaterial as they both explore what solution fits best. One-to-one interaction is preferred over review comments where some of the nuance of the conversation may be lost.

Finally, savvy reviewers will also understand that not all code quality issues need to be addressed at the code review stage. If something is unusual and perhaps a little contentious, then it can be addressed asynchronously the next time devs get together to talk about code. Good devs appreciate the cost involved in delay and will never seek to hold up code from being merged any more than strictly necessary.

This neatly leads us to the final point in how we can have more effective code reviews.

## Technical feedback
One of the most common memes when it comes to developers is that it’s hard to get a straight answer from them. Every decision seems to prompt a lot of discussions about trade offs and opportunity costs. 

Unfortunately I think there’s an element of truth to this. Most decisions, especially technical ones, are rarely straightforward and clear cut and usually there is an element of compromise to them. In spite of this ambiguity I think there is some general guidance we can apply when reviewing code for frequently deployed systems that have a low cost of change.

Let’s look at some valid justifications for rejecting a pull request and asking the dev that submitted it to look at it again (for brevity we’re going to assume the project builds successfully and unit tests are passing)


### It doesn't adhere to the teams coding standards
This is pretty straightforward. I won’t go into detail as we’ve already covered this but a team should agree what good looks like and agree to follow those standards. This should be the least contentious type of review comment as everyone had a chance to give their input in shaping these standards.

### The code has quantitative deficiencies
This is where code quality is compromised in ways that, while not explicitly caught by coding standards, have a clear and identifiable negative impact. 

For example, say a dev introduces a new dependency to the project to perform some functionality that is already present in language used. In the Javascript programming language (and others) concise dependency trees lessens potential version conflicts when upgrading. It also creates a smaller vector of attack as fewer dependencies means fewer packages that could, in the course of time, become outdated and insecure. 

In this instance, rejecting this code change upholds a facet of code quality that can’t be strongly argued against, especially since the introduced functionality is already present within our chosen language.

Unjustified code duplication, using deprecated language features or indeed any change that meaningfully compromises the non functional requirements of our system are all examples of quantitative deficiencies.

Beyond these two cases I think review comments fall into the realm of subjectivity. Responsible reviewers can and should acknowledge this and frame their critiques accordingly. Teams that can compromise where appropriate show maturity, even if there are some minor disagreements initially.


## Conclusion:
Doing code reviews well requires trust, openness and empathy within the teams that practice them. 

Far from being a mundane technical practice, code reviews have the chance to energise and engage software delivery teams by fully placing ownship of the software they write in their hands.

So let’s democratise code quality and build a vision of how our system could work that includes everyone.

