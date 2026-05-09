import hashlib
import secrets
from django.utils import timezone
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import AllowAny
import secrets
from django.utils import timezone

from .models import Usuarios, Objetivos
from .serializers import RegistroSerializer, LoginSerializer, UsuarioPublicoSerializer
from .token_model import TokenUsuario


class DebugTokenView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    
    def get(self, request):
        key = request.headers.get('Authorization', '').replace('Token ', '')
        
        response_data = {
            "token_recibido": key,
            "longitud_token": len(key) if key else 0,
            "tokens_en_bd": [],
            "error": None
        }
        
        try:
            # Buscar el token
            token_obj = TokenUsuario.objects.filter(key=key).first()
            if token_obj:
                response_data["token_encontrado"] = True
                response_data["usuario_id"] = token_obj.usuario_id
                response_data["creado"] = str(token_obj.creado)
            else:
                response_data["token_encontrado"] = False
                # Listar los primeros 5 tokens para depuración
                tokens = TokenUsuario.objects.all().values('key', 'usuario_id')[:5]
                response_data["tokens_en_bd"] = list(tokens)
        except Exception as e:
            response_data["error"] = str(e)
        
        return Response(response_data)

class RegistroView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = RegistroSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        usuario = serializer.save()

        Objetivos.objects.create(
            usuario=usuario,
            glucosa_ayunas_min=80, glucosa_ayunas_max=130,
            glucosa_post_min=80,   glucosa_post_max=180,
            fecha_inicio=timezone.now().date(),
            activo=1,
        )

        token = TokenUsuario.crear(usuario)
        return Response({
            "token": token.key,
            "usuario": UsuarioPublicoSerializer(usuario).data,
        }, status=status.HTTP_201_CREATED)


class LoginView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        usuario = serializer.validated_data['usuario']
        token = TokenUsuario.crear(usuario)
        return Response({
            "token": token.key,
            "usuario": UsuarioPublicoSerializer(usuario).data,
        }, status=status.HTTP_200_OK)


class LogoutView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        key = request.headers.get('Authorization', '').replace('Token ', '')
        TokenUsuario.objects.filter(key=key).delete()
        return Response({"mensaje": "Sesión cerrada."})


# views.py - Corregir método _get_usuario
class PerfilView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []
    def _get_usuario(self, request):
        # Obtener el token del header
        auth_header = request.headers.get('Authorization', '')
        key = auth_header.replace('Token ', '').strip()
        
        print(f"🔍 Debug - Header completo: {auth_header}")
        print(f"🔍 Debug - Token extraído: '{key}'")
        print(f"🔍 Debug - Longitud token: {len(key)}")
        
        if not key:
            print("❌ No hay token en el header")
            return None
        
        try:
            # Buscar el token en la base de datos
            token_obj = TokenUsuario.objects.get(key=key)
            print(f"✅ Token encontrado en BD para usuario_id: {token_obj.usuario_id}")
            
            # Obtener el usuario
            from .models import Usuarios
            usuario = Usuarios.objects.get(id=token_obj.usuario_id)
            print(f"✅ Usuario encontrado: {usuario.email}")
            return usuario
            
        except TokenUsuario.DoesNotExist:
            print(f"❌ Token no existe en BD: {key}")
            # Listar tokens existentes para depuración
            tokens_existentes = TokenUsuario.objects.all().values_list('key', flat=True)[:3]
            print(f"📋 Tokens en BD (primeros 3): {list(tokens_existentes)}")
            return None
            
        except Usuarios.DoesNotExist:
            print(f"❌ Usuario no encontrado para id: {token_obj.usuario_id}")
            return None
        
        except Exception as e:
            print(f"❌ Error inesperado: {e}")
            return None

    def get(self, request):
        usuario = self._get_usuario(request)
        if not usuario:
            return Response({"error": "Token inválido."}, status=status.HTTP_401_UNAUTHORIZED)
        return Response(UsuarioPublicoSerializer(usuario).data)
    def put(self, request):  # ← Agregar esto
        usuario = self._get_usuario(request)
        if not usuario:
            return Response({"error": "Token inválido."}, status=status.HTTP_401_UNAUTHORIZED)

        serializer = UsuarioPublicoSerializer(usuario, data=request.data, partial=True)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        serializer.save()
        return Response(serializer.data)