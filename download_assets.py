import re
import os
import urllib.request

output_path = '/Users/omarragab/.gemini/antigravity-ide/brain/6a3bb10e-717e-4e55-958c-2fc679a30352/.system_generated/steps/279/output.txt'
out_dir = '/Users/omarragab/Projects/kutub_fm/assets/profile'

os.makedirs(out_dir, exist_ok=True)

with open(output_path, 'r') as f:
    lines = f.readlines()

for line in lines:
    match = re.search(r'const (img[A-Za-z0-9_]+) = "(http://localhost:[0-9]+/assets/[A-Za-z0-9_]+\.(svg|png))"', line)
    if match:
        name = match.group(1)
        url = match.group(2)
        ext = match.group(3)
        file_path = os.path.join(out_dir, f'{name}.{ext}')
        print(f'Downloading {url} to {file_path}')
        try:
            urllib.request.urlretrieve(url, file_path)
        except Exception as e:
            print(f'Error downloading {url}: {e}')
