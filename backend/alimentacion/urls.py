from django.urls import path
from .views import (
    CatalogoView, BuscarAlimentosView, RegistrosDiaView,
    RegistroDetalleView, ResumenDiaView
)

urlpatterns = [
    path('catalogo/', CatalogoView.as_view(), name='catalogo'),
    path('buscar/', BuscarAlimentosView.as_view(), name='buscar_alimentos'),
    path('registros/', RegistrosDiaView.as_view(), name='registros_dia'),
    path('registros/<int:pk>/', RegistroDetalleView.as_view(), name='registro_detalle'),
    path('resumen/', ResumenDiaView.as_view(), name='resumen_dia'),
]
