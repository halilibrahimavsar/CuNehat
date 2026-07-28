package dev.halilibrahim.cunehat

import android.graphics.Bitmap
import android.graphics.Color
import android.graphics.pdf.PdfRenderer
import android.os.ParcelFileDescriptor
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

/**
 * Taranmış (metin katmanı olmayan) PDF sayfalarını PNG'ye çevirir; Dart tarafı
 * bunları ML Kit OCR'a verir.
 *
 * İşletim sisteminin kendi [PdfRenderer]'ı (API 21+) kullanılır — PDFium
 * paketleyen bir Flutter eklentisi (pdfrx vb.) eklemek APK'ya ABI başına
 * birkaç MB ekleyecekti; burada ek ikili YOK.
 *
 * Üretilen PNG'ler uygulamanın önbellek dizinine yazılır ve her çağrının
 * başında öncekiler silinir (finansal görüntüler birikmesin).
 */
class PdfRasterPlugin(messenger: BinaryMessenger, private val cacheDir: File) {

    private val channel = MethodChannel(messenger, CHANNEL)

    init {
        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "rasterize" -> handleRasterize(call.argument<String>("path"),
                    call.argument<Int>("maxPages") ?: DEFAULT_MAX_PAGES,
                    call.argument<Int>("targetWidth") ?: DEFAULT_TARGET_WIDTH,
                    result)
                else -> result.notImplemented()
            }
        }
    }

    fun dispose() = channel.setMethodCallHandler(null)

    private fun handleRasterize(
        path: String?,
        maxPages: Int,
        targetWidth: Int,
        result: MethodChannel.Result,
    ) {
        if (path.isNullOrEmpty()) {
            result.error("bad_args", "path gerekli", null)
            return
        }
        val source = File(path)
        if (!source.exists()) {
            result.error("not_found", "Dosya bulunamadı: $path", null)
            return
        }

        val outputDir = File(cacheDir, OUTPUT_DIR).apply {
            deleteRecursively()
            mkdirs()
        }

        var descriptor: ParcelFileDescriptor? = null
        var renderer: PdfRenderer? = null
        try {
            descriptor =
                ParcelFileDescriptor.open(source, ParcelFileDescriptor.MODE_READ_ONLY)
            renderer = PdfRenderer(descriptor)

            val paths = ArrayList<String>()
            val pageCount = minOf(renderer.pageCount, maxPages)
            for (index in 0 until pageCount) {
                renderer.openPage(index).use { page ->
                    // OCR isabeti çözünürlükle doğrudan ilişkili: sayfayı
                    // hedef genişliğe ölçekle (oran korunur).
                    val scale = targetWidth.toFloat() / page.width.toFloat()
                    val width = targetWidth
                    val height = (page.height * scale).toInt().coerceAtLeast(1)

                    val bitmap =
                        Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888)
                    // PdfRenderer saydam alanları boyamaz; ML Kit siyah zeminde
                    // metni bulamaz — önce beyaza boya.
                    bitmap.eraseColor(Color.WHITE)
                    page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)

                    val out = File(outputDir, "page_$index.png")
                    FileOutputStream(out).use { stream ->
                        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
                    }
                    bitmap.recycle()
                    paths.add(out.absolutePath)
                }
            }
            result.success(paths)
        } catch (e: Exception) {
            // Parola korumalı / bozuk PDF buraya düşer; Dart tarafı bunu
            // kullanıcıya açık bir mesaja çevirir.
            result.error("render_failed", e.message ?: e.toString(), null)
        } finally {
            runCatching { renderer?.close() }
            runCatching { descriptor?.close() }
        }
    }

    companion object {
        const val CHANNEL = "dev.halilibrahim.cunehat/pdf_raster"
        private const val OUTPUT_DIR = "bank_import_pdf_pages"
        private const val DEFAULT_MAX_PAGES = 10
        private const val DEFAULT_TARGET_WIDTH = 2000
    }
}
