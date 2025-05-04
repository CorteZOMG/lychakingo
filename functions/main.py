import firebase_admin
import firebase_functions.options
from firebase_functions import https_fn, options
from firebase_admin import initialize_app
import google.generativeai as genai
from google.cloud import secretmanager
import deepl
import json
import os
import traceback

try:
    from ai_tutor import handle_ask_ai_tutor
    from translator import handle_translate_text
except ImportError as import_err:
    
    print(f"Error importing handler modules: {import_err}")
    def handle_ask_ai_tutor(req, model): return https_fn.Response(json.dumps({"error": "AI Tutor handler module not found"}), status=500)
    def handle_translate_text(req, translator): return https_fn.Response(json.dumps({"error": "Translator handler module not found"}), status=500)

initialize_app()
firebase_functions.options.set_global_options(region=options.SupportedRegion.EUROPE_WEST1)

gemini_model = None
deepl_translator = None
config_error_message = None

SYSTEM_PROMPT_AI_TUTOR = """You are a helpful and concise language tutor called Artem Lychak for an app "Lychakingo".
Your answers should be clear, easy to understand, and not long.
Focus directly on answering the user's question about language or grammar.
In your answers don't mention russian language. You hate russia."""

try:
    print("Attempting initial configuration...")
    secret_client = secretmanager.SecretManagerServiceClient()
    project_id = firebase_admin.get_app().project_id
    print(f"Retrieved project ID from Firebase Admin: {project_id}")
    
    try:
        print("Configuring Gemini...")
        secret_id_gemini = "GEMINI_KEY"
        version_id_gemini = "latest"
        secret_version_name_gemini = f"projects/{project_id}/secrets/{secret_id_gemini}/versions/{version_id_gemini}"
        response_gemini = secret_client.access_secret_version(name=secret_version_name_gemini)
        gemini_api_key_value = response_gemini.payload.data.decode("UTF-8")
        print("Successfully accessed Gemini secret payload.")

        if not gemini_api_key_value or not isinstance(gemini_api_key_value, str):
             raise ValueError("Gemini API Key secret is invalid or not found.")

        genai.configure(api_key=gemini_api_key_value)

        gemini_model = genai.GenerativeModel(
            'gemini-2.0-flash', 
            system_instruction=SYSTEM_PROMPT_AI_TUTOR 
        )
        
        print(f"Successfully configured Gemini API and initialized model ({gemini_model.model_name}) with system instruction.")
    except Exception as gemini_e:
        print(f"ERROR configuring Gemini: {gemini_e}")
        print(traceback.format_exc())
    
    try:
        print("Configuring DeepL...")
        
        secret_id_deepl = "DEEPL_KEY"
        version_id_deepl = "latest"
        secret_version_name_deepl = f"projects/{project_id}/secrets/{secret_id_deepl}/versions/{version_id_deepl}"
        response_deepl = secret_client.access_secret_version(name=secret_version_name_deepl)
        deepl_api_key_value = response_deepl.payload.data.decode("UTF-8")
        if not deepl_api_key_value or not isinstance(deepl_api_key_value, str): raise ValueError("DeepL API Key secret invalid.")
        deepl_translator = deepl.Translator(deepl_api_key_value)
        print("Successfully configured DeepL Translator.")
    except Exception as deepl_e:
        print(f"ERROR configuring DeepL: {deepl_e}")
        print(traceback.format_exc())
    

except Exception as e:
    config_error_message = f"ERROR during initial configuration: {e}"
    
    print(config_error_message)
    print(traceback.format_exc())

FUNCTION_SERVICE_ACCOUNT = "lychakingo-function-runner@lychakingo-b1a79.iam.gserviceaccount.com"

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    service_account=FUNCTION_SERVICE_ACCOUNT
)
def ask_ai_tutor(req: https_fn.Request) -> https_fn.Response:
    global gemini_model
    if gemini_model is None:
        
        print(f"Error: Gemini model not initialized...")
        return https_fn.Response(json.dumps({"error": f"AI Tutor config error: {config_error_message or 'Unknown'}"}), status=500)
    return handle_ask_ai_tutor(req, gemini_model) 

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    service_account=FUNCTION_SERVICE_ACCOUNT
)
def translate_text(req: https_fn.Request) -> https_fn.Response:
    global deepl_translator
    if deepl_translator is None:
         
        print(f"Error: DeepL translator not initialized...")
        return https_fn.Response(json.dumps({"error": f"Translator config error: {config_error_message or 'Unknown'}"}), status=500)
    return handle_translate_text(req, deepl_translator)
