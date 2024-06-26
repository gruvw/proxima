import "package:flutter/material.dart";
import "package:proxima/models/ui/post_details.dart";
import "package:proxima/views/pages/create_account/create_account_page.dart";
import "package:proxima/views/pages/home/home_page.dart";
import "package:proxima/views/pages/login/login_page.dart";
import "package:proxima/views/pages/new_post/new_post_page.dart";
import "package:proxima/views/pages/post/post_page.dart";
import "package:proxima/views/pages/profile/profile_page.dart";

enum Routes {
  home("home"),
  login("login"),
  profile("profile"),
  newPost("new post"),
  createAccount("createAccount"),
  post("post");

  final String name;

  const Routes(this.name);

  static Routes parse(String name) {
    return Routes.values.firstWhere((r) => r.name == name);
  }

  Widget page(Object? args) {
    switch (this) {
      case home:
        return const HomePage();
      case login:
        return const LoginPage();
      case profile:
        return const ProfilePage();
      case newPost:
        return const NewPostPage();
      case createAccount:
        return const CreateAccountPage();
      case post:
        if (args is PostDetails) {
          return PostPage(postDetails: args);
        } else {
          throw Exception("PostDetails object required");
        }
    }
  }
}

Route generateRoute(RouteSettings settings) {
  final route = Routes.parse(settings.name!);

  return MaterialPageRoute(builder: (_) => route.page(settings.arguments));
}
