#!/usr/bin/env python3
import re
import glob

# Get all MD files
md_files = glob.glob(r"c:\Users\USUARIO\Desktop\Sweet Models Enterprise\sweet_models_enterprise\**\*.md", recursive=True)

for filepath in md_files:
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
        
        original = content
        
        # Fix MD022: Add blank line after headings
        content = re.sub(r'^(#{1,6}\s+[^\n]+)\n([^#\n\s])', r'\1\n\n\2', content, flags=re.MULTILINE)
        
        # Fix MD032: Add blank line around lists
        content = re.sub(r'^([^\n]*[^\n\s])\n([\s]*[-*][\s])', r'\1\n\n\2', content, flags=re.MULTILINE)
        
        # Fix MD031: Add blank lines around code blocks
        # Before code block
        content = re.sub(r'([^\n])\n(```)', r'\1\n\n\2', content)
        # After code block
        content = re.sub(r'(```)\n([^\n`])', r'\1\n\n\2', content)
        
        # Fix MD040: Specify language for empty code blocks
        # Match triple backticks with no language, followed by content that doesn't start with a newline
        content = re.sub(r'```\n([A-Za-z])', r'```text\n\1', content)
        content = re.sub(r'```\n(\|)', r'```text\n\1', content)
        content = re.sub(r'```\n(\-)', r'```text\n\1', content)
        content = re.sub(r'```\n(\d)', r'```text\n\1', content)
        
        # Fix MD033 and MD034: Wrap email addresses in backticks
        content = re.sub(r'([^`])(@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,})', r'\1`\2`', content)
        # Wrap URLs in backticks if not already wrapped
        content = re.sub(r'([^`])(http://[a-zA-Z0-9./:_-]+)', r'\1`\2`', content)
        
        if original != content:
            with open(filepath, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"✅ {filepath.split(chr(92))[-1]}")
        
    except Exception as e:
        print(f"❌ Error with {filepath}: {e}")

print("\nDone!")
