from django.urls import path
from .views import TrainModelView, GeneratePatternsView, PrediccionGlucosaView, GlobalModelStatusView, GlobalModelTrainView

urlpatterns = [
    path('train/<int:usuario_id>/', TrainModelView.as_view(), name='train_model'),
    path('patterns/generate/<int:usuario_id>/', GeneratePatternsView.as_view(), name='generate_patterns'),
    path('predict/<int:usuario_id>/', PrediccionGlucosaView.as_view(), name='predict_glucosa'),
    path('model/global/status/', GlobalModelStatusView.as_view(), name='global_model_status'),
    path('model/global/train/', GlobalModelTrainView.as_view(), name='global_model_train'),
]