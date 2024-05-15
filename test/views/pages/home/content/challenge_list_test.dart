import "package:flutter_test/flutter_test.dart";
import "package:proxima/views/pages/home/content/challenge/challenge_card.dart";
import "package:proxima/views/pages/home/content/challenge/challenge_list.dart";

import "../../../../mocks/data/challenge_list.dart";
import "../../../../mocks/providers/provider_challenge.dart";
import "../../../../testutils/expect_rich_text.dart";

void main() {
  group(
    "Static testing",
    () {
      testWidgets(
        "Check that there is the correct number of cards, with the correct icons",
        (tester) async {
          const data = mockChallengeList;

          await tester.pumpWidget(mockedChallengeListProvider);
          await tester.pumpAndSettle();

          expect(find.byType(ChallengeList), findsOneWidget);
          expect(find.byType(ChallengeCard), findsNWidgets(data.length));

          final nGroupChallenge =
              data.where((challenge) => challenge.isGroupChallenge).length;
          expect(
            find.byKey(ChallengeCard.challengeGroupIconKey),
            findsNWidgets(nGroupChallenge),
          );

          final nSingleChallenge =
              data.where((challenge) => !challenge.isGroupChallenge).length;
          expect(
            find.byKey(ChallengeCard.challengeSingleIconKey),
            findsNWidgets(nSingleChallenge),
          );

          // Challenges can either be single or group
          expect(nSingleChallenge + nGroupChallenge, data.length);
        },
      );

      testWidgets("Check that the correct data is displayed", (tester) async {
        await tester.pumpWidget(mockedChallengeListProvider);
        await tester.pumpAndSettle();

        for (final challenge in mockChallengeList) {
          expect(find.text(challenge.title), findsOneWidget);

          if (challenge.isFinished) {
            expectRichText("Challenged finished!", findsAtLeastNWidgets(1));
          } else {
            expectRichText(
              "Distance to post: ${challenge.distance} meters",
              findsOneWidget,
            );
          }
          expectRichText(
            "Reward: ${challenge.reward} Centauri",
            findsOneWidget,
          );

          if (!challenge.isGroupChallenge) {
            expectRichText(
              "Time left: ${challenge.timeLeft} hours",
              findsOneWidget,
            );
          }
        }
      });
    },
  );
}