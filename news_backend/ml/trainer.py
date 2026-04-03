import pandas as pd
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import LabelEncoder
import os

def train_model():
    # 1. Load your dataset
    csv_path = os.path.join("data", "..\\data\\dataset.csv")
    if not os.path.exists(csv_path):
        print(f"❌ Error: {csv_path} not found.")
        return None

    df = pd.read_csv(csv_path)

    # 2. Preprocess Sentiment (Convert 'positive', 'negative' to numbers)
    # Mapping: negative=0, neutral=1, positive=2
    le_sentiment = LabelEncoder()
    # 1. Drop rows where sentiment is missing
    df = df.dropna(subset=['sentiment'])

    # 2. Ensure all values are strings and lowercase
    df['sentiment'] = df['sentiment'].astype(str).str.lower()

    # 3. Now encode safely
    df['sentiment_encoded'] = le_sentiment.fit_transform(df['sentiment'])
        # 3. Define Features and Target
    # For a simple startup level, we use sentiment to predict market direction (UP/DOWN)
    # We assume 'positive' sentiment usually leads to 'UP' (1)
    X = df[['sentiment_encoded']]
    
    # Target: 1 for UP (Positive News), 0 for DOWN (Negative/Neutral)
    y = df['sentiment_encoded'].apply(lambda x: 1 if x == 2 else 0)

    # 4. Train Random Forest
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X, y)

    print(f"✅ NextMove Model trained on {len(df)} rows from dataset.")
    return model