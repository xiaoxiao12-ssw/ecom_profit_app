import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

def create_master_icon(size=1024):
    # Create base image
    img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    
    # 1. Background: Smooth gradient from Top-Left Dark Navy/Slate to Bottom-Right Emerald Teal
    bg = Image.new("RGBA", (size, size))
    draw_bg = ImageDraw.Draw(bg)
    
    c_top = (15, 23, 42)      # Deep Slate #0F172A
    c_mid = (13, 71, 62)      # Dark Pine/Teal #0D473E
    c_bot = (5, 150, 105)     # Rich Emerald #059669
    
    # Fast vertical gradient with angled bias
    for y in range(size):
        ratio = y / float(size)
        if ratio < 0.5:
            f = ratio / 0.5
            r = int(c_top[0] + f * (c_mid[0] - c_top[0]))
            g = int(c_top[1] + f * (c_mid[1] - c_top[1]))
            b = int(c_top[2] + f * (c_mid[2] - c_top[2]))
        else:
            f = (ratio - 0.5) / 0.5
            r = int(c_mid[0] + f * (c_bot[0] - c_mid[0]))
            g = int(c_mid[1] + f * (c_bot[1] - c_mid[1]))
            b = int(c_mid[2] + f * (c_bot[2] - c_mid[2]))
        draw_bg.line([(0, y), (size, y)], fill=(r, g, b, 255))
    
    # 2. Add soft ambient glow at the top-right and center
    glow = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    glow_draw = ImageDraw.Draw(glow)
    glow_draw.ellipse([size * 0.4, -size * 0.1, size * 1.1, size * 0.6], fill=(52, 211, 153, 50))
    glow_draw.ellipse([size * 0.2, size * 0.3, size * 0.8, size * 0.9], fill=(6, 182, 212, 40))
    glow = glow.filter(ImageFilter.GaussianBlur(radius=60))
    bg = Image.alpha_composite(bg, glow)
    
    # 3. Add modern geometric financial graphic:
    # Rising gradient area chart + crisp curve + glowing nodes + currency badge
    overlay = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    
    # Grid lines (subtle tech texture)
    grid_color = (255, 255, 255, 18)
    for gy in [320, 460, 600, 740]:
        draw.line([(140, gy), (884, gy)], fill=grid_color, width=3)
    for gx in [260, 420, 580, 740]:
        draw.line([(gx, 260), (gx, 780)], fill=grid_color, width=3)
        
    # Chart coordinates
    pts = [
        (180, 700),
        (340, 620),
        (500, 510),
        (660, 390),
        (820, 250)
    ]
    
    # Draw glowing area under the curve
    area_poly = [(180, 760)] + pts + [(820, 760)]
    area_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    area_draw = ImageDraw.Draw(area_layer)
    area_draw.polygon(area_poly, fill=(16, 185, 129, 65))
    bg = Image.alpha_composite(bg, area_layer)
    
    # Draw 3 vertical bar columns (subtle financial depth behind line)
    bar_color = (255, 255, 255, 28)
    bars = [
        (290, 620, 390, 760),
        (450, 510, 550, 760),
        (610, 390, 710, 760),
    ]
    for b in bars:
        draw.rounded_rectangle(b, radius=16, fill=bar_color)
    
    # Draw glowing main trend line
    line_layer = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    line_draw = ImageDraw.Draw(line_layer)
    
    # Multi-pass line for glow
    for w, a in [(32, 40), (22, 90), (14, 255)]:
        for i in range(len(pts) - 1):
            line_draw.line([pts[i], pts[i+1]], fill=(52, 211, 153, a) if w > 14 else (255, 255, 255, 255), width=w)
    
    # Draw data nodes
    for p in pts[:-1]:
        draw.ellipse([p[0] - 14, p[1] - 14, p[0] + 14, p[1] + 14], fill=(16, 185, 129, 255), outline=(255, 255, 255, 255), width=4)
        
    # Peak node (Arrow / Badge at the top right)
    peak = pts[-1]
    # Glowing pulse around peak
    draw.ellipse([peak[0] - 48, peak[1] - 48, peak[0] + 48, peak[1] + 48], fill=(52, 211, 153, 70))
    draw.ellipse([peak[0] - 30, peak[1] - 30, peak[0] + 30, peak[1] + 30], fill=(16, 185, 129, 255), outline=(255, 255, 255, 255), width=6)
    
    # Draw arrow head pointing up-right at peak
    arrow_pts = [
        (peak[0] + 36, peak[1] - 36),
        (peak[0] + 8, peak[1] - 36),
        (peak[0] + 36, peak[1] - 8)
    ]
    draw.line([(peak[0] + 10, peak[1] - 10), (peak[0] + 36, peak[1] - 36)], fill=(255, 255, 255, 255), width=8)
    draw.polygon(arrow_pts, fill=(255, 255, 255, 255))
    
    # 4. Stylized Financial "¥" Badge in center/left for instant recognition
    badge_box = (170, 240, 390, 460)
    draw.rounded_rectangle(badge_box, radius=48, fill=(15, 23, 42, 220), outline=(52, 211, 153, 180), width=6)
    
    # Draw bold crisp "¥" inside the badge
    # Top V of ¥
    cx, cy = (280, 350)
    draw.line([(cx - 48, cy - 54), (cx, cy - 8)], fill=(255, 255, 255, 255), width=12)
    draw.line([(cx + 48, cy - 54), (cx, cy - 8)], fill=(255, 255, 255, 255), width=12)
    # Stem of ¥
    draw.line([(cx, cy - 8), (cx, cy + 54)], fill=(255, 255, 255, 255), width=12)
    # Two crossbars
    draw.line([(cx - 42, cy + 4), (cx + 42, cy + 4)], fill=(52, 211, 153, 255), width=11)
    draw.line([(cx - 36, cy + 24), (cx + 36, cy + 24)], fill=(52, 211, 153, 255), width=11)

    # Composite layers
    img = Image.alpha_composite(bg, overlay)
    img = Image.alpha_composite(img, line_layer)
    
    # 5. Rounded squircle mask for the master icon
    mask = Image.new("L", (size, size), 0)
    mask_draw = ImageDraw.Draw(mask)
    # Soft squircle radius (~224px for 1024px)
    mask_draw.rounded_rectangle([0, 0, size, size], radius=224, fill=255)
    
    # Border stroke
    final_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    final_img.paste(img, (0, 0), mask)
    final_draw = ImageDraw.Draw(final_img)
    final_draw.rounded_rectangle([2, 2, size - 2, size - 2], radius=224, outline=(255, 255, 255, 50), width=4)
    
    return final_img

