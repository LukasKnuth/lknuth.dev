---
title: "Design a Technical Interview"
date: 2023-12-28T14:00:00+02:00
---

Last year, the company I work for was looking to hire a Backend Engineer.
We wanted somebody who was a senior or on their way to becoming one.

The Backend Squad was tasked with designing an interview to help decide who to hire based on technical merit.
Above all, we wanted our interview to favor candidates that are good fits.
Now, after working with our new hire for about 11 months, we know that we succeeded.
This is how we went about designing the interview.

## What do we _actually_ do?

To start, we looked at our day-to-day work and distilled it down to a few bullet points.
Such a list might look like this:

<ul>
<li>{{< ref-non-tech.inline >}}Requirements come from a non-technical colleague in unclear language - engineers must ask for clarification and verify they're building the right thing{{< /ref-non-tech.inline >}}</li>
<li>{{< ref-extend.inline >}}Usually we extend existing systems with new functionality - we don't really create new greenfield projects{{< /ref-extend.inline >}}</li>
<li>{{< ref-move-break.inline >}}We don't "move fast and break things" - we must understand the impact of changes before making them{{< /ref-move-break.inline >}}</li>
<li>{{< ref-boring.inline >}}We try to make our systems <a href='/writings/delightfully_boring'>Delightfully Boring</a> - candidates should be pragmatic{{< /ref-boring.inline >}}</li>
<li>{{< ref-process.inline >}}Our processes aren't settled yet and are subject to change - candidates must be able to adapt and share their own insights{{< /ref-process.inline >}}</li>
<li>{{< ref-learn.inline >}}Candidates must be willing to learn on the job - we don't require in-depth prior knowledge of our tech stack{{< /ref-learn.inline >}}</li>
<li>{{< ref-pair.inline >}}We pair on the bigger problems - both to tackle complexity and to challenge each others solutions{{< /ref-pair.inline >}}</li>
<li>{{< ref-high-vantage.inline >}}The backend team makes big decisions autonomously - we need people that can discuss ideas from a high vantage-point and not get bogged down in details{{< /ref-high-vantage.inline >}}</li>
<li>{{< ref-ideas.inline >}}We value engineers who bring their own thoughts and ideas - not code monkeys that simply do what they're told{{< /ref-ideas.inline >}}</li>
</ul>

Each point should be general enough to avoid specifics, yet clear enough to feel tangible.
The correct degree of "specific" will depend on your company.
For example, if you are a Flutter consultancy, Flutter experience is a very specific requirement.

Don't be fooled, it took quite a while to distill everything down to just the list above.
This is also not a job for one person alone.
We individually came up with points, collected them in the squad and decided together what we felt was most important to make the final list.

## Fixed requirements

The takeaways above are valuable, but they're only half of the story.
Usually, there are things that aren't up for discussion in the hiring process.
We'll look at these requirements next.

* The interview will be remote
* Interviews are set for 45 minutes
* The technical interviewer should not be the same person the candidate interacted with previously
* The language is English - spoken and written

This step is boring, but it helps to determine the _scope_ of the interview.

We must also consider how this will feel to the candidate and how it will influence their performance.
For example, they will probably be less comfortable when speaking to somebody they have never interacted with.
This could falsely register as the candidate being shy or uncommunicative.
So when assessing the candidate after the interview, we must be aware of this bias.

## Designing an interview

Now that we have gathered all the ingredients, we can start designing the actual interview.
We'll go through the points collected above and let them inform our design.

> * {{< ref-high-vantage.inline />}}
> * {{< ref-non-tech.inline />}}

We want to test for skills that are relevant to the work the candidate is _actually_ going to be doing at the company.
Therefor, the interview problem must be authentic.

The problem is stated in non-technical, ambiguous language - the candidate _must_ ask for clarification.
A shortened example of such a problem might be:

> We added many small features to our product which are very useful in very specific situations. We want to inform our users about the ones which are relevant to them. To do this, we will collect user statistics. Based on usage patterns we will then promote selected features to the users.

A problem statement like this gives the candidate plenty opportunity to ask questions.
What kind of statistics should be collected? Should they be collected for each user individually? How should they be collected? Can users opt-out? Does this have to be GDPR compliant?

Phrasing the problem like this also shows us if the candidate is able to focus on whats relevant.
In the example problem above, it's not clear how exactly the promotion of features to users will work.
While still relevant, this aspect is a proportionally tiny (and very specific) part of the overall problem.
We therefore expect the candidate to spend little time on it.

