#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import glob

def fix_blank_lines(filepath):
    """Remove multiple consecutive blank lines"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        # Process line by line to find consecutive blank lines
        result = []
        blank_count = 0
        
        for line in lines:
            if line.strip() == '':  # This is a blank line
                blank_count += 1
                if blank_count == 1:  # Keep only the first blank line
                    result.append(line)
            else:  # This is a content line
                blank_count = 0
                result.append(line)
        
        new_content = ''.join(result)
        
        # Ensure file ends with single newline
        new_content = new_content.rstrip() + '\n'
        
        # Read original to compare
        with open(filepath, 'r', encoding='utf-8') as f:
            original = f.read()
        
        if new_content != original:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(new_content)
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

fixed_count = 0
for filepath in md_files:
    if fix_blank_lines(filepath):
        filename = os.path.relpath(filepath, base_path)
        print(f"✅ Fixed: {filename}")
        fixed_count += 1

print(f"\n✅ Total files fixed: {fixed_count}/{len(md_files)}")
print("✅ All multiple blank lines removed!")
