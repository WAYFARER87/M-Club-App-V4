# Keep the audio service implementation so background playback remains functional
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# Retain AndroidX media classes that the audio service depends on
-keep class androidx.media.** { *; }
-dontwarn androidx.media.**

# ExoPlayer powers streaming playback for the radio feature
-keep class com.google.android.exoplayer2.** { *; }
-dontwarn com.google.android.exoplayer2.**

# Retain generated Flutter plugin services referenced by the radio module
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class com.ryanheise.audioservice.AudioService { *; }
-keep class com.ryanheise.audioservice.MediaButtonReceiver { *; }
