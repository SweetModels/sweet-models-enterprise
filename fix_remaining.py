#!/usr/bin/env python3
import re

files_to_fix = [
    r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\API_ENDPOINTS.md",
    r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\INICIO_LIMPIO.md"
]

for filepath in files_to_fix:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Fix MD022: Add blank lines around headings
    # Pattern: ## heading\nContent without blank line
    content = re.sub(r'(## [^\n]+)\n([^#\n])', r'\1\n\n\2', content)
    content = re.sub(r'(### [^\n]+)\n([^#\n])', r'\1\n\n\2', content)
    content = re.sub(r'(#### [^\n]+)\n([^#\n])', r'\1\n\n\2', content)
    
    # Fix MD032: Add blank lines around lists  
    # Add blank line before first list item
    content = re.sub(r'([^\n])\n(- )', r'\1\n\n\2', content)
    
    # Fix MD031: Add blank lines around code blocks
    # Before code block
    content = re.sub(r'([^\n])\n```', r'\1\n\n```', content)
    # After code block
    content = re.sub(r'```\n([^\n])', r'```\n\n\1', content)
    
    # Fix MD040: Specify language for code blocks
    # Plain backticks ``` without language
    content = re.sub(r'```\n([^`])', r'```text\n\1', content)
    
    # Fix MD058: Add blank lines around tables
    content = re.sub(r'([^\n])\n(\| )', r'\1\n\n\2', content)
    content = re.sub(r'(\|[^\n]+\|)\n([^|\n])', r'\1\n\n\2', content)
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)
    
    print(f"✅ Fixed {filepath.split(chr(92))[-1]}")

print("Done!")
