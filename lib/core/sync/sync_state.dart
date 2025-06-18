import 'package:hive/hive.dart';

part 'sync_state.g.dart';

@HiveType(typeId: 1)
enum SyncState {
  @HiveField(0)
  synced,
  @HiveField(1)
  updated,
  @HiveField(2)
  deleted,
  @HiveField(3)
  pending;

  bool get isSynced => this == SyncState.synced;
  bool get isUpdated => this == SyncState.updated;
  bool get isDeleted => this == SyncState.deleted;
  bool get isPending => this == SyncState.pending;

  @override
  String toString() {
    return name;
  }
}
