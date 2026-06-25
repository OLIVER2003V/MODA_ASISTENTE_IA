import pandas as pd
from sklearn.model_selection import train_test_split
from sklearn.ensemble import RandomForestClassifier, GradientBoostingClassifier
from sklearn.svm import SVC
from sklearn.neighbors import KNeighborsClassifier
from sklearn.neural_network import MLPClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.pipeline import make_pipeline
from sklearn.metrics import accuracy_score

df = pd.read_csv('models/face_shape_dataset.csv')
X = df[['height_ratio', 'jaw_ratio', 'forehead_ratio']]
y = df['label']

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

models = {
    'RF (max_depth=5)': RandomForestClassifier(n_estimators=100, max_depth=5, random_state=42),
    'RF (max_depth=3)': RandomForestClassifier(n_estimators=100, max_depth=3, random_state=42),
    'SVC (rbf)': make_pipeline(StandardScaler(), SVC(kernel='rbf', C=1.0)),
    'SVC (linear)': make_pipeline(StandardScaler(), SVC(kernel='linear', C=1.0)),
    'KNN (k=7)': make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=7)),
    'KNN (k=15)': make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=15)),
    'MLP (16,8)': make_pipeline(StandardScaler(), MLPClassifier(hidden_layer_sizes=(16, 8), max_iter=1000, random_state=42)),
    'GB': GradientBoostingClassifier(n_estimators=50, max_depth=3, random_state=42)
}

for name, clf in models.items():
    clf.fit(X_train, y_train)
    acc = accuracy_score(y_test, clf.predict(X_test))
    print(f'{name}: {acc*100:.2f}%')
