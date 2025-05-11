import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  String? _errorMessage;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      if (userCredential.user != null) {
        await _firestore.collection('users').doc(userCredential.user!.uid).set({
          'email': userCredential.user!.email,
          'createdAt': FieldValue.serverTimestamp(),
          'points': 0,
          'streak': 0,
          'completedLessons': [],
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Реєстрація успішна!')),
        );        
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        _errorMessage = 'Пароль занадто слабкий.';
      } else if (e.code == 'email-already-in-use') {
        _errorMessage = 'Ця пошта вже використовується.';
      } else {
        _errorMessage = 'Виникла помилка.';
        print('Firebase Auth Error: ${e.code} - ${e.message}');
      }
    } catch (e) {
      _errorMessage = 'Виникла помилка.';
      print('Registration Error: $e');
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
        title: const Text('Реєстрація'), 
        
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
                      return 'Введіть коректну пошту.';
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
                      return 'Пароль повинен містити щонайменше 6 символів.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16.0),
                TextFormField(
                  controller: _confirmPasswordController,
                  style: whiteTextStyle,
                  decoration: const InputDecoration(
                    labelText: 'Підтвердіть пароль',
                    labelStyle: whiteHintStyle,
                    errorStyle: whiteErrorStyle,
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Підтвердіть пароль';
                    }
                    if (value != _passwordController.text) {
                      return 'Паролі не сходяться';
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
                      style: const TextStyle(color: Colors.red), 
                      textAlign: TextAlign.center,
                    ),
                  ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Colors.white)) 
                    : ElevatedButton(
                        onPressed: _register,
                        child: const Text('Реєстрація'), 
                      ),
                const SizedBox(height: 16.0),
                TextButton(
                  onPressed: () {          
                    Navigator.of(context).pop();
                  },
                  child: const Text('Вже маєте акаунт? Увійдіть'), 
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}