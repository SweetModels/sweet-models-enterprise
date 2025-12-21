#!/usr/bin/env python3
import re
import glob
import os
import sys

# Fix encoding for Windows PowerShell
if sys.platform == 'win32':
    import io
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def fix_markdown(filepath):
    """Comprehensive markdown fixer"""
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # 1. Fix empty lines issues - remove more than 2 consecutive newlines
        content = re.sub(r'\n{3,}', '\n\n', content)
        
        # 2. Fix MD022: Headings surrounded by blank lines
        # Add blank line before heading if not at start and previous line not blank
        content = re.sub(r'([^\n])\n(#{1,6}\s+)', r'\1\n\n\2', content)
        # Add blank line after heading if next line is not blank/heading
        content = re.sub(r'(#{1,6}\s+[^\n]*)\n([^\n#\s])', r'\1\n\n\2', content)
        
        # 3. Fix MD032: Lists surrounded by blank lines
        content = re.sub(r'([^\n])\n([\s]*[-*+][\s])', r'\1\n\n\2', content)
        content = re.sub(r'([\s]*[-*+][^\n]*)\n([^\n\s])', r'\1\n\n\2', content)
        
        # 4. Fix MD031: Code blocks surrounded by blank lines
        content = re.sub(r'([^\n`])\n(```)', r'\1\n\n\2', content)
        content = re.sub(r'(```[^\n]*\n(?:[^`]|\n(?!```))*```)\n([^\n])', r'\1\n\n\2', content)
        
        # 5. Fix MD040: Fenced code blocks need language
        # Triple backticks with no language
        content = re.sub(r'^```\n', '```text\n', content, flags=re.MULTILINE)
        content = re.sub(r'^```(?![\w-])', '```text', content, flags=re.MULTILINE)
        
        # 6. Fix MD058: Tables surrounded by blank lines
        content = re.sub(r'([^\n])\n(\|[^\n]+\|)', r'\1\n\n\2', content)
        content = re.sub(r'(\|[^\n]+\|)\n([^\n|\s])', r'\1\n\n\2', content)
        
        # 7. Fix trailing spaces (MD009)
        content = re.sub(r'([^\s])\s+$', r'\1', content, flags=re.MULTILINE)
        
        # 8. Fix lines with only spaces
        content = re.sub(r'^\s+$', '', content, flags=re.MULTILINE)
        
        # 9. Ensure file ends with newline
        if content and not content.endswith('\n'):
            content += '\n'
        
        if original != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            return True
        return False
        
    except Exception as e:
        print(f"Error processing {filepath}: {e}")
        return False

# Process all MD files
md_files = glob.glob(r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\**\*.md", recursive=True)
fixed_count = 0
for filepath in sorted(md_files):
    if fix_markdown(filepath):
        fixed_count += 1
        filename = os.path.basename(filepath)
        print(f"[OK] {filename}")

print(f"\n[OK] Total archivos corregidos: {fixed_count}/{len(md_files)}")
