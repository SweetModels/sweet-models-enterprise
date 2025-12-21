#!/usr/bin/env python3
import re

# Read the file
with open(r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app\FLUTTER_APP_V2.md", 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: Add blank line after "#### **Flujo de Usuario**"
content = re.sub(
    r'(#### \*\*Flujo de Usuario\*\*)\n(1\. Usuario)',
    r'\1\n\n\2',
    content
)

# Fix 2: Add blank line after "#### **Campos del Formulario**"
content = re.sub(
    r'(#### \*\*Campos del Formulario\*\*)\n(\| Campo)',
    r'\1\n\n\2',
    content
)

# Fix 3: Add blank line after table and before "#### **Verificación de Teléfono (OTP Simulado)**"
content = re.sub(
    r'(\| \*\*Confirmar Contraseña\*\*[^\n]*\n)\n(#### \*\*Verificación)',
    r'\1\n\2',
    content
)

# Fix 4: Add blank line after code block and before next heading
content = re.sub(
    r'(```\n)\n(#### \*\*Endpoint Backend\*\*)',
    r'\1\n\2',
    content
)

# Fix 5: Add blank line before "- Grid Adaptativo:" list
content = re.sub(
    r'(### \*\*Vista de Cámaras \(Admin\)\*\*)\n(- \*\*Header\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 6: Remove trailing spaces on line with "- **Grid Adaptativo**:"
content = re.sub(
    r'(- \*\*Grid Adaptativo\*\*:) +$',
    r'\1',
    content,
    flags=re.MULTILINE
)

# Fix 7: Add blank line after "#### **Detalles de Cámara (Modal)**"
content = re.sub(
    r'(#### \*\*Detalles de Cámara \(Modal\)\*\*)\n\nAl hacer',
    r'\1\n\nAl hacer',
    content
)

# Fix 8: Add blank line after "- ID de cámara" list and before "#### **Endpoint Backend**"
content = re.sub(
    r'(- URL del stream RTSP)\n\n(#### \*\*Endpoint Backend\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 9: Add blank line before "#### **Detección de Plataforma**"
content = re.sub(
    r'(fluent_ui: \^4\.8\.0\n```)\n\n(#### \*\*Detección)',
    r'\1\n\n\2',
    content
)

# Fix 10: Add blank line after "bool get _isDesktop" code block
content = re.sub(
    r'(  return false;\n  }\n}\n```)\n\n(#### \*\*Navegación Adaptativa\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 11: Fix duplicate heading issue - "#### **Endpoint Backend**"
# Remove the first occurrence within Camera section
content = re.sub(
    r'(- URL del stream RTSP)\n\n(#### \*\*Endpoint Backend\*\*)\n\n```http\nGET /admin/cameras)',
    r'\1\n\n#### **API del Backend**\n\n```http\nGET /admin/cameras',
    content
)

# Fix 12: Add blank line before "### **Android**" in Configuration section
content = re.sub(
    r'(## 🚨 Configuración Requerida)\n\n(### \*\*Android\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 13: Add blank line after "1. Agregar permisos..." list
content = re.sub(
    r'(2\. Min SDK: 21 \(Android 5\.0\+\))\n\n(### \*\*iOS\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 14: Add blank line before iOS Info.plist code block
content = re.sub(
    r'(### \*\*iOS\*\*)\n\nAgregar a `Info\.plist`:\n(```xml)',
    r'\1\n\nAgregar a `Info.plist`:\n\n\2',
    content
)

# Fix 15: Add blank line after iOS Info.plist code block and before "### **Windows**"
content = re.sub(
    r'(<string>Usamos Face ID[^\n]*</string>\n```)\n\n(### \*\*Windows\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 16: Add blank line after Windows list
content = re.sub(
    r'(2\. Windows 10 Build 17763 o superior)\n\n(---\n\n## 🔒 Seguridad)',
    r'\1\n\n\2',
    content
)

# Fix 17: Add blank line before Biometría subsection
content = re.sub(
    r'(## 🔒 Seguridad Implementada)\n\n(### \*\*Biometría\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 18: Add blank line after Biometría list and before "### **API Calls**"
content = re.sub(
    r'(- ✅ Detección del tipo de biometría disponible)\n\n(### \*\*API Calls\*\*)',
    r'\1\n\n\2',
    content
)

# If that didn't work, try a different approach
if '- ✅ Timeout configurable (stickiness)' in content:
    content = re.sub(
        r'(- ✅ Timeout configurable \(stickiness\))\n\n(### \*\*API Calls\*\*)',
        r'\1\n\n\2',
        content
    )

# Fix 19: Add blank line after "### **API Calls**" list and before "### **Validaciones**"
content = re.sub(
    r'(- ✅ Manejo de errores 401 \(sesión expirada\))\n\n(### \*\*Validaciones\*\*)',
    r'\1\n\n\2',
    content
)

# Fix 20: Add blank line before "## 🎯 Próximos Pasos Sugeridos"
content = re.sub(
    r'(- ✅ Contraseña min\. 8 caracteres)\n\n(---\n\n## 🎯)',
    r'\1\n\n---\n\n\2',
    content
)

# Fix 21: Add blank lines around code blocks in "Próximos Pasos"
content = re.sub(
    r'(### \*\*1\. Integración Real de OTP\*\*)\n(```dart)',
    r'\1\n\n\2',
    content
)

content = re.sub(
    r'(### \*\*2\. Video Streaming Real\*\*)\n(```dart)',
    r'\1\n\n\2',
    content
)

content = re.sub(
    r'(### \*\*3\. Notificaciones Push\*\*)\n(```dart)',
    r'\1\n\n\2',
    content
)

content = re.sub(
    r'(### \*\*4\. Localización \(i18n\)\*\*)\n(```dart)',
    r'\1\n\n\2',
    content
)

# Fix 22: Specify language for the code metric block
content = re.sub(
    r'(## 📊 Métricas de Código)\n\n(```)\n(Archivos)',
    r'\1\n\n```text\n\3',
    content
)

# Fix 23: Add blank line before "## ✅ Checklist"
content = re.sub(
    r'(```)\n\n(---\n\n## ✅ Checklist)',
    r'\1\n\n---\n\n\2',
    content
)

# Fix 24: Add blank line before "## 🎓 Guía de Usuario"
content = re.sub(
    r'(\- \[x\] Soporte para Windows/Desktop)\n\n(---\n\n## 🎓)',
    r'\1\n\n---\n\n\2',
    content
)

# Fix 25: Add blank lines before subsections in User Guide
content = re.sub(
    r'(## 🎓 Guía de Usuario)\n\n(### \*\*Para Modelos\*\*)',
    r'\1\n\n\2',
    content
)

content = re.sub(
    r'(4\. Esperar aprobación del administrador)\n\n(### \*\*Para Administradores\*\*)',
    r'\1\n\n\2',
    content
)

content = re.sub(
    r'(5\. Click en cámara para ver detalles \(URL RTSP\))\n\n(### \*\*Activar Biometría\*\*)',
    r'\1\n\n\2',
    content
)

# Write the file back
with open(r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\mobile_app\FLUTTER_APP_V2.md", 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fixed FLUTTER_APP_V2.md")
