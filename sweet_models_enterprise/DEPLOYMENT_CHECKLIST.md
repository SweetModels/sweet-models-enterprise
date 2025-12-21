# ✅ CHECKLIST DE DESPLIEGUE PRODUCCIÓN - Studios DK

## 📋 PRE-DESPLIEGUE (1-2 semanas antes)

### Infraestructura
- [ ] Servidor aprovisionado (4+ vCPU, 8+ GB RAM, 100+ GB SSD)
- [ ] Acceso SSH configurado con clave privada
- [ ] Dominio DNS registrado y apuntando al servidor
- [ ] Certificados SSL Let's Encrypt listos (o plan de generación)
- [ ] Dirección IP pública estática asignada
- [ ] Backups configurados (externo a servidor)

### Seguridad
- [ ] VPN configurada para acceso administrativo
- [ ] Firewall implementado (UFW/IPTables)
- [ ] SSH hardening completado
- [ ] Fail2Ban instalado y configurado
- [ ] Certificados SSL/TLS verificados
- [ ] Contraseñas generadas con `openssl rand` (no usadas antes)
- [ ] API Keys generadas y almacenadas de forma segura
- [ ] Lista de IPs permitidas definida

### Aplicación
- [ ] Código compilado exitosamente (`cargo build --release`)
- [ ] Todos los tests pasados (`cargo test`)
- [ ] Variables de entorno `.env.prod` preparadas
- [ ] Base de datos `init-db.sql` validada
- [ ] Migraciones verificadas
- [ ] Documentación actualizada

### Equipo
- [ ] Runbook de despliegue preparado
- [ ] Plan de rollback documentado
- [ ] Equipo de on-call designado
- [ ] Canales de comunicación configurados (Slack, etc.)
- [ ] Cambio aprobado y programado

---

## 🚀 DÍA DEL DESPLIEGUE

### Ventana de Mantenimiento (Reasignar con cuidado)
- [ ] Mantenimiento notificado a usuarios (48h antes)
- [ ] Equipo disponible durante ventana
- [ ] Logs monitoreados en tiempo real
- [ ] Rollback plan verificado y probado
- [ ] Equipo de soporte en standby

### Ejecución
- [ ] Backup pre-despliegue completado ✓
- [ ] `docker-compose pull` ejecutado
- [ ] `docker-compose build` completado sin errores
- [ ] Environment variables verificadas en `.env.prod`
- [ ] Certificados SSL en lugar correcto
- [ ] Permisos de archivos correctos (`chmod 600 .env.prod`)
- [ ] `docker-compose -f docker-compose.prod.yml up -d` ejecutado
- [ ] Servicios esperando en healthy state (30 segundos máximo)
- [ ] Health checks pasados ✅

### Validación
- [ ] HTTP GET `/health` retorna 200 ✅
- [ ] HTTPS funciona (sin warnings de certificado)
- [ ] Nginx accesible en puerto 443 ✅
- [ ] Backend API responde correctamente ✅
- [ ] Base de datos conecta y migra ✅
- [ ] Redis conecta correctamente ✅
- [ ] NATS disponible para mensajería ✅
- [ ] MinIO accessible para almacenamiento ✅
- [ ] Prometheus recolecta métricas ✅
- [ ] Logs rotados sin errores

### Post-Deploy Inmediato
- [ ] Cambiar contraseña admin inicial
- [ ] Crear usuario de administración
- [ ] Configurar 2FA para admin
- [ ] Verificar permisos en base de datos
- [ ] Probar funcionalidad crítica (login, upload, etc.)
- [ ] Monitoreo de recursos iniciado

---

## 🔒 CONFIGURACIÓN DE SEGURIDAD

### SSL/TLS
- [ ] Certificado válido (openssl s_client)
- [ ] HSTS header presente
- [ ] TLS 1.2+ únicamente habilitado
- [ ] Ciphers moderados configurados
- [ ] Certificado renueved automáticamente (Certbot)

### Acceso
- [ ] Firewall permite solo puertos necesarios
- [ ] Puertos internos (5432, 6379, 4222) bloqueados externamente
- [ ] SSH solo desde IPs autorizadas
- [ ] Autenticación API keys verificada
- [ ] JWT tokens con expiración configurada

