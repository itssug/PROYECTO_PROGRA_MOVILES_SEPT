from django.urls import path
from .views import TrainModelView, GeneratePatternsView, PrediccionGlucosaView

urlpatterns = [
    path('train/<int:usuario_id>/', TrainModelView.as_view(), name='train_model'),
    path('patterns/generate/<int:usuario_id>/', GeneratePatternsView.as_view(), name='generate_patterns'),
    path('predict/<int:usuario_id>/', PrediccionGlucosaView.as_view(), name='predict_glucosa'),
]