import 'package:latlong2/latlong.dart';

/// Decodes a Google-format encoded polyline string into a list of [LatLng].
///
/// OSRM uses the standard Google Polyline encoding with precision 1e-5.
/// Reference: https://developers.google.com/maps/documentation/utilities/polylinealgorithm
abstract final class PolylineDecoder {
  /// Decodes [encoded] and returns the coordinate list.
  /// Returns an empty list if [encoded] is empty or null.
  static List<LatLng> decode(String? encoded) {
    if (encoded == null || encoded.isEmpty) return const [];

    final result = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      // Decode latitude delta
      int b;
      int shift = 0;
      int result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLat = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lat += dLat;

      // Decode longitude delta
      shift = 0;
      result0 = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result0 |= (b & 0x1F) << shift;
        shift += 5;
      } while (b >= 0x20);
      final dLng = (result0 & 1) != 0 ? ~(result0 >> 1) : (result0 >> 1);
      lng += dLng;

      result.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return result;
  }
}
