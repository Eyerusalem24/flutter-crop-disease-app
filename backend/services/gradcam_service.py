import torch
import torch.nn.functional as F
import numpy as np
import cv2

class GradCAMService:
    def __init__(self, model, target_layer_name="features"):
        self.model = model
        self.model.eval()

        self.gradients = None
        self.activations = None

        # Hook the last convolution layer of EfficientNet
        target_layer = self._find_target_layer(target_layer_name)

        target_layer.register_forward_hook(self._forward_hook)
        target_layer.register_full_backward_hook(self._backward_hook)

    def _find_target_layer(self, name):
        """
        EfficientNet structure:
        model.features is the main conv backbone
        """
        return getattr(self.model, name)

    def _forward_hook(self, module, input, output):
        self.activations = output

    def _backward_hook(self, module, grad_input, grad_output):
        self.gradients = grad_output[0]

    def get_heatmap(self, image_tensor, class_idx):
        """
        image_tensor shape: [1, 3, H, W]
        """

        self.model.zero_grad()

        output = self.model(image_tensor)

        loss = output[0, class_idx]
        loss.backward()

        # Global average pooling of gradients
        pooled_grads = torch.mean(self.gradients, dim=[0, 2, 3])

        activations = self.activations[0]

        for i in range(len(pooled_grads)):
            activations[i, :, :] *= pooled_grads[i]

        heatmap = torch.mean(activations, dim=0).detach().cpu().numpy()

        # Normalize
        heatmap = np.maximum(heatmap, 0)
        heatmap /= np.max(heatmap + 1e-8)

        return heatmap

    def save_heatmap(self, original_image_path, heatmap, output_path):
        """
        Overlay heatmap on original image
        """

        img = cv2.imread(original_image_path)
        img = cv2.resize(img, (224, 224))

        heatmap = cv2.resize(heatmap, (224, 224))
        heatmap = np.uint8(255 * heatmap)

        heatmap = cv2.applyColorMap(heatmap, cv2.COLORMAP_JET)

        overlay = cv2.addWeighted(img, 0.6, heatmap, 0.4, 0)

        cv2.imwrite(output_path, overlay)