import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; 
import 'dart:convert'; 

class AiQaScreen extends StatefulWidget {
  const AiQaScreen({super.key});

  @override
  State<AiQaScreen> createState() => _AiQaScreenState();
}

class _AiQaScreenState extends State<AiQaScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController(); 

  String _aiAnswer = ''; 
  String? _errorMessage; 
  bool _isLoading = false; 

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askAI() async {
    if (_questionController.text.trim().isEmpty) {
      setState(() {
         _errorMessage = "Please enter a question.";
         _aiAnswer = ''; 
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null; 
      _aiAnswer = ''; 
    });

    const String cloudFunctionUrl = 'https://europe-west1-lychakingo-b1a79.cloudfunctions.net/ask_ai_tutor';

    try {
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'question': _questionController.text.trim(), 
        }),
      );

      if (!mounted) return; 

      if (response.statusCode == 200) {
        // {'answer': 'The AI response'}
        final responseBody = jsonDecode(response.body);
        setState(() {
          _aiAnswer = responseBody['answer'] ?? 'No answer received.';
          _questionController.clear(); 
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
           if (_scrollController.hasClients) {
              _scrollController.animateTo(
                 _scrollController.position.maxScrollExtent,
                 duration: const Duration(milliseconds: 300),
                 curve: Curves.easeOut,
              );
           }
        });
      } else {
        print('Cloud Function Error: ${response.statusCode} ${response.body}');
        setState(() {
          _errorMessage = 'Error getting answer (${response.statusCode}). Please try again.';
        });
      }
    } catch (e) {
       if (!mounted) return;
      print('Network/Request Error: $e');
      setState(() {
        _errorMessage = 'Failed to connect. Please check your connection.';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ask Artem Lychak'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // scrollable
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Container(
                  padding: const EdgeInsets.all(12.0),
                  width: double.infinity,
                  decoration: BoxDecoration(
                      color: Colors.grey[200], 
                      borderRadius: BorderRadius.circular(8.0)
                  ),
                  child: _aiAnswer.isEmpty && _errorMessage == null && !_isLoading
                      ? const Text('Ask a language question below!', textAlign: TextAlign.center,) 
                      : _isLoading && _aiAnswer.isEmpty 
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage != null
                              ? Text(_errorMessage!, style: const TextStyle(color: Colors.red))
                              : Text(_aiAnswer),
                ),
              ),
            ),
            const SizedBox(height: 16.0), 

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    decoration: InputDecoration(
                      hintText: 'What is Present Simple?',
                      border: OutlineInputBorder(
                         borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                    onSubmitted: (_) => _askAI(), 
                  ),
                ),
                const SizedBox(width: 8.0), 

                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isLoading ? null : _askAI, 
                  style: IconButton.styleFrom(
                     backgroundColor: Theme.of(context).colorScheme.primary,
                     foregroundColor: Theme.of(context).colorScheme.onPrimary,
                     padding: const EdgeInsets.all(12),
                     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                  ),
                  tooltip: 'Ask Artem Lychak',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
