package com.google.ml.kit.flutter.example

import android.os.Bundle
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import io.flutter.embedding.android.FlutterActivity
import android.content.Intent

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val launchIntent = Intent(Intent.ACTION_VIEW).apply {
            setClassName(
                this@MainActivity,
                "com.google.ml.kit.flutter.example.MainActivity"
            )
            // No data URI needed for OPEN_APP
        }

        val shortcut = ShortcutInfoCompat.Builder(this, "open_app")
            .setShortLabel("Blind Assistance")
            .setLongLabel("Open Blind Assistance")
            .setIcon(IconCompat.createWithResource(this, R.mipmap.ic_launcher))
            .setIntent(launchIntent)
            // If this compiles for your version, you can keep it:
            // .addCapabilityBinding("actions.intent.OPEN_APP")
            .build()

        ShortcutManagerCompat.pushDynamicShortcut(this, shortcut)
    }
}
