package com.example.navtest.location

import android.Manifest
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager as SystemLocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import com.google.android.gms.tasks.CancellationTokenSource

class LocationManager(private val context: Context) {

    private val fusedClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private var streamCallback: LocationCallback? = null
    private var providerChangedReceiver: BroadcastReceiver? = null
    private var currentLocationCts: CancellationTokenSource? = null

    //Permission already granted or not
    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

    //Detect locations toggles
    fun isLocationServiceEnabled(): Boolean {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as SystemLocationManager
        return lm.isProviderEnabled(SystemLocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(SystemLocationManager.NETWORK_PROVIDER)
    }


    fun getCurrentLocation(
        onSuccess: (LocationMap) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!hasPermission()) {
            onError(ErrorCodes.PERMISSION_DENIED)
            return
        }
        if (!isLocationServiceEnabled()) {
            onError(ErrorCodes.LOCATION_SERVICE_DISABLED)
            return
        }

        // Cancel any in-flight request before starting a new one
        currentLocationCts?.cancel()
        val cts = CancellationTokenSource()
        currentLocationCts = cts

        fusedClient
            .getCurrentLocation(Priority.PRIORITY_HIGH_ACCURACY, cts.token)
            .addOnSuccessListener { location ->
                if (location != null) {
                    onSuccess(location.toMap())
                } else {
                    getLastKnownLocation(
                        onSuccess = onSuccess,
                        onError = { onError(ErrorCodes.LOCATION_UNAVAILABLE) }
                    )
                }
            }
            .addOnFailureListener { e ->
                onError(ErrorCodes.fromException(e))
            }
            .addOnCanceledListener {
                onError(ErrorCodes.LOCATION_UNAVAILABLE)
            }
    }

    /** Returns the last known location without forcing a new fix. Faster but may be stale or null. */
    fun getLastKnownLocation(
        onSuccess: (LocationMap) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!hasPermission()) {
            onError(ErrorCodes.PERMISSION_DENIED)
            return
        }

        fusedClient.lastLocation
            .addOnSuccessListener { location ->
                if (location != null) {
                    onSuccess(location.toMap())
                } else {
                    onError(ErrorCodes.LOCATION_UNAVAILABLE)
                }
            }
            .addOnFailureListener { e ->
                onError(ErrorCodes.fromException(e))
            }
    }

    /** Starts streaming location updates. */
    fun startLocationUpdates(
        onLocation: (LocationMap) -> Unit,
        onError: (String) -> Unit
    ) {
        if (!hasPermission()) {
            onError(ErrorCodes.PERMISSION_DENIED)
            return
        }
        if (!isLocationServiceEnabled()) {
            onError(ErrorCodes.LOCATION_SERVICE_DISABLED)
            return
        }

        // Remove any existing callback first
        stopLocationUpdates()

        val request = LocationRequest.Builder(
            Priority.PRIORITY_HIGH_ACCURACY,
            /* intervalMillis = */ 2000L
        )
            .setMinUpdateIntervalMillis(1000L)
            .setMinUpdateDistanceMeters(1f)
            .build()

        val callback = object : LocationCallback() {
            override fun onLocationResult(result: LocationResult) {
                result.lastLocation?.let { onLocation(it.toMap()) }
            }

            override fun onLocationAvailability(availability: LocationAvailability) {
                // Fused availability can briefly be false while a fix is
                // reacquired. Only surface an error when Android confirms
                // that both location providers are actually disabled.
                if (!availability.isLocationAvailable &&
                    !isLocationServiceEnabled()
                ) {
                    onError(ErrorCodes.LOCATION_SERVICE_DISABLED)
                }
            }
        }
        streamCallback = callback

        // Listen for system GPS/location toggle events immediately
        val receiver = object : BroadcastReceiver() {
            override fun onReceive(context: Context?, intent: Intent?) {
                if (intent?.action == SystemLocationManager.PROVIDERS_CHANGED_ACTION) {
                    if (!isLocationServiceEnabled()) {
                        onError(ErrorCodes.LOCATION_SERVICE_DISABLED)
                    }
                }
            }
        }
        providerChangedReceiver = receiver
        context.registerReceiver(
            receiver,
            IntentFilter(SystemLocationManager.PROVIDERS_CHANGED_ACTION)
        )

        fusedClient.requestLocationUpdates(
            request,
            callback,
            Looper.getMainLooper()
        ).addOnFailureListener { e ->
            onError(ErrorCodes.fromException(e))
        }
    }

    /** Stops any active continuous location updates. Safe to call repeatedly. */
    fun stopLocationUpdates() {
        providerChangedReceiver?.let {
            try {
                context.unregisterReceiver(it)
            } catch (_: Exception) {}
            providerChangedReceiver = null
        }
        streamCallback?.let {
            fusedClient.removeLocationUpdates(it)
            streamCallback = null
        }
        currentLocationCts?.cancel()
        currentLocationCts = null
    }
}

/** The shape sent over the EventChannel / MethodChannel to Dart. */
typealias LocationMap = Map<String, Any?>

/** Converts an Android [android.location.Location] to a Dart-compatible map. */
private fun android.location.Location.toMap(): LocationMap = mapOf(
    "lat"       to latitude,
    "lng"       to longitude,
    "accuracy"  to accuracy.toDouble(),
    "speed"     to speed.toDouble(),
    "bearing"   to bearing.toDouble(),
    "timestamp" to time          // epoch milliseconds
)

object ErrorCodes {
    const val PERMISSION_DENIED              = "PERMISSION_DENIED"
    const val PERMISSION_PERMANENTLY_DENIED  = "PERMISSION_PERMANENTLY_DENIED"
    const val LOCATION_SERVICE_DISABLED      = "LOCATION_SERVICE_DISABLED"
    const val LOCATION_TIMEOUT               = "LOCATION_TIMEOUT"
    const val LOCATION_UNAVAILABLE           = "LOCATION_UNAVAILABLE"
    const val NOT_SUPPORTED                  = "NOT_SUPPORTED"

    /** Maps a [Throwable] to the closest typed error code. */
    fun fromException(e: Throwable): String {
        val msg = e.message?.lowercase() ?: ""
        return when {
            msg.contains("permission") -> PERMISSION_DENIED
            msg.contains("timeout")    -> LOCATION_TIMEOUT
            else                       -> LOCATION_UNAVAILABLE
        }
    }
}
