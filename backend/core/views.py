from rest_framework.response import Response
from rest_framework.decorators import api_view
from django.db import connection

@api_view(['GET'])
def test(request):

    with connection.cursor() as cursor:
        cursor.execute("SELECT DATABASE();")
        row = cursor.fetchone()

    return Response({
        "database": row[0],
        "mensaje": "MySQL conectado correctamente"
    })