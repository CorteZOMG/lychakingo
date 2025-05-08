import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lychakingo/features/translator/ui/screens/translation_history_screen.dart';

const List<Map<String, String>> supportedLanguages = [
  {'code': 'UK', 'name': 'Ukrainian'},
  {'code': 'EN-US', 'name': 'English'}, 
  {'code': 'DE', 'name': 'German'},
  {'code': 'FR', 'name': 'French'},
  {'code': 'ES', 'name': 'Spanish'},
  {'code': 'JA', 'name': 'Japanese'},
];

const String deepLFunctionUrl = 'https://translate-text-dep6ecqopa-ew.a.run.app';

class TranslationScreen extends StatefulWidget {
  const TranslationScreen({super.key});

  @override
  State<TranslationScreen> createState() => _TranslationScreenState();
}

class _TranslationScreenState extends State<TranslationScreen> {
  final TextEditingController _textEditingController = TextEditingController();
  
  String? _sourceLang = 'EN-US'; 
  String? _targetLang = 'UK';    
  String _outputText = '';
  bool _isLoading = false;
  String? _error;

  
  Future<void> _saveTranslationHistory(String inputText, String outputText, String? sourceLang, String? targetLang, String? errorMsg) async {
     final String? userId = FirebaseAuth.instance.currentUser?.uid;
     
     if (userId == null || sourceLang == null || targetLang == null || inputText.isEmpty) {
        print("Cannot save translation history: Missing user ID, languages, or input text.");
        return;
     }

     try {
        await FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'main-db') 
           .collection('userHistories')
           .doc(userId)
           .collection('translationHistory')
           .add({
             'inputText': inputText,
             'outputText': outputText, 
             'sourceLang': sourceLang,
             'targetLang': targetLang,
             'error': errorMsg, 
             'timestamp': FieldValue.serverTimestamp(), 
           });
       print("Translation history saved successfully.");
     } catch (e) {
       print("Error saving translation history: $e");   
     }
  }
  

  Future<void> _translateText() async {
    final String inputText = _textEditingController.text;
    final String? sourceLangForHistory = _sourceLang;
    final String? targetLangForHistory = _targetLang;
    String finalOutput = ''; 
    String? errorForHistory; 
    
    if (inputText.isEmpty || sourceLangForHistory == null || targetLangForHistory == null) {
      setState(() {
        _error = "Введіть текст та оберіть мови.";
        _outputText = '';
      });
      return;
    }
    if (sourceLangForHistory == targetLangForHistory) {
       setState(() {
        _error = "Мови повинні бути різні.";
        _outputText = '';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
      _outputText = '';
    });

    try {
      
      final response = await http.post(
        Uri.parse(deepLFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': inputText, 
          'source_lang': sourceLangForHistory, 
          'target_lang': targetLangForHistory, 
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        
        final responseBody = jsonDecode(response.body);
        setState(() {
          _outputText = responseBody['translated_text'] ?? 'Не отримано результат.';
          finalOutput = _outputText; 
        });
      } else {
        
        print('Backend Error: ${response.statusCode} ${response.body}');
        String serverErrorMsg = response.body;
        try {
          final errorBody = jsonDecode(response.body);
          serverErrorMsg = errorBody['error'] ?? errorBody['message'] ?? response.body;
        } catch (_) {}
        setState(() {
          _error = 'Error translating (${response.statusCode}): $serverErrorMsg';
          errorForHistory = _error; 
        });
      }
    } catch (e) {
       
       if (!mounted) return;
       print('Network/Request Error: $e');
       setState(() {
         _error = 'Failed to connect. Please check your connection.';
         errorForHistory = _error; 
       });
    } finally {
       
       await _saveTranslationHistory(
           inputText,
           finalOutput, 
           sourceLangForHistory,
           targetLangForHistory,
           errorForHistory 
       );
       
       if (mounted) {
         setState(() {
           _isLoading = false;
         });
       }
    }
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
      
    return Scaffold(
      appBar: AppBar(
         automaticallyImplyLeading: false,
         title: const Text('Перекладач'),
      ),
      
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                _buildLanguageDropdown(
                  value: _sourceLang,
                  hint: 'З мови',
                  onChanged: (String? newValue) {
                    setState(() {
                      _sourceLang = newValue;
                      _error = null;
                    });
                  },
                ),
                const Icon(Icons.swap_horiz, size: 30),
                _buildLanguageDropdown(
                   value: _targetLang,
                   hint: 'На мову',
                   onChanged: (String? newValue) {
                    setState(() {
                      _targetLang = newValue;
                      _error = null;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
       
            TextField(
              controller: _textEditingController,
              decoration: const InputDecoration(
                hintText: 'Введіть текст який бажаєте перекласти',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
              onChanged: (_) => setState(() { _error = null; }),
            ),
            const SizedBox(height: 20),
            
            ElevatedButton(
              onPressed: _isLoading ? null : _translateText,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
                    )
                  : const Text('Перекласти'),
            ),
            const SizedBox(height: 10),
            
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            const SizedBox(height: 10),

          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Історія',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TranslationHistoryScreen()),
              );
            },
          ),

            Expanded(
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(4.0),
                  color: Colors.grey[100],
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    _outputText,
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildLanguageDropdown({
      required String? value,
      required String hint,
      required ValueChanged<String?> onChanged,
  }) {
    return DropdownButton<String>(
      value: value,
      hint: Text(hint),
      onChanged: onChanged,
      items: supportedLanguages.map<DropdownMenuItem<String>>((Map<String, String> lang) {
        return DropdownMenuItem<String>(
          value: lang['code']!,
          child: Text(lang['name']!),
        );
      }).toList(),
    );
  }
}