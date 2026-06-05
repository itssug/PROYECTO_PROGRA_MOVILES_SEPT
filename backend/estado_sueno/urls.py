from rest_framework.routers import DefaultRouter
from .views import EstadoEmocionalViewSet, RegistroSuenoViewSet

router = DefaultRouter()
router.register(r'estado-emocional', EstadoEmocionalViewSet, basename='estado-emocional')
router.register(r'registro-sueno', RegistroSuenoViewSet, basename='registro-sueno')

urlpatterns = router.urls