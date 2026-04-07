"""
Smart Student Task Prioritizer — ML Training Script
Run: python train_model.py
Output: priority_model.joblib (load this in FastAPI)
"""

import numpy as np
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.model_selection import train_test_split
from sklearn.metrics import mean_squared_error, r2_score
from sklearn.preprocessing import LabelEncoder
import joblib
import math

# ─── 1. SYNTHETIC TRAINING DATA ────────────────────────────────────────────────
np.random.seed(42)
N = 2000

categories = ["Academic", "Personal", "Extracurricular"]
statuses   = ["Pending", "In Progress"]

data = {
    "hours_remaining": np.random.uniform(1, 336, N),      # 1 hr → 2 weeks
    "task_weight":     np.random.uniform(0.05, 0.50, N),  # 5% → 50%
    "effort_level":    np.random.randint(1, 6, N),         # 1–5
    "category":        np.random.choice(categories, N),
}
df = pd.DataFrame(data)

# ─── 2. FEATURE ENGINEERING ────────────────────────────────────────────────────
# Core urgency formula from the spec
df["urgency_factor"] = df["task_weight"] / (np.log(df["hours_remaining"] + 1))

# Normalized hours (0–1, inverted so fewer hours = higher score)
df["hours_norm"] = 1 - (df["hours_remaining"] / 336).clip(0, 1)

# Effort normalized
df["effort_norm"] = df["effort_level"] / 5.0

# Category weights (Academic tasks get a slight boost)
category_map = {"Academic": 1.0, "Extracurricular": 0.75, "Personal": 0.5}
df["category_weight"] = df["category"].map(category_map)

# Encode category as integer for the model
le = LabelEncoder()
df["category_encoded"] = le.fit_transform(df["category"])

# ─── 3. SYNTHETIC TARGET (Priority Score 0.0 → 1.0) ──────────────────────────
# We simulate what a "smart" student would prioritize
raw_score = (
    0.40 * df["urgency_factor"] / df["urgency_factor"].max() +
    0.25 * df["hours_norm"] +
    0.20 * df["effort_norm"] +
    0.15 * df["category_weight"]
)
# Add slight noise to make the model generalize
noise = np.random.normal(0, 0.03, N)
df["priority_score"] = (raw_score + noise).clip(0, 1)

# ─── 4. TRAIN / TEST SPLIT ───────────────────────────────────────────────────
features = [
    "hours_remaining",
    "task_weight",
    "effort_level",
    "urgency_factor",
    "hours_norm",
    "effort_norm",
    "category_weight",
    "category_encoded",
]

X = df[features]
y = df["priority_score"]

X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# ─── 5. TRAIN RANDOM FOREST ──────────────────────────────────────────────────
model = RandomForestRegressor(
    n_estimators=200,
    max_depth=12,
    min_samples_split=5,
    min_samples_leaf=2,
    random_state=42,
    n_jobs=-1,
)
model.fit(X_train, y_train)

# ─── 6. EVALUATE ─────────────────────────────────────────────────────────────
y_pred = model.predict(X_test)
rmse = math.sqrt(mean_squared_error(y_test, y_pred))
r2   = r2_score(y_test, y_pred)
print(f"✅ RMSE : {rmse:.4f}")
print(f"✅ R²   : {r2:.4f}")

# Feature importances
print("\nFeature importances:")
for feat, imp in sorted(
    zip(features, model.feature_importances_), key=lambda x: -x[1]
):
    print(f"  {feat:<22} {imp:.4f}")

# ─── 7. SAVE MODEL + ENCODER ─────────────────────────────────────────────────
joblib.dump(model, "priority_model.joblib")
joblib.dump(le,    "category_encoder.joblib")
print("\n✅ Saved: priority_model.joblib")
print("✅ Saved: category_encoder.joblib")


# ─── 8. HELPER — SCORE A SINGLE TASK (for testing) ───────────────────────────
def score_task(hours_remaining: float,
               task_weight: float,
               effort_level: int,
               category: str) -> float:
    """
    Score one task manually — same logic the FastAPI endpoint uses.
    category must be one of: 'Academic', 'Personal', 'Extracurricular'
    """
    urgency_factor  = task_weight / math.log(hours_remaining + 1)
    hours_norm      = 1 - min(hours_remaining / 336, 1)
    effort_norm     = effort_level / 5.0
    cat_map         = {"Academic": 1.0, "Extracurricular": 0.75, "Personal": 0.5}
    category_weight = cat_map.get(category, 0.75)
    cat_encoded     = int(le.transform([category])[0])

    row = [[
        hours_remaining,
        task_weight,
        effort_level,
        urgency_factor,
        hours_norm,
        effort_norm,
        category_weight,
        cat_encoded,
    ]]
    return float(model.predict(row)[0])


if __name__ == "__main__":
    # Quick sanity check
    print("\n--- Sanity check ---")
    print("Final exam  (24h, 40%, effort 5, Academic):",
          round(score_task(24, 0.40, 5, "Academic"), 3))
    print("Quiz        (72h, 10%, effort 2, Academic):",
          round(score_task(72, 0.10, 2, "Academic"), 3))
    print("Club event  (48h, 5%,  effort 1, Extracurricular):",
          round(score_task(48, 0.05, 1, "Extracurricular"), 3))
