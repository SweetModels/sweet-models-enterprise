#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import glob

def remove_multiple_blank_lines(filepath):
    """Remove multiple consecutive blank lines, keep only one"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Replace 2 or more consecutive blank lines with just 1
        # This regex matches 2 or more newlines and replaces with 2 (which is 1 blank line)
        content = re.sub(r'\n\n\n+', '\n\n', content)
        
        # Ensure file ends with single newline
        content = content.rstrip() + '\n'
        
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

fixed_count = 0
for filepath in md_files:
    if remove_multiple_blank_lines(filepath):
        filename = os.path.basename(filepath)
        print(f"✅ Fixed: {filename}")
        fixed_count += 1

print(f"\n✅ Total files fixed: {fixed_count}/{len(md_files)}")
print("✅ All multiple blank lines removed!")
