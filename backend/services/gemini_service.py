import google.generativeai as genai
from config import Config

class GeminiService:
    def __init__(self):
        self.cache = {}
        self.model = None
        self._initialize()
    
    def _initialize(self):
        try:
            genai.configure(api_key=Config.GEMINI_API_KEY)
            self.model = genai.GenerativeModel("gemini-2.5-flash")
            response = self.model.generate_content("Say hello in one sentence.")
            print("✅ Gemini Connected")
            print(response.text)
        except Exception as e:
            print(f"❌ Gemini init error: {e}")
    
    def get_advice(self, crop, disease, confidence, treatment):
        if self.model is None:
            return "AI not available (Gemini disabled)."
        
        key = f"{crop}_{disease}_{int(confidence)}"
        
        if key in self.cache:
            print("⚡ CACHE HIT")
            return self.cache[key]
        
        print("⚡ CACHE MISS → calling Gemini")
        
        try:
            prompt = f"""
You are an agricultural expert for small-scale farmers in Ethiopia.
Crop: {crop}
Disease: {disease}
Treatment: {treatment}
Confidence: {confidence:.2f}%

Explain simply for farmers in Ethiopia:
1. What the disease is
2. Why it happens
3. Simple treatment steps
4. Prevention tips
"""
            response = self.model.generate_content(prompt)
            text = response.text if response else "No response"
            self.cache[key] = text
            return text
        except Exception as e:
            print(f"❌ Gemini error: {e}")
            return "AI temporarily unavailable"
