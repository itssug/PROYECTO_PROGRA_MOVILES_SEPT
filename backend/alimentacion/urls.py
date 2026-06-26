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
    ComidasListView,
    ComidaCreateView,
    RegistroComidaListView,
    RegistroComidaDeleteView,
    ResumenDiarioView,
    ResumenHistoricoView, 
    DietasCatologoView,   
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

    path('historico/', ResumenHistoricoView.as_view(), name='resumen-historico'),
    path('dietas/', DietasCatologoView.as_view(), name='dietas-catalogo'),
]
