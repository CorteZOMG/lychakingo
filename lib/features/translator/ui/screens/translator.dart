import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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

  Future<void> _translateText() async {
    
    if (_textEditingController.text.isEmpty || _sourceLang == null || _targetLang == null) {
      setState(() {
        _error = "Please enter text and select languages.";
        _outputText = '';
      });
      return;
    }
    if (_sourceLang == _targetLang) {
       setState(() {
        _error = "Source and target languages must be different.";
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
          
          'text': _textEditingController.text,
          'source_lang': _sourceLang,
          'target_lang': _targetLang,
        }),
      );

      if (!mounted) return;
      if (response.statusCode == 200) {
        
        final responseBody = jsonDecode(response.body);
        
        setState(() {
          _outputText = responseBody['translated_text'] ?? 'No translation received.';
        });
      } else {
        
        print('Backend Error: ${response.statusCode} ${response.body}');
        
        String serverErrorMsg = response.body;
        try {
          final errorBody = jsonDecode(response.body);
          
          serverErrorMsg = errorBody['error'] ?? errorBody['message'] ?? response.body;
        } catch (_) {
          
        }
        setState(() {
          _error = 'Error translating (${response.statusCode}): $serverErrorMsg';
        });
      }
    } catch (e) {  
      if (!mounted) return;
      print('Network/Request Error: $e');
      setState(() {
        _error = 'Failed to connect. Please check your connection or the URL.';
      });
    } finally {
      
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
        title: const Text('Translator'),
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
                  hint: 'Source Language',
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
                   hint: 'Target Language',
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
                hintText: 'Enter text to translate...',
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
                  : const Text('Translate'),
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