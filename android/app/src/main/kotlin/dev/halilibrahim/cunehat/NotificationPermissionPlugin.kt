package dev.halilibrahim.cunehat

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * Bildirim izninin sistem tarafındaki gerçek durumunu Dart'a taşır.
 *
 * flutter_local_notifications yalnızca "izin verildi mi" sorusunu yanıtlar;
 * "sistem bir daha SORAR MI" sorusunu yanıtlamaz. Bu ayrım kritik: Android,
 * kullanıcı izni iki kez reddettikten sonra istek diyaloğunu hiç göstermez ve
 * `requestNotificationsPermission()` anında `false` döner. O noktada kullanıcıya
 * "İzin Ver" düğmesi göstermek düğmeyi ölü bırakır — tek çözüm sistem ayarları.
 *
 * [shouldShowRequestPermissionRationale] tam olarak bu ayrımı verir ve yalnızca
 * bir Activity üzerinden okunabilir; bu yüzden burada, [MainActivity] ile
 * yaşayan bir kanal olarak duruyor.
 */
class NotificationPermissionPlugin(
    messenger: BinaryMessenger,
    private val activity: Activity,
) {

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "status" -> result.success(status())
                "openSettings" -> result.success(openSettings())
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun status(): Map<String, Any> {
        val needsRuntimePermission = Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU
        val granted = if (needsRuntimePermission) {
            activity.checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        } else {
            // Android 12 ve altında POST_NOTIFICATIONS diye bir çalışma zamanı
            // izni yok; bildirimler yalnızca sistem ayarlarından kapatılabilir.
            true
        }
        val shouldShowRationale = needsRuntimePermission &&
            activity.shouldShowRequestPermissionRationale(
                Manifest.permission.POST_NOTIFICATIONS,
            )
        return mapOf(
            "sdkInt" to Build.VERSION.SDK_INT,
            "granted" to granted,
            "shouldShowRationale" to shouldShowRationale,
        )
    }

    /**
     * Uygulamanın bildirim ayarlarını açar. Bildirim ayarı ekranı API 26'da
     * geldi; bulunamazsa uygulama ayrıntıları ekranına düşülür.
     */
    private fun openSettings(): Boolean {
        val candidates = listOf(
            Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                .putExtra(Settings.EXTRA_APP_PACKAGE, activity.packageName),
            Intent(
                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                Uri.fromParts("package", activity.packageName, null),
            ),
        )
        for (intent in candidates) {
            try {
                activity.startActivity(intent)
                return true
            } catch (e: Exception) {
                // Sıradaki adaya düş.
            }
        }
        return false
    }

    private companion object {
        const val CHANNEL = "dev.halilibrahim.cunehat/notification_permission"
    }
}
