package com.example.navtest.utils

/** The shape sent over the EventChannel / MethodChannel to Dart. */
typealias LocationMap = Map<String, Any?>

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