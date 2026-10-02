package com.example.navtest

import com.example.navtest.location.LocationChannel
import com.example.navtest.location.LocationManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Single Activity for the Flutter embedding.
 *
 * Responsibilities:
 *  1. Register the location MethodChannel + EventChannel via [LocationChannel]
 *  2. Register the AppConfig MethodChannel so Dart can read flavor values
 *  3. Forward permission results to [LocationChannel]
 *  4. Dispose all channel resources on destroy
 */
class MainActivity : FlutterActivity() {

    private lateinit var locationChannel: LocationChannel

    // -----------------------------------------------------------------------
    // Flutter engine configuration
    // -----------------------------------------------------------------------

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // --- Location channels (MethodChannel + EventChannel) ----------------
        locationChannel = LocationChannel(
            locationManager = LocationManager(applicationContext),
            getActivity      = { this }
        )
        locationChannel.register(flutterEngine)

        // --- AppConfig channel -----------------------------------------------
        // Supplies flavor-injected BuildConfig values to Dart's AppConfig class.
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

    // -----------------------------------------------------------------------
    // Permission result forwarding
    // -----------------------------------------------------------------------

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        // Let LocationChannel handle its own request code first
        if (!locationChannel.onPermissionResult(requestCode, permissions, grantResults)) {
            super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        }
    }

    // -----------------------------------------------------------------------
    // Lifecycle
    // -----------------------------------------------------------------------

    override fun onDestroy() {
        locationChannel.dispose()
        super.onDestroy()
    }
}
