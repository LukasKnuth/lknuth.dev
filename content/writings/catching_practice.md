---
title: "Catching Practice"
date: 2012-07-06T20:40:00+01:00
---

I recently answered a question on StackOverflow, asking if catching an `Error` would be reasonable in a particular case. The original question and my answer can be found [here](http://stackoverflow.com/q/11017304/717341), however I felt that my answer could be extended with a more general discussion of the implications and additional examples.

<!--more-->

## Clarification: Throwable, Error, Exception

In Java, errors and exceptions (which are the main types) are thrown using the `throw`-keyword. Every class which extends the basic `java.lang.Throwable` can be thrown.

In the Standard Library, there are two classes which inherit from the basic `Throwable`-class: `Exception` and `Error`. Their semantics are explained in the respective documentation:

**[Error](http://docs.oracle.com/javase/6/docs/api/java/lang/Error.html)**

> An `Error` is a subclass of `Throwable` that **indicates serious problems that a reasonable application *should not* try to catch.**
> Most such errors are abnormal conditions. [...]

**[Exception](http://docs.oracle.com/javase/6/docs/api/java/lang/Exception.html)**

> The class `Exception` and its subclasses are a form of `Throwable` that **indicates conditions that a reasonable application
> *might* want to catch.**

So, it appears, that it's generally a bad idea to catch an `Error` on purpose.

## Why do we distinguish?

Additionally, exceptions are further divided into "checked exceptions" (which inherit from the basic `java.lang.Exception`-class) and "runtime exceptions" (which inherit from `java.lang.RuntimeException`).

The difference being that when a "checked exception" is thrown, it must be handled (by a "try/catch"-block), whereas a "runtime exception" *should not* be handled at all.

The reason why there are multiple different types of `Throwable` is, because they all have different origins:

* An `Error` represents a critical low-level problem (probably with the VM) which an application is *most likely* not able to recover from.
* A "checked exception" indicates a high-level problem, which the application is *likely* to recover from.
* A "runtime exception" indicates a programming error, which the application *should not* recover from.

The keyword here really is _recover_.

## Can we recover?

The question to ask when catching any kind of `Throwable` is always the following: **Can my application recover from it?** If the application *can* recover, it should catch. If it *can't* (or is most likely unable to) recover, it shouldn't.

From the (excellent) "[Effective Java - Second Edition](http://www.amazon.com/Effective-Java-Edition-Joshua-Bloch/dp/0321356683)" by Joshua Bloch, Chapter 9, Item 58:

> If a program throws an unchecked exception or an error, it is generally the case that recovery is impossible and
> continued execution would do more harm than good.

Now, the task is to determine whether we can recover or not. The type of `Throwable` gives us a hint, but it's really depending on the actual situation.

## Examples

### Error

This example is from the original question linked above:

> [...] I'm currently loading a DLL that is not guaranteed to be on the PATH, and would like to switch to a
> user-configured location in the case that it isn't.

The code is given as follows:

```java
try {
    System.loadLibrary("HelloWorld");
} catch(UnsatisfiedLinkError ule){
    System.load("C:/libraries/HelloWorld.dll");
}
```

Quoting from the `java.lang.System`-[JavaDoc](http://docs.oracle.com/javase/6/docs/api/java/lang/System.html#loadLibrary%28java.lang.String%29), the `UnsatisfiedLinkError` is thrown...

> Throws: UnsatisfiedLinkError - if the library does not exist.

So, **can we recover?** The application tries to load the library from the `PATH`. If this does not succeed, there is a fallback location to look for the library. Hence, the application is able to recover from the error-condition.

So, in this example, it's perfectly reasonable to catch the `Error`. Whether or not the library is guaranteed to be at the fallback location is outside the scope of this example!

### RuntimeException

Imagine you're trying to parse a CSV-file containing integers. Reading the file line by line using a `BufferedReader`, we get a string per line. If you want integers, you need to parse.

Unfortunately, it's not guaranteed that what you expect to be an integer in the CSV file is actually even a number. One possibility is, that the value is empty, in which case you want to use a default value instead:

```java
try {
    last_int = Integer.parseInt(foo); // Where foo is a string-value from the CSV
} catch (NumberFormatException e){
    last_int = 1; // As our default value
}
```

From the [JavaDoc](http://docs.oracle.com/javase/6/docs/api/java/lang/Integer.html#parseInt%28java.lang.String%29) of `java.lang.Integer#parseInt(String)`:

> Throws: NumberFormatException - if the string does not contain a parsable integer.

And, believe it or not, an empty string is not a parsable integer:

    Exception in thread "main" java.lang.NumberFormatException: For input string: ""
        at java.lang.NumberFormatException.forInputString(Unknown Source)
        at java.lang.Integer.parseInt(Unknown Source)

So again, we're catching an exception which we are (by convention) not supposed to. In this case again, we're able to recover from it and can continue the execution without problems.

One could now argue that it might be a design-error to make the `NumberFormatException`-class a runtime exception, but as mentioned above, runtime exceptions indicate *programming errors*. And since it *is* possible to know if a string is a real integer *before* parsing it, it can be considered a programming error to not check first. For further reading, check [this SO question](http://stackoverflow.com/a/7205689/717341).

Additionally, using checked exceptions extensively tends to clutter calling code with `try/catch` blocks or add ridiculous amounts of `throws` declarations on methods. Check the ["design advices"](#design-advices) below for further reading.

### Exception

If an application is likely to *not* recover from a thrown, <u>checked</u>, `Exception`, then making it a checked exception was a design-error in the first place.

None the less, such cases need to be handled, since the compiler wont let you compile the program without catching this exception. 

Since we've already established that we aren't able to recover from the `Exception` and should really stop the program, let's do so using a `RuntimeException` but give all available information by specifying the original exception as the cause:

```java
try {
    ifThisDoesntWorkWereScrewed();
} catch (UnrecoverableCheckedException e) {
    throw RuntimeException("Can't recover from this!", e);
}
```

This way the previously checked exception now behaves as it should, while no information is lost because it's stack-trace is included in the newly created `RuntimeException`. **Note** that this is a workaround and should ideally never be necessary!

## Design advices

To round everything up, some advices if you're writing an API or library yourself.

### Making the ball

As a general advice when creating a library/API: **Favor the use of standard exceptions**. Again, quoting from "Effective Java - Second Edition", Chapter 9, Item 60:

> Reusing preexisting exceptions has several benefits. Chief among these, **it makes your API easier to learn and use
> because it matches established conventions** with which programmers are already familiar. A close second is
> that programs using your API are **easier to read because they aren't cluttered with unfamiliar exceptions**.
> [...]

But, aside from this, there are cases when you need to create your own exceptions because you want to express something more specific, or there is just no standard exception which meets your needs.

In these cases, do so, but **never extend `Throwable` directly!** It's not that the compiler wont let you (it will work like a "checked exception", just like the `Exception`-class), the Java Language Specs do not address such throwables directly. So, you're going into _undefined behavior_, which should always be avoided.

Instead, extend specific subclasses of `Exception` or `RuntimeException` (to get a new "checked-" or "unchecked-exception" respectively). It's by convention not wrong to make your new `CSVParsingException` extend the basic `Exception`-class, but extending the more specific `ParseException` (which is a subclass of `Exception` - therefor a checked exception) makes for a cleaner picture.

Of course if you can't find any "more specific" subclasses, you'll need to extend the basic `Exception`- or `RuntimeException`-classes.

Also, be sure to **add a constructor which takes a `Throwable cause`-parameter** to preserve information from the originally thrown Exception when re-throwing (see further down). The basic `Exception`-class offers [such a constructor](http://docs.oracle.com/javase/6/docs/api/java/lang/Exception.html#Exception%28java.lang.String,%20java.lang.Throwable%29) which you can simply overwrite.

A word on extending `Error`: <u>Don't do it.</u> As mentioned above, errors are (by convention) reserved for low-level problems (with the VM). Instead, use a `RuntimeException`.

### Throwing the ball

*Think twice before you throw.* Checked exceptions are a powerful language-feature, because other than return types, you can force the developer to handle them. This can be nice but can also make the resulting code very bloated, as every thrown exception needs to be handled in it's own `catch`-block (yes, there is a Java 7 feature for that...).

So, thinking about whether to throw a checked or unchecked exception can make your API/library more pleasant to use. As a rule of thumb consider the following:

> The burden [of handling a checked exception] is justified **if the exceptional condition cannot be prevented by
> proper use of the API *and* the programmer using the API can take some useful action once confronted with the
> exception**. Unless both of these conditions hold, an unchecked exception is more appropriate.
>
> *From "Effective Java - Second Edition", Chapter 9, Item 59*

Just like in the above "Making the ball" section, a short word on throwing `Error`: <u>Don't do it.</u> Since we already clarified that errors are reserved for low-level problems, there should be no need to throw them yourself.

### Catching the ball

Exceptions tend to be ignored. For unchecked exceptions and errors, this might be desired (in most cases, see above), but it completely defeats the purpose of throwing a checked exception. I have seen this in various places (even in the [Java Docs](http://docs.oracle.com/javase/6/docs/api/javax/swing/SwingWorker.html)):

```java
// Bad practice example. DON'T DO THIS!
try {
    somethingThatThrows();
} catch (SomeException ignored){
    // Can't happen...
}
```

... until the day it does. Also bad:

```java
// Bad practice example. DON'T DO THIS!
try {
    somethingThatTrows();
} catch (SpecificException e){
    throw new OtherException("Doesn't work");
}
```

While this example *will* throw an exception, it **totally discards any (useful) information from the previously thrown `SpecificException`**. It's not generally wrong to re-throw an exception, but you should either print the stack-trace of the original one, or (even better) include it as the cause in the new Exception. Every exception from the standard API has a constructor which accepts a `Throwable cause` as an argument (and your custom ones should, too). Use it!

```java
throw new OtherException("Doesn't work", e);
```

And now, the worst possible approach:

```java
// Bad practice example. DON'T DO THIS!
try {
    somethingThatThrows();
    somethingElseThatThrows();
} catch (Exception ignore) {
    // Ignored.
}
```

The last example (sometimes referred to as "[Pokemon Exception Handling](http://stackoverflow.com/a/2308988/717341)") is generally **discarding *all* possibly thrown exceptions** (including the unchecked ones). If something goes wrong in this piece of code, your program wont crash but it wont behave as expected either. And you won't get any information about it.

Exceptions are not your enemies. They are a helping hand from the runtime. So don't abandon them. If there is really nothing you can (or want) to do about an exception, **at least** print the stack-trace (when in developing stage) or log them anywhere (when in productive state). Otherwise, some fine day, you might suffer from the revenge of the forgotten ones.

#### Catching generally

Last but not least, an advice on catching more general errors: <u>Do it with extreme caution</u>

Third party code in your application (such as libraries or even the standard library) might change with a new version of the library. A general catching block could swallow a newly added exception and suddenly your applications code (which wasn't even touched) stops working as expected.

The only thing you should do in generalized `catch`-blocks is logging. For example, the following is perfectly reasonable:

```java
try {
    somethingThatThrows();
} catch (SpecificException e){
    // Handle the specific exception here
} catch (OtherSpecificException e){
    // Handle the other specific exception here
} catch (GeneralException e){
    e.printStackTrace();
    logger.error(e);
}
```

The important part is, that the more specific exceptions need to be caught before the more general one. And when doing so, `GeneralException` should be as specific as you can make it.

#### Returning from finally

As you are handling exceptions in your code, you should remember to **never return in a `finally`-block!**. This can become a serious problem, as outlined in [James Stauffer's article](http://weblogs.java.net/blog/staufferjames/archive/2007/06/_dont_return_in.html):

> If you return in a finally block then **any `Throwables` that aren't caught (in a catch block that is part of the
> same try statement as the `finally` block) will be completely lost**. The really bad part about this is that it
> looks so innocent. <br> [...] <br>
> Note **this also applies to other things that transfer control** (continue, throw, etc).

So keep an eye out for that.

## Conclusion

* If you can recover from an exception/error, don't hesitate to catch it.
* Prefer the default exceptions over creating your own.
* When creating your own exceptions, don't extend `Throwable` *directly* and don't extend `Error`.
* Many checked exceptions make the calling code bloated.
* Never ignore or discard exceptions without **at least** logging them.
* Never return from within a `finally`-block.
