import sys

content = open('core/views.py', 'rb').read().replace(b'\x00', b'').decode('utf-8', errors='ignore')

append_str = """
from .serializers import GlucosaSerializer
from .models import Glucosa

class GlucosaView(APIView):
    permission_classes = [AllowAny]
    authentication_classes = []

    def post(self, request):
        # Temporarily read user_id from headers/body until JWT
        user_id = request.headers.get('X-User-Id') or request.data.get('usuario')
        if not user_id:
            return Response({"error": "Se requiere usuario id"}, status=status.HTTP_400_BAD_REQUEST)
        
        data = request.data.copy()
        data['usuario'] = user_id
        
        from datetime import date, datetime
        if 'fecha' not in data:
            data['fecha'] = str(date.today())
        if 'hora' not in data:
            data['hora'] = str(datetime.now().time().strftime("%H:%M:%S"))
        if 'tipo_medicion' not in data:
            data['tipo_medicion'] = 'aleatoria'
            
        serializer = GlucosaSerializer(data=data)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
"""

open('core/views.py', 'w', encoding='utf-8').write(content + append_str)
