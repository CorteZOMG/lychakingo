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
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Expanded(
                child: _buildLanguageDropdown(
                  value: _sourceLang,
                  hint: 'З мови',
                  onChanged: (String? newValue) {
                    setState(() {
                      _sourceLang = newValue;
                      _error = null;
                    });
                  },
                ),
              ),
              Padding( // Add padding around the icon if it feels too close
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
                const Icon(Icons.swap_horiz, size: 30),
                Padding( // Add padding around the icon if it feels too close
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
            ),
                Expanded(
                child: _buildLanguageDropdown(
                   value: _targetLang,
                   hint: 'На мову',
                   onChanged: (String? newValue) {
                    setState(() {
                      _targetLang = newValue;
                      _error = null;
                    });
                  },
                ),
                ),
              ],
            ),
            const SizedBox(height: 20),
       
            TextField(
              controller: _textEditingController,
              style: const TextStyle(
              color: Colors.black, 
              fontSize: 16, 
            ),

              decoration: InputDecoration(
                hintText: 'Введіть текст який бажаєте перекласти',
                filled: true,
                fillColor: Colors.white,  
                enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0), // Adjust radius as you like
                borderSide: BorderSide(
                  color: Colors.grey.shade400, // Color for the border when enabled
                  width: 1.0,
                ),
              ),
              // Border when the field is focused
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0), // Keep radius consistent
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary, // Use theme's primary color for focus
                  width: 2.0, // Make border thicker on focus
                ),
              ),
              // You might also want to define 'border' for a general case or 'errorBorder'
              // For a simpler setup if you want the same border always (just color changes on focus):
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
                // borderSide: BorderSide.none, // Use this if you only want the fill and no visible border line
              ),
              // Ensure content padding is appropriate for the new border
              contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0)
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
                padding: const EdgeInsets.all(16.0), // Adjusted padding for a bit more space inside
                decoration: BoxDecoration(
                  color: Colors.white, // Set background to white
                  borderRadius: BorderRadius.circular(12.0), // Set desired border radius
                  border: Border.all(
                    color: Colors.grey.shade300, // Softer grey border color
                    width: 1.0,
                  ),
                  // You could add a subtle shadow if you like:
                  // boxShadow: [
                  //   BoxShadow(
                  //     color: Colors.grey.withOpacity(0.2),
                  //     spreadRadius: 1,
                  //     blurRadius: 3,
                  //     offset: Offset(0, 1),
                  //   ),
                  // ],
                ),
                child: SingleChildScrollView( // Good for long translated text
                  child: SelectableText(
                    _outputText,
                    style: const TextStyle(
                      fontSize: 16.0,
                      color: Colors.black87, // Set text color to black (or Colors.black)
                    ),
                  ),
                ),
              ),
            ),
          ],
      ),
    );
  }
  
    Widget _buildLanguageDropdown({
        required String? value,
        required String hint,
        required ValueChanged<String?> onChanged,
      }) {

        final TextStyle menuItemStyle = TextStyle(
          color: Colors.black87, 
          fontSize: 16,
        );

        final TextStyle hintStyle = TextStyle(
          color: Colors.white70, 
          fontSize: 16,
        );

        final TextStyle mainSelectedItemStyle = TextStyle(
          color: Colors.white, 
          fontSize: 16,
          fontWeight: FontWeight.w500,
        );

        return DropdownButton<String>(
          value: value,
          hint: Text(hint, style: hintStyle),
          isExpanded: true, 
          iconSize: 28,
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white), 

          selectedItemBuilder: (BuildContext context) {
            return supportedLanguages.map<Widget>((Map<String, String> item) {
              return DropdownMenuItem<String>(
                value: item['code']!,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    item['name']!,
                    style: mainSelectedItemStyle, 
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              );
            }).toList();
          },

          underline: Container( 
            height: 1,
            color: Colors.white,
          ),

          dropdownColor: Colors.white, 
          onChanged: onChanged,
          items: supportedLanguages.map<DropdownMenuItem<String>>((Map<String, String> lang) {
            return DropdownMenuItem<String>(
              value: lang['code']!,
              child: Text(lang['name']!, style: menuItemStyle), 
            );
          }).toList(),
        ); 
    }
}