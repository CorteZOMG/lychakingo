import 'package:lychakingo/features/lessons/domain/models/lesson.dart';
import 'package:lychakingo/features/lessons/domain/models/task.dart';

final List<Lesson> allLessons = [
  
  StandardLesson(
    id: 'L1_ArticlesAAn',
    title: "'A' vs 'An'",
    description: "Learn when to use the articles 'a' and 'an'.",
    iconName: 'article_icon', 
    theoryTitle: "Using 'a' and 'an'",
    theoryContent: """
Use 'a' before words that start with a consonant sound.
Examples: a cat, a dog, a big apple, a university (starts with 'y' sound).

Use 'an' before words that start with a vowel sound (a, e, i, o, u sounds).
Examples: an apple, an elephant, an interesting book, an hour (h is silent).
""",
    prerequisiteLessonId: null, 
    tasks: [
      MultipleChoiceTask(
        id: 'L1T1', instruction: "Choose the correct article:", questionText: "___ apple",
        options: ["a", "an"], correctAnswerIndex: 1,
      ),
      MultipleChoiceTask(
        id: 'L1T2', instruction: "Choose the correct article:", questionText: "___ big dog",
        options: ["a", "an"], correctAnswerIndex: 0,
      ),
      MultipleChoiceTask(
        id: 'L1T3', instruction: "Choose the correct article:", questionText: "___ hour",
        options: ["a", "an"], correctAnswerIndex: 1,
      ),
       MultipleChoiceTask(
        id: 'L1T4', instruction: "Choose the correct article:", questionText: "___ university",
        options: ["a", "an"], correctAnswerIndex: 0,
      ),
    ],
  ),
  
  StandardLesson(
    id: 'L2_SimplePlurals', title: "Simple Plurals", description: "Learn how to make basic nouns plural.",
    iconName: 'plural_icon', theoryTitle: "Making Nouns Plural",
    theoryContent: """
Most nouns form their plural by adding '-s'.
Example: cat -> cats, book -> books

Nouns ending in -s, -x, -ch, -sh add '-es'.
Example: bus -> buses, box -> boxes, watch -> watches, dish -> dishes
""",
    prerequisiteLessonId: 'L1_ArticlesAAn', 
    tasks: [
      FillBlankTask(
        id: 'L2T1', instruction: "Write the plural form:", sentenceParts: ["One dog, two ", "."],
        correctFilling: "dogs",
      ),
      FillBlankTask(
        id: 'L2T2', instruction: "Write the plural form:", sentenceParts: ["A box, many ", "."],
        correctFilling: "boxes",
      ),
       MultipleChoiceTask(
        id: 'L2T3', instruction: "Choose the correct plural:", questionText: "watch",
        options: ["watchs", "watches", "watch"], correctAnswerIndex: 1,
      ),
       MultipleChoiceTask(
        id: 'L2T4', instruction: "Choose the correct plural:", questionText: "car",
        options: ["cars", "cares", "car"], correctAnswerIndex: 0,
      ),
    ],
  ),
   
  StandardLesson(
    id: 'L3_ToBePresent', title: "Verb 'To Be'", description: "Learn the present simple forms: am, is, are.",
    iconName: 'verb_icon', theoryTitle: "Using 'am', 'is', 'are'",
    theoryContent: """
Use 'am' with 'I'. (I am)
Use 'is' with 'he', 'she', 'it' (or singular nouns). (He is, She is, The cat is)
Use 'are' with 'you', 'we', 'they' (or plural nouns). (You are, We are, They are, The dogs are)
""",
    prerequisiteLessonId: 'L2_SimplePlurals', 
    tasks: [
       MultipleChoiceTask(
        id: 'L3T1', instruction: "Choose the correct form:", questionText: "I ___ happy.",
        options: ["am", "is", "are"], correctAnswerIndex: 0,
      ),
       FillBlankTask(
        id: 'L3T2', instruction: "Fill in the blank:", sentenceParts: ["She ", " a doctor."],
        correctFilling: "is",
      ),
       MultipleChoiceTask(
        id: 'L3T3', instruction: "Choose the correct form:", questionText: "They ___ friends.",
        options: ["am", "is", "are"], correctAnswerIndex: 2,
      ),
       FillBlankTask(
        id: 'L3T4', instruction: "Fill in the blank:", sentenceParts: ["We ", " ready."],
        correctFilling: "are",
      ),
    ],
  ),

  StandardLesson(
    id: 'L4_PresentSimpleReg', title: "Present Simple", description: "Learn regular verbs in the present simple.",
    iconName: 'present_simple_icon', theoryTitle: "Using Present Simple",
    theoryContent: """
Use the base form of the verb for I, you, we, they.
Example: I walk, You work, We play, They study.

Add '-s' to the verb for he, she, it.
Example: He walks, She works, It plays.
(Verbs ending in -s, -x, -ch, -sh add '-es': He watches)
(Verbs ending in consonant + y, change y to i and add -es: study -> studies)
""",
    prerequisiteLessonId: 'L3_ToBePresent', 
    tasks: [
       MultipleChoiceTask(
        id: 'L4T1', instruction: "Choose the correct form:", questionText: "She ___ (work) here.",
        options: ["work", "works", "working"], correctAnswerIndex: 1,
      ),
       MultipleChoiceTask(
        id: 'L4T2', instruction: "Choose the correct form:", questionText: "They ___ (live) in Kyiv.",
        options: ["live", "lives", "living"], correctAnswerIndex: 0,
      ),
       FillBlankTask(
        id: 'L4T3', instruction: "Fill in the blank (use 'study'):", sentenceParts: ["He ", " English every day."],
        correctFilling: "studies",
      ),
       FillBlankTask(
        id: 'L4T4', instruction: "Fill in the blank (use 'play'):", sentenceParts: ["We ", " football on weekends."],
        correctFilling: "play",
      ),
    ],
  ),
   
  StandardLesson(
    id: 'L5_PrepositionsPlace', title: "Prepositions of Place", description: "Learn basic use of 'in', 'on', 'at' for places.",
    iconName: 'preposition_icon', theoryTitle: "'in', 'on', 'at' for Place",
    theoryContent: """
Use 'in' for enclosed spaces or larger areas.
Examples: in the box, in Kyiv, in the park, in the car.

Use 'on' for surfaces.
Examples: on the table, on the wall, on the floor, on the bus (you stand/sit on its floor).

Use 'at' for specific points or locations.
Examples: at the door, at the bus stop, at the party, at work, at home.
""",
    prerequisiteLessonId: 'L4_PresentSimpleReg', 
    tasks: [
       MultipleChoiceTask(
        id: 'L5T1', instruction: "Choose the correct preposition:", questionText: "The keys are ___ the table.",
        options: ["in", "on", "at"], correctAnswerIndex: 1,
      ),
      MultipleChoiceTask(
        id: 'L5T2', instruction: "Choose the correct preposition:", questionText: "He lives ___ London.",
        options: ["in", "on", "at"], correctAnswerIndex: 0,
      ),
       MultipleChoiceTask(
        id: 'L5T3', instruction: "Choose the correct preposition:", questionText: "Meet me ___ the main entrance.",
        options: ["in", "on", "at"], correctAnswerIndex: 2,
      ),
        FillBlankTask(
        id: 'L5T4', instruction: "Fill in the blank:", sentenceParts: ["The picture is ", " the wall."],
        correctFilling: "on",
      ),
    ],
  ),
  
  StandardLesson(
    id: 'L6_SentenceOrder',
    title: "Basic Sentence Order",
    description: "Practice arranging words into correct sentences.",
    iconName: 'sort_by_alpha', 
    theoryTitle: "English Sentence Structure (SVO)",
    theoryContent: """
Most basic English sentences follow a Subject-Verb-Object (SVO) order.
Subject: Who or what performs the action (e.g., 'I', 'The cat', 'She').
Verb: The action (e.g., 'eat', 'reads', 'is').
Object: Who or what receives the action (e.g., 'apples', 'a book', 'happy').

Example: She (S) reads (V) a book (O). Put the words in the right order!
""",
    prerequisiteLessonId: 'L5_PrepositionsPlace', 
    tasks: [
      SentenceOrderTask(
        id: 'L6T1',
        instruction: "Put the words in the correct order:",
        words: ["like", "I", "apples"], 
        correctOrder: ["I", "like", "apples"],
      ),
      SentenceOrderTask(
        id: 'L6T2',
        instruction: "Put the words in the correct order:",
        words: ["is", "blue", "sky", "The"],
        correctOrder: ["The", "sky", "is", "blue"],
      ),
      SentenceOrderTask(
        id: 'L6T3',
        instruction: "Put the words in the correct order:",
        words: ["reads", "book", "a", "He"],
        correctOrder: ["He", "reads", "a", "book"],
      ),
       
       FillBlankTask(
        id: 'L6T4',
        instruction: "Fill in the blank (use 'happy'):",
        sentenceParts: ["They are ", "."],
        correctFilling: "happy",
      ),
    ],
  ),

  
   StandardLesson(
    id: 'L7_VocabMatch',
    title: "Basic Vocabulary Match",
    description: "Match English words with their Ukrainian translations.",
    iconName: 'compare_arrows', 
    theoryTitle: "Basic Greetings & Words",
    theoryContent: """
Let's learn some basic words and greetings! Match the pairs correctly.
Hello - Привіт
Goodbye - До побачення
Thank you - Дякую
Yes - Так
No - Ні
Please - Будь ласка
Cat - Кіт
Dog - Пес / Собака
""",
    prerequisiteLessonId: 'L6_SentenceOrder', 
    tasks: [
       MatchingPairsTask(
        id: 'L7T1',
        instruction: "Match the English word to its Ukrainian translation:",
        pairs: {
          'Hello': 'Привіт',
          'Goodbye': 'До побачення',
          'Thank you': 'Дякую',
        },
       ),
       MatchingPairsTask(
        id: 'L7T2',
        instruction: "Match the word to its meaning:",
         pairs: {
          'Yes': 'Так',
          'No': 'Ні',
          'Please': 'Будь ласка',
        },
       ),
       MatchingPairsTask( 
         id: 'L7T3',
         instruction: "Match the animal:",
         pairs: {
           'Cat': 'Кіт',
           'Dog': 'Пес', 
           'Bird': 'Птах',
         }
       ),
       
       MultipleChoiceTask(
         id: 'L7T4',
         instruction: "How do you say 'Hello'?",
         questionText: "Привіт means:",
         options: ["Hello", "Please", "Thank you", "Goodbye"],
         correctAnswerIndex: 0,
       ),
    ],
  ),
]; 