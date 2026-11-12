class BleDeviceEntity {
  final String id;
  final String name;
  final int rssi;

  const BleDeviceEntity({
    required this.id,
    required this.name,
    this.rssi = 0,
  });

  String get displayName => name.isNotEmpty ? name : "Невідомий BLE пристрій";

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BleDeviceEntity &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'BleDeviceEntity(id: $id, name: $name, rssi: $rssi)';
}
