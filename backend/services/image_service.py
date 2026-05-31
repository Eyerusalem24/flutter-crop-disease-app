import cv2
import os

class ImageService:
    
    @staticmethod
    def enhance_image(image_path):
        """Enhance low-quality image using OpenCV"""
        try:
            img = cv2.imread(image_path)
            if img is None:
                print(f"❌ Could not read image: {image_path}")
                return image_path
            
            print(f"📷 Original shape: {img.shape}")
            
            # Denoise
            denoised = cv2.fastNlMeansDenoisingColored(img, None, 10, 10, 7, 21)
            
            # CLAHE contrast enhancement
            lab = cv2.cvtColor(denoised, cv2.COLOR_BGR2LAB)
            l, a, b = cv2.split(lab)
            clahe = cv2.createCLAHE(clipLimit=2.0, tileGridSize=(8, 8))
            cl = clahe.apply(l)
            merged = cv2.merge((cl, a, b))
            contrast_enhanced = cv2.cvtColor(merged, cv2.COLOR_LAB2BGR)
            
            # Upscale
            high_res = cv2.resize(contrast_enhanced, (512, 512), interpolation=cv2.INTER_CUBIC)
            
            # Sharpening
            gaussian = cv2.GaussianBlur(high_res, (0, 0), 2.0)
            sharpened = cv2.addWeighted(high_res, 2.5, gaussian, -0.5, 0)
            
            # Save enhanced image
            base, ext = os.path.splitext(image_path)
            enhanced_path = f"{base}_enhanced{ext}"
            cv2.imwrite(enhanced_path, sharpened)
            
            print(f"✨ Enhanced image saved: {enhanced_path}")
            return enhanced_path
            
        except Exception as e:
            print(f"⚠️ Enhancement failed: {e}")
            return image_path
    
    @staticmethod
    def preprocess_image(image_path, target_size=(224, 224)):
        img = cv2.imread(image_path)
        if img is None:
            raise ValueError("Could not read image")
        
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        img = cv2.resize(img, target_size)
        img = img.astype('float32') / 255.0
        img = np.expand_dims(img, axis=0)
        return img
import numpy as np
