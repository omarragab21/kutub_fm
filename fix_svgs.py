import os
import re

dir_path = '/Users/omarragab/Projects/kutub_fm/assets/profile/'
for filename in os.listdir(dir_path):
    if filename.endswith('.svg'):
        filepath = os.path.join(dir_path, filename)
        with open(filepath, 'r') as f:
            content = f.read()
        
        # Replace var(--something, #hex) with #hex
        new_content = re.sub(r'var\(--[^,]+,\s*(#[A-Fa-f0-9]+)\)', r'\1', content)
        
        if content != new_content:
            with open(filepath, 'w') as f:
                f.write(new_content)
            print(f'Fixed {filename}')
