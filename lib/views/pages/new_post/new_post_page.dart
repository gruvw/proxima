import "package:flutter/material.dart";
import "package:proxima/views/navigation/leading_back_button/leading_back_button.dart";

import "package:proxima/views/pages/new_post/new_post_form.dart";

class NewPostPage extends StatelessWidget {
  const NewPostPage({super.key});

  static const _pageTitle = "Create a new post";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(_pageTitle),
        leading: const LeadingBackButton(),
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Center(
          child: NewPostForm(),
        ),
      ),
    );
  }
}
