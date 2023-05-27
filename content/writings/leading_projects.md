---
title: "Leading Projects"
date: 2023-05-21T12:55:32+02:00
draft: true
---

Some years ago I worked in a team of software developers which I still consider the most productive team I have ever been a part of. We built a large system for our internal users with a dozen product team members and had a turnaround time from _idea_ to _implementation_ of about three weeks. This is how we did it.

## Day to day

There where two types of work: the eternal pull-queue of tasks like maintenance or smaller adjustments to existing services, and the frequent but short projects we did to build new services or make larger changes to existing ones.

Since the team had a very high degree of maturity and everyone's experience was basically on-par, we rotated everything. A typical month then was working on the pull-queue for the first week, being part of a project for the next two weeks and then getting to wind down again with a week of pull-queue. Rinse and repeat.

## Projects

The basis for how we did project work was inspired by [Basecamp's Shape Up](https://basecamp.com/shapeup). We adapted it for our specific use-case, taking what made sense and slightly altering things to work well with already established processes or business realities we could not affect.

This didn't happen over night. The process was continuously re-examined and changed through the feedback of both developers doing the projects, managing team members chaperoning them and stakeholders/domain experts trying to make their work more efficient. 

## Shapes

The starting point for any project was a Shape. It was a basic description of a problem to solve and the **boundaries** of the solution. It did not contain any requirements or outlines of exactly what was to be built or how - and if anything bore semblance of it, the project team was always free to ignore it entirely.

An important property of a shape was that it was **solved**, meaning it outlined a thought through solution for the problem on a _macro_ level. This also meant that stakeholders where involved in the process early and their domain knowledge had informed the shape.

As far as foresight would allow, it listed rabbit-holes and no-gos to establish the **boundaries** around the solution. Within these given boundaries, the eventual project team was free to find whatever implementation delivered value to users in the allotted time.

## Projects

Projects where always eight workdays. They were always based on a shape that was provided by managing members of the team. The project always had around four or five people attached to it, including developers, designers and domain experts. Every project had one project lead tasked with coordinating the project and communicating with stakeholders. Every project always had at least one stakeholder attached to it, available to validate assumptions and solutions with their domain knowledge.

We had one immutable rule in these projects: **Fixed time, variable scope**. We would never extend a project, instead cutting the scope to fit the available time. We'd be adamant about this, going so far as to making decisions to cut scope on the first day already. The goal was always to deliver value to users, _compared to their current baseline experience_.

In the rare instance where we failed to deliver at least _some_ value to our users, we re-examined the projects progress and shape to try and understand why it didn't work out. If after this the shape - with any changes applied - still seemed doable, we would schedule a follow up project a few weeks later. Same rules applied.

## Kick-Off

We'd have a single kick-off meeting in the afternoon on the day of the project start, giving members a chance to read the shape beforehand and clarify any open questions with the stakeholders also attending the meeting.

In later iterations of the process, we put more emphasis on walking through the _problem_ with the stakeholders present. We'd use the insights to challenge the shape directly with it's authors. This often uncovered small but important details the authors hadn't thought to include in the shape because they seemed prerequisite after enough engagement with the problem.

It was understood that to begin work, a solid understanding was required first. The managing members and shape authors where tightly looped into this phase, which served as a feedback loop for _their_ respective processes which had produced the shape.

## Work

Given the rough nature of a shape we where very careful about any work resulting from reading the shape first, going so far as to classify this work as **imagined work**. This was work we expected to do based on what we read, informed by our existing preconceptions and biases. It was a necessary starting point, but not of much value.

Once we started working on the tickets resulting from _imagined_ work, we'd usually discover things where slightly different, more complicated or not at all as imagined. This was expected and understood to be so valuable we called this work **discovered work**. This would end up being the bulk of actual work to do and was of high value.

The project was structured then to get from _imagined_ work to _discovered_ work as quickly as possible. To this end, we'd prioritize shipping iterations quickly to the staging environment, getting them into the hands of stakeholders early.

## Vertical Slices

These iterations where vertical slices, starting of with many mocked layers which where gradually replaced by the actual implementations later. The goal was to build something stakeholders could get their hands on early to determine if the solution would deliver the value we envisioned. If this turned out not to be the case, we could pivot early when making large changes was still relatively cheap.

The goal of these slices was always to _discover_ as much work as possible. To maximize for this then, we went for anything **novel** and **core** first. We preferred small pieces of _imagined work_ and if none existed that matched the aforementioned criteria, we made the ones that did smaller by mocking extensively.

## From a Scope to Scopes

Since we where already building slices of the projects vertically, we planned them like this as well. The whole project was sliced into multiple smaller scopes, initially from _imagined_ work which was continuously replaced by _discovered_ work as we dug deeper into the tasks.

As we discovered more and more work in the project, we'd collect it into scopes, each representing a slice of the whole project. The 1:1 relation between a scope and a vertical slice wasn't mandatory but often occurred naturally.

The scopes where not drawn once, but refined throughout the project many times, often settling only when most of the work inside it was _discovered_ work. This was accepted and reported on.

Naming these scopes was important, as they would be referred to often in conversations and so gradually become part of the language spoken in the project. As a yardstick for how settled the projects scopes where, we asked ourselves if we could see the **entire** project just by looking at the scope names and whether it was always clear to what scope any new work would belong to. If this proofed hard with the existing scopes, we would redrawn them until it was.

## Tasks

As tasks where placed into their respective scopes, we would categorize them into either an "uphill" or "downhill" phase of work. Any task would start of as "uphill" and remain there until it was clear exactly what had to be done and how it would be done.

We took this serious, only promoting something to "downhill" when we could validate (e.g. through a prototype) that everything was truly understood and going to work as we expected.

The tickets in a scope could then be summed up to show the overall phase of the scope. We'd aim to first get _all_ tickets out of the "uphill" phase before then implementing them all in a concentrated pair programming session. This drastically reduced the chances of complexity catching us off guard during implementation.

We'd try to finish one scope before tackling the next, but allowing ourselves to work on other scopes when progress was blocked or no clear primary scope was chosen yet - mainly in the very beginning of the project. Depending on the available project resources we could even parallelize work on multiple scopes. 

As more and more vertical slices of the whole project where integrated this way, it was straightforward to tell how much we would be able to finish during the projects runtime and then prioritize the remaining scopes by impact together with stakeholders.

## Reporting

Since much emphasis was placed on scopes and they where part of the projects natural language already, they became our number one reporting tool. This also meant that if during reporting it was hard to tell exactly how 'done' a scope was, it wasn't a useful scope and would again be redrawn.

Reporting was done by the project lead on a bi-daily basis. This may sound like a lot, but it also forced the lead to be on top of all scopes and their current phase virtually all the time, which increased awareness of the overall progress and incentivized thinking about cutting scope early and often.

During the reporting, managing members of the project team could take the role of outside entities with a more detached view on the overall project momentum. Having the reports happen frequently meant we got to compare the perceived project momentum by members of the project with what the outside entities felt. This was usually valuable feedback and led to cutting scope when it mattered.

## Good enough

> Perfect is the enemy of good

With all the scope cutting encouraged as it was, to some colleagues it felt like we where failing to deliver. Cutting scope had previously been a last resort and doing it frequently felt like failing to deliver many times over. When a final result was archived but didn't match what was envisioned in the shape or at the start of the project, colleagues felt like the whole project was a failure.

Worse yet, when colleagues felt like _their_ project was getting into this territory, they'd sacrifice tests, documentation or pairing for perceived speed gains when coding. We found that, at best, this reduced the quality of delivered software significantly; if it worked out to deliver anything substantial at all.

To counteract this thinking, we put emphasis on comparing project outcomes to the _baseline_ experience for users before the project. We also made it clear that we would not compromise on quality, knowing that as a product company, we'd have to support bad software for longer than we'd like. It took a while until this paradigm shift took hold, but eventually it did.

# Problems

* Shapes handed down from above
* Short supply of certain resources (designers)
* Not written out before i did it
* Stakeholders where not on-board enough (given too little time) 
* Sometimes we didn't built what stakeholders initially wanted which management didn't love