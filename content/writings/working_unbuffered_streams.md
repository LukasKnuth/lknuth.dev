---
title: "Working unbuffered Streams"
date: 2012-10-15T15:54:32+01:00
---

When working with I/O in Java, you can normally choose from a variety of `Stream` and `Reader` or `Writer` classes to handle all the "dirty" work for you. But what happens under the hood? And why is this stuff so error-prone?

<!--more-->

## Being the buffer

When reading/writing binary data, for example from a `Socket` or a file, you should use a [`BufferedOutputStream`](https://docs.oracle.com/javase/7/docs/api/java/io/BufferedOutputStream.html). But what if you couldn't?

Lets implement a simple binary copy ourselfs:

```java
// This code is intended to be incorrect. DON'T COPY THIS!
byte buffer[] = new byte[1024];
while (input.read(buffer, 0, buffer.length) != -1) {
    output.write(buffer, 0, buffer.length);
}
```

Can you spot the problem in the snippet? It's subtle. What makes it worse is that (under the correct conditions) the result _can_ be perfectly correct. Never the less, this code has a bug!

### The "full buffer" lie

The problem with the code above is on line 4, the one that reads `output.write(buffer, 0, buffer.length)`. The code assumes that the buffer is always completely filled, which is not necessarily the case! The [documentation for `InputStream.read(byte[], int, int)` states](http://docs.oracle.com/javase/6/docs/api/java/io/InputStream.html#read%28byte[],%20int,%20int%29):

> **Reads <u>up to</u> `len` bytes of data from the input stream** into an array of bytes. **An attempt is made to
> read as many as `len` bytes, but a smaller number may be read.** The number of bytes actually read is returned
> as an integer. [...]

So, the buffer is not guaranteed to be full. This becomes a problem when we use the `OutputStream.write(byte[], int, int)`-method to write the read bytes to the output stream. It's [documentation reads](http://docs.oracle.com/javase/6/docs/api/java/io/OutputStream.html#write%28byte[],%20int,%20int%29):

> **Writes [exactly] `len` bytes** from the specified byte array starting at offset `off` to this output stream. [...]

Here, it's the other way around. When we call the method with a `len`-parameter of our byte-array size (which is and will always be 1024 in this example), the method will write exactly 1024 bytes.

Now, if the `read()`-method only read 300 bytes into the buffer and we tell the `write()`-method to write exactly 1024 bytes, the remaining 724 bytes will be filled up with null-bytes. Even worse, if we previously read 700 bytes of data into the buffer and the next call to `read()` only overwrote the first 300 bytes, the remaining 400 bytes from the previous `read()`-call will be written out again (along with another 324 null-bytes). Either case will lead to corrupted output.

### Doing it right

So, how do we know how many bytes where read into the buffer? Quoting again from the [`InputStream.read(byte[], int, int)`-documentation](http://docs.oracle.com/javase/6/docs/api/java/io/InputStream.html#read%28byte[],%20int,%20int%29):

> [...] a smaller number may be read. **The number of bytes actually read is returned as an integer.**

In the above example, we already checked the return-value to see if we where at the end of the stream. Now, we'll store it and use it as the `len`-parameter for the `write()`-method:

```java
byte buffer[] = new byte[1024];
int read_count = 0;
while ((read_count = input.read(buffer, 0, buffer.length)) != -1) {
    output.write(buffer, 0, read_count); // Now writes the correct amount of bytes
}
```

This will write the exact amount of bytes read from the input-stream, into the output-stream.

## Conclusion

* Keep track of the amount of bytes read from your input-stream.
* Check to write the correct amount of bytes to your output-stream.
* Use the [`BufferedOutputStream`](https://docs.oracle.com/javase/7/docs/api/java/io/BufferedOutputStream.html) for binary data.
* Use existing [Reader](http://docs.oracle.com/javase/6/docs/api/java/io/Reader.html)/[Writer](http://docs.oracle.com/javase/6/docs/api/java/io/Writer.html) implementations when handling String data.