### Datos
- [ ] Contraseñas hasheadas (bcrypt verificado)
- [ ] Encriptación en tránsito (HTTPS)
- [ ] Encriptación en reposo (si requerida)
- [ ] Permisos de base de datos restrictivos
- [ ] No hay secretos en logs o error messages

### Rate Limiting
- [ ] Rate limiting activo en endpoints API (100 req/s)
- [ ] Rate limiting stricter en auth (10 req/s)
- [ ] DDoS protección en nginx
- [ ] IP blocking implementado

---

## 📊 MONITOREO

### Metrics
- [ ] Prometheus recolectando datos
- [ ] CPU usage monitoreado
- [ ] Memoria usage monitoreado
- [ ] Disk usage monitoreado
- [ ] Network I/O monitoreado
- [ ] Database connections monitoreado
- [ ] Redis memory monitoreado

### Alertas
- [ ] CPU > 80% genera alerta
- [ ] Memoria > 85% genera alerta
- [ ] Disk > 90% genera alerta
- [ ] Response time > 1s genera alerta
- [ ] Error rate > 1% genera alerta
- [ ] SSL certificado expiración < 30 días genera alerta

### Logs
- [ ] Logs centralizados configurados
- [ ] Error logs monitoreados activamente
- [ ] Access logs rotados
- [ ] Auditoria logs habilitada
- [ ] Log retention policy implementada

---

## 🔄 POST-DESPLIEGUE (Primeras 24 horas)

### Validación Funcional
- [ ] Todos los endpoints API funcionan
- [ ] Autenticación/Autorización correcta
- [ ] Upload de archivos funciona
- [ ] Reportes generan correctamente
- [ ] Integraciones externas operativas
- [ ] Webhooks enviando correctamente
- [ ] Cron jobs ejecutándose

### Performance
- [ ] Respuestas rápidas (< 500ms)
- [ ] Cache hit ratio > 70%
- [ ] Database queries optimizadas
- [ ] No hay N+1 queries
- [ ] Conexiones pool funcionando

### Stability
- [ ] Error rate < 0.1%
- [ ] No memory leaks observados
- [ ] No conexión abandoned
- [ ] Graceful shutdown funciona
- [ ] Services recovery after failure funciona

### Compliance
- [ ] GDPR compliance verificado
- [ ] Data retention policies cumplidas
- [ ] Encryption standards cumplidas
- [ ] Audit logs completos
- [ ] Backup policies active

---

## 🆘 ROLLBACK PLAN

Si algo va mal después de despliegue:

```bash
# 1. Detener servicios nuevos
docker-compose -f docker-compose.prod.yml down

# 2. Restaurar código anterior
git revert HEAD~1

# 3. Restaurar base de datos (si fue modificada)
# gunzip < backup-$(timestamp).sql.gz | docker exec -i postgres psql -U user db

# 4. Reiniciar servicios
docker-compose -f docker-compose.prod.yml up -d

# 5. Verificar
curl https://api.studios-dk.com/health

# 6. Notificar equipo
# - Investigar qué salió mal
# - Reportar en postmortem
# - Actualizar runbook
```

---

## 📈 ESCALADO FUTURO

- [ ] Plan de escalado horizontal documentado
- [ ] Load balancer configuration probado
- [ ] Database replication planificada
- [ ] Redis clustering evaluado
- [ ] CDN integration planificada

---

## 📞 CONTACTOS DE EMERGENCIA

| Rol | Nombre | Teléfono | Email |
|-----|--------|----------|-------|
| DevOps Lead | [NOMBRE] | [TELÉFONO] | [EMAIL] |
| Backend Lead | [NOMBRE] | [TELÉFONO] | [EMAIL] |
| On-Call | [NOMBRE] | [TELÉFONO] | [EMAIL] |
| Management | [NOMBRE] | [TELÉFONO] | [EMAIL] |

---

## 🎉 DESPLIEGUE EXITOSO CUANDO:

✅ Todos los checkpoints marcados  
✅ Health checks pasados al 100%  
✅ Monitoreo activo y alertas funcionales  
✅ Equipo notificado y tranquilo  
✅ Documentación actualizada  
✅ Métricas baseline establecidas  

---

**Fecha de Despliegue**: _____________  
**Responsable**: _____________  
**Aprobado por**: _____________  

---

*Documento clasificado como Confidencial - Acceso restringido*
