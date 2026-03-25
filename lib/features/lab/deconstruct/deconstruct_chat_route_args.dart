/// [GoRouter] `extra` for `/deconstruct-chat`
class DeconstructChatRouteArgs {
  final String? targetModuleId;
  final bool isTutorialMode;
  final String? tutorialStep;

  const DeconstructChatRouteArgs({
    this.targetModuleId,
    this.isTutorialMode = false,
    this.tutorialStep,
  });
}
