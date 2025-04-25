import firebase_admin
import firebase_functions.options
from firebase_functions import https_fn, options 
from firebase_admin import initialize_app
import google.generativeai as genai
from google.cloud import secretmanager 
import json
import os
import traceback

initialize_app()

firebase_functions.options.set_global_options(region=options.SupportedRegion.EUROPE_WEST1)

model = None 
config_error_message = None 
try:
    print("Attempting to configure Gemini API using direct Secret Manager access...") 

    try:
        project_id = firebase_admin.get_app().project_id
        print(f"Retrieved project ID from Firebase Admin: {project_id}") 
    except Exception as admin_err:
        print(f"Error getting project ID from Firebase Admin: {admin_err}")
        raise ValueError("Could not determine Firebase Project ID.") from admin_err

    secret_id = "GEMINI_KEY" 
    version_id = "latest" 

    if not project_id:
        raise ValueError("Firebase Project ID is empty.")

    print("Creating Secret Manager client...") 
    secret_client = secretmanager.SecretManagerServiceClient()

    secret_version_name = f"projects/{project_id}/secrets/{secret_id}/versions/{version_id}"
    print(f"Accessing secret version: {secret_version_name}") 

    print("Attempting to access secret payload...") 
    response = secret_client.access_secret_version(name=secret_version_name)
    gemini_api_key_value = response.payload.data.decode("UTF-8")
    print("Successfully accessed secret payload.") 
    print(f"Retrieved secret value type: {type(gemini_api_key_value)}, Length: {len(gemini_api_key_value)}") 

    if not gemini_api_key_value or not isinstance(gemini_api_key_value, str):
         raise ValueError(f"Gemini API Key secret is invalid or not found. Type: {type(gemini_api_key_value)}")
    print("Secret value is a valid string.")

    print("Configuring genai...") 
    genai.configure(api_key=gemini_api_key_value)
    print("genai.configure called successfully.") 

    print("Initializing GenerativeModel...") 
    model = genai.GenerativeModel('gemini-1.5-flash-latest') # Or 'gemini-pro'
    print("Successfully configured Gemini API and initialized model.") 

except Exception as e:
    config_error_message = f"ERROR during Gemini configuration: {e}" 
    print(config_error_message) 
    print("--- Full Traceback ---") 
    print(traceback.format_exc()) 
    print("--- End Traceback ---") 


FUNCTION_SERVICE_ACCOUNT = "lychakingo-function-runner@lychakingo-b1a79.iam.gserviceaccount.com"

@https_fn.on_request(
    cors=options.CorsOptions(cors_origins="*", cors_methods=["post"]),
    service_account=FUNCTION_SERVICE_ACCOUNT 
)
def ask_ai_tutor(req: https_fn.Request) -> https_fn.Response:

    if model is None:
        print(f"Error: Gemini model not initialized due to configuration error: {config_error_message}") # Include stored error
        return https_fn.Response(json.dumps({"error": f"AI Tutor configuration error: {config_error_message}"}), status=500, mimetype="application/json")

    if req.method != "POST":
        print(f"Error: Method {req.method} not allowed.")
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

