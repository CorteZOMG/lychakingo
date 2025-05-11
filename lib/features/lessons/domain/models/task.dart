import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

@immutable
abstract class Task {
  final String id;
  final String instruction;

  Task({
    required this.id,
    required this.instruction,
  });

  Widget buildTaskWidget(
    BuildContext context,
    dynamic currentAnswer,
    Function(dynamic userAnswer) onAnswerSelected,
  );

  bool isAnswerCorrect(dynamic userAnswer);
  dynamic get correctAnswer;
}

class FillBlankTask extends Task {
  final List<String> sentenceParts;
  final String correctFilling;

  FillBlankTask({
    required super.id,
    required super.instruction,
    required this.sentenceParts,
    required this.correctFilling,
  }) : assert(sentenceParts.length == 2);

  @override
  bool isAnswerCorrect(dynamic userAnswer) {
    if (userAnswer is! String) return false;
    return userAnswer.trim().toLowerCase() == correctFilling.toLowerCase();
  }

  @override
  String get correctAnswer => correctFilling;

  @override
  Widget buildTaskWidget(BuildContext context, dynamic currentAnswer, Function(dynamic) onAnswerSelected) {
    return _FillBlankTaskWidget(
      key: ValueKey(id),
      task: this,
      currentAnswer: currentAnswer as String?,
      onAnswerSelected: onAnswerSelected,
    );
  }
}

class _FillBlankTaskWidget extends StatefulWidget {
  final FillBlankTask task;
  final String? currentAnswer;
  final Function(String text) onAnswerSelected;

