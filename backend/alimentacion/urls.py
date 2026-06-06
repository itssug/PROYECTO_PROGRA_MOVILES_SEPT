from django.urls import path
from .views import (
    ComidasListView,
    ComidaCreateView,
    RegistroComidaListView,
    RegistroComidaDeleteView,
    ResumenDiarioView,
)

urlpatterns = [
    # Catálogo de comidas
    path('comidas/', ComidasListView.as_view(), name='comidas-list'),
    path('comidas/crear/', ComidaCreateView.as_view(), name='comidas-crear'),

    # Registro de comidas del usuario
    path('registro/', RegistroComidaListView.as_view(), name='registro-list'),
    path('registro/<int:pk>/', RegistroComidaDeleteView.as_view(), name='registro-delete'),

    # Resumen diario
    path('resumen/', ResumenDiarioView.as_view(), name='resumen-diario'),
]