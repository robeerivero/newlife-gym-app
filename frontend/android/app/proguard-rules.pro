# Evita que R8 elimine clases necesarias para Flutter
-keep class io.flutter.** { *; }
-keep class android.window.** { *; }
-dontwarn android.window.**

# Para flutter_inappwebview (aunque no lo uses, una dependencia lo mete indirectamente)
-keep class com.pichillilorenzo.** { *; }
-dontwarn com.pichillilorenzo.**
-dontwarn android.window.BackEvent
