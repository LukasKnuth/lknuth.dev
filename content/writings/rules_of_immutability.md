---
title: "Rules of Immutability"
date: 2012-07-17T22:00:00+01:00
---

In a perfect world, every *value container* (an object that only holds multiple fields of data and defines methods for access) is immutable. Immutability should always be a design-goal, especially, when creating a library or API.

In this article, I'm going to explain what immutable objects are, why they are cool and what stumbling blocks you should watch out for.

<!--more-->

> [!note]
> Although the idea of immutability is applicable to most programming languages, specifics vary greatly.
> More functional languages usually enforce immutability at the language level while imperative languages allow you to opt-in as needed.
> 
> The following article is focused on **Java 7**, but the ideas discussed are transferable to other languages.

## What makes an object "immutable"?

[Wikipedia](http://en.wikipedia.org/wiki/Immutable_object) boils it down to one simple sentence:

> In object-oriented and functional programming, an immutable object is **an object whose state cannot be modified
> after it is created.**

Let's look at an example:

```java
public final class GeoTag {

    private final int latitude;
    private final int longitude;
    private final Date timestamp;
    private final String message;

    public GeoTag(int latitude, int longitude, Date timestamp, String message) {
        this.latitude = latitude;
        this.longitude = longitude;
        this.timestamp = timestamp;
        this.message = message;
    }

    public int getLatitude() {
        return latitude;
    }

    public int getLongitude() {
        return longitude;
    }

    public Date getTimestamp() {
        return timestamp;
    }

    public String getMessage() {
        return message;
    }
}
```

This is a class which encapsulates multiple values into one single object. It provides geographical information for a message, including latitude and longitude, the date of creation and the message itself.

An instance of this class can only be created by using it's constructor (which initializes and populates all fields with the given values). After the instance is created, there is no way to change any of those values, since no *setter*-methods are available.

By doing so, we can assure that this object can not be manipulated after it's creation. But what are the benefits of doing so?

### Why immutability is cool

As pointed out above, the object can not be manipulated or changed in any way after it was created. This ensures the *consistency* of the instance across the whole application.

You can access an immutable objects on multiple threads simultaneously, without the fear of any concurrent modification by another thread. Immutable objects are always synchronized. No extra work is needed.

This makes passing objects around multiple threads or across multiple application-modules simple. It's the easiest approach to thread-safety.

Also, immutable objects make for the perfect `Map`-keys, because you don't have to worry about their values (and therefor the key) changing, which would destroy the Maps invariants.

## Designing immutable objects

In this section, I'm going to give some design-advices and show some possible weak-spots.

### Finalize to freeze the state

Let's take a closer look. Notice how all the fields are declared to be `private final`? A field declared `final` can't be assigned outside of the constructor.

This secures any primitive value-type as much as possible. Since the primitive types don't offer any methods to mutate their state, they are now immutable.

### Prevent extensibility

We also declared the class itself to be `final`. *Finalized* classes can't be extended, which freezes their internals from being manipulated. For example, an "attacker" could create a subclass of our `GeoTag`-class and make it mutable:

```java
public class GeoTagMutable extends GeoTag {

    private int mLatitude;
    private int mLongitude;

    public GeoTagMutable(int latitude, int longitude, Date timestamp, String message) {
        super(latitude, longitude, timestamp, message);
        this.mLatitude = latitude;
        this.mLongitude = longitude;
    }

    /**
        * Copy-constructor to make an <i>immutable</i> instance <i>mutable</i>.
        */
    public GeoTagMutable(GeoTag immutable_tag){
        super(immutable_tag.getLatitude(), immutable_tag.getLongitude(),
                immutable_tag.getTimestamp(), immutable_tag.getMessage()
        );
        this.mLatitude = immutable_tag.getLatitude();
        this.mLongitude = immutable_tag.getLongitude();
    }

    @Override
    public int getLatitude() {
        return mLatitude;
    }

    @Override
    public int getLongitude() {
        return mLongitude;
    }

    public void setLatitude(int latitude) {
        this.mLatitude = latitude;
    }

    public void setLongitude(int longitude) {
        this.mLongitude = longitude;
    }
}
```

The extending `GeoTagMutable`-class uses it's own, non-final fields for latitude and longitude. It overrides the `getLatitude()` and `getLongitude()`-methods to return it's own fields and offers two setter methods for them, too. Using the new class, we can now create new, *mutable* `GeoTag` objects and, we can change an existing, *immutable* object, to a *mutable* one:

```java
GeoTag tag = new GeoTag(12, 14, new Date(), "Some message!");
GeoTagMutable mutableTag = new GeoTagMutable(tag);
mutableTag.setLatitude(41);
System.out.println(tag.getLatitude()+" > "+mutableTag.getLatitude());
```

To prevent this kind of "attack", we declare the class to be `final`.

### Mutable components in immutable objects

But the `GeoTag`-class is **not perfect**. It is possible to mutate the `timestamp`-field. See the following example "attack":

```java
Calendar calendar = Calendar.getInstance();
calendar.set(1999, 12, 24);
GeoTag tag = new GeoTag(12, 14, calendar.getTime(), "Some message!");
tag.getTimestamp().setDate(30);
tag.getTimestamp().setMonth(10);
System.out.println("GeoTag taken on: "+tag.getTimestamp().toLocaleString());
```

This gives us the following output:

> GeoTag taken on: 30.10.1999 00:00:00

Congratulations. You just traveled back in time from christmas to halloween. But for our goal of immutability, not that cool. The problem here is not our object (which is quite immutable), but the `Date`-object, which is not immutable.

To overcome this problem, we'll need to make *defensive copies* of our "timestamp".

## Making *defensive copies*

As shown above, a mutable object can be changed, due to the fact that Java passes around object-*references* to method-calls (more on the "pass-by-reference" and "pass-by-value" stuff can be found [here](http://stackoverflow.com/q/40480/717341)).

To overcome this, the `getTimestamp()`-method will now be implemented to use defensive copies. This is as easy as doing the following:

```java
public Date getTimestamp() {
    return new Date(timestamp.getTime());
}
```

What happens here? Instead of giving out a reference to our internal `Date`-object, we create a new Date-instance (with the same time as our internal one) and return it. This will preserve the original date, but protect us from the above explained "attack". Run the code again and see for yourself:

> GeoTag taken on: 24.12.1999 00:00:00

The timestamp is unchanged, because we didn't give out our internal reference. So, now our `GeoTag`-class is save, right? Wrong!

Here is the new "attack", suffering from the same problem:

```java
Calendar calendar = Calendar.getInstance();
calendar.set(1999, 12, 24);
Date time = calendar.getTime();
GeoTag tag = new GeoTag(12, 14, time, "Some message!");
time.setDate(30);
time.setMonth(10);
System.out.println("GeoTag taken on: "+tag.getTimestamp().toLocaleString());
```

And once again, the output is:

> GeoTag taken on: 30.10.1999 00:00:00

Our `getTimestamp()`-method might be secure now, but the `Date`-instance, given to our constructor, can still be manipulated (since we're storing a reference to it). To prevent this attack, we'll need to make a defensive copy in our constructor, too:

```java
public GeoTag(int latitude, int longitude, Date timestamp, String message) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.timestamp = new Date(timestamp.getTime()); // Defensive copy
    this.message = message;
}
```

Now, the first and the second attack show no effects. Our class is now truly *immutable*.

A quick word on performance: Yes, making defensive copies (which might happen quite often) can result in many object-creations and therefor much GC-activity. In general however, the correctness of your program should outweigh any perceived performance problems. Always measure the performance impact before concerning yourself with possible performance issues prematurely!

### Don't use `clone()` for defensive copies!

There is yet another possible "attack", which can be used to manipulate the timestamp, before it is stored in the field. This "attack" uses the `clone()`-method of `Date`, which gets overloaded to manipulate the freshly cloned object:

```java
public class DateCloneAttack extends Date implements Cloneable{

    public DateCloneAttack(Date date){
        super(date.getTime());
    }

    /**
        * This method clones a {@code Date} and manipulates it.
        */
    @Override
    public Date clone(){
        Date result = (Date) super.clone();
        result.setDate(30);
        result.setMonth(10);
        return result;
    }
}
```

To make the attack work (and show why you shouldn't use clone for defensive copies), let's change the constructor to use the `clone()`-method of what seems to be a `Date`-object:

```java
// Bad practice example. DON'T DO THIS!
public GeoTag(int latitude, int longitude, Date timestamp, String message) {
    this.latitude = latitude;
    this.longitude = longitude;
    this.timestamp = (Date) timestamp.clone();
    this.message = message;
}
```

Now, it's possible to change the `Date`-object, which is passed to the constructor, after it is passed:

```java
Calendar calendar = Calendar.getInstance();
calendar.set(1999, 12, 24);
DateCloneAttack attack = new DateCloneAttack(calendar.getTime());
GeoTag tag = new GeoTag(12, 14, attack, "Some message!");
System.out.println("GeoTag taken on: "+tag.getTimestamp().toLocaleString());
```

This will print out:

> GeoTag taken on: 30.10.1999 00:00:00

The lesson here is, that you can't trust the user. If the `Date`-class would have been *finalized*, creating a manipulated `clone()`-method would have been impossible.

In an actual, real-live example, this attack could smuggle an invalid object around the validity tests and modify it afterwards, leaving the new object in an invalid state. Therefore, check for validity *after* cloning or recreating your mutable parameters (on the defensive copies).

Although you might use a mix of both: In the constructor, recreate the object using it's constructor. When giving the object out (in it's getter-method), you can use `clone()`, because you already have a validated copy of it. But, since cloning objects does not necessarily result in any kind of performance-increase, but rather makes your code more error prone, **you should not use `clone()` if possible**.

### Strings are immutable

You might wonder why we need to make a defensive copy of the `Date`, but not the `String`-object. This is, because `String` itself is immutable. Quoting from it's [JavaDoc](http://docs.oracle.com/javase/6/docs/api/java/lang/String.html):

> Strings are constant; their values cannot be changed after they are created. String buffers support mutable strings.
> Because **String objects are immutable** they can be shared [...]

A more detailed explanation might be found on the linked documentation page.

## Changing a `GeoTag`

An object that can't be modified is pretty boring. What if you _do_ have legit reasons to change certain fields, for example if you want to make the message editable?

Let's write a setter method for message that **still leaves the object immutable**:

```java
public GeoTag setMessage(String newMessage) {
  return new GeoTag(getLatitude(), getLongitude(), getTimestamp(), newMessage);
}
```

The setter **does not modify the object** but instead returns a new object with the modified message. This means that references to the original `GeoTag` are still valid (and will still show the old message), but now there is a new object with the same latitude/longitude/timestamp and a new message.

Of course this means that any code that is currently working with the old object will not see this change. But remember that this is exactly what we wanted, specifically in a multi-threaded context. In practice, this is rarely a problem because changes to an object require that operations be re-run with the new object anyways. For example, if our `GeoTag` was being persisted to a database, changing the message would require persisting the change to the database again anyways.

## Conclusion

Make your _value containers_ immutable. It makes writing _correct_ software much easier.

Here are the five simple rules to create an immutable object in Java, taken from "Effective Java - Second Edition", Chapter 4, Item 15:

> 1. Don't provide any methods that modify the object's state.
> 2. Ensure that the class can't be extended.
> 3. Make all fields final.
> 4. Make all fields private.
> 5. Ensure exclusive access to any mutable components (defensive copies)

As a sixth rule: **Document immutability**. If you designed a component to be immutable, document so in the JavaDoc of this class.
