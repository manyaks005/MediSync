# Keep ML Kit Text Recognition classes
-keep class com.google.mlkit.** { *; }

# Keep Google Play Services ML Kit
-keep class com.google.android.gms.** { *; }

# Don't warn about missing ML Kit language modules
-dontwarn com.google.mlkit.**