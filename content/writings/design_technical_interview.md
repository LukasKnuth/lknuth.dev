---
title: "Design a Technical Interview"
date: 2023-10-28T14:00:00+02:00
---

Last year, we where hiring for a Backend Engineer position.
We wanted somebody who was a senior or on their way to becoming one.
After the initial CV screening and 1:1 phone interview to check social compatibility, candidates would have to complete a technical interview.

But how do you design a technical interview?
More importantly, how do you make sure to test if the candidate can perform the day to day work you actually do at your company?

## What do we _actually_ do?

We started by looking at our day to day work and distilled it down to a few bullet points:

<ul>
<li> {{< ref-non-tech.inline >}}Requirements come from a non-technical colleague in unclear language - engineers must ask for clarification and verify they're building the right thing{{< /ref-non-tech.inline >}}</li>
<li>REFORMULATE! * We want engineers that weigh in with their thoughts and ideas - not code monkeys that simply do what they're told</li>
<li>{{< ref-extend.inline >}}Usually we extend existing systems with new functionality - not create new greenfield projects{{< /ref-extend.inline >}}</li>
<li>We don't "move fast and break things" - we must understand the impact of changes before making them</li>
<li>We pair on complex things and ask colleagues to challenge our ideas</li>
<li>We try to make our systems <a href='{{< ref "delightfully_boring" >}}'>Delightfully Boring</a> - candidates should be pragmatic</li>
<li>Our processes aren't settled yet and are subject to change - candidates must be able to adapt and bring their own insights</li>
<li>Candidates must be willing to learn on the job - we don't require in-depth prior knowledge of our tech stack</li>
<li>{{< ref-high-vantage.inline >}}The backend team makes big decisions autonomously - we need people that can discuss ideas from a high vantage-point and not get bogged down in details{{</ ref-high-vantage.inline >}}</li>
</ul>

We try to make these points free of specifics, yet clear enough to feel tangible.

Don't be fooled, it took quite a while to distill everything down to just this.
This is also not a job for one person alone.
Gather input and feedback from your colleagues and discuss what each of you feels is important.

## Process requirements
TODO other name for this concept?

The takeaways above are valuable, but they're only half of the recipe.
Usually, there are things that aren't up for discussion in the hiring process.
We'll look at these requirements next and then finally bake them together.

* The interview will be remote
* Interviews are set for 45min
* The technical interviewer should not be the same as from previous steps
* The language is English - spoken and written

This step is boring, but it helps us determine the _scope_ of the interview.

We must also consider how these make the candidate feel.
For example, they will probably be less comfortable in front of somebody they have never interacted with.
They might come off as shy or uncommunicative in the beginning.
So when assessing the candidate after the interview, the interviewer we must recognize this bias.

## Designing an interview

Now that we have gathered all the ingredients, we can start designing the actual interview.

> * {{< ref-high-vantage.inline />}}
> * {{< ref-extend.inline />}}

THis means that bla blabla bla
j
---

If we want to test for skills that are relevant to the work the candidate is _actually_ going to be doing at the company, we must model the interview problem after a "normal day at the office":

* The candidate (driver) and the interviewer (navigator) pair on the problem
* The problem is stated in non-technical, ambiguous language - the candidate _must_ ask for clarification
* 

To group these insights together, we'll name them **Relevance**


## Specifics

We usually hire engineers to work with a specific programming language, but we don't require prior knowledge of it. We expect capable developers are able to adopt to a new language quickly, so proficiency with language/tooling isn't a focus point.

The same goes for techniques and processes. We have our own processes that we expect are slightly different to the ones the candidates are used to from their previous workplace. We expect the 
candidate will learn these during their onboarding period.

**PERIOD OF LEANRING AFTER BEING HIRED ANYWAYS**

We set the following rules for the interview:

* We don't impose a specific modeling technique for architecture diagrams
* We don't impose a specific programming language for coding assignments - pseudo code is also fine
* We don't impose a specific architecture - candidates are free to make assumptions that they're comfortable with

## Scope

There is limited time in these interviews, usually 45min. This is not enough time to create a complete solution to any meaningful problem, but it is enough to observe the way candidates go about solving the problem.

We're also interested if the candidate is able to concentrate on doing a rough pass of a problem from a high vantage point rather than getting stuck in details. We're usually not concerned if the code the candidate writes will compile or if they remember the order of arguments for standard library functions, for example.

Again, the following rules are applied:

* Time limits are _gently_ enforced by the interviewer to ensure the candidate has time to get to all parts of the problem
* We communicate up front that we don't expect a _complete or perfect_ solution
* Diagrams drawn need not be beautiful, just cohesive
* Code written does not need to compile