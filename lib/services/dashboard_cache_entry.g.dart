// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dashboard_cache_entry.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DashboardCacheEntryAdapter extends TypeAdapter<DashboardCacheEntry> {
  @override
  final int typeId = 0;

  @override
  DashboardCacheEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DashboardCacheEntry(
      data: (fields[0] as Map).cast<String, dynamic>(),
      fetchedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, DashboardCacheEntry obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.data)
      ..writeByte(1)
      ..write(obj.fetchedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DashboardCacheEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
