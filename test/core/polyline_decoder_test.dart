import 'package:flutter_test/flutter_test.dart';

import 'package:geo_navigation/core/utils/polyline_decoder.dart';

void main() {
  test('decodes the standard Google polyline example', () {
    final points = PolylineDecoder.decode('_p~iF~ps|U_ulLnnqC_mqNvxq`@');

    expect(points, hasLength(3));
    expect(points[0].latitude, closeTo(38.5, 0.00001));
    expect(points[0].longitude, closeTo(-120.2, 0.00001));
    expect(points[1].latitude, closeTo(40.7, 0.00001));
    expect(points[1].longitude, closeTo(-120.95, 0.00001));
    expect(points[2].latitude, closeTo(43.252, 0.00001));
    expect(points[2].longitude, closeTo(-126.453, 0.00001));
  });

  test('empty and null polylines decode to no points', () {
    expect(PolylineDecoder.decode(null), isEmpty);
    expect(PolylineDecoder.decode(''), isEmpty);
  });
}
