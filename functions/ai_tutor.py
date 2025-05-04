from firebase_functions import https_fn
import google.generativeai as genai
import json
import traceback

def handle_ask_ai_tutor(req: https_fn.Request, model: genai.GenerativeModel) -> https_fn.Response:
    if req.method != "POST":
        print(f"Error: Method {req.method} not allowed.")
        return https_fn.Response(json.dumps({"error": "Method Not Allowed"}), status=405, mimetype="application/json")

    validated_history = []
    user_question = None

    try:
        request_json = req.get_json(silent=True)
        if not request_json:
             raise ValueError("Request body is not valid JSON or is empty.")

        user_question = request_json.get("question")
        history_data = request_json.get("history", [])

        if not user_question:
            print("Error: 'question' field missing in request body.")
            return https_fn.Response(json.dumps({"error": "Missing 'question' in request body"}), status=400, mimetype="application/json")
       
        if isinstance(history_data, list):
             for turn in history_data:
                  if (isinstance(turn, dict) and
                      turn.get('role') in ['user', 'model'] and
                      isinstance(turn.get('parts'), list) and
                      len(turn['parts']) > 0 and
                      isinstance(turn['parts'][0].get('text'), str)):
                       validated_history.append(turn)
                  else: print(f"Warning: Skipping invalid history turn format: {turn}")
        else:
             print(f"Warning: Received invalid history format (expected list): {history_data}")
             validated_history = []

    except Exception as e:
        print(f"Error parsing request JSON: {e}")
        return https_fn.Response(json.dumps({"error": f"Invalid request format: {e}"}), status=400, mimetype="application/json")

    try:

        print(f"Starting chat with history length: {len(validated_history)}")
        if validated_history: print(f"History snippet (last turn): {validated_history[-1]}")
        
        chat = model.start_chat(history=validated_history)
        print(f"Sending message to chat: {user_question[:100]}...")
        response = chat.send_message(user_question)
        
        if not response.parts:
            print("Warning: Received empty response parts from Gemini chat.")
            ai_answer = "(No answer generated, possibly due to safety filters or empty response)"
            if response.prompt_feedback and response.prompt_feedback.block_reason:
                 print(f"Content blocked. Reason: {response.prompt_feedback.block_reason}")
                 ai_answer = f"(Content blocked: {response.prompt_feedback.block_reason})"
        else:
             ai_answer = response.text

        print(f"Received answer from Gemini chat: {ai_answer[:100]}...")
        return https_fn.Response(
            json.dumps({"answer": ai_answer}),
            status=200,
            mimetype="application/json"
        )

    except Exception as e:
        
        print(f"Error during Gemini chat/generation: {e}")
        print("--- Full Traceback ---")
        print(traceback.format_exc())
        print("--- End Traceback ---")
        error_message = f"Failed to get answer from AI Tutor. Error: {type(e).__name__}"
        return https_fn.Response(
            json.dumps({"error": error_message}),
            status=500,
            mimetype="application/json"
        )
