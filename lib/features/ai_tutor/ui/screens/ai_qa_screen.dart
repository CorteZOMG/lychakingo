import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AiQaScreen extends StatefulWidget {
  const AiQaScreen({super.key});

  @override
  State<AiQaScreen> createState() => _AiQaScreenState();
}

class _AiQaScreenState extends State<AiQaScreen> {
  final _questionController = TextEditingController();
  final _scrollController = ScrollController(); 
  bool _isLoading = false; 
  final String? userId = FirebaseAuth.instance.currentUser?.uid; 

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  Future<void> _saveAiHistory(String question, String answer, String? errorMsg) async {
    if (userId == null) {
      print("User not logged in, cannot save AI history.");
      return;
    }
    try {
      await FirebaseFirestore.instanceFor(
          app: Firebase.app(), databaseId: 'main-db') 
          .collection('userHistories')
          .doc(userId)
          .collection('aiHistory')
          .add({
            'question': question,
            'answer': answer,
            'error': errorMsg,
            'timestamp': FieldValue.serverTimestamp(),
          });
      print("AI history saved successfully.");
    } catch (e) {
      print("Error saving AI history: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Історія недоступна: $e"),
            duration: const Duration(seconds: 2)));
      }
    }
  }

  void _scrollToBottom() {
     WidgetsBinding.instance.addPostFrameCallback((_) {
       if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  
  Future<void> _askAI() async {
    final String questionText = _questionController.text.trim();
    if (questionText.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Будь ласка, задайте питання."), duration: Duration(seconds: 2))
       );
      return;
    }
    
    _questionController.clear(); 
    String finalAnswer = ''; 
    String? errorForHistory; 
    setState(() { _isLoading = true; }); 
    
    List<Map<String, dynamic>> chatHistoryForApi = [];
    if (userId != null) {
      print("Fetching recent chat history...");
      try {
        
        const int historyLimit = 5; 

        final historySnapshot = await FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'main-db')
            .collection('userHistories')
            .doc(userId)
            .collection('aiHistory')
            .orderBy('timestamp', descending: true) 
            .limit(historyLimit)
            .get();
        
        for (var doc in historySnapshot.docs.reversed) {
          var data = doc.data();
          final String? storedQuestion = data['question'] as String?;
          final String? storedAnswer = data['answer'] as String?;
          final String? storedError = data['error'] as String?;
          
          if (storedQuestion != null && storedQuestion.isNotEmpty) {
             
             chatHistoryForApi.add({'role': 'user', 'parts': [{'text': storedQuestion}]});
          }

          if (storedError == null || storedError.isEmpty) {
              if (storedAnswer != null && storedAnswer.isNotEmpty) {
                 
                 chatHistoryForApi.add({'role': 'model', 'parts': [{'text': storedAnswer}]});
              }
          }      
        }
        print("Prepared history for API: ${chatHistoryForApi.length} turns (from ${historySnapshot.docs.length} documents)");

      } catch (e) {
        print("Error fetching/preparing chat history: $e");
         if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Історія недоступна: $e"), duration: const Duration(seconds: 2))
          );
        }
      }
    }
    
    const String cloudFunctionUrl = 'https://ask-ai-tutor-dep6ecqopa-ew.a.run.app';

    try {
      print("Sending request to AI Tutor with history...");
      final response = await http.post(
        Uri.parse(cloudFunctionUrl),
        headers: {'Content-Type': 'application/json'},
        
        body: jsonEncode({
          'question': questionText,
          'history': chatHistoryForApi,
        }),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        finalAnswer = responseBody['answer'] ?? 'No answer received.';
        print("Received AI answer successfully.");
      } else {
        print('Cloud Function Error: ${response.statusCode} ${response.body}');
        
         String serverError = response.body;
          try {
             final errorBody = jsonDecode(response.body);
             serverError = errorBody['error'] ?? response.body;
          } catch (_) {}
        errorForHistory = 'Error (${response.statusCode}): $serverError';
        if(mounted){
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorForHistory), duration: const Duration(seconds: 3)));
        }
      }
    } catch (e) {
       if (!mounted) return;
       print('Network/Request Error: $e');
       errorForHistory = 'Failed to connect. Please check your connection.';
       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorForHistory), duration: const Duration(seconds: 3)));
       }
    } finally {
       
       await _saveAiHistory(questionText, finalAnswer, errorForHistory);
       if (mounted) { setState(() { _isLoading = false; }); }
       
       _scrollToBottom();
    }
  }

  Widget _buildChatList() {
     if (userId == null) { return const Center(child: Text("Please log in")); }
     return StreamBuilder<QuerySnapshot>(
       stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'main-db')
           .collection('userHistories').doc(userId).collection('aiHistory')
           .orderBy('timestamp', descending: false).snapshots(),
       builder: (context, snapshot) {
         if (snapshot.hasError) { return Center(child: Text('Error: ${snapshot.error}'));}
         if (snapshot.connectionState == ConnectionState.waiting) { return const Center(child: CircularProgressIndicator()); }
         if (!snapshot.hasData || snapshot.data!.docs.isEmpty) { return const Center(child: Text('Задавайте питання!')); }

         WidgetsBinding.instance.addPostFrameCallback((_) {
           if (_scrollController.hasClients) {
             _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
           }
         });

         return ListView.builder(
           controller: _scrollController,
           padding: const EdgeInsets.symmetric(vertical: 8.0),
           itemCount: snapshot.data!.docs.length,
           itemBuilder: (context, index) {
             var doc = snapshot.data!.docs[index];
             var data = doc.data() as Map<String, dynamic>;
             return _buildConversationTurn(data);
           },
         );
       },
     );
   }

   Widget _buildConversationTurn(Map<String, dynamic> data) {
     final String question = data['question'] ?? '';
     final String answer = data['answer'] ?? '';
     final String? error = data['error'] as String?;
     return Column(
       crossAxisAlignment: CrossAxisAlignment.stretch,
       children: [
         _buildChatBubble(text: question, isUserMessage: true),
         _buildChatBubble(text: answer, isUserMessage: false, error: error),
       ],
     );
   }

   Widget _buildChatBubble({required String text, required bool isUserMessage, String? error}) {
     final bool hasError = error != null && error.isNotEmpty;
     final String displayText = hasError ? "Error: $error" : (text.isEmpty ? (isUserMessage ? '' : '...') : text);
     final color = hasError ? Colors.red.shade100 : isUserMessage ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer;
     final textColor = hasError ? Colors.red.shade900 : isUserMessage ? Theme.of(context).colorScheme.onPrimaryContainer : Theme.of(context).colorScheme.onSecondaryContainer;

     if (isUserMessage && displayText.isEmpty) return const SizedBox.shrink();

     return Container(
       padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
       alignment: isUserMessage ? Alignment.centerRight : Alignment.centerLeft,
       child: Container(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.only( topLeft: const Radius.circular(16), topRight: const Radius.circular(16), bottomLeft: Radius.circular(isUserMessage ? 16 : 0), bottomRight: Radius.circular(isUserMessage ? 0 : 16),),
            boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 3, offset: const Offset(0, 1),) ]
          ),
          child: SelectableText( displayText, style: TextStyle(color: textColor),),
       ),
     );
   }
  
  @override
  Widget build(BuildContext context) {
    return Padding(    
      padding: const EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 16.0),
      child: Column(
        children: [
          Expanded( child: _buildChatList(), ), 
          const SizedBox(height: 8.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _questionController,
                    style: const TextStyle(
                      color: Colors.black87, 
                      fontSize: 16, 
                    ),
                    decoration: InputDecoration(
                      hintText: 'Задайте питання...',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24.0),
                        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                    textInputAction: TextInputAction.send,
                    onSubmitted: _isLoading ? null : (_) => _askAI(),
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
                    shape: const CircleBorder(),
                  ),
                  tooltip: 'Запитайте в Артема Личака', 
                ),
              ],
            ),
          ),
        ],
      ),
    ); 
  }
}