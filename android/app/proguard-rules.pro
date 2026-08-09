-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

-keepclassmembers class com.razorpay.** {
    *;
}

-dontwarn com.razorpay.**
