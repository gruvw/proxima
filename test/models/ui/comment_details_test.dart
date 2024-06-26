import "package:flutter_test/flutter_test.dart";

import "../../mocks/data/post_comment.dart";

void main() {
  group("Comment Post testing", () {
    test("hash overrides correctly", () {
      final commentPost = testComments[0];

      final expectedHash = Object.hash(
        commentPost.content,
        commentPost.ownerDisplayName,
        commentPost.ownerUsername,
        commentPost.ownerUserID,
        commentPost.ownerCentauriPoints,
        commentPost.publicationDate,
      );

      final actualHash = commentPost.hashCode;

      expect(actualHash, expectedHash);
    });

    test("equality overrides correctly", () {
      final commentPost = unequalComments[0];
      final commentPostCopy = unequalComments[0];

      expect(commentPost, commentPostCopy);
    });

    test("inequality test on content", () {
      final commentPost = unequalComments[0];
      final commentPostOther = unequalComments[1];

      expect(commentPost, isNot(equals(commentPostOther)));
    });

    test("inequality test on username", () {
      final commentPost = unequalComments[0];
      final commentPostOther = unequalComments[2];

      expect(commentPost, isNot(equals(commentPostOther)));
    });

    test("inequality test on publication time", () {
      final commentPost = unequalComments[0];
      final commentPostOther = unequalComments[3];

      expect(commentPost, isNot(equals(commentPostOther)));
    });

    test("inequality test on owner ID", () {
      final commentPost = unequalComments[0];
      final commentPostOther = unequalComments[4];

      expect(commentPost, isNot(equals(commentPostOther)));
    });
  });
}
