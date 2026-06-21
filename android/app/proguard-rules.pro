# Proguard rules for SQLCipher and SQFlite to prevent JNI LinkageErrors in Release builds

-keep class net.sqlcipher.** { *; }
-keep class net.sqlcipher.database.** { *; }
-dontwarn net.sqlcipher.**

-keep class com.tekartik.sqflite.** { *; }
-dontwarn com.tekartik.sqflite.**