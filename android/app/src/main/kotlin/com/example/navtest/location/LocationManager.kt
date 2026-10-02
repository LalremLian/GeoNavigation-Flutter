package com.example.navtest.location

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.location.LocationManager as SystemLocationManager
import android.os.Looper
import androidx.core.content.ContextCompat
import com.google.android.gms.location.*
import com.google.android.gms.tasks.CancellationTokenSource

/**
 * Wraps [FusedLocationProviderClient] with a clean API for the channel layer.
 *
 * Responsibilities:
 *  - Permission checks (does NOT request — that is handled by MainActivity)
 *  - Single location fix with timeout via getCurrentLocation()
 *  - Continuous location updates via startLocationUpdates() / stopLocationUpdates()
 *  - Location service (GPS) enabled check
 *
 * All callbacks fire on the main thread. The channel layer converts results
 * to Flutter-compatible maps before forwarding to Dart.
 */
class LocationManager(private val context: Context) {

    private val fusedClient: FusedLocationProviderClient =
        LocationServices.getFusedLocationProviderClient(context)

    // Holds the active stream callback so we can remove it cleanly.
    private var streamCallback: LocationCallback? = null

    // CancellationTokenSource for the one-shot getCurrentLocation request.
    private var currentLocationCts: CancellationTokenSource? = null

    // -----------------------------------------------------------------------
    // Permission helpers
    // -----------------------------------------------------------------------

    /** Returns true if ACCESS_FINE_LOCATION is currently granted. */
    fun hasPermission(): Boolean =
        ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED

    /** Returns true if the system location provider (GPS or network) is enabled. */
    fun isLocationServiceEnabled(): Boolean {
        val lm = context.getSystemService(Context.LOCATION_SERVICE) as SystemLocationManager
        return lm.isProviderEnabled(SystemLocationManager.GPS_PROVIDER) ||
                lm.isProviderEnabled(SystemLocationManager.NETWORK_PROVIDER)
    }

    // -----------------------------------------------------------------------
    // Single fix
    // -----------------------------------------------------------------------

    /**
     * Requests a single fresh location fix.
     *
     * @param onSuccess called with a [LocationMap] on success
     * @param onError   called with an error code string on failure
     */
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
                    // Fused returned null — try last known as fallback
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

    /**
     * Returns the last known location without forcing a new fix.
     * Faster but may be stale or null.
     */
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

    // -----------------------------------------------------------------------
    // Continuous updates
    // -----------------------------------------------------------------------

    /**
     * Starts streaming location updates.
     *
     * Fires [onLocation] for each new fix and [onError] on failure.
     * Calling this while already streaming replaces the previous callback.
     */
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
                if (!availability.isLocationAvailable) {
                    onError(ErrorCodes.LOCATION_UNAVAILABLE)
                }
            }
        }
        streamCallback = callback

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
        streamCallback?.let {
            fusedClient.removeLocationUpdates(it)
            streamCallback = null
        }
        currentLocationCts?.cancel()
        currentLocationCts = null
    }
}

// ---------------------------------------------------------------------------
// Type alias + extension helpers
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Error code constants
// ---------------------------------------------------------------------------

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
