import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lychakingo/features/authentication/ui/widgets/register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _auth = FirebaseAuth.instance;

  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Вхід успішний!')),
        );
        
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        _errorMessage = 'Неправильна пошта або пароль.'; 
      } else {
        _errorMessage = 'Виникла помилка. Будь ласка, спробуйте ще раз.'; 
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      _errorMessage = 'Виникла непередбачена помилка.'; 
      print('Sign In Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    const TextStyle whiteTextStyle = TextStyle(color: Colors.white);
    const TextStyle whiteHintStyle = TextStyle(color: Colors.white70);
    const TextStyle whiteErrorStyle = TextStyle(color: Colors.white70);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Логін'), 
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextFormField(
                  controller: _emailController,
                  style: whiteTextStyle, 
                  decoration: const InputDecoration(
                    labelText: 'Ел. пошта',
                    labelStyle: whiteHintStyle, 
                    errorStyle: whiteErrorStyle, 
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty || !value.contains('@')) {
                      return 'Будь ласка, введіть коректну пошту';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _passwordController,
                  style: whiteTextStyle, 
                  decoration: const InputDecoration(
                    labelText: 'Пароль',
                    labelStyle: whiteHintStyle, 
                    errorStyle: whiteErrorStyle, 
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 6) {
                      return 'Пароль повинен містити щонайменше 6 символів';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24.0),
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                    : ElevatedButton(
                        onPressed: _signIn,
                        child: const Text('Login'), 
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {
                    
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const RegisterScreen(),
                    ));
                  },
                  child: const Text('Немає акаунту? Зареєструйтесь'), 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}