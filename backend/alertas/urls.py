from django.urls import path
from rest_framework.routers import DefaultRouter
from .views import AlertasViewSet, VerificarAlertasView, ResumenDiarioView

router = DefaultRouter()
router.register(r'alertas', AlertasViewSet, basename='alertas')

urlpatterns = router.urls + [
    path('verificar/', VerificarAlertasView.as_view(), name='verificar-alertas'),
    path('resumen-diario/', ResumenDiarioView.as_view(), name='resumen-diario'),
]