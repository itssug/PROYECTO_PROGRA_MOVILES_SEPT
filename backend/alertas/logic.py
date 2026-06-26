from datetime import date
from django.db.models import Sum
from core.models import RegistroComidas, Alertas

# ── Límites recomendados para diabetes tipo 2 ──
# Ajustables: en el futuro pueden venir de la tabla 'objetivos'
LIMITE_CARBOHIDRATOS_DIA = 180.0  # gramos/día
LIMITE_AZUCARES_DIA = 25.0        # gramos/día (límite estricto, ADA)


def calcular_consumo_hoy(usuario_id):
    """Suma carbohidratos y azúcares consumidos hoy por el usuario."""
    hoy = date.today()
    registros = RegistroComidas.objects.filter(
        usuario_id=usuario_id, fecha=hoy
    )
    totales = registros.aggregate(
        carbohidratos=Sum('carbohidratos_calculados'),
        azucares=Sum('azucares_calculados'),
    )
    return {
        'carbohidratos': float(totales['carbohidratos'] or 0),
        'azucares': float(totales['azucares'] or 0),
    }


def verificar_y_crear_alerta(usuario_id):
    """
    Revisa el consumo acumulado de HOY y crea una alerta si supera
    los límites recomendados. Se llama después de registrar una comida.
    Evita duplicar alertas del mismo tipo en el mismo día.
    """
    consumo = calcular_consumo_hoy(usuario_id)
    hoy = date.today()
    alertas_creadas = []

    # ── Verificar carbohidratos ──
    if consumo['carbohidratos'] > LIMITE_CARBOHIDRATOS_DIA:
        ya_existe = Alertas.objects.filter(
            usuario_id=usuario_id,
            tipo='exceso_carbohidratos',
            fecha__date=hoy,
        ).exists()
        if not ya_existe:
            exceso = consumo['carbohidratos'] - LIMITE_CARBOHIDRATOS_DIA
            alerta = Alertas.objects.create(
                usuario_id=usuario_id,
                tipo='exceso_carbohidratos',
                prioridad='alta',
                titulo='Límite de carbohidratos superado',
                mensaje=(
                    f'Has consumido {consumo["carbohidratos"]:.1f}g de '
                    f'carbohidratos hoy, superando el límite recomendado '
                    f'de {LIMITE_CARBOHIDRATOS_DIA:.0f}g por {exceso:.1f}g. '
                    f'Considera reducir tu ingesta el resto del día.'
                ),
                leido=0,
            )
            alertas_creadas.append(alerta)

    # ── Verificar azúcares ──
    if consumo['azucares'] > LIMITE_AZUCARES_DIA:
        ya_existe = Alertas.objects.filter(
            usuario_id=usuario_id,
            tipo='exceso_azucares',
            fecha__date=hoy,
        ).exists()
        if not ya_existe:
            exceso = consumo['azucares'] - LIMITE_AZUCARES_DIA
            alerta = Alertas.objects.create(
                usuario_id=usuario_id,
                tipo='exceso_azucares',
                prioridad='alta',
                titulo='Límite de azúcares superado',
                mensaje=(
                    f'Has consumido {consumo["azucares"]:.1f}g de azúcares '
                    f'hoy, superando el límite recomendado de '
                    f'{LIMITE_AZUCARES_DIA:.0f}g por {exceso:.1f}g. '
                    f'Esto puede afectar tus niveles de glucosa.'
                ),
                leido=0,
            )
            alertas_creadas.append(alerta)

    return alertas_creadas


def generar_resumen_diario(usuario_id):
    """
    Genera una alerta-resumen del día con el % del límite alcanzado.
    Se llama al consultar el dashboard o al final del día.
    """
    consumo = calcular_consumo_hoy(usuario_id)
    hoy = date.today()

    ya_existe = Alertas.objects.filter(
        usuario_id=usuario_id,
        tipo='resumen_diario',
        fecha__date=hoy,
    ).exists()
    if ya_existe:
        return None

    pct_carbos = (consumo['carbohidratos'] / LIMITE_CARBOHIDRATOS_DIA) * 100
    pct_azucares = (consumo['azucares'] / LIMITE_AZUCARES_DIA) * 100

    if pct_carbos >= 90 or pct_azucares >= 90:
        prioridad = 'alta'
    elif pct_carbos >= 70 or pct_azucares >= 70:
        prioridad = 'media'
    else:
        prioridad = 'baja'

    alerta = Alertas.objects.create(
        usuario_id=usuario_id,
        tipo='resumen_diario',
        prioridad=prioridad,
        titulo='Resumen nutricional del día',
        mensaje=(
            f'Hoy llevas {consumo["carbohidratos"]:.1f}g de carbohidratos '
            f'({pct_carbos:.0f}% de tu límite) y {consumo["azucares"]:.1f}g '
            f'de azúcares ({pct_azucares:.0f}% de tu límite).'
        ),
        leido=0,
    )
    return alerta