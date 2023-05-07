---
title: Delightfully Boring
date: 2023-05-07T20:20:00+02:00
draft: true
---

When I joined my current company a year ago, I was hired partially to help migrate the existing system away from micro-services towards a new monolithic Elixir application.

This decision was made before I had joined, but having worked in a company that went very all-in on micro-services before, I welcomed it.

The reason for the pivot away from the architecture was simple: The team felt that the benefits did not outweigh the drawbacks. We wanted simpler deployments, less independently moving parts and most of all less overhead for building new functionality.

As with many older startups, their initial system was not designed to handle whatever the day-to-day is now, many years later. Often, tech debt was inucrred to buy quick wins for a company that was still figuring out exactly what it was going to be. This is normal.

The result of this rapid change phase was a monolithical Ruby application, which powered the business for a good while. When it became complicated and messy to extend this system, and the new trend of micro-services was all the rage, development of new features was switched over to this new architecture.

The micro-service architecture allowed for different tooling to be used in different services, but decisions for tech where too often done because the tech was interresting, not necessarily because it was the best fit for the problem at hand.

So when I joined the company last April, there was a Ruby Monolith, a handful of micro-services, many self-hosted systems 


I have worked in multiple smaller companies, that have built significant parts of their system using the micro-services architecture. In none of those companies did the benefits promised by the architecture outweigh the drawbacks caused by it. Let me elaborate.

When deciding to built small, self contained services, you get the following advantages:

**Polyglot** You get to use technologies that perform very well in solving your particular problem without needing to commit to them for everything

**Scalability** You can independently scale services to match your individual traffic patterns 

**Coupling** Since individual services can only communicate through specifically defined interfaces, building a tightly coupled systems doesn't happen accidentally.

**Impact** When a service goes down, other parts of the system are still available. Restarts of small services (or even just serverless functions) is fast.

**Independence** When building large systems, a small team can own a couple of related services. Independent repositories allow teams to establish their own workflows. This reduces communication overhead to coordinate changes to the overall system significantly.  

The currency you have to pay for all these advantages is _complexity_.

This is not inherently a problem, but a trade-off. In organizations of certain sizes, communication brings an inherent amount of complexity to development. Once you're in this realm, micro-services allow to deal with this communication complexity with the classic strategy of divide and conquer. They are an appropriate choice.


However, too often an organizations communication complexity is overestimated and declared to be a problem or predicted to _become_ a problem prematurely. This makes sense, since estimating software complexity is one of the hardest things in our profession and often only possible based on historic data, which for architectural decisions isn't generated at the same pace than say ticket estimates.

When discussing this architecture then, it is essential to _always_ look at both the system and the organization in which it exists. This coninsides with the law of BLABLA 

> One must ensure that the actual complexity of a system in an organization matches the preceived complexity 


So what do you do when you want all the advantages from above but the organization does not have the communication complexity which merits using micro-services?

Well I work in a four person backend team. Here's the approach we took.

We are in the process of replacing both our micro-service architecture as well as the leftover ruby monolith with a new system: An Elixir Modulith. Mind the difference in spelling there!

A **Modulith** is an architecture in which you still build a single large application that encompasses many different modules, each implementing a different sub-domain.
Crucially though, the modules are self-contained and only communicate through predefined interfaces.

An alternative way to describe this would be a micro-service architecture from a singular repository in a singular deployable. 

**Polyglot** We can archive this to some extend: everything that is available in the Elixir eco-system can be used in a module. This means different languages (Gleam anyone?), more specific databases or specific libraries/architectures. Since the whole system is now one big application though, different versions of dependencies is not possible.

**Scalability** Elixirs process model allows us to control the amount of parallelism that we allocate to specific tasks. Say the message throughput of a specific module is much higher than others, this module can have multiple instances of the consuming process. Additionally our traffic is not very variable and in it's total amount easily handled by a single application. The micro-services that we have in production right now all run as single instances as well, further reinforcing this point.

**Coupling** This is the tricky one. We currently rely purely on our process of reviewing Pull Requests. There is automated linting available to help with this but shooting yourself in the food accidentally is certainly still possible. As a fallback for this, we have team ceremonies to discuss and validate larger architectural changes as well as a review day where we validate that everything is still on track.

**Impact** Once again, Elixir turns out to be the right technology choice. It's "let it crash" methodology means that the standard library ships with many tools to build long running applications that heal automatically from failure and don't fall over when crashes happen.

**Independence** Since our modules are self-contained, changes to shared functionality is the only thing that must be coordinated. These happen less and less frequently as the system matures. Through the aforementioned ceremonies, we make this communication overhead predictable. Workflows are still allowed some amount of independence as long as the changes produced by them are contained to singular modules.

This has been an approach which so far has allowed us the flexibility we need while keeping complexity as low as appropriate for the small team we are. We have put the focus on not repeating the mistakes of the past, choosing established technologies which are right for the job at hand. We do all this in service of the guiding principle we subscript to as a team: "The whole backend. Delightfully boring."