---
title: "AI Products"
date: 2025-07-07T14:03:58+02:00
---

Based on what XCompany explained of how their new AI generated training plans work

> The old plans where created in a specificalyl programmed way
> They gave too many content units considered "old"
> They where not "good" (not qualified)

The new setup they have is:

1. Filter all eligable content from their database
2. Upload the JSON dump to Gemini model
3. Ask it (with the user-formed prompt) to generate a plan
4. Wait up to 3min
5. Plan.

## Problems

The are happy with the new plans but have not "measured" that they're better.
They can not point to any specific indication that makes them "better".
Perhaps the same could have been achieved by adding `random` to the suggestions?

It takes forever and god knows how much energy to build something that a well engineered series of queries could do.
This has nothing to do with engineering anymore.
We're just throwing shit at the cristal ball in the skye, hoping the results are good.

One of their ideas is that AI can already filter things based on user queries.
For example "I can't use my knee due to injury".
They have however nothing definite in place to prevent the AI from suggesting knee-intesive content either.
This isn't really safe to use for users.

They don't _own_ the propriatrary function that generates their plans.
Microsoft does.
They can't fine tune this meaningfully either (other then playing with the prompt).
What if weights change or the new version of the model decides for different things?
There is no real recourse to correct or go back when that happens.
You have given your USP to an external company.

## "Looks good"

The upside of building things like this is that you don't have to understand your problem fully anymore.
To build an algorithm, you do.
With this you can just throw it at the LLM and hope that it gives good looking results.

You can not really verify that the AI will always give you good results.
Perhaps in the product you can add a feedback mechanism where users can say "this was good" or "this was bad".
The results are good enough but they would probably _always_ be good enough.
Its wishy washy that embraces the idea of "just ship it".
The corner cases (like users with disabilities) only apply to low percentage, so they're not super important.

We can finally build algorithms that are not strict but fuzzy.
While this is probably good enough for someone knowledgable to use as a template, is it good enough to _sell_ to people?
It creates things that pass the face check.

## The tyranny of Product

It is the product teams ultimate dream of building this because it aligns so well with all the other methodology that they have established already.
Its the “fake it till you make it”, “good enough”, “ship early”, “users are testers”, “bananensoftware”, "jesus take the wheel" approach to building algorithms. 

It falls in line with so many other decisions we make in the "product" space that aren't compatible with "engineering".
In no other engineering profession can you get away with "lets just put the MVP bridge up now, we can fix it if it breaks."

If you have ever flagged a security issue and been asked "how many users are even affected", you know the idea.
The product is allowed to be broken on the edges as long as the main road is shiny.
Its even encouraged to be broken at the edges, in order to build it up faster.

Engineers in our profession do not fear the consequences of their actions.
Most of them aren't even sensitised to the fact that there could be consequences.
This carefree attitude works very well with AI tooling.
