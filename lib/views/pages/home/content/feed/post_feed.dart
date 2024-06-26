import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:proxima/viewmodels/posts_feed_view_model.dart";
import "package:proxima/views/components/async/circular_value.dart";
import "package:proxima/views/components/async/error_refresh_page.dart";
import "package:proxima/views/components/options/feed/feed_sort_option_chips.dart";
import "package:proxima/views/helpers/types/result.dart";
import "package:proxima/views/navigation/routes.dart";
import "package:proxima/views/pages/home/content/feed/components/post_list.dart";

/// This widget is the feed of the home page
/// It contains the posts
class PostFeed extends ConsumerWidget {
  static const feedSortOptionKey = Key("feedSortOption");

  static const refreshButtonKey = Key("refreshButton");
  static const feedKey = Key("feed");
  static const emptyfeedKey = Key("emptyFeed");
  static const newPostButtonTextKey = Key("newPostButtonTextKey");

  const PostFeed({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPosts = ref.watch(postsFeedViewModelProvider.future).mapRes();

    final newPostButton = InkWell(
      onTap: () {
        Navigator.pushNamed(context, Routes.newPost.name);
      },
      child: const Text(
        key: newPostButtonTextKey,
        "create one!",
        style: TextStyle(color: Colors.blue),
      ),
    );

    final onRefresh = ref.read(postsFeedViewModelProvider.notifier).refresh;
    final refreshButton = ElevatedButton(
      key: refreshButtonKey,
      onPressed: onRefresh,
      child: const Text("Refresh"),
    );

    final emptyHelper = Center(
      key: emptyfeedKey,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text("No post in this area, "),
              newPostButton,
            ],
          ),
          const SizedBox(height: 10),
          refreshButton,
        ],
      ),
    );

    return Column(
      children: [
        const FeedSortOptionChips(
          key: feedSortOptionKey,
        ),
        const Divider(),
        Expanded(
          child: CircularValue(
            future: asyncPosts,
            builder: (context, posts) {
              final postsList = PostList(
                posts: posts,
                onRefresh: onRefresh,
              );

              return posts.isEmpty ? emptyHelper : postsList;
            },
            fallbackBuilder: (context, error) {
              return ErrorRefreshPage(
                onRefresh: onRefresh,
              );
            },
          ),
        ),
      ],
    );
  }
}
