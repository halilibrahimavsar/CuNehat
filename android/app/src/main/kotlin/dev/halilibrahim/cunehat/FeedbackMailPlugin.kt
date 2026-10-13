package dev.halilibrahim.cunehat

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel

/**
 * "Görüş gönder": alıcısı, konusu ve gövdesi dolu bir e-posta taslağı açar.
 *
 * Tek bir intent için `url_launcher` eklemek yerine burada duruyor (uygulamanın
 * öteki küçük kanalları gibi). `ACTION_SENDTO` + `mailto:` yalnız e-posta
 * uygulamalarını hedefler; paylaşım sayfası (`ACTION_SEND`) alıcıyı
 * dolduramadığı için kullanılmadı.
 *
 * Cihazda e-posta uygulaması yoksa `false` döner; Dart tarafı adresi panoya
 * kopyalayıp bunu söyler.
 */
class FeedbackMailPlugin(
    messenger: BinaryMessenger,
    private val activity: Activity,
) {

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "compose" -> result.success(
                    compose(
                        to = call.argument<String>("to").orEmpty(),
                        subject = call.argument<String>("subject").orEmpty(),
                        body = call.argument<String>("body").orEmpty(),
                    ),
                )
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun compose(to: String, subject: String, body: String): Boolean {
        if (to.isBlank()) return false
        // Konu ve gövde hem adreste hem ek alanlarda: bazı istemciler yalnız
        // birini okur. Adresteki `@` KODLANMAZ (ikinci parametre): `%40`'ı
        // çözmeyen bir istemci alıcıyı boş bırakırdı.
        val uri = Uri.parse(
            "mailto:" + Uri.encode(to, "@") +
                "?subject=" + Uri.encode(subject) +
                "&body=" + Uri.encode(body),
        )
        val intent = Intent(Intent.ACTION_SENDTO, uri).apply {
            putExtra(Intent.EXTRA_EMAIL, arrayOf(to))
            putExtra(Intent.EXTRA_SUBJECT, subject)
            putExtra(Intent.EXTRA_TEXT, body)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        }
    }

    companion object {
        private const val CHANNEL = "dev.halilibrahim.cunehat/feedback_mail"
    }
}
