from django.core.management.base import BaseCommand
from datetime import date, timedelta, time
from random import randint, choice
from decimal import Decimal

from core.models import (
    Usuarios,
    RegistroSueno,
    EstadoEmocional,
    ActividadFisica,
    RegistroComidas,
    Glucosa,
    AnalisisGlucosa,
    Comidas
)


class Command(BaseCommand):

    help = "Genera dataset para entrenamiento ML"

    def handle(self, *args, **kwargs):

        usuario14, _ = Usuarios.objects.get_or_create(
            id=14,
            defaults={
                "nombre": "Maria Lopez",
                "email": "maria14@gmail.com",
                "password": "123456",
                "sexo": "femenino",
                "peso": 62,
                "altura": 165,
                "anios_diagnostico": 2,
                "hba1c_inicial": 5.4,
                "usa_insulina": 0,
                "nivel_actividad_base": "activo"
            }
        )

        usuario15, _ = Usuarios.objects.get_or_create(
            id=15,
            defaults={
                "nombre": "Roberto Vargas",
                "email": "roberto15@gmail.com",
                "password": "123456",
                "sexo": "masculino",
                "peso": 95,
                "altura": 170,
                "anios_diagnostico": 12,
                "hba1c_inicial": 9.2,
                "usa_insulina": 1,
                "nivel_actividad_base": "sedentario"
            }
        )

        saludables = [2,4,5,6,7,8,9,11,13,15,18,19,20,23,25]
        riesgo = [1,3,10,16,21,22,24]

        inicio = date(2025, 1, 1)

        for dia in range(120):

            fecha = inicio + timedelta(days=dia)

            for usuario, sano in [(usuario14, True), (usuario15, False)]:

                # -------------------------
                # SUEÑO
                # -------------------------
                if sano:
                    horas_sueno = round(choice([7.0, 7.5, 8.0, 8.5, 9.0]), 2)
                    estres = randint(1, 3)

                    estado_val = "tranquilo"
                    calidad_sueno = "bueno"
                    despertares = 0
                else:
                    horas_sueno = round(choice([4.0, 4.5, 5.0, 5.5, 6.0]), 2)
                    estres = randint(7, 10)

                    estado_val = "estresado"
                    calidad_sueno = "malo"
                    despertares = 1

                sueno = RegistroSueno.objects.create(
                    usuario=usuario,
                    fecha=fecha,
                    horas_dormidas=horas_sueno,
                    calidad=calidad_sueno,
                    hubo_despertares=despertares
                )

                emocional = EstadoEmocional.objects.create(
                    usuario=usuario,
                    fecha=fecha,
                    nivel_estres=estres,
                    estado=estado_val
                )

                tipos_sanos = ["caminata", "trote", "ciclismo", "natacion", "pesas", "yoga"]
                tipos_riesgo = ["otro_anaerobico", "otro_aerobico"]

                actividad = ActividadFisica.objects.create(
                    usuario=usuario,
                    tipo=choice(tipos_sanos) if sano else choice(tipos_riesgo),
                    intensidad=choice(["leve", "moderada", "intensa"]),
                    duracion=randint(20, 90) if sano else randint(0, 20),
                    pasos=randint(3000, 12000) if sano else randint(500, 2500),
                    fecha=fecha
                )

                # -------------------------
                # COMIDAS + GLUCOSA
                # -------------------------
                for tipo_comida in ["desayuno", "almuerzo", "cena"]:

                    comida_id = choice(saludables) if sano else choice(riesgo)
                    glucosa_pre = randint(85, 120) if sano else randint(150, 230)

                    comida = Comidas.objects.get(id=comida_id)

                    registro = RegistroComidas.objects.create(
                        usuario=usuario,
                        comida=comida,
                        cantidad=100,
                        unidad="gramos",
                        tipo_comida=tipo_comida,
                        fecha=fecha,
                        hora=time(randint(7, 20), 0),
                        calorias_calculadas=comida.calorias,
                        carbohidratos_calculados=comida.carbohidratos,
                        carga_glucemica_calc=comida.carga_glucemica
                    )

                    # -------------------------
                    # IMPACTO (Decimal-safe)
                    # -------------------------
                    if sano:
                        impacto = (
                            Decimal(comida.carga_glucemica) * Decimal("0.8")
                            + Decimal(estres) * Decimal("1.5")
                            - Decimal(actividad.duracion) * Decimal("0.2")
                        )
                    else:
                        impacto = (
                            Decimal(comida.carga_glucemica) * Decimal("2.5")
                            + Decimal(estres) * Decimal("3")
                            - Decimal(actividad.duracion) * Decimal("0.1")
                        )

                    glucosa_post = float(Decimal(glucosa_pre) + impacto)
                    glucosa_post = round(glucosa_post, 2)

                    # -------------------------
                    # GLUCOSA PRE
                    # -------------------------
                    Glucosa.objects.create(
                        usuario=usuario,
                        nivel_glucosa=glucosa_pre,
                        tipo_medicion="pre_desayuno",
                        fecha=fecha,
                        hora=time(randint(7, 20), 0),
                        registro_comida=registro,
                        actividad=actividad
                    )

                    # -------------------------
                    # GLUCOSA POST
                    # -------------------------
                    Glucosa.objects.create(
                        usuario=usuario,
                        nivel_glucosa=glucosa_post,
                        tipo_medicion="post_desayuno",
                        fecha=fecha,
                        hora=time(randint(7, 20), 30),
                        registro_comida=registro,
                        actividad=actividad
                    )
                    # -------------------------
                    # CLASIFICACIÓN
                    # -------------------------
                    if glucosa_post < 70:
                        clasificacion = "hipo_detectada"

                    elif glucosa_post < 90:
                        clasificacion = "respuesta_baja"

                    elif glucosa_post < 140:
                        clasificacion = "respuesta_normal"

                    elif glucosa_post < 180:
                        clasificacion = "respuesta_alta"

                    else:
                        clasificacion = "hiper_detectada"

                    # -------------------------
                    # ANALISIS (SIN "diferencia")
                    # -------------------------
                    AnalisisGlucosa.objects.create(
                        usuario=usuario,
                        fecha=fecha,
                        glucosa_antes=glucosa_pre,
                        glucosa_despues=glucosa_post,
                        registro_comida=registro,
                        actividad=actividad,
                        diferencia = glucosa_pre - glucosa_post,
                        estado_emocional=emocional,
                        sueno=sueno,
                        carga_glucemica_total=comida.carga_glucemica,
                        prediccion_impacto=impacto,
                        confianza_prediccion=Decimal("0.90"),
                        alimento_culpable=comida.nombre,
                        clasificacion_respuesta=clasificacion
                        )
                    
        self.stdout.write(
            self.style.SUCCESS("Dataset generado correctamente")
        )