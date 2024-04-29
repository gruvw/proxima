import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/models/ui/challenge_card_data.dart";

// TODO: For now, this is duplicated code with the mock from the tests.
// This will just be replaced when we implement a real view model anyway.
class ChallengeViewModel extends AsyncNotifier<List<ChallengeCardData>> {
  @override
  Future<List<ChallengeCardData>> build() async {
    return const [
      ChallengeCardData.solo(
        title: "I hate UNIL, here's why",
        distance: 700,
        timeLeft: 27,
        reward: 250,
      ),
      ChallengeCardData.solo(
        title:
            "John fell here lmaoooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooooo",
        distance: 3200,
        timeLeft: 27,
        reward: 400,
      ),
      ChallengeCardData.group(
        title: "I'm moving out",
        distance: 4000,
        reward: 350,
      ),
      ChallengeCardData.soloFinished(
        title: "What a view!",
        timeLeft: 27,
        reward: 200,
      ),
    ];
  }
}

final challengeProvider =
    AsyncNotifierProvider<ChallengeViewModel, List<ChallengeCardData>>(
  () => ChallengeViewModel(),
);