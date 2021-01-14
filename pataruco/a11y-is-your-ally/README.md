# a11y\* is your ally

> `*` Accessibility is often abbreviated as the [numeronym][numeronym] **a11y**, where the number 11 refers to the number of letters omitted.

I am going to talk about Accessibility for the Web by offering a software engineer perspective (my area of ​​knowledge) of it. However, it is important to highlight that each member of the team could approach this topic from their own discipline.

For instance, product designers could ensure that colours have an adequate contrast ratio. QA engineers could use end to end tools to test whether pages can be used with assistive technologies (AT), and so on.

To continue with this exercise, I will use the [Five Ws][five-w]

## What?

The best inclusive tool of all!

Accessibility is the practice of making websites usable by as many people as possible. It is treating everyone equally and giving them the same opportunities, regardless of ability or circumstances. [[1](#references)]

## Who?

You and your team!

By using modern software delivery techniques (Agile, Scrum, Kanban, etc.), developers can work together (and not exclusively) with product designers, user experience designers, QA engineers, product managers, among others. All of us should raise and maintain the conversation on how to develop accessible products and services at all times.

## When?

From the beginning and forever!

Accessibility should not be just one more layer of development to be added later. Not only is this approach more expensive, but it is more complex.

Accessibility must be the core of all development because in the end, what we are doing is solving human problems with the use of technologies. Therefore, our focus must be anthropocentric.

## Where?

For starters, in all HTML development!

Web browsers make use of special accessibility APIs (provided by the underlying operating system) that expose useful information for assistive technologies (ATs). Most ATs tend to use semantic information from HTML, but this content does not include style or JavaScript information.

When the native semantic information provided by the HTML elements of web applications fails, it can be supplemented by features of the [WAI-ARIA][wai-aria-basics] specification.

## Why?

Because it is the law! It helps people and SEO.

Some countries have specific legislation that regulates the need of accessibility for websites. For example, [EN 301 549][eu-law] in the EU, [Section 508 of the Rehabilitation Act][usa-law] in the USA, [Accessibility Regulation 2018][uk-law] in the UK are some examples.

Even though accessibility for the web is included in some laws, unfortunately, there is still no authority to issue fines to those who break the law (more on this at the end of this article).

But if following the law is not enough stimulus, I am going to name another one: SEO! Search engine indexers (Yahoo !, Google, Bing, DuckDuckGo) use semantic HTML to extract information about a web page. It means that to have accessibility as a core leads to better chances that the content we are serving will be best ranked in search engines.

## How?

Easier than you think!

I am going to mention some tools that have helped me when I develop.

- **Semantic HTML**: Use HTML tags to give semantic meaning to the content. For example, it is very common to see developers who, when viewing the content directly from design, get confused if the content is a paragraph (`<p>`) or a heading (`<h1>-<h6>`) when the font size is big. So you should always ask the following question: what is the semantic intention of this content?

- **Command-line browsers**: Before styling the component with CSS, add it to the pages where it will be used and then navigate to them using a command-line browser like [Lynx][lynx]. If you can navigate and use the component with a command-line browser, it means that that component is accessible.

- **Linters**: [ESLint][eslint] has accessibility [plugins][eslint-a11y-plugins] that together with [Git Hooks][git-hooks] can generate the first barrier for non-accessible components in the [source code][mhra-a11y-example].

- **CI accessibility tests**: Run accessibility tests against multiple URLs and reports on any issues using [Pa11y-CI][pa11y-ci] or [Puppeteer][puppeteer] with [Axe][axe].

### Sidenotes

[Domino's v. Robles][usa-supreme-court-ruling-about-a11y]. On October 7th of 2018, the U.S. Supreme Court allowed a blind man’s accessibility lawsuit against Domino’s Pizza to proceed, paving the way to enforce more companies to provide accessible digital services.

### References

1. "[So What is accessibility](https://developer.mozilla.org/en-US/docs/Learn/Accessibility/What_is_accessibility#So_what_is_accessibility)". Mozilla Developer Network

[numeronym]: https://en.wikipedia.org/wiki/Numeronym
[five-w]: https://en.wikipedia.org/wiki/Five_Ws
[wai-aria-basics]: https://developer.mozilla.org/en-US/docs/Learn/Accessibility/WAI-ARIA_basics
[eu-law]: https://www.etsi.org/deliver/etsi_en/301500_301599/301549/02.01.02_60/en_301549v020102p.pdf
[usa-law]: https://www.section508.gov/training
[uk-law]: https://www.legislation.gov.uk/uksi/2018/952/introduction/made
[lynx]: https://invisible-island.net/lynx/
[eslint]: https://eslint.org/
[eslint-a11y-plugins]: https://www.npmjs.com/package/eslint-plugin-jsx-a11y
[git-hooks]: https://git-scm.com/book/en/v2/Customizing-Git-Git-Hooks
[mhra-a11y-example]: https://github.com/MHRA/products/blob/master/medicines/web/.pa11yci
[pa11y-ci]: https://github.com/pa11y/pa11y-ci
[puppeteer]: https://github.com/puppeteer/puppeteer
[axe]: https://github.com/dequelabs/axe-core
[usa-supreme-court-ruling-about-a11y]: https://www.supremecourt.gov/DocketPDF/18/18-1539/102950/20190613153319483_DominosPetition.pdf
