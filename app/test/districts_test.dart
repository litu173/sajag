import 'package:flutter_test/flutter_test.dart';
import 'package:sajag/core/districts.dart';

void main() {
  test('64 districts', () => expect(districtIds, hasLength(64)));

  test('geocoder names map to district ids', () {
    expect(districtIdFromName('Dhaka District'), 'dhaka');
    expect(districtIdFromName('Chittagong'), 'chattogram');
    expect(districtIdFromName("Cox's Bazar"), 'coxs-bazar');
    expect(districtIdFromName('Jessore Zila'), 'jashore');
    expect(districtIdFromName('যশোর জেলা'), 'jashore');
    expect(districtIdFromName('Gulshan'), isNull);
    expect(districtIdFromName(null), isNull);
  });
}
