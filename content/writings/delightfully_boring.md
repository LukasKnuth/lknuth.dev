---
title: Delightfully Boring
date: 2023-05-15T13:30:00+02:00
summary: |
  When I joined 7Mind a year ago, I was hired partially to help migrate the existing system away from micro-services towards a new monolithic Elixir application.
  This decision was made before I had joined, but having worked in a company that went very all-in on micro-services before, I welcomed it.

  In this article we'll look at the value that micro-services bring to an organization and how at 7Mind we capture the same value with a single modulithic application.
---

This article was originally published on [tech.7mind.de](https://tech.7mind.de/posts/delightfully_boring/)

---

When I joined 7Mind a year ago, I was hired partially to help migrate the existing system away from micro-services towards a new monolithic Elixir application.

This decision was made before I had joined, but having worked in a company that went very all-in on micro-services before, I welcomed it. But first, some background.

As with many older startups, their initial system was not designed to handle whatever the day-to-day is now, many years later. Often, tech debt was inucrred to move quickly alongside a company that was still figuring out exactly what it was going to be. In this phase, the system grew organically. This is expected.

The result of this rapid change phase was a monolithical Ruby application, which powered the business for a good while. When it became complicated and messy to extend this system, and the new trend of micro-services was all the rage, development of new features was switched over to the new and exciting thing.

As with everything, micro-services are not a silver bullet, and in this case the benefits promised by the architecture did not outweigh the drawbacks caused by it. Let me elaborate.

## Advantages of micro-services

When deciding to built small, self contained services, you get the following advantages:

### Polyglot

You get to use technologies that perform very well in solving your particular problem without needing to commit to them for everything.

### Scalability

You can independently scale services to match your individual traffic patterns.

### Coupling

Since individual services can only communicate through specifically defined interfaces, building a tightly coupled system doesn't happen accidentally.

### Impact

When a service goes down, other parts of the system are still available. Restarts of small services (or even just serverless functions) is fast.

### Independence

When building large systems, a small team can own a couple of related services. Independent repositories allow teams to establish their own workflows. This reduces communication overhead to coordinate changes to the overall system significantly.  

## Balancing complexity

The price you pay for all these advantages is _complexity_.

This is not a problem in and of itself, but a trade-off. In organizations of certain sizes, communication brings an inherent amount of complexity to software development. Once you're in this realm, micro-services allow to deal with this communication complexity with the classic strategy of divide-and-conquer. They are an appropriate choice.

However, too often an organizations communication complexity is overestimated and declared to be a problem or predicted to _become_ one prematurely. This makes sense, since estimating software complexity is one of the hardest things in our profession and often only approximated based on historic data, which for architectural decisions isn't generated at the same pace than say tickets in a sprint.

When considering this architecture then, it is essential to _always_ look at both the system and the organization in which it exists. This conincides with [Conway's Law](https://en.wikipedia.org/wiki/Conway%27s_law):

> Any organization that designs a system (defined broadly) will produce a design whose structure is a copy of the organization's communication structure.

This seems to suggest that the precondition to any serious discussion of using micro-services is to ensure that the perceived complexity of a system in an organization matches the actual complexity of said system.

## Having your cake and eating it, too

So what do you do when you want all the advantages from above but the organization does not have the communication complexity that merits using micro-services?

Well I work in a four person backend team. Here's the approach we took.

We are in the process of replacing both our micro-service architecture as well as the leftover ruby monolith with a new system: An Elixir Modulith. Mind the difference in spelling there!

A **Modulith** is an architecture in which you still build a single large application that encompasses many different modules, each implementing a different sub-domain.
Crucially though, the modules are self-contained and only communicate through predefined interfaces, like events.

A different way to say this is: micro-service architecture in a singular repository resulting in a singular deployable. 

### Polyglot

We can archive this to some extend: everything that is available in the Elixir eco-system can be used in a module. This means different languages ([Gleam](https://gleam.run/) anyone?), more specific databases or libraries/architectures.

Since the whole system is now one big application though, different versions of dependencies aren't supported.

### Scalability

Elixirs [process model](https://launchscout.com/blog/intro-to-processes-in-elixir) allows us to control the amount of parallelism that we allocate to specific tasks. Say the message throughput of a specific module is much higher than others, this module can have multiple instances of the consuming process.

Additionally our traffic is not very fluctuating and in it's total amount easily handled by a single instance. In fact the micro-services that we have in production right now all run as single instances as well, further reinforcing this point.

### Coupling

This is the tricky one. We currently rely purely on our process of reviewing Pull Requests. There is [automated linting](https://github.com/sasa1977/boundary) available to help with this but shooting yourself in the food accidentally is certainly still possible.

As a second line of defense, we have team ceremonies to discuss and validate larger architectural changes as well as a review day where we validate that everything is still on track.

### Impact

Once again, Elixir turns out to be the right technology choice. It's ["let it crash" philosophy](https://rafaelantunes.com.br/understanding-the-let-it-crash-philosophy) and the tools provided by the standard library to support it mean it's easier to build long running applications that are fault tolerant and heal automatically.

### Independence

Since our modules are self-contained, changes to shared functionality is the only thing that must be coordinated. These happen less and less frequently as the system matures. Through the aforementioned ceremonies, we make this communication overhead predictable.

Workflows are still allowed some amount of independence as long as the changes produced by them are contained to singular modules.

## Closing thoughts

This approach has allowed us the flexibility we need while keeping complexity as low as appropriate for the small team we are. It has also had direct positive impact on our day to day work, for example by allowing us to run the entire system on our development machines without locally replicating large parts of the cluster when testing interactions between multiple services.

We have put the focus on not repeating the mistakes of the past, choosing established technologies which are right for the job at hand. We do all this in service of the guiding principle we subscribe to as a team: "The whole backend. Delightfully boring."
