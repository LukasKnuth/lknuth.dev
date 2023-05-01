---
title: "Generating Qrcodes With Zxing"
date: 2013-08-25T16:00:11+01:00
description: About how to use the ZXing library to generate QR-Codes on Android
---

When it comes to reading QR-codes, most Android applications use the [ZXing library](https://github.com/zxing/zxing). It's capabilities and ease of use when *reading* QR-Codes is already known, but ZXing can also *generate* QR-Codes.

Sadly, a lack of documentation makes it pretty hard to dive into this topic, so this article aims to provide a simple starting point.

## Integration choices

There are two ways to integrate ZXing in your application: by using Intents or as a library.

Using the Intent integration makes development easier, since it's less work. The downside to that is, that **the ["Barcode Scanner" application](https://play.google.com/store/apps/details?id=com.google.zxing.client.android) must be installed** on the device. The integration-module will automatically prompt the user to install the application, if it's not already installed, but still this involves manual interaction and might not be what you want.

The library integration is a little more complicated, but **does not require any third-party applications** to be installed on the device. It's also not really documented, so you'll have to do some digging around and source-reading if you want to do something custom.

We'll be focusing on the library integration in this article.

### Intent integration

When you decide to use Intents, all you have to do is add the `android-integration` module ([Maven repository](https://mvnrepository.com/artifact/com.google.zxing/android-integration)) to your Android project and use the `IntentIntegrator`-class:

```java
IntentIntegrator integrator = new IntentIntegrator(AnActivity.this);
integrator.shareText("http://codeisland.org");
```

And that's really all there is to it. The [`shareText(CharSequence)`-method](https://github.com/zxing/zxing/blob/c062955c841fd074bfaa42bafeb65b514d4c72fc/android-integration/src/main/java/com/google/zxing/integration/android/IntentIntegrator.java#LL462C8-L462C8) will **start an Activity of the "Barcode Scanner" application** to show the generated barcode. If the application could not be found, it will prompt the user to install it.

This is a very fast and simple way to integrate this in your application. But if you want to show the generated QR-Code in your own `ImageView`, you'll have to go with the...

### Library integration

If something more customizable is needed, choose the library integration. Next to the `android-integration` module from before, this time we'll also need the `core` module ([Maven repository](https://mvnrepository.com/artifact/com.google.zxing/android-core)). Both these go into androids `libs/`-directory (or you simply use Maven).

Encoding a String into a QR-Code is *almost* straightforward with the [`QRCodeWriter.encode(String, BarcodeFormat, int, int)`-method](https://github.com/zxing/zxing/blob/c062955c841fd074bfaa42bafeb65b514d4c72fc/core/src/main/java/com/google/zxing/Writer.java#L40):

```java
QRCodeWriter writer = new QRCodeWriter();
try {
    BitMatrix matrix = writer.encode(
        "http://lknuth.dev", BarcodeFormat.QR_CODE, 400, 400
    );
    // Now what??
} catch (WriterException e) {
    e.printStackTrace();
}
```

The data (in this example, the URL) is now encoded into a `BitMatrix`. But how do we get the matrix to show on-screen?

## How **not** to do it

It's [sometimes](https://groups.google.com/d/msg/zxing/-LjwQAykQ4M/KsONovYDBIUJ) [suggested](http://stackoverflow.com/q/10090797/717341) to simply use the `javase` module and it's [`MatrixToImageWriter`-class](https://github.com/zxing/zxing/blob/master/javase/src/main/java/com/google/zxing/client/j2se/MatrixToImageWriter.java). However, **this will not work on Android**, since it does not have the `BufferedImage`-class in it's Java implementation!

Executing the code will throw a `ClassNotFoundException` at runtime:

    ERROR/AndroidRuntime(xxx): java.lang.NoClassDefFoundError: javax.imageio.ImageIO

Using the `MatrixToImageWriter` to write the matrix to a file and decode it via `BitmapFactory` does **also not work**, since this method uses a `BufferedImage` and the `ImageIO`-class internally. Both of which are **not available in Android**.

## Generating an Android-Bitmap

The alternative to a `BufferedImage` on Android is to use a `Bitmap`, which is Androids "replacement" class. It offers almost the same methods as the `BufferedImage`, so migration of the `toBufferedImage()`-methods is pretty easy. The "Barcode Scanner" application uses a [similar approach](https://github.com/zxing/zxing/blob/c062955c841fd074bfaa42bafeb65b514d4c72fc/android/src/com/google/zxing/client/android/encode/QRCodeEncoder.java#L329):

```java
/**
* Writes the given Matrix on a new Bitmap object.
* @param matrix the matrix to write.
* @return the new {@link Bitmap}-object.
*/
public static Bitmap toBitmap(BitMatrix matrix){
    int height = matrix.getHeight();
    int width = matrix.getWidth();
    Bitmap bmp = Bitmap.createBitmap(width, height, Bitmap.Config.RGB_565);
    for (int x = 0; x < width; x++){
        for (int y = 0; y < height; y++){
            bmp.setPixel(x, y, matrix.get(x,y) ? Color.BLACK : Color.WHITE);
        }
    }
    return bmp;
}
```

This is a very simple and straightforward port of the `toBufferedImage()`-method from the `javase` module. The code in the ZXing application actually does a lot more than that, but I have found that this works fine as well.

A noticeable difference between the two implementations is, that I use `Bitmap.Config.RGB_565` instead of `Bitmap.Config.ARGB_8888`. The [docs say](http://developer.android.com/reference/android/graphics/Bitmap.Config.html):

> * `ARGB_8888` Each pixel is stored on **4 bytes**.
> * `RGB_565` Each pixel is stored on **2 bytes** and only the RGB channels are encoded [...]

Since we're showing an all black & white image and there are *only* "rough edges", the **quality will not decrease, but the memory-footprint will**.

The generated `Bitmap`-object can now be shown using [`ImageView.setImageBitmap(Bitmap)`](http://developer.android.com/reference/android/widget/ImageView.html#setImageBitmap(android.graphics.Bitmap)).

### Storing the Bitmap

To save the `Bitmap`-object as a image-file, use the [`Bitmap.compress(Bitmap.CompressFormat, int, OutputStream)`-method](http://developer.android.com/reference/android/graphics/Bitmap.html#compress%28android.graphics.Bitmap.CompressFormat,%20int,%20java.io.OutputStream%29):

```java
File sdcard = Environment.getExternalStorageDirectory();
FileOutputStream out = null;
try {
    out = new FileOutputStream(new File(sdcard, "qrcode.jpg"));
    boolean success = qrcode_bmp.compress(Bitmap.CompressFormat.JPEG, 100, out);
    if (success){
        // Successfully saved!
    } else {
        // ... or not.
    }
} catch (FileNotFoundException e) {
    e.printStackTrace();
} finally {
    if (out != null) try {
        out.close();
    } catch (IOException e) {
        e.printStackTrace();
    }
}
```

This will store the `Bitmap`-instance `qrcode_bmp` to the SD-Card's root folder, using the given filename.

Note that in a real-live implementation, you'd also need to check the SD-Card's state and ensure that it's writable. Note also, that you'll have to declare the use of the `android.permission.WRITE_EXTERNAL_STORAGE`-permission in your manifest-file.

## Conclusion

* For fast integration, use the `android-integration` module and it's `shareText(CharSequence)`-method.
* For maximum customization, create a `BitMatrix` and convert it into a `Bitmap`
* The `javase` module will not work, because **Android does not offer** the `BufferedImage`-class, nor does it offer `ImageIO`!
