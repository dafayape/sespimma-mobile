# Proguard rules for SQLCipher and SQFlite to prevent JNI LinkageErrors in Release builds

-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-dontwarn net.sqlcipher.**

-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**

# Preserve BitmapFactory options for proper R8 optimization & downsampling checks
-keepclassmembers class android.graphics.BitmapFactory {
    public static *** decode*(...);
}
-keep class android.graphics.BitmapFactory$Options { *; }