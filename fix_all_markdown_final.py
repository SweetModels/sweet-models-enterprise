#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os
import re
import glob

def fix_markdown_file(filepath):
    """Fix all common Markdown linting issues"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Remove trailing whitespace from all lines
        lines = content.split('\n')
        lines = [line.rstrip() for line in lines]
        content = '\n'.join(lines)
        
        # Remove multiple consecutive blank lines (more than 2)
        content = re.sub(r'\n{4,}', '\n\n\n', content)
        
        # Ensure file ends with single newline
        content = content.rstrip() + '\n'
        
        # Fix MD022: Ensure blank lines around headings
        # Add blank line before heading (except at start of file)
        content = re.sub(r'([^\n])\n(#{1,6}\s)', r'\1\n\n\2', content)
        # Add blank line after heading
        content = re.sub(r'^(#{1,6}\s[^\n]+)\n([^\n#])', r'\1\n\n\2', content, flags=re.MULTILINE)
        
        # Fix MD032: Ensure blank lines around lists
        # Before list
        content = re.sub(r'([^\n])\n([\s]*[-*+]\s)', r'\1\n\n\2', content)
        # After list (before non-list content)
        content = re.sub(r'^([\s]*[-*+]\s[^\n]+)\n([^\n\s*+#-])', r'\1\n\n\2', content, flags=re.MULTILINE)
        
        # Fix MD031: Ensure blank lines around code blocks
        content = re.sub(r'([^\n])\n(```)', r'\1\n\n\2', content)
        content = re.sub(r'(```)\n([^\n`])', r'\1\n\n\2', content)
        
        # Fix MD040: Add language to code blocks without one
        # Match ``` followed immediately by newline (no language specified)
        content = re.sub(r'```\n([A-Z])', r'```text\n\1', content)
        content = re.sub(r'```\n([a-z])', r'```text\n\1', content)
        content = re.sub(r'```\n(\d)', r'```text\n\1', content)
        content = re.sub(r'```\n(\|)', r'```text\n\1', content)
        content = re.sub(r'```\n(-)', r'```text\n\1', content)
        content = re.sub(r'```\n(\+)', r'```text\n\1', content)
        content = re.sub(r'```\n(/)', r'```text\n\1', content)
        content = re.sub(r'```\n(#)', r'```text\n\1', content)
        content = re.sub(r'```\n(<)', r'```text\n\1', content)
        content = re.sub(r'```\n(>)', r'```text\n\1', content)
        content = re.sub(r'```\n({)', r'```text\n\1', content)
        content = re.sub(r'```\n(\[)', r'```text\n\1', content)
        
        # Fix excessive blank lines (reduce to max 2)
        content = re.sub(r'\n{4,}', '\n\n\n', content)
        
        # Fix MD058: Blank lines around tables
        content = re.sub(r'([^\n])\n(\|)', r'\1\n\n\2', content)
        content = re.sub(r'(\|[^\n]+)\n([^\n|])', r'\1\n\n\2', content)
        
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
    if fix_markdown_file(filepath):
        filename = os.path.basename(filepath)
        print(f"✅ Fixed: {filename}")
        fixed_count += 1

print(f"\n✅ Total files fixed: {fixed_count}/{len(md_files)}")
print("✅ All Markdown files have been cleaned!")
