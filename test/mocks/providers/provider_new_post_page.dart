import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/services/database/post_repository_service.dart";
import "package:proxima/services/sensors/geolocation_service.dart";
import "package:proxima/viewmodels/login_view_model.dart";
import "package:proxima/views/pages/new_post/new_post_page.dart";

import "../data/firestore_user.dart";
import "../overrides/override_firestore.dart";
import "../services/mock_geo_location_service.dart";
import "../services/mock_post_repository_service.dart";

ProviderScope newPostPageProvider(
  MockPostRepositoryService postRepository,
  MockGeolocationService geoLocationService,
) {
  return ProviderScope(
    overrides: [
      ...firebaseMocksOverrides,
      postRepositoryServiceProvider.overrideWithValue(postRepository),
      geolocationServiceProvider.overrideWithValue(geoLocationService),
      loggedInUserIdProvider.overrideWithValue(testingUserFirestoreId),
    ],
    child: const MaterialApp(
      title: "New post page",
      home: NewPostPage(),
    ),
  );
}
