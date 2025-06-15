---
title: "Saying more than nothing"
date: 2012-07-23T22:00:00+01:00
---

As I was reading around on StackOverflow, digging through other peoples source code, I spotted multiple methods returning `null` in a variety of circumstances. I also found rather imaginative ways to handle null-values.

Although there is nothing wrong with `null`, the concept of null-pointers seems to be somewhat misunderstood. Let's change that.

<!--note-->

## What are null-pointers?

[Wikipedia](http://en.wikipedia.org/wiki/Null_pointer#Null_pointer) has the following to say:

> A null pointer has a value reserved for indicating that **the pointer does not refer to a valid object.**

In Java, there are two types of variables: *value-types* and *reference-types*. The first group includes the primitive data-types like `int`, `float`, `char` and `byte`. The second contains objects.

Since only reference-types can be `null` (a reference to *nothing*), it's not possible to set a value-type to `null`. **Side-Note**: In Java, you can set a *value-type* to `null`, by using the appropriate boxing-type (e.g. `Integer`, which is a *reference-type*) and setting it to `null`.

When invoking a method or accessing a field on an object with a `null` reference, a [`NullPointerException`](http://docs.oracle.com/javase/6/docs/api/java/lang/NullPointerException.html) will be thrown.

## When to use null

A value of `null` should only be used when effectively saying *nothing*. For example, it might be important that there is a difference between an empty message (string `""`), and no message *at all* (as in the [`BufferedReader.readLine()`-method](http://docs.oracle.com/javase/6/docs/api/java/io/BufferedReader.html#readLine%28%29)).

A more practical example is given in "C# in Depth" by Jon Skeet, Chapter 4, "Saying nothing with nullable types":

> [...] an example might be an e-commerce application where users are looking at their account history. If an order has
> been placed but not delivered, there may be a purchase date but no dispatch date [...]

In those cases, where there is just *nothing* to say about the value, you should use `null`.

## The dangers of null

Let's take a look at some common anti-patterns where `null` is used inappropriately.

### Never use null to indicate an error

Quite often, developers tend to return `null` when something went wrong in the method. Here is a classic example:

```java
// Anti-pattern. DON'T DO THIS!
public Foo readFoo(File file){
    try {
        // Try reading the contents from the given file
        return actualReadData;
    } catch (IOException e){
        e.printStackTrace();
        return null;
    }
}
```

This code will (given that the reading part is actually implemented) read the contents from the passed `file`-argument, create a new `Foo`-object and return it. If however the method fails to read the contents from the file, it will return `null`.

This pattern is problematic, as it has to be explicitly documented under which circumstances the method returns `null`. Otherwise, it's unclear what the returned `null` actually means. Does it mean the file is empty? Does the file not exist? Was the content not parseable?

Additionally, it might be possible to recover from certain failure cases, but you can't differentiate between them when they all just return `null` (which only tells you that *something* went wrong). Last but not least, returning `null` does not force any handling of the error-condition. All those drawbacks can be overcome by [throwing an exception]({{< relref "catching_practice.md#throwing-the-ball" >}}) instead.

### Yoda Conditions

As cool as the name sounds, ["Yoda Conditions"](http://www.codinghorror.com/blog/2012/07/new-programming-jargon.html) are a danger because they completely defeat the purpose of making a value `null`. Here is an example:

```java
String possiblyNull = possiblyReturnsNull();
if ("constant".equals(possiblyNull)){
    // it equals!
} else {
    // it doesn't.
}
```

Let's assume that `possiblyReturnsNull()` does not return `null` to indicate an error but actually, to return *nothing*. Using the "Yoda Condition" avoids a possible `NullPointerException`. But this also indicates that: "null is the same as everything which is not `constant`".

Since there's probably a reason why `possiblyReturnsNull()` returns `null` instead of an actual value, you should test for this specifically. If it doesn't make a difference if the value is `null` or anything which is not "constant", the decision to return `null` in this case was probably a design-error.

### Never return null for arrays/collections

Let's say you have a function which returns all Unicorn-toys still in stock:

```java
// Anti-pattern. DON'T DO THIS!
public List<Unicorns> getUnicorns(){
    if (unicornList.size() == 0){
        return null;
    }
    // ...
}
```

This case is special because we want to say that there are currently *no unicorns* in stock. So why is this bad?

Consider a world in which the hypothetical shop *usually* always has Unicorn-toys in stock. When the calling code does not explicitly check for a `null` return value, it might run as expected for years. Until somebody buys up the entire stock and now the shop is crashing.

So in this case, nothing *is* the same as empty. Therefor, you can (and should) return an *empty* array/collection, instead of `null`:

```java
// Return empty arrays/collections instead of null
public List<Unicorns> getUnicorns(){
    if (unicornList.size() == 0){
        return Collections.emptyList();
    }
    // ...
}
```

This enables the caller of the method to simply iterate over the returned list, without needing to fear a `NullPointerException`.

You don't even need to instantiate a new collection, as the `Collections`-class provides the methods `emptySet()`, `emptyList()` and `emptyMap()` to return an empty, [immutable]({{< relref "rules_of_immutability" >}}) collection for the given type of collection.

## Conclusion

To sum it all up:

* Use `null` when the value is *nothing*
* Don't return `null` to indicate an error!
* Check for `null`, if it indicates a different result then "not what you're looking for"
* Don't return `null` for empty arrays/collections
