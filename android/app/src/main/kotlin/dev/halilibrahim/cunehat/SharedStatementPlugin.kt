package dev.halilibrahim.cunehat

import android.app.Activity
import android.content.ContentResolver
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.OpenableColumns
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException
import java.util.concurrent.Executors

/**
 * Başka bir uygulamadan (banka uygulaması, dosya yöneticisi, e-posta eki)
 * PAYLAŞILAN ekstre dosyasını içe aktarma akışına taşır.
 *
 * **Yeni bir izin YOKTUR.** Manifest'teki `ACTION_SEND` süzgeci bir izin değil;
 * uygulamayı yalnızca paylaş menüsünde görünür yapar. Kullanıcı CuNehat'i
 * seçtiğinde Android o TEK öğe için tek seferlik, salt-okunur bir URI izni
 * verir — dosya seçicinin (SAF) verdiğinden daha geniş değil, daha dardır.
 *
 * **Tampon-ve-çek (push değil pull).** Paylaşım intent'i Dart tarafı hazır
 * olmadan da gelebilir (soğuk açılış); URI burada tamponlanır ve Dart hazır
 * olduğunda [consume] ile çeker. Bu, "kanala yazdık ama dinleyen yoktu"
 * yarışını tamamen ortadan kaldırır — bildirim yükünün tamponlanmasıyla aynı
 * yaklaşım.
 *
 * **Kopya neden gerekiyor.** Ayrıştırma zinciri `File(path)` üzerine kurulu;
 * `content://` bir dosya yolu değil. Akış uygulamanın ÖZEL önbelleğine
 * kopyalanır (başka uygulama okuyamaz, `allowBackup=false` olduğu için yedeğe
 * de gitmez) ve her yeni paylaşımda öncekiler silinir — finansal belge
 * birikmesin. Dart tarafı da akış bitince kopyayı siler.
 */
class SharedStatementPlugin(
    messenger: BinaryMessenger,
    private val activity: Activity,
) {

    private val channel = MethodChannel(messenger, CHANNEL)

    /** Kopyalama ana iş parçacığını kilitlemesin (sağlayıcı yavaş olabilir). */
    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    /** Henüz Dart'a teslim edilmemiş paylaşım. */
    private var pending: Uri? = null

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "consume" -> consume(result)
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() {
        channel.setMethodCallHandler(null)
        worker.shutdown()
    }

    /**
     * Açılış intent'ini ya da [Activity.onNewIntent] ile geleni inceler.
     * Paylaşım değilse (normal başlatma) sessizce yok sayılır.
     */
    fun handleIntent(intent: Intent?) {
        if (intent == null || intent.action != Intent.ACTION_SEND) return
        val uri = extraStream(intent) ?: return
        pending = uri
    }

    /**
     * Bekleyen paylaşımı önbelleğe kopyalayıp yolunu döner; bekleyen yoksa
     * `null`. Tek seferliktir: aynı paylaşım iki kez teslim edilmez.
     */
    private fun consume(result: MethodChannel.Result) {
        val uri = pending
        pending = null
        if (uri == null) {
            result.success(null)
            return
        }
        worker.execute {
            try {
                val path = copyToCache(uri)
                main.post { result.success(path) }
            } catch (e: Exception) {
                // Sağlayıcı ölmüş / izin düşmüş / dosya çok büyük. Dart tarafı
                // bunu sessiz no-op'a çevirir: ortada açılmış bir ekran yok.
                main.post {
                    result.error("share_read_failed", e.message ?: e.toString(), null)
                }
            }
        }
    }

    @Suppress("DEPRECATION")
    private fun extraStream(intent: Intent): Uri? =
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }

    private fun copyToCache(uri: Uri): String {
        val dir = File(activity.cacheDir, OUTPUT_DIR).apply {
            deleteRecursively()
            mkdirs()
        }
        val target = File(dir, safeName(uri))

        try {
            val input = activity.contentResolver.openInputStream(uri)
                ?: throw IOException("Paylaşılan dosya açılamadı")
            input.use { source ->
                target.outputStream().use { sink ->
                    val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
                    var total = 0L
                    while (true) {
                        val read = source.read(buffer)
                        if (read == -1) break
                        total += read
                        if (total > MAX_BYTES) {
                            throw IOException(
                                "Dosya çok büyük (> ${MAX_BYTES / (1024 * 1024)} MB)",
                            )
                        }
                        sink.write(buffer, 0, read)
                    }
                }
            }
        } catch (e: Exception) {
            // Yarım kalan kopya durmasın: bir sonraki paylaşıma kadar
            // beklemesi gereksiz (ve finansal bir belgenin parçası).
            target.delete()
            throw e
        }
        return target.absolutePath
    }

    /**
     * Gönderen uygulamanın bildirdiği görünen ad. Uzantı KORUNUR: imzası
     * olmayan biçimlerde (CSV/TXT) tespit uzantıya düşüyor ve ad inceleme
     * ekranında kullanıcıya gösteriliyor.
     *
     * Ad gönderenin denetimindedir → yol ayırıcıları ve kontrol karakterleri
     * temizlenir (dizin dışına yazma). Türkçe harfler bilerek korunur; sadece
     * ASCII'ye indirgemek "Hesap Özeti.pdf"i okunmaz hale getirirdi.
     */
    private fun safeName(uri: Uri): String {
        val raw = displayName(uri).orEmpty()
            .substringAfterLast('/')
            .substringAfterLast('\\')
            .replace(Regex("[\\u0000-\\u001F]"), "_")
            .trim()
        if (raw.isEmpty() || raw == "." || raw == "..") return FALLBACK_NAME
        return raw.take(MAX_NAME_LENGTH)
    }

    private fun displayName(uri: Uri): String? {
        if (uri.scheme != ContentResolver.SCHEME_CONTENT) return uri.lastPathSegment
        try {
            activity.contentResolver
                .query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
                ?.use { cursor ->
                    val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
                    if (index >= 0 && cursor.moveToFirst()) {
                        return cursor.getString(index)
                    }
                }
        } catch (e: Exception) {
            // Sağlayıcı sorguyu desteklemiyor olabilir; son çare son yol parçası.
        }
        return uri.lastPathSegment
    }

    private companion object {
        const val CHANNEL = "dev.halilibrahim.cunehat/shared_statement"
        const val OUTPUT_DIR = "bank_import_shared"
        const val FALLBACK_NAME = "ekstre"
        const val MAX_NAME_LENGTH = 120

        /** Ekstre bu boyutu geçmez; sınır, kötü niyetli/yanlış paylaşıma karşı. */
        const val MAX_BYTES = 32L * 1024 * 1024
    }
}
