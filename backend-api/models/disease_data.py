DISEASE_CLASSES = {
    'maize': ['Gray Leaf Spot', 'Common Rust', 'Northern Leaf Blight', 'Healthy'],
    'tomato': ['Late Blight', 'Early Blight', 'Leaf Mold', 'Septoria Leaf Spot', 'Healthy'],
    'potato': ['Late Blight', 'Early Blight', 'Healthy'],
    'wheat': ['Stripe Rust', 'Leaf Rust', 'Stem Rust', 'Healthy'],
    'rice': ['Blast', 'Blight', 'Sheath Rot', 'Healthy']
}

TREATMENTS = {
    'maize': {
        'Gray Leaf Spot': 'Apply fungicides. Remove infected leaves. Rotate crops for 2 years.',
        'Common Rust': 'Use resistant varieties. Apply fungicides if severe.',
        'Northern Leaf Blight': 'Apply fungicides. Practice crop rotation.',
        'Healthy': 'Your maize crop is healthy! Continue good practices.'
    },
    'tomato': {
        'Late Blight': 'Remove infected leaves. Apply copper-based fungicides.',
        'Early Blight': 'Prune lower leaves. Apply fungicides containing chlorothalonil.',
        'Leaf Mold': 'Improve air circulation. Reduce leaf wetness.',
        'Septoria Leaf Spot': 'Remove infected leaves. Apply fungicides.',
        'Healthy': 'Your tomato crop is healthy!'
    },
    'potato': {
        'Late Blight': 'Apply fungicides immediately. Destroy infected plants.',
        'Early Blight': 'Rotate crops. Apply protective fungicides.',
        'Healthy': 'Your potato crop is healthy!'
    },
    'wheat': {
        'Stripe Rust': 'Use resistant varieties. Apply fungicides at first sign.',
        'Leaf Rust': 'Apply fungicides. Plant resistant varieties.',
        'Stem Rust': 'Destroy volunteer wheat. Apply fungicides.',
        'Healthy': 'Your wheat crop is healthy!'
    },
    'rice': {
        'Blast': 'Use resistant varieties. Apply silicon fertilizers.',
        'Blight': 'Drain fields. Avoid excess nitrogen.',
        'Sheath Rot': 'Apply fungicides. Use clean seeds.',
        'Healthy': 'Your rice crop is healthy!'
    }
}
