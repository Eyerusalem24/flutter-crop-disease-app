import numpy as np
import cv2
import tensorflow as tf
from tensorflow import keras

class GradCAMService:
    def __init__(self, model):
        self.model = model
        self.last_conv_layer_name = self._find_last_conv_layer(model)
        
    def _find_last_conv_layer(self, model):
        """Find the last convolutional layer in the model"""
        for layer in reversed(model.layers):
            if isinstance(layer, tf.keras.layers.Conv2D):
                return layer.name
        return None
    
    def get_heatmap(self, img_array, class_idx):
        """Generate Grad-CAM heatmap for the predicted class"""
        if self.last_conv_layer_name is None:
            return None
            
        # Create a model that maps input to conv layer output and predictions
        grad_model = tf.keras.models.Model(
            inputs=self.model.input,
            outputs=[self.model.get_layer(self.last_conv_layer_name).output, self.model.output]
        )
        
        with tf.GradientTape() as tape:
            conv_output, predictions = grad_model(img_array)
            loss = predictions[:, class_idx]
        
        # Get gradients
        grads = tape.gradient(loss, conv_output)
        
        # Global average pooling
        pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2))
        
        # Weight the conv output
        conv_output = conv_output[0]
        heatmap = conv_output @ pooled_grads[..., tf.newaxis]
        heatmap = tf.squeeze(heatmap)
        
        # Normalize heatmap
        heatmap = tf.maximum(heatmap, 0) / tf.math.reduce_max(heatmap)
        
        return heatmap.numpy()
    
    def apply_heatmap(self, image_path, heatmap):
        """Apply heatmap overlay to original image"""
        # Read image
        img = cv2.imread(image_path)
        img = cv2.cvtColor(img, cv2.COLOR_BGR2RGB)
        
        # Resize heatmap to image size
        heatmap = cv2.resize(heatmap, (img.shape[1], img.shape[0]))
        
        # Convert heatmap to RGB
        heatmap = np.uint8(255 * heatmap)
        heatmap = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)
        
        # Superimpose heatmap on original image
        superimposed_img = cv2.addWeighted(img, 0.6, heatmap, 0.4, 0)
        
        return superimposed_img
    
    def save_heatmap(self, image_path, heatmap, output_path):
        """Save heatmap overlay to file"""
        overlay = self.apply_heatmap(image_path, heatmap)
        overlay_bgr = cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR)
        cv2.imwrite(output_path, overlay_bgr)
        return output_path
