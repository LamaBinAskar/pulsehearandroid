package com.example.pulse_hear

import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import org.vosk.Model
import org.vosk.Recognizer
import java.io.File

/**
 * VoskPlugin — native Android platform channel for offline Arabic keyword detection.
 * Channel: "pulsehear/vosk"
 *
 * Methods (called from Flutter/Dart):
 *   init()              → "ok" | error
 *   acceptWaveform(ByteArray) → JSON String ({"text":...} or {"partial":...})
 *   getFinalResult()    → JSON String
 *   dispose()           → null
 */
class VoskPlugin(private val context: Context) : MethodCallHandler {

    companion object {
        const val CHANNEL = "pulsehear/vosk"
        private const val MODEL_NAME = "vosk-model-small-ar-0.3"
        // In a Flutter APK, assets live under flutter_assets/
        private const val ASSET_ROOT = "flutter_assets/assets/models/$MODEL_NAME"
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var model: Model? = null
    private var recognizer: Recognizer? = null

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {

            "init" -> {
                Thread {
                    try {
                        val modelPath = extractModelIfNeeded()
                        model?.close()
                        recognizer?.close()
                        model = Model(modelPath)
                        recognizer = Recognizer(model, 16000.0f)
                        mainHandler.post { result.success("ok") }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("INIT_ERROR", e.message, null)
                        }
                    }
                }.start()
            }

            "acceptWaveform" -> {
                val bytes = call.arguments<ByteArray>()
                if (bytes == null) {
                    result.error("INVALID_ARGS", "Expected ByteArray", null)
                    return
                }
                Thread {
                    try {
                        val rec = recognizer
                        if (rec == null) {
                            mainHandler.post { result.success("") }
                            return@Thread
                        }
                        val accepted = rec.acceptWaveForm(bytes, bytes.size)
                        val json = if (accepted) rec.result else rec.partialResult
                        mainHandler.post { result.success(json ?: "") }
                    } catch (e: Exception) {
                        mainHandler.post {
                            result.error("WAVEFORM_ERROR", e.message, null)
                        }
                    }
                }.start()
            }

            "getFinalResult" -> {
                try {
                    val json = recognizer?.finalResult ?: "{\"text\":\"\"}"
                    result.success(json)
                } catch (e: Exception) {
                    result.error("FINAL_ERROR", e.message, null)
                }
            }

            "dispose" -> {
                recognizer?.close()
                model?.close()
                recognizer = null
                model = null
                result.success(null)
            }

            else -> result.notImplemented()
        }
    }

    // ── Extract model from Flutter assets to app files directory ────
    private fun extractModelIfNeeded(): String {
        val modelDir = File(context.filesDir, MODEL_NAME)
        val testFile = File(modelDir, "am/final.mdl")

        if (testFile.exists()) {
            android.util.Log.d("VoskPlugin", "Model already on disk: ${modelDir.absolutePath}")
            return modelDir.absolutePath
        }

        android.util.Log.d("VoskPlugin", "Extracting model from Flutter assets…")
        modelDir.mkdirs()
        copyAssetDir(ASSET_ROOT, modelDir)
        android.util.Log.d("VoskPlugin", "Model extracted to ${modelDir.absolutePath}")
        return modelDir.absolutePath
    }

    private fun copyAssetDir(assetPath: String, destDir: File) {
        val children = try {
            context.assets.list(assetPath)
        } catch (e: Exception) {
            null
        } ?: return

        for (child in children) {
            val childAsset = "$assetPath/$child"
            val destChild = File(destDir, child)
            val subChildren = try { context.assets.list(childAsset) } catch (e: Exception) { null }
            if (!subChildren.isNullOrEmpty()) {
                // Directory — recurse
                destChild.mkdirs()
                copyAssetDir(childAsset, destChild)
            } else {
                // File — copy bytes
                context.assets.open(childAsset).use { input ->
                    destChild.outputStream().use { output ->
                        input.copyTo(output)
                    }
                }
            }
        }
    }
}