  const _FillBlankTaskWidget({
    super.key,
    required this.task,
    required this.currentAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<_FillBlankTaskWidget> createState() => _FillBlankTaskWidgetState();
}

class _FillBlankTaskWidgetState extends State<_FillBlankTaskWidget> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.currentAnswer ?? '');
    _textController.addListener(() {
      widget.onAnswerSelected(_textController.text);
    });
  }

   @override
  void didUpdateWidget(covariant _FillBlankTaskWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentAnswer != oldWidget.currentAnswer &&
        widget.currentAnswer != _textController.text ) {
       WidgetsBinding.instance.addPostFrameCallback((_) {
         if(mounted) {
            _textController.text = widget.currentAnswer ?? '';
            _textController.selection = TextSelection.fromPosition(
                TextPosition(offset: _textController.text.length));
         }
       });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  double _calculateTextWidth(String text, TextStyle style) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: double.infinity);
    return textPainter.size.width;
  }

 @override
  Widget build(BuildContext context) {
    final TextStyle explicitRichTextStyle = TextStyle(
      fontSize: 18,
      color: Colors.black87, 
      decoration: TextDecoration.none,
      fontFamily: DefaultTextStyle.of(context).style.fontFamily,
    );

    final TextStyle textFieldStyleForMeasurement = explicitRichTextStyle.copyWith(
        fontWeight: FontWeight.bold,
        
    );

    String textToMeasure = widget.task.correctFilling.isNotEmpty
        ? widget.task.correctFilling
        : "MMMM"; 
    
    
    if ((widget.currentAnswer?.length ?? 0) > textToMeasure.length) {
      textToMeasure = widget.currentAnswer!;
    }

    double calculatedWidth = _calculateTextWidth(textToMeasure, textFieldStyleForMeasurement);
    calculatedWidth += 132.0; 
    
    final double dynamicInputFieldWidth = calculatedWidth.clamp(
        80.0, 
        MediaQuery.of(context).size.width * 0.6, 
    );

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.instruction,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black) ??
                     const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
            ),
            const SizedBox(height: 24),
            RichText(
              text: TextSpan(
                style: explicitRichTextStyle, 
                children: [
                  TextSpan(text: widget.task.sentenceParts[0]),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: SizedBox(
                      width: dynamicInputFieldWidth, 
                      child: TextField(
                        controller: _textController,
                        textAlign: TextAlign.center,
                        style: explicitRichTextStyle.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 2),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
                          ),
                        ),
                      ),
                    ),
                  ),
                  TextSpan(text: widget.task.sentenceParts[1]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultipleChoiceTask extends Task {
  final String questionText;
  final List<String> options;
  final int correctAnswerIndex;

  MultipleChoiceTask({
    required super.id,
    required super.instruction,
    required this.questionText,
    required this.options,
    required this.correctAnswerIndex,
  }) : assert(correctAnswerIndex >= 0 && correctAnswerIndex < options.length);

  @override
  bool isAnswerCorrect(dynamic userAnswer) {
    return userAnswer is int && userAnswer == correctAnswerIndex;
  }

  @override
  String get correctAnswer => options[correctAnswerIndex];

  @override
  Widget buildTaskWidget(BuildContext context, dynamic currentAnswer, Function(dynamic) onAnswerSelected) {
    return _MultipleChoiceTaskWidget(
      key: ValueKey(id),
      task: this,
      currentAnswerIndex: currentAnswer as int?,
      onAnswerSelected: onAnswerSelected,
    );
  }
}

class _MultipleChoiceTaskWidget extends StatefulWidget {
  final MultipleChoiceTask task;
  final int? currentAnswerIndex;
  final Function(int? index) onAnswerSelected;

  const _MultipleChoiceTaskWidget({
    super.key,
    required this.task,
    required this.currentAnswerIndex,
    required this.onAnswerSelected,
  });

  @override
  State<_MultipleChoiceTaskWidget> createState() => _MultipleChoiceTaskWidgetState();
}

class _MultipleChoiceTaskWidgetState extends State<_MultipleChoiceTaskWidget> {
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.currentAnswerIndex;
  }

   @override
  void didUpdateWidget(covariant _MultipleChoiceTaskWidget oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.currentAnswerIndex != oldWidget.currentAnswerIndex) {
        setState(() {
            _selectedIndex = widget.currentAnswerIndex;
        });
      }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.instruction,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.black) ?? const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            Text(
              widget.task.questionText,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87)
            ),
            const SizedBox(height: 16),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: widget.task.options.asMap().entries.map((entry) {
                int index = entry.key;
                String optionText = entry.value;
                return RadioListTile<int>(
                  title: Text(optionText, style: const TextStyle(color: Colors.black87)),
                  value: index,
                  groupValue: _selectedIndex,
                  onChanged: (int? newValue) {
                    setState(() { _selectedIndex = newValue; });
                    widget.onAnswerSelected(newValue);
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: Theme.of(context).colorScheme.primary,
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class SentenceOrderTask extends Task {
  final List<String> words;
  final List<String> correctOrder;

  SentenceOrderTask({
    required super.id,
    required super.instruction,
    required this.words,
    required this.correctOrder,
  });

  @override
  bool isAnswerCorrect(dynamic userAnswer) {
    if (userAnswer is! List<String>) return false;
    return listEquals<String>(userAnswer, correctOrder);
  }

  @override
  List<String> get correctAnswer => correctOrder;

  @override
  Widget buildTaskWidget(BuildContext context, dynamic currentAnswer, Function(dynamic) onAnswerSelected) {
    return _SentenceOrderTaskWidget(
      key: ValueKey(id),
      task: this,
      currentAnswer: (currentAnswer as List?)?.cast<String>(),
      onAnswerSelected: onAnswerSelected,
    );
  }
}

class _SentenceOrderTaskWidget extends StatefulWidget {
  final SentenceOrderTask task;
  final List<String>? currentAnswer;
  final Function(List<String> currentOrder) onAnswerSelected;

  const _SentenceOrderTaskWidget({
    super.key,
    required this.task,
    required this.currentAnswer,
    required this.onAnswerSelected,
  });

  @override
  State<_SentenceOrderTaskWidget> createState() => _SentenceOrderTaskWidgetState();
}

class _SentenceOrderTaskWidgetState extends State<_SentenceOrderTaskWidget> {
  late List<String> availableWords;
  late List<String> selectedWords;

  @override
  void initState() {
    super.initState();
    _initializeState();
  }

  void _initializeState() {
     selectedWords = List<String>.from(widget.currentAnswer ?? []);
     availableWords = List<String>.from(widget.task.words);
     for (String word in selectedWords) {
       availableWords.remove(word);
     }
  }

   @override
  void didUpdateWidget(covariant _SentenceOrderTaskWidget oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.currentAnswer != oldWidget.currentAnswer) {
          setState(() {
             _initializeState();
          });
      }
  }

  void _selectWord(String word) {
    setState(() {
      availableWords.remove(word);
      selectedWords.add(word);
    });
    widget.onAnswerSelected(List<String>.from(selectedWords));
  }

  void _deselectWord(int index) {
    setState(() {
      final word = selectedWords.removeAt(index);
      availableWords.add(word);
    });
     widget.onAnswerSelected(List<String>.from(selectedWords));
  }

  @override
  Widget build(BuildContext context) {
     final theme = Theme.of(context);
    return Card(
       elevation: 0,
       margin: EdgeInsets.zero,
       color: Colors.white,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.instruction,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.black) ?? const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              constraints: const BoxConstraints(minHeight: 60),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: theme.colorScheme.outlineVariant)
              ),
              child: Wrap(
                spacing: 8.0,
                runSpacing: 4.0,
                children: selectedWords.isEmpty
                  ? [Text("Tap words below to build the sentence here.", style: TextStyle(color: Colors.grey.shade600))]
                  : selectedWords.asMap().entries.map((entry) {
                      int idx = entry.key;
                      String word = entry.value;
                      return Chip(
                        label: Text(word, style: const TextStyle(color: Colors.black87)),
                        onDeleted: () => _deselectWord(idx),
                        deleteIcon: const Icon(Icons.close, size: 14, color: Colors.black54),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        labelStyle: TextStyle(color: theme.colorScheme.onSecondaryContainer), 
                      );
                    }).toList(),
              ),
            ),
            const Divider(height: 1, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              "Available words:",
              style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54) ?? const TextStyle(color: Colors.black54)
            ),
             const SizedBox(height: 8),
            Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: availableWords.map((word) {
                return ActionChip(
                  label: Text(word, style: const TextStyle(color: Colors.black87)),
                  onPressed: () => _selectWord(word),
                  backgroundColor: theme.colorScheme.surfaceVariant,
                   labelStyle: TextStyle(color: theme.colorScheme.onSurfaceVariant), 
                );
              }).toList(),
            ),
          ],
        ),
       ),
    );
  }
}

