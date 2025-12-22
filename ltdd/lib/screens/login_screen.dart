// Updated: lib/screens/login_screen.dart - Cinema Classic Theme
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/database_services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegister = false;

  Future<void> _authAction() async {
    try {
      UserCredential cred;
      if (_isRegister) {
        cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
        UserModel user = UserModel(
          id: cred.user!.uid,
          name: 'New User',
          email: _emailController.text,
          role: 'user',
        );
        await DatabaseService().saveUser(user);
      } else {
        cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo?.isNewUser ?? false) {
        UserModel user = UserModel(
          id: userCredential.user!.uid,
          name: googleUser.displayName ?? 'New User',
          email: googleUser.email,
          role: 'user',
        );
        await DatabaseService().saveUser(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          color: Color(0xFF1a1a1a),
        ),
        child: Stack(
          children: [
            // Film reel borders
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildFilmStrip(),
            ),
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildFilmStrip(),
            ),
            // Main content
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 60.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo với film reel icon
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Color(0xFFD4AF37), width: 3),
                        ),
                        child: Icon(
                          Icons.movie_filter,
                          size: 60,
                          color: Color(0xFFD4AF37),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        'Cinema',
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 4,
                          fontFamily: 'serif',
                        ),
                      ),
                      Text(
                        'Ticket',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w300,
                          color: Color(0xFFD4AF37),
                          letterSpacing: 8,
                          fontFamily: 'serif',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Buy Your Ticket Now',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFFB8941E),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 50),
                      // Email TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFD4AF37), width: 1),
                        ),
                        child: TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Email',
                            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            prefixIcon: Icon(Icons.email_outlined, color: Color(0xFFD4AF37)),
                          ),
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Password TextField
                      Container(
                        decoration: BoxDecoration(
                          color: Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Color(0xFFD4AF37), width: 1),
                        ),
                        child: TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            labelStyle: TextStyle(color: Color(0xFFD4AF37)),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            prefixIcon: Icon(Icons.lock_outline, color: Color(0xFFD4AF37)),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Login/Register Button
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFFD4AF37),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFFD4AF37).withOpacity(0.3),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _authAction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Text(
                            _isRegister ? 'SIGN UP' : 'SIGN IN',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1a1a1a),
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Toggle Register/Login
                      TextButton(
                        onPressed: () => setState(() => _isRegister = !_isRegister),
                        child: Text(
                          _isRegister ? 'Already have account? Sign In' : 'Don\'t have account? Sign Up',
                          style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Divider
                      Row(
                        children: [
                          Expanded(child: Divider(color: Color(0xFFD4AF37).withOpacity(0.3))),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(color: Color(0xFFD4AF37).withOpacity(0.5)),
                            ),
                          ),
                          Expanded(child: Divider(color: Color(0xFFD4AF37).withOpacity(0.3))),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // Google Sign In
                      Container(
                        width: double.infinity,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Color(0xFF2a2a2a),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: Color(0xFFD4AF37), width: 1),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          icon: Image.network(
                            'https://www.google.com/images/branding/googlelogo/1x/googlelogo_color_272x92dp.png',
                            height: 20,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.g_mobiledata, color: Color(0xFFD4AF37)),
                          ),
                          label: Text(
                            'Sign in with Google',
                            style: TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilmStrip() {
    return Container(
      width: 40,
      color: Color(0xFFD4AF37),
      child: Column(
        children: List.generate(
          50,
              (index) => Container(
            margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            height: 15,
            decoration: BoxDecoration(
              color: Color(0xFF1a1a1a),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
      ),
    );
  }
}