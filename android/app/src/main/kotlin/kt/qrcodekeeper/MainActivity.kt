package kt.qrcodekeeper

import android.os.Build
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "kt.qrcodekeeper"
    private var methodChannel: MethodChannel? = null

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        methodChannel  =   MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        methodChannel!!.setMethodCallHandler {
                call,
                result ->
            when (call.method) {
                "getVersionsInfo" -> {
                    val data = getVersionsInfo()
                    result.success(data)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun getVersionsInfo(): Map<String, Any?> {
        var data:MutableMap<String, Any> = mutableMapOf<String, Any>()

        data["appVersionName"] = BuildConfig.VERSION_NAME
        data["appVersionCode"] = BuildConfig.VERSION_CODE

        val osVersion: String = Build.VERSION.RELEASE
        val parsedOsVersion = "\\d+(\\.\\d+)?".toRegex().find(osVersion)?.value
        val osVersionValue:  Float? = parsedOsVersion?.toFloatOrNull()
        if (osVersionValue != null) {
            data["osVersion"] = osVersionValue;
        }

        return data
    }
}