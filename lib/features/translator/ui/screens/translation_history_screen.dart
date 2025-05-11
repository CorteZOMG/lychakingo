import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; 

class TranslationHistoryScreen extends StatefulWidget {
  const TranslationHistoryScreen({super.key});

  @override
  State<TranslationHistoryScreen> createState() => _TranslationHistoryScreenState();
}

class _TranslationHistoryScreenState extends State<TranslationHistoryScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  
  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    
    return DateFormat('MMM d, HH:mm').format(timestamp.toDate());
  }

  Future<void> _deleteHistoryItem(String docId) async {
     if (userId == null) return;
     try {
          await FirebaseFirestore.instanceFor(
            app: Firebase.app(),
            databaseId: 'main-db')
            .collection('userHistories')
            .doc(userId)
            .collection('translationHistory')
            .doc(docId) 
            .delete();
        if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("History item deleted."), duration: Duration(seconds: 1))
           );
        }
     } catch (e) {
        print("Error deleting history item: $e");
         if(mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error deleting item: $e"), duration: Duration(seconds: 2))
           );
        }
     }
  }
  
  void _copyToClipboard(String text, String label) {
     Clipboard.setData(ClipboardData(text: text));
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$label copied to clipboard"), duration: const Duration(seconds: 1))
     );
  }

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Історія перекладача")),
        body: const Center(child: Text("Please log in to see history.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Історія перекладача"),        
                
      ),
      body: StreamBuilder<QuerySnapshot>(
        
        stream: FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'main-db'
          )
            .collection('userHistories')
            .doc(userId)
            .collection('translationHistory')
            .orderBy('timestamp', descending: true) 
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('Не знайдено даних.'));
          }
          
          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              
              QueryDocumentSnapshot doc = snapshot.data!.docs[index];
              Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
              bool hadError = data['error'] != null;
              
              return _buildHistoryCard(doc.id, data, hadError);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryCard(String docId, Map<String, dynamic> data, bool hadError) {
    final String sourceLang = data['sourceLang'] ?? '?';
    final String targetLang = data['targetLang'] ?? '?';
    final String inputText = data['inputText'] ?? 'N/A';
    final String outputText = hadError ? ('Error: ${data['error']}') : (data['outputText'] ?? 'N/A');
    final String timestampStr = _formatTimestamp(data['timestamp'] as Timestamp?);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$sourceLang → $targetLang',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 20, color: Colors.grey.shade500),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Видалити',
                  onPressed: () => _deleteHistoryItem(docId), 
                ),
              ],
            ),
            const SizedBox(height: 8),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    child: SelectableText(inputText, style: const TextStyle(fontSize: 15, color: Color.fromARGB(255, 0, 0, 0)))
                ),
                IconButton(
                  icon: Icon(Icons.copy, size: 18, color: Colors.grey.shade500),
                  padding: const EdgeInsets.only(left: 8),
                  constraints: const BoxConstraints(),
                  tooltip: 'Copy original text',
                  onPressed: () => _copyToClipboard(inputText, 'Original text'),
                ),
              ],
            ),
            const Divider(height: 16),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SelectableText(
                    outputText,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: hadError ? FontWeight.normal : FontWeight.w500,
                      color: hadError ? Color.fromARGB(255, 255, 0, 0) : Color.fromARGB(255, 0, 0, 0), 
                    ),
                  )
                ),
                 
                 if (!hadError)
                   IconButton(
                     icon: Icon(Icons.copy, size: 18, color: Colors.grey.shade500),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                     tooltip: 'Copy translation',
                     onPressed: () => _copyToClipboard(outputText, 'Translation'),
                   ),
              ],
            ),
             
             if (timestampStr.isNotEmpty) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    timestampStr,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                  ),
                ),
             ]
          ],
        ),
      ),
    );
  }
}