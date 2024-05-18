import "package:application_learning_english/Homepage.dart";
import "package:application_learning_english/loginPage.dart";
import "package:application_learning_english/utils/providerTopics.dart";
import "package:flutter/material.dart";
import "package:jwt_decoder/jwt_decoder.dart";
import "package:shared_preferences/shared_preferences.dart";
import 'package:provider/provider.dart';

// void main() async {
//   runApp(MaterialApp(
//     debugShowCheckedModeBanner: false,
//     home: MyLogin(),
//     routes: {
//       'register': (context) => MyRegister(),
//       'login': (context) => MyLogin()
//     },
//   ));
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  runApp(ChangeNotifierProvider(
    create:  (context) => TopicsProvider(),
    child: MyApp(
      token: prefs.getString('token'),
    ),
  ));
}

class MyApp extends StatelessWidget {
  final token;
  const MyApp({
    @required this.token,
    Key? key,
  }) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Learning English',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primaryColor: Colors.black,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: (token != null && JwtDecoder.isExpired(token) == false)
            ? HomeScreen()
            : MyLogin());
  }
}
