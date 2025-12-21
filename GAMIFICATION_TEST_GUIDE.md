# 🎮 GAMIFICACIÓN - GUÍA DE PRUEBA

**Fecha**: 18 de Diciembre 2025  
**Estado**: ✅ OPERATIVO

---

## ✅ LO QUE SE IMPLEMENTÓ HOY

### 1. **Base de Datos - Tabla Production**
- ✅ Migración aplicada: `20251218_create_production_table.up.sql`
- ✅ Tabla `daily_production` con índice único por (model_id, date, platform)
- ✅ Campos: token_amount, token_value_cop, created_at

### 2. **Backend - Endpoint Admin**
- ✅ Ruta: `POST /api/admin/production`
- ✅ Handler: `handlers::admin::register_production`
- ✅ Valida rol `admin` con JWT
- ✅ Upsert en `daily_production` (acumula tokens del mismo día)
- ✅ Inserta en `points_ledger` para actualizar XP inmediatamente

### 3. **Backend - Sistema de Rangos**
- ✅ Endpoint: `GET /api/model/stats`
- ✅ 5 Rangos: Novice (🐣), Rising Star (🚀), Elite (💎), Queen (👑), Goddess (🦄)
- ✅ Cálculo automático de XP, progreso, y próximo nivel

### 4. **Frontend Flutter - Admin Dashboard**
- ✅ FloatingActionButton (+) para registrar producción
- ✅ Dialog con campos: Email, Tokens, Plataforma
- ✅ Llama a `DashboardService.registerProduction()`
- ✅ SnackBar de confirmación verde

### 5. **Frontend Flutter - Model Home Screen**
- ✅ Pantalla gamificada con círculo de progreso
- ✅ Muestra XP, rango, icono, siguiente nivel
- ✅ Stat cards: Tokens del día, Ganancias COP
- ✅ Mensajes motivacionales (<30%, >80%)

---

## 🧪 PASO A PASO - PRUEBA DE ASCENSO

### PASO 1: Login como Admin
```bash
# En tu emulador Android o navegador:
Email: admin@sweetmodels.com
Password: sweet123
```

**Resultado**: Deberías ver el Admin Dashboard con gráficas doradas/negras.

---

### PASO 2: Registrar Producción
1. Presiona el botón **+** (FloatingActionButton rosado)
2. Completa el formulario:
   - **Email**: `modelo@sweet.com`
   - **Tokens**: `25000` (Esto hará que Isaura suba de rango)
   - **Plataforma**: `chaturbate`
3. Presiona **REGISTRAR**

**Resultado**: 
- SnackBar verde: "¡Producción guardada!"
- Dashboard se actualiza automáticamente

---

### PASO 3: Login como Modelo
1. Cierra sesión del admin (botón logout)
2. Entra con las credenciales de Isaura:
   ```bash
   Email: modelo@sweet.com
   Password: modelo123
   ```

**Resultado**: Deberías ver la pantalla gamificada (fondo violeta/rosa).

---

### PASO 4: Verificar Ascenso
Revisa los siguientes elementos en la pantalla de Isaura:

| Campo | Valor Esperado |
|-------|----------------|
| **Rango** | 🚀 Rising Star (si XP entre 20k-60k) |
| **XP Total** | ~25,000 |
| **Progreso** | ~12.5% (hacia Elite) |
| **Próximo Nivel** | Elite (necesita 35,000 XP más) |
| **Tokens Hoy** | 25,000 |
| **Ganancias Hoy** | ~$125,000 COP |

**Círculo de Progreso**:
- Debe mostrar un arco rosado del 12.5% completo
- En el centro: Emoji 🚀 + "Rising Star" + "12%"

**Mensaje Motivacional**:
- Debe decir algo como: "💪 ¡Vas muy bien! 35,000 XP para ascender"

---

## 🔄 PRUEBA ADICIONAL: Acumular Más Tokens

Si quieres ver a Isaura subir a **Elite**, repite el PASO 2 con:
- Email: `modelo@sweet.com`
- Tokens: `40000` (total acumulado: 65k)
- Plataforma: `stripchat`

**Resultado**: Al volver a login como modelo, deberías ver:
- Rango: 💎 Elite
- XP: 65,000
- Progreso hacia Queen: ~5.5%

---

## 🐛 TROUBLESHOOTING

### Error: "Model not found"
- Verifica que Isaura exista en la BD:
  ```bash
  docker exec -it sme_postgres psql -U sme_user -d sme_db \
    -c "SELECT email, role, full_name FROM users WHERE email='modelo@sweet.com';"
  ```

### Error: "Admin role required"
- Verifica que estés logueado como admin
- El token debe tener `role: 'admin'`

### No actualiza XP
- Verifica que el endpoint retorna 200
- Revisa logs del backend:
  ```bash
  docker-compose logs -f backend
  ```

### Flutter no compila
- Ejecuta:
  ```bash
  flutter pub get
  flutter clean
  flutter pub get
  ```

---

## 📝 ENDPOINTS IMPLEMENTADOS

### Admin Production (Nuevo)
```bash
# Registrar tokens para modelo
curl -X POST http://localhost:3000/api/admin/production \
  -H "Authorization: Bearer {admin_token}" \
  -H "Content-Type: application/json" \
  -d '{
    "model_email": "modelo@sweet.com",
    "tokens": 25000,
    "platform": "chaturbate"
  }'

# Respuesta exitosa:
{
  "message": "Production recorded",
  "total_points": 25000.0
}
```

### Model Stats (Gamification)
```bash
# Obtener stats de la modelo
curl -H "Authorization: Bearer {model_token}" \
  http://localhost:3000/api/model/stats

# Respuesta:
{
  "xp": 25000,
  "rank": "Rising Star",
  "icon": "🚀",
  "next_level_in": 35001,
  "progress": 0.125,
  "today_tokens": 25000,
  "today_earnings_cop": 125000.0
}
```

---

## 🎯 RANGOS Y UMBRALES DE XP

| Rango | Icono | XP Mínimo | XP Máximo |
|-------|-------|-----------|-----------|
| Novice | 🐣 | 0 | 20,000 |
| Rising Star | 🚀 | 20,001 | 60,000 |
| Elite | 💎 | 60,001 | 150,000 |
| Queen | 👑 | 150,001 | 400,000 |
| Goddess | 🦄 | 400,001 | ∞ |

---

## ✅ CHECKLIST DE VERIFICACIÓN

- [ ] Backend compila sin errores
- [ ] Migración aplicada (`daily_production` existe)
- [ ] Login admin funciona
- [ ] FloatingActionButton visible en Admin Dashboard
- [ ] Dialog de registro se abre al presionar (+)
- [ ] POST a `/api/admin/production` retorna 200
- [ ] Login modelo funciona
- [ ] ModelHomeScreen muestra pantalla gamificada
- [ ] Círculo de progreso se actualiza
- [ ] Rango correcto según XP acumulado
- [ ] Tokens y ganancias se muestran correctamente

---

**Generado**: 18 de Diciembre 2025  
**Versión**: 2.0 (Gamification System)  
**Estado**: ✅ LISTO PARA PRUEBAS