def main():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    assets_icon_dir = os.path.join(base_dir, "assets", "icon")
    os.makedirs(assets_icon_dir, exist_ok=True)
    
    print("Generating 1024x1024 Master Icon...")
    master = create_master_icon(1024)
    master_path = os.path.join(assets_icon_dir, "app_icon.png")
    master.save(master_path, "PNG")
    print(f"Master icon saved to {master_path}")
    
    # Android mipmap targets
    sizes = {
        "mipmap-mdpi": 48,
        "mipmap-hdpi": 72,
        "mipmap-xhdpi": 96,
        "mipmap-xxhdpi": 144,
        "mipmap-xxxhdpi": 192,
    }
    
    # Save to assets/icon/mipmap-* as templates
    for folder, dim in sizes.items():
        out_dir = os.path.join(assets_icon_dir, folder)
        os.makedirs(out_dir, exist_ok=True)
        resized = master.resize((dim, dim), Image.Resampling.LANCZOS)
        out_path = os.path.join(out_dir, "ic_launcher.png")
        resized.save(out_path, "PNG")
        print(f"Generated {out_path} ({dim}x{dim})")

    # If android folder exists locally, also copy there
    android_res = os.path.join(base_dir, "android", "app", "src", "main", "res")
    if os.path.exists(android_res):
        for folder, dim in sizes.items():
            target_dir = os.path.join(android_res, folder)
            os.makedirs(target_dir, exist_ok=True)
            resized = master.resize((dim, dim), Image.Resampling.LANCZOS)
            target_path = os.path.join(target_dir, "ic_launcher.png")
            resized.save(target_path, "PNG")
            print(f"Copied to local android res: {target_path}")

    print("App icon generation complete!")

if __name__ == "__main__":
    main()
