import os
import math
from PIL import Image

def process_logo():
    input_path = "/Users/omarragab/.gemini/antigravity-ide/brain/261d4c43-713b-4b54-9261-002e4649fe6b/media__1781538900206.png"
    assets_dir = "/Users/omarragab/Projects/kutub_fm/assets"
    
    os.makedirs(assets_dir, exist_ok=True)
    
    app_icon_path = os.path.join(assets_dir, "app_icon.png")
    app_icon_foreground_path = os.path.join(assets_dir, "app_icon_foreground.png")
    
    # Load original image
    print(f"Loading image from {input_path}...")
    img = Image.open(input_path).convert("RGBA")
    width, height = img.size
    
    # We want a center square of height x height
    size = height
    left = (width - size) // 2
    top = 0
    right = left + size
    bottom = size
    
    print(f"Original size: {width}x{height}. Center cropping to {size}x{size}...")
    cropped_img = img.crop((left, top, right, bottom))
    
    # Save standard/iOS app icon (opaque RGB)
    ios_icon = cropped_img.convert("RGB")
    ios_icon.save(app_icon_path, "PNG")
    print(f"Saved iOS app icon to {app_icon_path}")
    
    # Create Adaptive Icon Foreground Layer (RGBA)
    scale_factor = 0.75
    scaled_size = int(size * scale_factor)
    
    print(f"Scaling logo content for adaptive foreground to {scaled_size}x{scaled_size}...")
    scaled_content = cropped_img.resize((scaled_size, scaled_size), Image.Resampling.LANCZOS)
    
    # Create transparent canvas
    foreground_canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # Paste the scaled content in the center
    paste_offset = (size - scaled_size) // 2
    foreground_canvas.paste(scaled_content, (paste_offset, paste_offset))
    
    # Apply a radial alpha mask to fade the edges smoothly
    print("Applying radial alpha mask to feather the edges...")
    width_fg, height_fg = foreground_canvas.size
    center_x, center_y = width_fg / 2.0, height_fg / 2.0
    
    # Safe zone radius (about 180px on 576 canvas) and fade start/end
    fade_start = 180.0
    fade_end = 270.0
    
    pixels = foreground_canvas.load()
    for y in range(height_fg):
        for x in range(width_fg):
            dx = x - center_x
            dy = y - center_y
            distance = math.sqrt(dx*dx + dy*dy)
            
            r, g, b, a = pixels[x, y]
            
            if distance <= fade_start:
                # Keep original alpha
                new_a = a
            elif distance >= fade_end:
                # Fully transparent
                new_a = 0
            else:
                # Interpolate alpha smoothly from current alpha to 0
                factor = (fade_end - distance) / (fade_end - fade_start)
                new_a = int(a * factor)
                
            pixels[x, y] = (r, g, b, new_a)
            
    # Save adaptive foreground image
    foreground_canvas.save(app_icon_foreground_path, "PNG")
    print(f"Saved feathered adaptive icon foreground to {app_icon_foreground_path}")
    
    # The background color we recommend to use (we will use the dark `#0b0c07` to match the darkest corner)
    recommended_bg = "#0b0c07"
    return recommended_bg

if __name__ == "__main__":
    bg_hex = process_logo()
    print(f"SUCCESS: Generated assets. Use background color '{bg_hex}' in your configuration.")
