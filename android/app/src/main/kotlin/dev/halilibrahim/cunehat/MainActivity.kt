package dev.halilibrahim.cunehat

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterFragmentActivity() {

    private var pdfRaster: PdfRasterPlugin? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pdfRaster = PdfRasterPlugin(
            flutterEngine.dartExecutor.binaryMessenger,
            cacheDir,
        )
    }

    override fun onDestroy() {
        pdfRaster?.dispose()
        pdfRaster = null
        super.onDestroy()
    }
}
