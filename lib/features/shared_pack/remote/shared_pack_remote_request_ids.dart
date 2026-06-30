class SharedPackRemoteRequestIds {
  const SharedPackRemoteRequestIds._();

  static const createPackV1 = 'shared_pack.create_pack.v1';
  static const generateInviteV1 = 'shared_pack.generate_invite.v1';
  static const previewInviteV1 = 'shared_pack.preview_invite.v1';
  static const joinByInviteV1 = 'shared_pack.join_by_invite.v1';
  static const fetchSnapshotV1 = 'shared_pack.fetch_snapshot.v1';
  static const updateItemStateV1 = 'shared_pack.update_item_state.v1';

  static const all = <String>[
    createPackV1,
    generateInviteV1,
    previewInviteV1,
    joinByInviteV1,
    fetchSnapshotV1,
    updateItemStateV1,
  ];
}
