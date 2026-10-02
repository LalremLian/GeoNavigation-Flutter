package com.example.navtest.location

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

// Channel name constants — must match channel_constants.dart exactly
private const val METHOD_CHANNEL_NAME  = "com.example.navtest/location"
private const val EVENT_CHANNEL_NAME   = "com.example.navtest/location_stream"

// Request code used when asking MainActivity to trigger the permission dialog
const val LOCATION_PERMISSION_REQUEST_CODE = 1001

/**
 * Registers and handles the MethodChannel + EventChannel for location.
 *
 * Design:
 *  - [MethodChannel] handles one-shot commands (permission, single fix, settings)
 *  - [EventChannel] streams continuous location fixes to Dart
 *  - [LocationManager] owns all FusedLocation logic — this class only routes calls
 *
 * Lifecycle:
 *  - Call [register] from MainActivity.configureFlutterEngine
 *  - Call [onPermissionResult] from MainActivity.onRequestPermissionsResult
 *  - Call [dispose] from MainActivity.onDestroy
 */
class LocationChannel(
    private val locationManager: LocationManager,
    private val getActivity: () -> Activity?
) {

    private var methodChannel: MethodChannel? = null
    private var eventChannel: EventChannel? = null

    // Holds the pending permission result callback while the OS dialog is shown
    private var pendingPermissionResult: MethodChannel.Result? = null

    // EventChannel sink — non-null while Dart has an active stream subscription
    private var eventSink: EventChannel.EventSink? = null

    // -----------------------------------------------------------------------
    // Registration
    // -----------------------------------------------------------------------

    fun register(flutterEngine: FlutterEngine) {
        // --- MethodChannel ---------------------------------------------------
        methodChannel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            METHOD_CHANNEL_NAME
        ).also { channel ->
            channel.setMethodCallHandler { call, result ->
                handleMethodCall(call, result)
            }
        }

        // --- EventChannel ----------------------------------------------------
        eventChannel = EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            EVENT_CHANNEL_NAME
        ).also { channel ->
            channel.setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink) {
                    eventSink = sink
                    locationManager.startLocationUpdates(
                        onLocation = { map -> sink.success(map) },
                        onError    = { code -> sink.error(code, code, null) }
                    )
                }

                override fun onCancel(arguments: Any?) {
                    // Dart cancelled the stream — stop native updates immediately
                    locationManager.stopLocationUpdates()
                    eventSink = null
                }
            })
        }
    }

    // -----------------------------------------------------------------------
    // MethodChannel dispatch
    // -----------------------------------------------------------------------

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {

            // -----------------------------------------------------------------
            "requestPermission" -> {
                val activity = getActivity() ?: run {
                    result.error(ErrorCodes.NOT_SUPPORTED, "No activity available", null)
                    return
                }

                if (locationManager.hasPermission()) {
                    result.success("granted")
                    return
                }

                // Store result; actual response sent in onPermissionResult()
                pendingPermissionResult = result

                ActivityCompat.requestPermissions(
                    activity,
                    arrayOf(
                        android.Manifest.permission.ACCESS_FINE_LOCATION,
                        android.Manifest.permission.ACCESS_COARSE_LOCATION
                    ),
                    LOCATION_PERMISSION_REQUEST_CODE
                )
            }

            // -----------------------------------------------------------------
            "checkPermission" -> {
                result.success(if (locationManager.hasPermission()) "granted" else "denied")
            }

            // -----------------------------------------------------------------
            "isLocationServiceEnabled" -> {
                result.success(locationManager.isLocationServiceEnabled())
            }

            // -----------------------------------------------------------------
            "getCurrentLocation" -> {
                locationManager.getCurrentLocation(
                    onSuccess = { map -> result.success(map) },
                    onError   = { code -> result.error(code, code, null) }
                )
            }

            // -----------------------------------------------------------------
            "getLastKnownLocation" -> {
                locationManager.getLastKnownLocation(
                    onSuccess = { map -> result.success(map) },
                    onError   = { code -> result.error(code, code, null) }
                )
            }

            // -----------------------------------------------------------------
            "stopLocationUpdates" -> {
                locationManager.stopLocationUpdates()
                eventSink = null
                result.success(null)
            }

            // -----------------------------------------------------------------
            "openAppSettings" -> {
                val activity = getActivity() ?: run {
                    result.error(ErrorCodes.NOT_SUPPORTED, "No activity", null)
                    return
                }
                val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                    data = Uri.fromParts("package", activity.packageName, null)
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                activity.startActivity(intent)
                result.success(null)
            }

            // -----------------------------------------------------------------
            else -> result.notImplemented()
        }
    }

    // -----------------------------------------------------------------------
    // Permission result callback
    // -----------------------------------------------------------------------

    /**
     * Must be called from [MainActivity.onRequestPermissionsResult].
     * Returns true if this class handled the request code.
     */
    fun onPermissionResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ): Boolean {
        if (requestCode != LOCATION_PERMISSION_REQUEST_CODE) return false

        val pending = pendingPermissionResult ?: return true
        pendingPermissionResult = null

        val granted = grantResults.isNotEmpty() &&
                grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED

        if (granted) {
            pending.success("granted")
        } else {
            // Check if "don't ask again" was selected
            val activity = getActivity()
            val showRationale = activity?.let {
                ActivityCompat.shouldShowRequestPermissionRationale(
                    it,
                    android.Manifest.permission.ACCESS_FINE_LOCATION
                )
            } ?: false

            if (!showRationale) {
                // User ticked "don't ask again" — permanently denied
                pending.error(
                    ErrorCodes.PERMISSION_PERMANENTLY_DENIED,
                    ErrorCodes.PERMISSION_PERMANENTLY_DENIED,
                    null
                )
            } else {
                pending.error(
                    ErrorCodes.PERMISSION_DENIED,
                    ErrorCodes.PERMISSION_DENIED,
                    null
                )
            }
        }
        return true
    }

    // -----------------------------------------------------------------------
    // Lifecycle
    // -----------------------------------------------------------------------

    /**
     * Stops all native listeners and clears channel handlers.
     * Call from MainActivity.onDestroy.
     */
    fun dispose() {
        locationManager.stopLocationUpdates()
        eventSink?.endOfStream()
        eventSink = null
        pendingPermissionResult = null
        methodChannel?.setMethodCallHandler(null)
        eventChannel?.setStreamHandler(null)
        methodChannel = null
        eventChannel = null
    }
}
