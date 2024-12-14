-keep class io.grpc.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider