package kt.qrcodekeeper

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kt.qrcodekeeper"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getOsVersion" -> {
                    var v = getVersion()
                    result.success(v)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getVersion(): Float {
        val release = Build.VERSION.RELEASE
        val parsedVersion = "\\d+(\\.\\d+)?".toRegex().find(release)?.value
        if (parsedVersion.isNullOrBlank()) return 0f
        return try {
            parsedVersion.toFloat()
        } catch (e: Exception) {
            0f
        }
    }
}
