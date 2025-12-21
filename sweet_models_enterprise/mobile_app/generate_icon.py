from PIL import Image, ImageDraw, ImageFont
import os

# Crear directorio si no existe
icon_dir = "assets/icon"
os.makedirs(icon_dir, exist_ok=True)

# Colores del tema
background_color = "#09090B"  # Negro oscuro
accent_color = "#00F5FF"      # Cyan
border_color = "#EB1555"      # Rosa

# Crear imagen de 1024x1024
size = 1024
img = Image.new('RGB', (size, size), background_color)
draw = ImageDraw.Draw(img)

# Dibujar borde rosa
border_width = 20
draw.rectangle(
    [border_width, border_width, size - border_width, size - border_width],
    outline=border_color,
    width=border_width
)

# Dibujar círculo cyan en el centro
circle_radius = 300
center = size // 2
draw.ellipse(
    [center - circle_radius, center - circle_radius, 
     center + circle_radius, center + circle_radius],
    fill=accent_color
)

# Intentar agregar texto "SM"
try:
    # Intentar usar una fuente del sistema
    font_size = 400
    try:
        font = ImageFont.truetype("arial.ttf", font_size)
    except:
        try:
            font = ImageFont.truetype("C:\\Windows\\Fonts\\arial.ttf", font_size)
        except:
            # Si no hay fuente, usar la default
            font = ImageFont.load_default()
            font_size = 100
    
    text = "SM"
    # Obtener dimensiones del texto
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    
    # Centrar texto
    text_x = (size - text_width) // 2
    text_y = (size - text_height) // 2 - 50
    
    # Dibujar texto en negro sobre el círculo cyan
    draw.text((text_x, text_y), text, fill=background_color, font=font)
except Exception as e:
    print(f"⚠️  No se pudo agregar texto: {e}")
    # Continuar sin texto

# Guardar ícono principal
icon_path = os.path.join(icon_dir, "app_icon.png")
img.save(icon_path, "PNG")
print(f"✅ Ícono creado: {icon_path}")

# Crear versión foreground (solo el círculo y texto, fondo transparente)
img_fg = Image.new('RGBA', (size, size), (0, 0, 0, 0))
draw_fg = ImageDraw.Draw(img_fg)

# Círculo cyan
draw_fg.ellipse(
    [center - circle_radius, center - circle_radius, 
     center + circle_radius, center + circle_radius],
    fill=accent_color
)

# Texto
try:
    if font_size > 100:
        draw_fg.text((text_x, text_y), text, fill=background_color, font=font)
except:
    pass

# Guardar foreground
fg_path = os.path.join(icon_dir, "app_icon_foreground.png")
img_fg.save(fg_path, "PNG")
print(f"✅ Ícono foreground creado: {fg_path}")

print(f"\n🎨 Íconos generados en: {icon_dir}")
print(f"   - {icon_path}")
print(f"   - {fg_path}")
print(f"\n📝 Siguiente paso: flutter pub run flutter_launcher_icons")