> * {{< ref-pair.inline />}}

Because we pair regularly, the interview is no different.
The candidate is the Driver, making the decisions and steering the the interviews direction.
The interviewer takes the role of the navigator, answering questions and giving insight to guide the candidate.

> * {{< ref-high-vantage.inline />}}
> * {{< ref-extend.inline />}}
> * {{< ref-move-break.inline />}}

Extending existing systems is a very relevant task.
We have a number of complicated legacy systems.
While we usually don't expect to touch these systems at all, we can't break them either.

Candidates must have the ability to grasp existing systems, find the right place to extend them and plan everything out.
Once again we're interested in seeing if a candidate can identify and stick to the relevant parts of the problem.
Diagrams created in this step are not expected to be beautiful, only cohesive.

To test all this, we added a **Systems Design** portion to the interview.
Here, candidates are expected to design and model a system that solves the initially stated problem.

We don't impose a specific modeling technique, nor a specific architecture.
Candidates can ask for architecture details if needed, but are also told they're free to assume.
We're hoping to make it as comfortable for the candidate as possible to observe their skills under ideal conditions.

> * {{< ref-learn.inline />}}
> * {{< ref-process.inline />}}

Designing the system is only half the story though.
For the **Software Development** portion of the interview, we ask candidates to build a _small piece_ of the solution they just modeled.

Again, we don't enforce any specific tooling.
While we hire engineers to work in Elixir, we don't require prior knowledge of it.
We expect capable developers are able to adopt to a new language quickly, so proficiency with language/tooling isn't a focus for the interview.

Candidates are free to use whatever language/framework/environment they're proficient with.
Pseudo code is also accepted.
It's not relevant to us if the candidate knows their languages standard library by heart.
Code doesn't need to compile either, as long as the intend is clearly communicated.

Our approach to team processes is similar.
We don't treat popular processes like Agile or Shape-Up like dogma.
Instead, we pick and choose what works for us, revisiting and refining as needed.
This means that whatever touch points the candidate previously had with these processes, the details will differ.

> * {{< ref-ideas.inline />}}
> * {{< ref-boring.inline />}}

There isn't enough time to have the candidate build a complete solution to the given problem.
But there _is_ enough time to observe the way they go about solving the problem.
This tells us if candidates are organized and how they communicate.

While everyone is unique in this regard, we explicitly look for strong communicators.
Candidates that ask questions, explain their train of thought and ask for help when stuck.
Since we expect this behavior from them, we state up front that no extra credit is given for solving the problem without asking questions.

## Sequence

**First**, we (the interviewer) do a very brief introduction.
We state all parameters and expectations for the interview up-front.
We stress that there are no extra points for completeness, speed or or working without asking questions.

In the **second** step we unveil the problem statement.
We give the candidate time to read it, highlight what _they_ think is important and ask questions.

The **third** step is to design the system as stated in the problem.
We use an infinite modeling canvas for all this, currently Miro.
During this phase we try to offer soft guidance where necessary and keep an eye on the time, aiming for about 20min.
When the candidate is happy with their design, we shortly discuss pros/cons as well as issues we see and possible solutions.

The final, **fourth** step is to take a piece of the problem statement and write code to solve it.
We let the candidate use their familiar tooling and simply share their screen.
During this phase we help with questions and challenge if the code fits the previously designed system.
Once again, we keep the time and aim for 20min.
As with the design, we shortly discuss pros/cons as well as issues (and their solutions) in the code.

## Learnings

Since we ran this interview strategy before, here are some takeaways and ideas for iterating on the process.

Many companies require developers to create small sample projects in their free time.
This tends to penalize people with families or just less free time, so we decided to avoid it.
We've gotten largely positive feedback from candidates for this decision.

Many candidates spend too much time making their diagrams look pretty.
This is an interesting observation.
On the one hand, we could discourage this behavior for example by choosing tooling that doesn't allow for precise alignment in diagrams.
On the other hand, we also feel this is a good tell if the candidate is able to focus on what's relevant.

Interviews like these create high pressure situations, almost like school tests.
Additionally, time is very constrained.
We think this is fair in our case, because we were hiring senior engineers.
When hiring less experienced engineers though, its unreasonable to expect them to perform their best under these circumstances.
