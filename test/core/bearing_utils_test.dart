import 'package:flutter_test/flutter_test.dart';

import 'package:geo_navigation/core/utils/bearing_utils.dart';

void main() {
  test('normalise returns values in the canonical range', () {
    expect(BearingUtils.normalise(-1), 359);
    expect(BearingUtils.normalise(360), 0);
  });

  test('interpolate follows the shortest path across north', () {
    expect(BearingUtils.interpolate(359, 1, 0.5), 0);
    expect(BearingUtils.interpolate(1, 359, 0.5), 0);
  });
}
