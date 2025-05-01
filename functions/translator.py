from firebase_functions import https_fn
import deepl 
import json
import traceback

def handle_translate_text(req: https_fn.Request, translator) -> https_fn.Response:
    
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
        print(f"Received source_lang: {source_language}, target_lang: {target_language}") 
        
        deepl_source_lang = None
        if source_language:
            deepl_source_lang = source_language.split('-')[0] 
            print(f"Using source_lang for DeepL API: {deepl_source_lang}")
        else:
             print(f"Using source_lang for DeepL API: None (Auto-detect)")
        
        result = translator.translate_text(
            text_to_translate,
            source_lang=deepl_source_lang, 
            target_lang=target_language
        )
        translated = result.text

        
        actual_source_lang = None
        if source_language: 
            actual_source_lang = source_language
            print(f"Translation successful (Source: Provided '{actual_source_lang}'): {translated[:100]}...")
        elif hasattr(result, 'detected_source_language'):
             actual_source_lang = result.detected_source_language
             print(f"Translation successful (Source: Detected '{actual_source_lang}'): {translated[:100]}...")
        else:
             print(f"Translation successful (Source: Unknown/Not Detected): {translated[:100]}...")

        return https_fn.Response(
            json.dumps({
                "translated_text": translated,
                "detected_source_lang": actual_source_lang
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