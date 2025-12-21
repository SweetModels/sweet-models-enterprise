#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import glob
import re

def remove_blank_lines_in_lists(filepath):
    """Remove blank lines between list items"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        result = []
        i = 0
        modified = False
        
        while i < len(lines):
            current_line = lines[i]
            result.append(current_line)
            
            # Check if current line is a list item (starts with -, *, or number.)
            if re.match(r'^\s*[-*]|\s*\d+\.', current_line.strip()):
                # Look ahead for next lines
                j = i + 1
                while j < len(lines):
                    next_line = lines[j]
                    
                    # If it's a blank line
                    if next_line.strip() == '':
                        # Check if the line after the blank is also a list item
                        if j + 1 < len(lines):
                            after_blank = lines[j + 1]
                            if re.match(r'^\s*[-*]|\s*\d+\.', after_blank.strip()):
                                # Skip this blank line (don't add it to result)
                                modified = True
                                j += 1
                                continue
                        # If not followed by list item, keep the blank line
                        result.append(next_line)
                        break
                    elif re.match(r'^\s*[-*]|\s*\d+\.', next_line.strip()):
                        # Another list item found, go back to outer loop
                        i = j - 1
                        break
                    else:
                        # Not a list item and not blank, exit the list
                        result.append(next_line)
                        break
                    
                    j += 1
            
            i += 1
        
        if modified:
            new_content = ''.join(result)
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

print(f"Found {len(md_files)} markdown files\n")

fixed_files = []
for filepath in md_files:
    if remove_blank_lines_in_lists(filepath):
        filename = os.path.relpath(filepath, base_path)
        print(f"✅ Fixed: {filename}")
        fixed_files.append(filename)

print(f"\n✅ Total files fixed: {len(fixed_files)}/{len(md_files)}")
print("✅ Blank lines between list items removed!")
