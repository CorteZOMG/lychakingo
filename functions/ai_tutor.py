

from firebase_functions import https_fn
import json
import traceback



def handle_ask_ai_tutor(req: https_fn.Request, model) -> https_fn.Response:
    """
    Handles the request logic for the AI Tutor function.
    Expects the initialized Gemini model to be passed in.
    """
    
    if req.method != "POST":
        print(f"Error: Method {req.method} not allowed for ask_ai_tutor handler.")
        
        return https_fn.Response(json.dumps({"error": "Method Not Allowed"}), status=405, mimetype="application/json")

    
    try:
        request_json = req.get_json(silent=True)
        user_question = request_json.get("question") if request_json else None

        if not user_question:
            print("Error: 'question' field missing in request body.")
            return https_fn.Response(json.dumps({"error": "Missing 'question' in request body"}), status=400, mimetype="application/json")

    except Exception as e:
        print(f"Error parsing request JSON: {e}")
        return https_fn.Response(json.dumps({"error": "Invalid request format"}), status=400, mimetype="application/json")

    
    prompt = f"""You are a helpful and concise language tutor for an app called LychaKingo.
Your answers should be clear, easy to understand, and relatively short.
Focus directly on answering the user's question about language or grammar.

User's Question: "{user_question}"

Answer:"""
    

    try:
        
        print(f"Sending prompt to Gemini: {prompt[:100]}...")
        
        response = model.generate_content(prompt)
        

        
        if not response.parts:
             print("Warning: Received empty response parts from Gemini.")
             ai_answer = "(No answer generated, possibly due to safety filters or empty response)"
        else:
             ai_answer = response.text

        print(f"Received answer from Gemini: {ai_answer[:100]}...")

        return https_fn.Response(
            json.dumps({"answer": ai_answer}),
            status=200,
            mimetype="application/json"
        )

    except Exception as e:
        print(f"Error calling Gemini API: {e}")
        print("--- Full Traceback ---") 
        print(traceback.format_exc()) 
        print("--- End Traceback ---") 
        return https_fn.Response(
            json.dumps({"error": f"Failed to get answer from AI Tutor. Error: {e}"}),
            status=500,
            mimetype="application/json"
        )
