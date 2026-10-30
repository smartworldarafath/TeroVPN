# Flutter Proguard Rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Go Mobile (gomobile) & JNI Bindings
-keep class go.** { *; }
-keep interface go.** { *; }
-keepclassmembers class go.** { *; }

-keep class mobile.** { *; }
-keep interface mobile.** { *; }
-keepclassmembers class mobile.** { *; }

-keep class com.terovpn.android.** { *; }
-keepclassmembers class com.terovpn.android.** { *; }

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers class * {
    native <methods>;
}
