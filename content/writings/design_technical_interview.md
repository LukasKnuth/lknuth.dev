---
title: "Design a Technical Interview"
date: 2023-10-28T14:00:00+02:00
---

Last year, we where hiring for a Backend Engineer position.
We wanted somebody who was a senior or on their way to becoming one.
After the initial CV screening and 1:1 phone interview to check social compatibility, candidates would have to complete a technical interview.

But how do you design a technical interview?
And, more importantly, how do you ensure your technical interview favors candidates that are good fits for your real day to day work?

## What do we _actually_ do?

We started by looking at our day to day work and distilled it down to a few bullet points:

<ul>
<li>{{< ref-non-tech.inline >}}Requirements come from a non-technical colleague in unclear language - engineers must ask for clarification and verify they're building the right thing{{< /ref-non-tech.inline >}}</li>
<li>{{< ref-extend.inline >}}Usually we extend existing systems with new functionality - we don't really create new greenfield projects{{< /ref-extend.inline >}}</li>
<li>{{< ref-move-break.inline >}}We don't "move fast and break things" - we must understand the impact of changes before making them{{< /ref-move-break.inline >}}</li>
<li>{{< ref-boring.inline >}}We try to make our systems <a href='/writings/delightfully_boring'>Delightfully Boring</a> - candidates should be pragmatic{{< /ref-boring.inline >}}</li>
<li>{{< ref-process.inline >}}Our processes aren't settled yet and are subject to change - candidates must be able to adapt and share their own insights{{< /ref-process.inline >}}</li>
<li>{{< ref-learn.inline >}}Candidates must be willing to learn on the job - we don't require in-depth prior knowledge of our tech stack{{< /ref-learn.inline >}}</li>
<li>{{< ref-pair.inline >}}We pair on complex things and ask colleagues to challenge our ideas{{< /ref-pair.inline >}}</li>
<li>{{< ref-high-vantage.inline >}}The backend team makes big decisions autonomously - we need people that can discuss ideas from a high vantage-point and not get bogged down in details{{< /ref-high-vantage.inline >}}</li>
<li>{{< ref-ideas.inline >}}We value engineers who bring their own thoughts and ideas - not code monkeys that simply do what they're told{{< /ref-ideas.inline >}}</li>
</ul>

We attempted to keep these points non-specific, yet clear enough to feel tangible.

Don't be fooled, it took quite a while to distill everything down to just this.
This is also not a job for one person alone.
Gather input and feedback from your colleagues and discuss what each of you feels is important.

## Fixed requirements

The takeaways above are valuable, but they're only half of the story.
Usually, there are things that aren't up for discussion in the hiring process.
We'll look at these requirements next.

* The interview will be remote
* Interviews are set for 45min
* The technical interviewer should not be the same person the candidate interacted with previously
* The language is English - spoken and written

This step is boring, but it helps us determine the _scope_ of the interview.

We must also consider how this will feel to the candidate and how it will influence their performance.
For example, they will probably be less comfortable in front of somebody they have never interacted with.
They might come off as shy or uncommunicative in the beginning.
So when assessing the candidate after the interview, the interviewer we must recognize this bias.

## Designing an interview

Now that we have gathered all the ingredients, we can start designing the actual interview.
We'll go through the points collected above and let them inform our interview.

> * {{< ref-high-vantage.inline />}}
> * {{< ref-non-tech.inline />}}

We want to test for skills that are relevant to the work the candidate is _actually_ going to be doing at the company.
Therefor, the interview problem must be authentic.

The problem is stated in non-technical, ambiguous language - the candidate _must_ ask for clarification.
An example of such a problem might be:

> We added many small features to our product which are very useful in very specific situations. We want inform our users about the ones which are relevant to them. To do this, we will collect user statistics. Based on usage patterns we will then promote selected features to users.

A problem statement like this gives the candidate plenty opportunity to ask questions.
What kind of statistics should be collected? Should they be collected for each user individually? How should they be collected? Can users opt-out? Does this have to be GDPR compliant?

Phrasing the problem like this also shows us if the candidate is able to focus whats relevant.
In the example problem above, we would expect the aspect of promoting features to users be less important.

> * {{< ref-pair.inline />}}

Since we often work in pairs, the interview is no different.
The candidate is the Driver, making the decisions and steering the the interviews direction.
The interviewer takes the role of the navigator, answering questions and giving insight to guide the candidate.

> * {{< ref-high-vantage.inline />}}
> * {{< ref-extend.inline />}}
> * {{< ref-move-break.inline />}}

Extending existing systems is a relevant task.
We have a number of complicated legacy systems.
While we usually don't expect to touch them at all, we can't break them either.

Candidates must have the ability to grasp existing systems, find the right place to extend them and plan everything out.
Designs are then vetted by other team members before they're applied.
Once again we're interested in seeing if a candidate can identify and stick to the relevant parts of the problem.
Diagrams created in this step are not expected to be beautiful, only cohesive.

To test all this, we added a **Systems Design** portion to the interview.
Here, candidates are expected to design and model a system that solves the initially stated problem.

We don't impose a specific modeling technique, nor do we impose a specific architecture.
Candidates can ask architecture details if needed, but they are also told they're free to assume.
We're hoping to make it as comfortable for the candidate as possible to observe their skills under ideal circumstances.

> * {{< ref-learn.inline />}}

For the **Software Development** portion of the interview, we ask candidates to build a _piece_ of the solution they modeled previously.

Again, we don't enforce the usage of specific tooling.
While we hire engineers to work with a specific programming language, we don't require prior knowledge of it.
We expect capable developers are able to adopt to a new language quickly, so proficiency with language/tooling isn't a focus point.

Candidates are free to use whatever language/framework/environment they're proficient in.
Pseudo code is also accepted.
It's not relevant to us if the candidate knows all standard library functions by heart.
Code doesn't need to compile either, as long as the intend is clearly communicated.

> * {{< ref-process.inline />}}

We have our own processes that we expect are slightly different to the ones the candidate is used to from their previous workplace.
We expect they will learn these during their onboarding period.

> * {{< ref-ideas.inline />}}
> * {{< ref-boring.inline />}}

There isn't enough time to create a complete solution to the given problem.
But there _is_ enough time to observe the way candidates go about solving the problem.
This tells us if candidates are organized and how they communicate.

While everyone is individual in this regard, we explicitly look for strong communicators.
Candidates that ask questions, explain their train of thought and ask for help when stuck.
Since we expect this behavior from them, we state up front that no extra credit is given for solving the problem without any questions.

## Sequence

**First**, we do a short introduction between the candidate and the interviewer.
We state all parameters up-front for the interview, most importantly that there are no extra points for completeness.

In the **second** step we unvail the problem statement.
We have the candidate read it, mark what _they_ think is important and ask questions.

The **third** step is to design the system as stated in the problem.
We use an infinite modeling canvas for all this, currently miro.com
During this phase we try the steer the candidate softly where needed and keep an eye to land at around 25min.

The final, **fourth** step is to take a piece of the problem statement and write code to solve it.
We let the candidate use their familiar tooling and do screen sharing.
During this phase we help with questions, verify that they build a solution compatible with the previous step and once again, keep an eye on the time.

## Learnings

Since we ran this interview strategy before, here are some takeaways and ideas for iterating on the process.

We've gotten largely positive feedback from candidates.
Many companies require developers to create small sample projects in their free time.
This tends to penalize people with families or just less free time, so we decided to avoid it.

Many candidates spend too much time making their systems diagrams pretty.
Instead of discouraging them to do so, we could also use simpler tools, like MS Paint.
The idea is to signify from the beginning that we only expect rough outlines.