class MatchingPairsTask extends Task {
  final Map<String, String> pairs;

  MatchingPairsTask({
    required super.id,
    required super.instruction,
    required this.pairs,
  }) : assert(pairs.isNotEmpty);

  @override
  bool isAnswerCorrect(dynamic userAnswer) {
     if (userAnswer is! Map) return false;
     final Map<String, String?> userAnswerMap = Map<String, String?>.from(userAnswer);
     if (userAnswerMap.values.where((v) => v != null).length != pairs.length) return false;
     for (var entry in pairs.entries) {
        if (!userAnswerMap.containsKey(entry.key) || userAnswerMap[entry.key] != entry.value) {
          return false;
        }
     }
     return true;
  }

  @override
  Map<String, String> get correctAnswer => pairs;

  @override
  Widget buildTaskWidget(BuildContext context, dynamic currentAnswer, Function(dynamic) onAnswerSelected) {
     final currentAnswerMap = (currentAnswer as Map?)?.cast<String, String?>();
    return _MatchingPairsTaskWidget(
      key: ValueKey(id),
      task: this,
      currentAnswerMap: currentAnswerMap,
      onAnswerSelected: onAnswerSelected,
    );
  }
}

class _MatchingPairsTaskWidget extends StatefulWidget {
  final MatchingPairsTask task;
  final Map<String, String?>? currentAnswerMap;
  final Function(Map<String, String?> matches) onAnswerSelected;

  const _MatchingPairsTaskWidget({
    super.key,
    required this.task,
    required this.currentAnswerMap,
    required this.onAnswerSelected,
  });

  @override
  State<_MatchingPairsTaskWidget> createState() => _MatchingPairsTaskWidgetState();
}

class _MatchingPairsTaskWidgetState extends State<_MatchingPairsTaskWidget> {
  late List<String> leftOptions;
  late List<String> rightOptions;
  late Map<String, String?> userSelections;
  String? _selectedLeft;

  @override
  void initState() {
    super.initState();
    _initializeAndShuffle();
    userSelections = Map<String, String?>.from(widget.currentAnswerMap ?? {});
    _selectedLeft = null;
  }

