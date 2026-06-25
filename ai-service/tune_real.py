import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.metrics import accuracy_score

df = pd.read_csv('models/face_shape_dataset_real.csv')

# Crear características adicionales
df['ratio_f_j'] = df['forehead_width'] / df['jaw_width']
df['ratio_h_j'] = df['face_height'] / df['jaw_width']
df['ratio_h_f'] = df['face_height'] / df['forehead_width']
df['ratio_c_j'] = df['cheekbone_width'] / df['jaw_width']

X = df[['height_ratio', 'jaw_ratio', 'forehead_ratio', 'ratio_f_j', 'ratio_h_j', 'ratio_h_f', 'ratio_c_j']]
y = df['label']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

models = {
    'RF (max_depth=5)': RandomForestClassifier(n_estimators=150, max_depth=5, random_state=42),
    'RF (max_depth=7)': RandomForestClassifier(n_estimators=150, max_depth=7, random_state=42),
    'SVC (rbf)': make_pipeline(StandardScaler(), SVC(kernel='rbf', C=1.5, random_state=42)),
    'SVC (linear)': make_pipeline(StandardScaler(), SVC(kernel='linear', C=1.0, random_state=42)),
    'KNN (k=9)': make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=9)),
    'GB (depth=3)': GradientBoostingClassifier(n_estimators=100, max_depth=3, random_state=42)
}

for name, clf in models.items():
    clf.fit(X_train, y_train)
    acc = accuracy_score(y_test, clf.predict(X_test))
    print(f'{name}: {acc*100:.2f}%')
