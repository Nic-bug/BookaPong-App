package com.nicoleann.bookapong

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {

    override fun onCreate(savedInstanceState: Bundle?) {
        if (intent != null) {
            intent.putExtra("enable-impeller", false)
        }

        System.setProperty("flutter.android.enableImpeller", "false")

        super.onCreate(savedInstanceState)
    }
}
