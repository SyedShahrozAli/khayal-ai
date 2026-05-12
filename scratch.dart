import 'package:google_sign_in/google_sign_in.dart';

void main() async {
  final GoogleSignIn googleSignIn = GoogleSignIn;();
  final account = await googleSignIn.signIn();
}
