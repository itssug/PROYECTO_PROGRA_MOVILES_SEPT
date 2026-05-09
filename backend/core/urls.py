from django.urls import path
from .views import RegistroView, LoginView, LogoutView, PerfilView

urlpatterns = [
    path('auth/registro/', RegistroView.as_view(), name='registro'),
    path('auth/login/',    LoginView.as_view(),    name='login'),
    path('auth/logout/',   LogoutView.as_view(),   name='logout'),
    path('auth/perfil/',   PerfilView.as_view(),   name='perfil'),
]