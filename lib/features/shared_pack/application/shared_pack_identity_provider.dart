abstract class SharedPackIdentityProvider {
  Future<String> currentIdentityId();
}

class StaticSharedPackIdentityProvider implements SharedPackIdentityProvider {
  const StaticSharedPackIdentityProvider(this.identityId);

  final String identityId;

  @override
  Future<String> currentIdentityId() async => identityId;
}
