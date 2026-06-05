# This is an auto-generated Django model module.
# You'll have to do the following manually to clean this up:
#   * Rearrange models' order
#   * Make sure each model has one field with primary_key=True
#   * Make sure each ForeignKey and OneToOneField has `on_delete` set to the desired behavior
#   * Remove `managed = False` lines if you wish to allow Django to create, modify, and delete the table
# Feel free to rename the models, but don't rename db_table values or field names.
from django.db import models


class ActividadFisica(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    tipo = models.CharField(max_length=15)
    intensidad = models.CharField(max_length=8, blank=True, null=True)
    duracion = models.IntegerField()
    calorias_quemadas = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    pasos = models.IntegerField(blank=True, null=True)
    frecuencia_cardiaca_prom = models.IntegerField(blank=True, null=True)
    fecha = models.DateField()
    hora_inicio = models.TimeField(blank=True, null=True)
    glucosa_pre = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_post = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'actividad_fisica'


class Alertas(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    tipo = models.CharField(max_length=24)
    prioridad = models.CharField(max_length=7, blank=True, null=True)
    titulo = models.CharField(max_length=150, blank=True, null=True)
    mensaje = models.TextField(blank=True, null=True)
    leido = models.IntegerField(blank=True, null=True)
    fecha = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'alertas'


class AnalisisGlucosa(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    fecha = models.DateField()
    glucosa_antes = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_despues = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    diferencia = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    registro_comida = models.ForeignKey('RegistroComidas', models.DO_NOTHING, blank=True, null=True)
    actividad = models.ForeignKey(ActividadFisica, models.DO_NOTHING, blank=True, null=True)
    estado_emocional = models.ForeignKey('EstadoEmocional', models.DO_NOTHING, blank=True, null=True)
    sueno = models.ForeignKey('RegistroSueno', models.DO_NOTHING, blank=True, null=True)
    carga_glucemica_total = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    prediccion_impacto = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    confianza_prediccion = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    alimento_culpable = models.CharField(max_length=150, blank=True, null=True)
    clasificacion_respuesta = models.CharField(max_length=16, blank=True, null=True)
    notas_ia = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'analisis_glucosa'


class Comidas(models.Model):
    id = models.BigAutoField(primary_key=True)
    nombre = models.CharField(max_length=150)
    descripcion = models.TextField(blank=True, null=True)
    categoria = models.CharField(max_length=13, blank=True, null=True)
    calorias = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    carbohidratos = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    azucares = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    fibra = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    proteinas = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    grasas = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    sodio = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    indice_glucemico = models.IntegerField(blank=True, null=True)
    carga_glucemica = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    unidad_medida = models.CharField(max_length=9, blank=True, null=True)
    porcion_tipica = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    es_personalizado = models.IntegerField(blank=True, null=True)
    usuario_id = models.PositiveBigIntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'comidas'


class EstadoEmocional(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    fecha = models.DateField()
    hora = models.TimeField(blank=True, null=True)
    nivel_estres = models.IntegerField()
    estado = models.CharField(max_length=9)
    evento = models.CharField(max_length=255, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'estado_emocional'


class FeedbackPredicciones(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    analisis = models.ForeignKey(AnalisisGlucosa, models.DO_NOTHING, blank=True, null=True)
    prediccion_ia = models.TextField(blank=True, null=True)
    fue_correcta = models.IntegerField(blank=True, null=True)
    calificacion = models.IntegerField(blank=True, null=True)
    comentario_usuario = models.TextField(blank=True, null=True)
    correccion = models.TextField(blank=True, null=True)
    fecha = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'feedback_predicciones'


class Glucosa(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    nivel_glucosa = models.DecimalField(max_digits=5, decimal_places=2)
    tipo_medicion = models.CharField(max_length=13)
    fecha = models.DateField()
    hora = models.TimeField()
    registro_comida = models.ForeignKey('RegistroComidas', models.DO_NOTHING, blank=True, null=True)
    actividad = models.ForeignKey(ActividadFisica, models.DO_NOTHING, blank=True, null=True)
    medicamento_id = models.PositiveBigIntegerField(blank=True, null=True)
    clasificacion = models.CharField(max_length=13, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'glucosa'


class Hba1C(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    valor = models.DecimalField(max_digits=4, decimal_places=2)
    fecha = models.DateField()
    laboratorio = models.CharField(max_length=100, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'hba1c'


class HistorialPeso(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    peso = models.DecimalField(max_digits=5, decimal_places=2)
    imc = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    cintura = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    fecha = models.DateField()
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'historial_peso'


class Medicamentos(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    nombre = models.CharField(max_length=150)
    tipo = models.CharField(max_length=15, blank=True, null=True)
    dosis = models.CharField(max_length=100, blank=True, null=True)
    unidad = models.CharField(max_length=3, blank=True, null=True)
    hora_toma = models.TimeField(blank=True, null=True)
    relacion_comida = models.CharField(max_length=13, blank=True, null=True)
    frecuencia = models.CharField(max_length=15, blank=True, null=True)
    fecha_inicio = models.DateField(blank=True, null=True)
    fecha_fin = models.DateField(blank=True, null=True)
    activo = models.IntegerField(blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'medicamentos'


class Objetivos(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    glucosa_ayunas_min = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_ayunas_max = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_post_min = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_post_max = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    calorias_diarias = models.IntegerField(blank=True, null=True)
    carbohidratos_dia = models.IntegerField(blank=True, null=True)
    pasos_diarios = models.IntegerField(blank=True, null=True)
    peso_objetivo = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    hba1c_objetivo = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField(blank=True, null=True)
    activo = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'objetivos'


class PatronesAprendidos(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    comida = models.ForeignKey(Comidas, models.DO_NOTHING, blank=True, null=True)
    veces_registrada = models.IntegerField(blank=True, null=True)
    impacto_promedio = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    impacto_maximo = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    impacto_minimo = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    desviacion_estandar = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    clasificacion = models.CharField(max_length=8, blank=True, null=True)
    nivel_confianza = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    peor_en_estres = models.IntegerField(blank=True, null=True)
    peor_sin_dormir = models.IntegerField(blank=True, null=True)
    mejor_con_ejercicio = models.IntegerField(blank=True, null=True)
    mejor_con_medicamento = models.IntegerField(blank=True, null=True)
    ultima_actualizacion = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'patrones_aprendidos'
        unique_together = (('usuario', 'comida'),)


class RegistroComidas(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    comida = models.ForeignKey(Comidas, models.DO_NOTHING)
    cantidad = models.DecimalField(max_digits=7, decimal_places=2)
    unidad = models.CharField(max_length=9, blank=True, null=True)
    tipo_comida = models.CharField(max_length=12)
    fecha = models.DateField()
    hora = models.TimeField()
    calorias_calculadas = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    carbohidratos_calculados = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    azucares_calculados = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    carga_glucemica_calc = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'registro_comidas'


class RegistroMedicamentos(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    medicamento = models.ForeignKey(Medicamentos, models.DO_NOTHING)
    fecha = models.DateField()
    hora = models.TimeField()
    dosis_tomada = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    fue_tomado = models.IntegerField(blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'registro_medicamentos'


class RegistroSueno(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    fecha = models.DateField()
    hora_acostarse = models.TimeField(blank=True, null=True)
    hora_despertar = models.TimeField(blank=True, null=True)
    horas_dormidas = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    calidad = models.CharField(max_length=9)
    hubo_despertares = models.IntegerField(blank=True, null=True)
    notas = models.TextField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'registro_sueno'


class ResumenDiario(models.Model):
    id = models.BigAutoField(primary_key=True)
    usuario = models.ForeignKey('Usuarios', models.DO_NOTHING)
    fecha = models.DateField()
    glucosa_promedio = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_max = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    glucosa_min = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    cantidad_mediciones = models.IntegerField(blank=True, null=True)
    tiempo_en_rango = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    calorias_totales = models.DecimalField(max_digits=7, decimal_places=2, blank=True, null=True)
    carbohidratos_totales = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    carga_glucemica_total = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    minutos_ejercicio = models.IntegerField(blank=True, null=True)
    pasos_totales = models.IntegerField(blank=True, null=True)
    calorias_quemadas = models.DecimalField(max_digits=6, decimal_places=2, blank=True, null=True)
    medicamentos_tomados = models.IntegerField(blank=True, null=True)
    horas_sueno = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    nivel_estres_promedio = models.DecimalField(max_digits=3, decimal_places=1, blank=True, null=True)
    puntuacion_dia = models.IntegerField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'resumen_diario'
        unique_together = (('usuario', 'fecha'),)


class Usuarios(models.Model):
    id = models.BigAutoField(primary_key=True)
    nombre = models.CharField(max_length=100)
    email = models.CharField(unique=True, max_length=100)
    password = models.CharField(max_length=255)
    fecha_nacimiento = models.DateField(blank=True, null=True)
    sexo = models.CharField(max_length=9, blank=True, null=True)
    peso = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    altura = models.DecimalField(max_digits=5, decimal_places=2, blank=True, null=True)
    imc = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    anios_diagnostico = models.IntegerField(blank=True, null=True)
    hba1c_inicial = models.DecimalField(max_digits=4, decimal_places=2, blank=True, null=True)
    usa_insulina = models.IntegerField(blank=True, null=True)
    tiene_hipertension = models.IntegerField(blank=True, null=True)
    tiene_dislipidemia = models.IntegerField(blank=True, null=True)
    es_fumador = models.IntegerField(blank=True, null=True)
    nivel_actividad_base = models.CharField(max_length=10, blank=True, null=True)
    fecha_registro = models.DateTimeField(blank=True, null=True)

    class Meta:
        managed = False
        db_table = 'usuarios'
