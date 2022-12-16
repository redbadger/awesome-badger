---
layout: post
title:  "Quick notes on how to be a Principal Dev"
date:   2022-12-16 12:00:00 +0000
category: timlee
author: Tim Lee
excerpt: Do you want to be a principal dev? Look no further. These notes will sort you right out.
---

# Quick notes on how to be a Principal Dev

_[Tim Lee](../) — 16 December 2022_

## Introduction
Short notes from a 2-day [Principal Dev](https://principal.dev/) training I attended, lead by Eduards Sizovs.

Full course slides can be found [here](https://sizovs.net/principal/#1) (arrow to navigate).

## Short notes

### Agile 
- Agile manifesto says "Our highest priority is to satisfy the customer through early and continuous delivery of valuable software". But customers don't _need_ software, they need cost-efficient solutions to their problems. So perhaps it should be reworded to: "Our highest priority is to find cost-efficient solutions to customers' problems"
- Process of finding the cost-efficient solution from a list of options is called Cost-Benefit Analysis (CBA). Parameters to consider - speed, cost, benefit, risk
- Disney brainstorming method good for sourcing ideas as a group
  1.  Phase 1: gather all ideas, acting as "Dreamers"
  2.  Phase 2: assess ideas as "Realists" looking for limitations
  3.  Phase 3: analyze ideas as "Critics", addressing possible risks
- Don't do what a customer says they want, do what a customer needs (cost-efficiently). Should solve the problem, not the want.
- Important not to shield developers from the business, because software is the implementation **of** the business. Shielding leads to low trust, low motivation and mediocre software solutions.
  - To find cost-efficient solutions, you need a whole-team approach.
  - To write great code, you need a deep understanding of the underlying problem. (software is the implementation of the problem domain. Weak problem understanding -> weak solutions)
  - Understanding the business domain turns engineers into business partners
  - The team owns the product, not product owners. Product ~owners~ leaders promote product understanding.
  - Make impacts, not software

### Leading
- As a leader your job depends on seeing things others don't see. Can't make yourself always busy - need head space to observe. 
- Should switch focus to high-leverage activities (HLAs) - the activities with the highest return on your time investment. Leverage = impact / effort
- Your output is the output of your team. Being busy is not the same as being productive. So focus on HLAs (Pareto principle - 20% of activities give 80% of result). To notice HLAs, don't overwhelm yourself with Low Level Activities (LLAs).
- To get rid of LLAs: Delete -> Defer -> Delegate -> Do
- Removing impediments is good, but empowering the team to see, prioritise and remove it's own impediments is better.

### Measuring dev team's performance
- Lead time - time taken to solve a problem, or time a problem stays "in progress"
	- Can be reduced with cost efficient solutions, good architecture, full-cycle teams (autonomous, cross-functional, self-organising)
- Defects
- DDP (due date performance) - ability to deliver on time
- Reliability
	- MTBF (mean time between failures), MTTD (mean time to detect), MTTR (mean time to remediate)
- ROI - what can you offer that the market can't? Cost-efficient solutions, cost reduction, innovation, leadership, mentoring, visibility, hiring
- Satisfaction - of customers and business
	- Ask 3 questions:
		1. Are you happy with my work?
		2. What do I suck at?
		3. What can I do to improve?

### Throughput
- Little's law - lead time = work in progress / throughput
- Reducing WIP leads to work being delivered more quickly
- Focus as many people as possible on as few projects/stories/tasks as possible - swarming. 
- 4 ways to increase throughput:
  1. Hire more people - though law of diminishing returns (adding more people beyond certain threshold is less efficient). Also Brooks law - adding manpower to late project makes it even later. Small teams tend to do better than large ones - more flexible, aligned, involved, engaged, better relationships, low management overhead. If need more people, continuously refactor company into a network of small, independent, full-cycle teams
  2. High-performance teams - aligned, small, diverse, full-cycle, stable (to achieve Tuckman's stages of group development - forming, storming, norming, performing, takes about a year to get to last stage), skilled
  3. Technical excellence - engineers learn by example from seniors, so choose seniors and leaders carefully. Make sure they promote software craftmanship, clean code, extreme programming, TDD. Make mentoring a prerequisite for promotion. 
  4. Reduce waste, which includes
     1. Partially done work
     2. Overproduction
     3. Waiting/handoffs
     4. Rework
     5. Non-value added activities

### Tips for delivering on promises (namely, within Scrum)
- Know your velocity (work delivered without cutting corners)
- Even under pressure, don't take more work than allowed by your velocity
- Remove planned work when unplanned work appears
- Minimise unplanned work
- Estimate with Fibonnaci numbers to gain speed at cost of accuracy
- Play planning poker until all team members estimates match to reduce HIPPO pressure
- When estimation is difficult or the problem is too big - split or spike to reduce unknowns
- Estimates are innacruate - comfortable velocity must include a buffer
- Turn on swarming for speed and continuous flow, monitor flow to notice issues
- Keep tech debt under control
- Process of estimation is more important than estimates - learn about business, understand problems better, cut scope, slice work for better flow, raise inconvenient questions like why estimates are inflated...

### Tech debt
- There is a strong correlation between the quality of the codebase and throughput. 
- A delivery team tries to maintain it's velocity over time.
- Degredation of the codebase accelerates with time due to reinforcing loops - broken window theory, Brook's law, Lehman's law (entropy), Gresham's law (bad code drives out good - you want to touch nice code, you don't want to touch bad code so they stay longer and sometimes have abstractions written around them).
- Way to achieve sustainable pace/continuous improvement - every time you touch code try and make it slightly better, never worse than before (the Boyscout rule)
- Currency of technical debt is throughput - you borrow throughput and pay it back. It compounds, so the longer it takes to pay back, the worse it gets. Things get built on top of it. So want to pay technical debt early.
- Tech debt is a tool for short term gain.
- Explain the cost of tech debt when making the trade off so there's an understanding that it will either slow down future delivery or be paid back soon.
- Eliminating the cause of technical debt is more important than eliminating the technical debt.
- 4 main causes of tech debt:
  1. Knowledge or skills problem - strong technical leadership/mentoring needed
  2. Attitude problem - "I don't have time for quality"
  3. Borrowing
  4. Learning - knowing more at a later date, finding a better way to do it. So important to attract, develop, retain tech/domain knowledge, along with KISS, YAGNI, validate before building  

### Mentoring
- The learning pyramid goes from least effective to most effective - watching lectures -> reading -> audio/visual -> demonstration -> group discussion -> practicing by doing -> teaching others
- Pyramid moves from passive learning method to active learning methods
- Teaching others is most effective, notably even more than by doing, which is why mentoring is crucial
- 4 stages of learning:
  1. Accumulate knowledge (read, hear, practice)
  2. Teach, explain (code review, pairing, writing, presenting)
  3. Get feedback
  4. Deepen understanding (and improve how well you can articulate an idea)  
- If you can't explain it, you don't understand it

### High performing teams
- Bus factor - make yourself replaceable. The more influential your role, the more you have to care about succession planning. Leaders grow leaders.
- Team performance = sum of performance of each individual x teamwork / wastes
- The wider the skill gap between you and your teammates, the more you have to mentor
- A team needs T-shape people, ensure people have some capability in all areas
- Retention more important than hiring - retain domain knowledge, benefit from growing them, don't have cost of hiring
- 2 types of motivation
  1. Intrinsic - driven because you find it rewarding, performing an activity for its own sake, the behaviour itself is its own reward
  2. Extrinsic motivation - driven to earn a reward, get praise or avoid punishment. Do something because expect to get something in exchange
- Intrinsic motivation is the optimum, more sustainable driver.
- Primary motivators:
  1. Autonomy - freedom to make decisions, create workspace, choose what to work on. Not complete freedom, especially more junior members - not earned trust. More senior = more autonomy - more trust, more expertise. 
  2. Mastery - becoming more capable, learning new skills
  3. Purpose - aligning work with personal goals

### Recruiting
- Important to improve quality of inbound traffic
- Be visible, otherwise people will come to the interview just to find out who you are, waste of time
- Write ads that attract good candidates (with right attitude but lacking certain skills, or with imposter syndrome) and drives away bad candidates (right skills but lacking attitude)
- Perceived ability vs Actual ability graph. Imposter syndrome - high actual ability, low perceived ability. Dunning-Kruger - high perceived ability, low actual ability. A lot of job ads attracts Dunning-Kruger's. Instead of "deep understanding", "good knowledge of", "+3 years of experience", describe the environment, technology and what the person will be doing, what you tend to favour (pair programming, etc) and that it doesn't matter if you don't know something because they offer mentoring. Show job ads to as many colleageus as possible, not just the hiring manager/recruiter having written. textio.com - accessibility language checker
- Beat expectations
	- People should walk out of a conversation smarter, happier, energized (even if they don't make the hire)
	- Invite for a conversation, not an . Run as a conversation instead of a conversation. 
	- Start with a presentation
	- Inspire with gift of books in the interview that are relevant - e.g. Clean Code
- Let candidates code in their comfortable environment
	- The Hawthorne effect (Thinking, fast and slow) - when in stressful situation System 1 dominates and can't think
	- Homework is most inclusive way to assess tech skills
	- Compact but representative
	- Owe the candidate a code review (good parts, bad parts, suggestions, books)

### Reciprocity
- Reciprocity is a social norm of responding to a positive action with another positive action, rewarding kind actions. If you invest in someone, they'll invest in you - invest wisely
- Important for:
  1. Authority - brings influence
  2. Consistency - basic social contract, do what you say
  3. Liking - if people don't like you, they'll object to your ideas even if they're rational
  4. Scarcity - things that are available for everyone have lower perceived value. Things that are not available for everyone have higher perceived value. If you have skills that are more in demand, they'll be more valuable.
  5. Social proof - shortcut to make decisions based on things like ratings, reviews, recommendations, etc

### Management toolbox
- Encourage - help people fight self-doubts
	- #1 reason people leave their role is lack of appreciation - just say thanks is not good, say thank you, "name" for doing "x"
	- Support initiative
	- Behind every request is an unfulfilled desire or need - ask why if don't understand, try to get to bottom of need
- Challenge - delegate technical and non-technical work
	- Delegate tasks that maximize learning (trade-off with speed)
- Answer "how can I do X or Y" with "what options do you see?"
- Share:
	- Knowledge
	- Energy - should know the source of your energy, understand what energises you
- Set rules
	- Less control, more systems
	- e.g. WIP limits, YBIYRI (You Build It, You Run It), CI with daily push into the , QA should find nothing (build quality in), every time new pair
- What skills do my team-mates need the most?
  - At the intersection of personal career goals and team needs
- Trust - product of:
  - Your knowledge
  - Your consistency
  - Your authority
  - Your confidence
  - Your charisma - energy, body language, voice, words
  - Read: Nonviolent communication
  - Your Emotional Intelligence (EQ) - managing thoughts, emotions, mind, ability to connect with others

### Answering the question - am I a good leader?
- Is your team successful?
- Is each individual in your team successful?
- Is your work appreciated by others?
- Is your team reporting high scores in weekly health checks (Spotify strategy - R/G/B scored against categories)?
- Is employee turnover low?
- Are people lining up to work with you?
