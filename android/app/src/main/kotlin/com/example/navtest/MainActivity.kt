package com.example.navtest

import com.example.navtest.location.LocationChannel
import com.example.navtest.location.LocationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private lateinit var locationChannel: LocationChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- Location channels (MethodChannel + EventChannel) ----------------
        locationChannel = LocationChannel(
            locationManager = LocationManager(applicationContext),
            getActivity      = { this }
        )
        locationChannel.register(flutterEngine)

        // --- AppConfig channel -----------------------------------------------
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.navtest/app_config"
        ).setMethodCallHandler { call, result ->
            if (call.method == "getConfig") {
                result.success(
                    mapOf(
                        "routingBaseUrl" to BuildConfig.ROUTING_BASE_URL,
                        "flavorName"     to BuildConfig.FLAVOR_NAME
                    )
                )
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        if (!locationChannel.onPermissionResult(requestCode, permissions, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    override fun onDestroy() {
        locationChannel.dispose()
        super.onDestroy()
    }
}
