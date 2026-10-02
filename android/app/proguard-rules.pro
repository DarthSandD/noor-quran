# ProGuard/R8 rules for Noor Qur'an release builds.

# Flutter engine
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# just_audio / audio_service background playback
-keep class com.ryanheise.** { *; }
-keep class androidx.media.** { *; }

# geolocator
-keep class com.baseflow.geolocator.** { *; }

# permission_handler
-keep class com.baseflow.permissionhandler.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# url_launcher / share_plus
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Keep annotations & generic signatures used reflectively
-keepattributes *Annotation*, Signature, InnerClasses, EnclosingMethod

# Kotlin metadata
-keep class kotlin.Metadata { *; }
