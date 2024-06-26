import "package:flutter_test/flutter_test.dart";
import "package:proxima/models/ui/challenge_details.dart";

import "../../mocks/data/latlng.dart";

void main() {
  group("Challenge card data testing", () {
    test("hash overrides correctly", () {
      const challengeCard = ChallengeDetails.group(
        title: "title",
        distance: 50,
        reward: 100,
        location: latLngLocation0,
      );

      final expectedHash = Object.hash(
        challengeCard.title,
        challengeCard.distance,
        challengeCard.timeLeft,
        challengeCard.reward,
        challengeCard.location,
      );

      final actualHash = challengeCard.hashCode;

      expect(actualHash, expectedHash);
    });

    test("equality overrides correctly", () {
      const challengeCardData = ChallengeDetails.group(
        title: "title",
        distance: 50,
        reward: 100,
        location: latLngLocation0,
      );
      const challengeCardDataCopy = ChallengeDetails.group(
        title: "title",
        distance: 50,
        reward: 100,
        location: latLngLocation0,
      );

      expect(challengeCardData, challengeCardDataCopy);
    });
  });
}
