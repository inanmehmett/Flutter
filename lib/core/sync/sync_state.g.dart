// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_state.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncStateAdapter extends TypeAdapter<SyncState> {
  @override
  final int typeId = 1;

  @override
  SyncState read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncState.synced;
      case 1:
        return SyncState.updated;
      case 2:
        return SyncState.deleted;
      case 3:
        return SyncState.pending;
      default:
        return SyncState.synced;
    }
  }

  @override
  void write(BinaryWriter writer, SyncState obj) {
    switch (obj) {
      case SyncState.synced:
        writer.writeByte(0);
        break;
      case SyncState.updated:
        writer.writeByte(1);
        break;
      case SyncState.deleted:
        writer.writeByte(2);
        break;
      case SyncState.pending:
        writer.writeByte(3);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
