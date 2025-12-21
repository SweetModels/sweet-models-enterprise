#!/usr/bin/env python3
import re

files = [
    r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\LOGIN_IMPLEMENTATION.md",
    r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\INTEGRACION_LOGIN.md"
]

for filepath in files:
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Build output
    output = []
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Check if current line is a heading
        is_heading = line.strip().startswith('#')
        
        if is_heading:
            # Add the heading
            output.append(line)
            i += 1
            
            # Check if next line is blank or content
            if i < len(lines):
                next_line = lines[i]
                # If next line is NOT blank and NOT heading, add blank line
                if next_line.strip() and not next_line.strip().startswith('#'):
                    output.append('\n')
        else:
            output.append(line)
            i += 1
    
    # Write back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(output)
    
    print(f"✅ Fixed {filepath.split(chr(92))[-1]}")

print("Done!")
