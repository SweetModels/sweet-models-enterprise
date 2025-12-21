import sys
import re

if len(sys.argv) != 2:
    print("Uso: python clean_blanks.py <archivo.md>")
    sys.exit(1)

filename = sys.argv[1]
with open(filename, 'r', encoding='utf-8') as f:
    content = f.read()

# Reemplaza 3 o más saltos de línea consecutivos por solo 2
content = re.sub(r'\n{3,}', '\n\n', content)

with open(filename, 'w', encoding='utf-8') as f:
    f.write(content)

