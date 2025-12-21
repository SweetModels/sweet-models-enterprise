#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import glob

def fix_blank_lines(filepath):
    """Remove multiple consecutive blank lines using regex"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Replace any occurrence of 3+ newlines with exactly 2 newlines (1 blank line)
        # This pattern matches 3 or more consecutive newlines
        content = re.sub(r'\n\n\n+', '\n\n', content)
        
        # Also handle the case of just before EOF
        if content.endswith('\n\n'):
            content = content[:-1]
        
        if not content.endswith('\n'):
            content += '\n'
        
        if content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
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
    if fix_blank_lines(filepath):
        filename = os.path.relpath(filepath, base_path)
        print(f"✅ Fixed: {filename}")
        fixed_files.append(filename)

print(f"\n✅ Total files fixed: {len(fixed_files)}/{len(md_files)}")
if fixed_files:
    print("\nFixed files:")
    for f in fixed_files:
        print(f"  - {f}")
print("✅ Done!")
