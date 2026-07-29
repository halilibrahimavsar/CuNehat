package dev.halilibrahim.cunehat

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    private var pdfRaster: PdfRasterPlugin? = null
    private var notificationPermission: NotificationPermissionPlugin? = null

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
    }

    override fun onDestroy() {
        pdfRaster?.dispose()
        pdfRaster = null
        notificationPermission?.dispose()
        notificationPermission = null
        super.onDestroy()
    }
}
