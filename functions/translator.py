from firebase_functions import https_fn
import deepl 
import json
import traceback

def handle_translate_text(req: https_fn.Request, translator) -> https_fn.Response:
    """
    Handles the request logic for the Translator function.
    Expects the initialized DeepL Translator object to be passed in.
    """
    
    if req.method != "POST":
        print(f"Error: Method {req.method} not allowed for translate_text handler.")
        return https_fn.Response(json.dumps({"error": "Method Not Allowed"}), status=405, mimetype="application/json")

    
    try:
        request_json = req.get_json(silent=True)
        text_to_translate = request_json.get("text") if request_json else None
        target_language = request_json.get("target_lang") if request_json else None
        source_language = request_json.get("source_lang") if request_json else None 

        if not text_to_translate or not target_language:
            missing = []
            if not text_to_translate: missing.append("'text'")
            if not target_language: missing.append("'target_lang'")
            return https_fn.Response(json.dumps({"error": f"Missing required fields in request body: {', '.join(missing)}"}), status=400, mimetype="application/json")

    except Exception as e:
        return https_fn.Response(json.dumps({"error": f"Invalid request format: {e}"}), status=400, mimetype="application/json")

    
    try:
        print(f"Translating text to {target_language}: {text_to_translate[:100]}...")
        
        result = translator.translate_text(
            text_to_translate,
            source_lang=source_language, 
            target_lang=target_language
        )
        translated = result.text
        detected_source = result.detected_source_language
        print(f"Translation successful (Source: {detected_source}): {translated[:100]}...")

        return https_fn.Response(
            json.dumps({
                "translated_text": translated,
                "detected_source_lang": detected_source
            }),
            status=200,
            mimetype="application/json"
        )

    except deepl.DeepLException as e:
        
        print(f"DeepL API Error: {e}")
        return https_fn.Response(json.dumps({"error": f"Translation failed: {e}"}), status=500, mimetype="application/json")
    except Exception as e:
        
        print(f"Unexpected error during translation: {e}")
        print(traceback.format_exc())
        return https_fn.Response(json.dumps({"error": f"An unexpected error occurred during translation: {e}"}), status=500, mimetype="application/json")