  @override
  void didUpdateWidget(covariant _MatchingPairsTaskWidget oldWidget) {
      super.didUpdateWidget(oldWidget);
      if (widget.currentAnswerMap != oldWidget.currentAnswerMap) {
          setState(() {
              userSelections = Map<String, String?>.from(widget.currentAnswerMap ?? {});
              _selectedLeft = null;
          });
      }
  }

  void _initializeAndShuffle() {
     leftOptions = widget.task.pairs.keys.toList()..shuffle();
     rightOptions = widget.task.pairs.values.toList()..shuffle(Random());
  }

  void _selectLeft(String item) {
    if (_isLeftMatched(item)) {
      _unmatchLeft(item);
    } else {
      setState(() { _selectedLeft = item; });
    }
  }

  void _selectRight(String item) {
    final bool isRightAlreadyMatched = _isRightMatched(item);
    if (_selectedLeft != null && !isRightAlreadyMatched) {
      setState(() {
        userSelections[_selectedLeft!] = item;
        _selectedLeft = null;
      });
      widget.onAnswerSelected(Map<String, String?>.from(userSelections));
    } else if (_selectedLeft != null && isRightAlreadyMatched) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(
         content: Text("'$item' is already matched."),
         duration: const Duration(seconds: 1),
       ));
    }
  }

 void _unmatchLeft(String leftItem) {
    if (userSelections.containsKey(leftItem) && userSelections[leftItem] != null) {
       setState(() {
           userSelections.remove(leftItem);
           _selectedLeft = null;
       });
       widget.onAnswerSelected(Map<String, String?>.from(userSelections));
    }
 }

 bool _isRightMatched(String rightItem) {
    return userSelections.values.contains(rightItem);
 }

 bool _isLeftMatched(String leftItem) {
    return userSelections.containsKey(leftItem) && userSelections[leftItem] != null;
 }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final TextStyle buttonTextStyle = TextStyle(color: Colors.black87); 
    final TextStyle matchedButtonTextStyle = TextStyle(color: Colors.grey.shade600, decoration: TextDecoration.lineThrough);

    return Card(
       elevation: 0,
       margin: EdgeInsets.zero,
       color: Colors.white,
       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
       child: Padding(
         padding: const EdgeInsets.all(16.0),
         child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.task.instruction,
              style: theme.textTheme.titleMedium?.copyWith(color: Colors.black) ?? const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 24),
            Text(
                _selectedLeft == null
                    ? "Tap an item on the left, then its match on the right."
                    : "Selected: '$_selectedLeft'. Tap its match on the right.",
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54) ?? const TextStyle(color: Colors.black54)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: leftOptions.map((item) {
                    bool isSelected = _selectedLeft == item;
                    bool isMatched = _isLeftMatched(item);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: OutlinedButton(
                        onPressed: () => _selectLeft(item),
                        style: OutlinedButton.styleFrom(
                           minimumSize: const Size(120, 40),
                           backgroundColor: isSelected ? theme.colorScheme.primaryContainer : null,
                           side: BorderSide(color: isSelected ? theme.colorScheme.primary : (isMatched ? Colors.grey.shade400 : theme.colorScheme.outline)),
                        ),
                        child: Text( item, style: isMatched ? matchedButtonTextStyle : buttonTextStyle ),
                      ),
                    );
                  }).toList(),
                ),
                Column(
                   mainAxisSize: MainAxisSize.min,
                   children: rightOptions.map((item) {
                     bool isMatched = _isRightMatched(item);
                     bool canSelect = _selectedLeft != null && !isMatched;
                     return Padding(
                       padding: const EdgeInsets.symmetric(vertical: 4.0),
                       child: OutlinedButton(
                          onPressed: canSelect ? () => _selectRight(item) : null,
                          style: OutlinedButton.styleFrom(
                             minimumSize: const Size(120, 40),
                             side: BorderSide(color: isMatched ? Colors.grey.shade400 : theme.colorScheme.outline)
                          ),
                          child: Text( item, style: isMatched ? matchedButtonTextStyle : buttonTextStyle ),
                       ),
                     );
                   }).toList(),
                ),
              ],
            ),
          ],
        ),
       ),
    );
  }
}