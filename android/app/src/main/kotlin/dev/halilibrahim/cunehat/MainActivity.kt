package dev.halilibrahim.cunehat

import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    private var pdfRaster: PdfRasterPlugin? = null
    private var notificationPermission: NotificationPermissionPlugin? = null
    private var sharedStatement: SharedStatementPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pdfRaster = PdfRasterPlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            cacheDir,
        )
        notificationPermission = NotificationPermissionPlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )
        sharedStatement = SharedStatementPlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            this,
        )
        // Uygulama KAPALIYKEN gelen paylaşım: açılış intent'i. Kanal burada
        // kurulduğu için Dart entrypoint çalışmaya başlamadan önce tamponlanır.
        sharedStatement?.handleIntent(intent)
    }

    /**
     * Uygulama AÇIKKEN gelen paylaşım. `launchMode="singleTop"` sayesinde yeni
     * bir örnek yaratılmaz, mevcut activity'ye buradan teslim edilir.
     */
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // Aksi halde getIntent() açılıştaki eski intent'i döndürmeye devam eder.
        setIntent(intent)
        sharedStatement?.handleIntent(intent)
    }

    override fun onDestroy() {
        pdfRaster?.dispose()
        pdfRaster = null
        notificationPermission?.dispose()
        notificationPermission = null
        sharedStatement?.dispose()
        sharedStatement = null
        super.onDestroy()
    }
}
