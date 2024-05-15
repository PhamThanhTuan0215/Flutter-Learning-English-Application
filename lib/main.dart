import "package:application_learning_english/loginPage.dart";
import "package:application_learning_english/registration.dart";
import "package:flutter/material.dart";

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: MyLogin(),
    routes: {
      'register': (context) => MyRegister(),
      'login': (context) => MyLogin()
    },
  ));
}
