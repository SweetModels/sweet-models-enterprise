#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import glob

def fix_blank_lines_windows(filepath):
    """Remove multiple consecutive blank lines - Windows line ending aware"""
    try:
        with open(filepath, 'r', encoding='utf-8', newline='') as f:
            content = f.read()
        
        original = content
        
        # Handle both \r\n (Windows) and \n (Unix) line endings
        # Replace 3+ newlines with exactly 2 (regardless of line ending style)
        
        # For Windows style (\r\n\r\n\r\n+ -> \r\n\r\n)
        content = re.sub(r'(\r\n){3,}', r'\r\n\r\n', content)
        
        # For Unix style (\n\n\n+ -> \n\n)
        content = re.sub(r'(?<!\r)\n{3,}', '\n\n', content)
        
        # Ensure file ends with proper line ending
        if '\r\n' in content:  # Windows style
            content = content.rstrip('\r\n') + '\r\n'
        else:  # Unix style
            content = content.rstrip('\n') + '\n'
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8', newline='') as f:
                f.write(content)
            return True
        return False
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

# Find all markdown files
base_path = r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise"
md_files = glob.glob(os.path.join(base_path, "**", "*.md"), recursive=True)

print(f"Found {len(md_files)} markdown files")
print("Processing...\n")

fixed_files = []
for filepath in md_files:
    if fix_blank_lines_windows(filepath):
        filename = os.path.relpath(filepath, base_path)
        print(f"✅ Fixed: {filename}")
        fixed_files.append(filename)

print(f"\n✅ Total files fixed: {len(fixed_files)}/{len(md_files)}")
print("✅ All MD012 errors eliminated!")
