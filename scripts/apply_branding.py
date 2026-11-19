import os
import shutil
import re

def apply_branding():
    base_dir = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
    manifest_path = os.path.join(base_dir, "android", "app", "src", "main", "AndroidManifest.xml")
    
    print(f"Updating AndroidManifest.xml at {manifest_path}...")
    if os.path.exists(manifest_path):
        with open(manifest_path, "r", encoding="utf-8") as f:
            content = f.read()
        
        # Replace label with 少伟利润通
        if 'android:label="ecom_profit_app"' in content:
            content = content.replace('android:label="ecom_profit_app"', 'android:label="少伟利润通"')
            print("Replaced android:label with 少伟利润通")
        elif 'android:label="' in content:
            content = re.sub(r'android:label="[^"]*"', 'android:label="少伟利润通"', content, count=1)
            print("Regex updated android:label to 少伟利润通")
        
        # Ensure icon is @mipmap/ic_launcher
        if 'android:icon="' in content:
            content = re.sub(r'android:icon="[^"]*"', 'android:icon="@mipmap/ic_launcher"', content, count=1)
            print("Verified android:icon=@mipmap/ic_launcher")
        
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(content)
    else:
        print("Warning: AndroidManifest.xml not found!")

    # Copy launcher icons to android res
    assets_icon_dir = os.path.join(base_dir, "assets", "icon")
    android_res_dir = os.path.join(base_dir, "android", "app", "src", "main", "res")
    
    # Remove anydpi-v26 if present so Android always uses our high-res full bleed ic_launcher.png
    anydpi_dir = os.path.join(android_res_dir, "mipmap-anydpi-v26")
    if os.path.exists(anydpi_dir):
        shutil.rmtree(anydpi_dir)
        print("Removed mipmap-anydpi-v26 to ensure full custom launcher icon display")

    mipmaps = ["mipmap-mdpi", "mipmap-hdpi", "mipmap-xhdpi", "mipmap-xxhdpi", "mipmap-xxxhdpi"]
    for folder in mipmaps:
        src = os.path.join(assets_icon_dir, folder, "ic_launcher.png")
        dst_folder = os.path.join(android_res_dir, folder)
        os.makedirs(dst_folder, exist_ok=True)
        if os.path.exists(src):
            shutil.copy(src, os.path.join(dst_folder, "ic_launcher.png"))
            print(f"Copied {folder}/ic_launcher.png")
            
    print("Branding application complete!")

if __name__ == "__main__":
    apply_branding()
