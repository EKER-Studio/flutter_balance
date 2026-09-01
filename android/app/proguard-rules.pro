# R8 Full Mode Optimizations & Class Repackaging for Google Play
-repackageclasses ''
-allowaccessmodification

# Flutter Local Notifications Plugin
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.dexterous.flutterlocalnotifications.ActionBroadcastReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver { *; }
-keep class com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Flutter engine / platform channels (minimal rules)
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keepclassmembers class * implements android.os.IInterface {
    public static ** DEFAULT;
}

# Play Store Split Install (optional, used by Flutter for deferred components)
-dontwarn com.google.android.play.core.**

# Isar Database (JNI and generated bindings)
-keep class io.isar.** { *; }
-dontwarn io.isar.**

# Health Connect / AndroidX Health
-keep class androidx.health.** { *; }
-dontwarn androidx.health.**

# home_widget package — HomeWidgetProvider, launch-intent glue, and background receiver
# must be preserved; R8 renames/strips them in release builds causing "Nie można wczytać widżetu"
-keep class es.antonborri.home_widget.** { *; }
-keep interface es.antonborri.home_widget.** { *; }
-dontwarn es.antonborri.home_widget.**

# App widget providers declared in AndroidManifest — R8 must not rename or remove them
-keep class com.ekerstudio.balance.BalanceAppWidgetProvider { *; }
-keep class com.ekerstudio.balance.BalanceFullAppWidgetProvider { *; }