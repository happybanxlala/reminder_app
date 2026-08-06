import 'package:flutter_test/flutter_test.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_commands.dart';
import 'package:reminder_app/features/shared_packs/application/shared_pack_read_models.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_ids.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_models.dart';
import 'package:reminder_app/features/shared_packs/domain/shared_pack_runtime_values.dart';

void main() {
  group('Shared value contracts', () {
    test('typed IDs use type-sensitive value equality', () {
      expect(RemotePackId('pack-1'), RemotePackId('pack-1'));
      expect(RemotePackId('pack-1'), isNot(RemotePackId('pack-2')));
      expect(RemotePackId('same'), isNot(RemoteItemId('same')));
      expect(
        ClientRequestId('123e4567-e89b-42d3-a456-426614174000'),
        ClientRequestId('123e4567-e89b-42d3-a456-426614174000'),
      );
    });

    test('IDs and versions reject invalid basic values', () {
      expect(() => RemotePackId(''), throwsArgumentError);
      expect(() => RemotePackVersion(0), throwsRangeError);
      expect(() => RemoteItemVersion(-1), throwsRangeError);
      expect(() => ClientRequestId('not-a-uuid-v4'), throwsArgumentError);
    });

    test('UTC instant rejects device-local DateTime', () {
      expect(() => UtcInstant(DateTime(2030, 1, 2)), throwsArgumentError);
      expect(
        UtcInstant(DateTime.utc(2030, 1, 2, 3, 4, 5)),
        UtcInstant(DateTime.utc(2030, 1, 2, 3, 4, 5)),
      );
    });

    test('display-name input applies the exact boundary trim contract', () {
      final input = MembershipDisplayNameInput('\u3000 小明 \u00a0');
      expect(input.value, '小明');
      expect(() => MembershipDisplayNameInput('   '), throwsArgumentError);
      expect(
        () => MembershipDisplayNameInput(List.filled(41, 'a').join()),
        throwsArgumentError,
      );
    });

    test('thresholds enforce ordered bounded state-based values', () {
      expect(
        SharedItemThresholds(
          infoAfterMinutes: 10,
          warningAfterMinutes: 20,
          dangerAfterMinutes: 30,
        ),
        SharedItemThresholds(
          infoAfterMinutes: 10,
          warningAfterMinutes: 20,
          dangerAfterMinutes: 30,
        ),
      );
      expect(
        () => SharedItemThresholds(
          infoAfterMinutes: 20,
          warningAfterMinutes: 10,
          dangerAfterMinutes: 30,
        ),
        throwsArgumentError,
      );
    });

    test('immutable read models have structural value equality', () {
      final now = UtcInstant(DateTime.utc(2030, 1, 2));
      final trust = TrustPresentation(
        trust: SharedCacheTrust.verified,
        lastVerifiedAt: now,
        canRefreshOrRecheck: true,
        mutationBlocked: false,
      );
      SharedPackListReadModel build() => SharedPackListReadModel(
        packs: [
          SharedPackListEntry(
            remotePackId: RemotePackId('pack-1'),
            title: 'Household',
            iconEmoji: '🏠',
            role: SharedRole.owner,
            trust: trust,
            lastVerifiedAt: now,
          ),
        ],
        unresolved: UnresolvedMutationPresentation(entries: const []),
      );

      expect(build(), build());
      expect(
        () => build().packs.add(
          SharedPackListEntry(
            remotePackId: RemotePackId('pack-2'),
            title: 'Other',
            iconEmoji: '📦',
            role: SharedRole.member,
            trust: trust,
            lastVerifiedAt: now,
          ),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
