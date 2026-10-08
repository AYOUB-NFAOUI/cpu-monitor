# Corrige l'erreur R8 "Missing class com.amazon.privacypass..." (AppLovin / OMID)
-dontwarn com.amazon.privacypass.**

# Règles générales pour les SDK publicitaires
-dontwarn com.applovin.**
-dontwarn com.iab.omid.**
-keep class com.applovin.** { *; }
-keep class com.google.android.gms.ads.** { *; }
