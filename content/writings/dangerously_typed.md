---
title: "Dangerously Typed"
date: 2017-01-07T16:05:00+01:00
description: Why you should be careful when extending build-in types in TypeScript
---

At work, I'm currently building an new Node.js Application. I opted to use Node, because the application is highly parallel and while I could have build it in Java, Node already does all the hard things that come with building multi-threaded Applications.

For my language of choice, I looked to [TypeScript](https://www.typescriptlang.org/), because it adds some compile-time type-safety to JavaScript. For the most part, TypeScript has been helping me to write clean code that I can trust when the compiler gives it's "all clear". But recently, while hunting an unrelated bug, I stumbled upon something dangerous.

## Minimal working example

Read the following lines of code and tell me, what they print:

```typescript
class MyError extends Error {};
try {
    throw new MyError("This is a test");
} catch (e) {
    if (e instanceof MyError){
        console.log("yay!");
    } else {
        console.log("nay!");
    }
}
```

It must print "yay!", right? Surely it does. Let's try it:

    $ tsc --version
    Version 2.1.4
    $ node --version
    v6.9.4

    $ tsc test-error1.ts
    $ node test-error1.js
    nay!

Say what now? What is going on here? We created a custom error-class by extending the build-in type `Error`, which is also the base-class for all build-in errors that are more specific, like `URIError` or `TypeError`. Then, we created an instance of our class and threw it using the `throw`-keyword.

But why does it not print "yay!", as one would expect? When we use the Nodejs debugger to inspect the type of `e` at runtime, we get this:

    $ node debug test-error1.js
    < Debugger listening on [::]:5858
    connecting to 127.0.0.1:5858 ... ok
    break in test-error1.js:18
     17 catch (e) {
    >18     debugger;
     19     if (e instanceof MyError) {

    debug> repl
    > e instanceof MyError
    false
    > e instanceof Error
    true

Okay. So at runtime, `e` is not an instance of our own `MyError`-class, but the base-class `Error`! That doesn't seem right, what is happening here?

## Explanation

As it turns out after some googleing, this is actually a [documented breaking change with TypeScript 2.1](https://github.com/Microsoft/TypeScript/wiki/Breaking-Changes#extending-built-ins-like-error-array-and-map-may-no-longer-work). Here are the relevant parts:

> [...], **subclassing Error, Array, and others may no longer work as expected**. This is due to the fact that constructor functions for Error, Array, and the like use **ECMAScript 6's [new.target](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Operators/new.target) to adjust the prototype chain; however, there is no way to ensure a value for new.target when invoking a constructor in ECMAScript 5**. Other downlevel compilers generally have the same limitation by default.
>
> [...]
>
> you may find that:
>
> * methods may be `undefined` on objects returned by constructing these subclasses, [...]
> * **`instanceof` will be broken between instances of the subclass and their instances**, so `(new FooError()) instanceof FooError` will return `false`.

This matches our observation. How this doesn't generate at least a compiler-warning is beyond me. But how do we fix it?

## Workaround

The proposed fix given in the breaking changes document is to manually set the prototype of every instance, either by using `Object.setPrototype()` or the objects `__proto__`-property. This seems very hacky to me and like something you will probably forget in that one class you wrote at Friday at 5 o'clock and then you find yourself debugging all Monday morning. Also, this won't work in IE 10 or older, so if you need your code to run in the Browser, you have to do extra work.

Another option is to just *not* extend `Error`. JavaScript (as opposed to Java) is perfectly happy to throw any kind of object (or string, or number) around:

```typescript
class MyError {
    constructor(readonly message: string){}
};

try {
    throw new MyError("This is a test");
} catch (e) {
    if (e instanceof MyError){
        console.log("yay!");
    } else {
        console.log("nay!");
    }
}
```

This does print "yay!", as expected. The drawback is, that the `MyError`-type doesn't have the `stack`-property that gives you the StackTrace. You can [build it yourself](http://stackoverflow.com/a/635852/717341), but that seems tedious.

The third option (and the one I went with) is to change the target of the TypeScript compiler to ECMAScript 6, which has classes and inheritance build-in. This way, the code from the original example just works:

    $ tsc --target es6 test-error1.ts
    $ node test-error1.js
    yay!

Since I run the code on Node exclusively, I can use the transpiled ES6 code just fine (as long as I don't use any [unsupported features](http://node.green/)). If you want to use this in a browser, you can run it through [Babel](https://babeljs.io/) to get compatible JavaScript. However, this adds another step to your build-process.

## Conclusion

While inheritance in TypeScript works just fine, you have to be careful when extending any of the build-in types. Also, TypeScript doesn't go out of it's way to tell you about the potential danger of doing it anyways, so be vigilant!

* **Don't extend build-in types**
* If you must, be sure to **manually set the prototype** of every new instance.
* If you don't want to think about any of this, target ECMAScript 6 with TypeScript (and transpile it, if you can't use it directly).