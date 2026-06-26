from django.urls import path
from . import views

urlpatterns = [
    path('actividades/', views.actividades_list_create,
         name='actividades-list-create'),
    path('actividades/estadisticas/', views.actividades_estadisticas,
         name='actividades-estadisticas'),
    path('actividades/hoy/', views.actividades_hoy,
         name='actividades-hoy'),
    path('actividades/<int:pk>/', views.actividad_detail,
         name='actividad-detail'),
]