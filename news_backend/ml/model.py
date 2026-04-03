import numpy as np

def predict_ml(model, sentiment_score, auth_val):
    """
    Predicts using the trained model.
    Input: sentiment_score (float from -1 to 1)
    """
    if model is None:
        return 0

    # Convert the live -1 to 1 score into the model's categories (0, 1, 2)
    # Logic: < -0.2 (Neg), -0.2 to 0.2 (Neu), > 0.2 (Pos)
    if sentiment_score < -0.2:
        encoded_val = 0 # Negative
    elif sentiment_score > 0.2:
        encoded_val = 2 # Positive
    else:
        encoded_val = 1 # Neutral

    # Prepare input for the model
    # Note: If you add more columns later, add them here
    features = np.array([[encoded_val]])
    
    prediction = model.predict(features)
    return int(prediction[0])