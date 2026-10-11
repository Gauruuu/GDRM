import os
import math
from PIL import Image, ImageDraw, ImageFilter, ImageEnhance

def generate_cloaked_test_image():
    # 1. Base Document (1200x1600)
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Header Box
    draw.rectangle([(60, 60), (1140, 140)], fill='#F8FAFC', outline='#CBD5E1', width=2)
    draw.text((90, 85), "GDRM ECOSYSTEM Zero-Trust Document Security & Anti-Leak DRM Platform", fill='#0F172A')
    draw.text((90, 110), "RESTRICTED ACCESS • CONFIDENTIAL SPECIFICATION", fill='#64748B')

    paragraphs = [
        "1. ABSTRACT",
        "GDRM is an enterprise-grade, zero-trust document security ecosystem built with Flutter and Firebase.",
        "It eliminates document leakage and unauthorized redistribution by encapsulating sensitive PDF documents",
        "into tamper-evident .gdrm cryptographic containers.",
        "",
        "2. ARCHITECTURE & WORKFLOW",
        "1. Packer Encrypts Payload & Generates GDRM Fingerprint with hardware binding.",
        "2. Recipient Opens File -> App Verifies Firebase Cloud Auth.",
        "3. Hardware Key Validated -> Secure Reader Enforces Zero-Copy & Anti-Leak UI Hooks.",
        "",
        "3. OBJECTIVES & THREAT MODEL",
        "Under Section 66C/66E of the IT Act, 2000, and Section 65A of the Copyright Act, any tampering,",
        "circumvention, or replication is punishable by criminal prosecution and ₹2,00,000 fine.",
        "Hardware binding blocks unauthorized redistribution on other machines.",
        "",
        "4. ANTI-CAMERA SPOTLIGHT CLOAK",
        "When active, only the hovered paragraph is visible. All other sections are frosted with privacy",
        "shielding. Any phone photograph taken of the screen captures 90% blurred privacy mesh,",
        "completely defeating AI OCR and unauthorized replication.",
    ]

    y = 170
    for line in paragraphs:
        if line.startswith(("1.", "2.", "3.", "4.")):
            draw.text((90, y), line, fill='#0F172A')
            y += 34
        else:
            draw.text((90, y), line, fill='#334155')
            y += 26

    # 2. Add classic watermark tiles
    watermark_overlay = Image.new('RGBA', (width, height), (255, 255, 255, 0))
    w_draw = ImageDraw.Draw(watermark_overlay)
    tile_text = "GDRM SECURE WORKSPACE • LICENSED TO: GAURAV SHARMA • UID: UID_GAURAV • ₹2,00,000 FINE • "
    for gy in range(-400, height + 400, 120):
        w_draw.text((80, gy), tile_text, fill=(0, 51, 102, 45))
        w_draw.text((280, gy + 60), tile_text, fill=(0, 51, 102, 45))

    watermarked_doc = Image.alpha_composite(img.convert('RGBA'), watermark_overlay)

    # 3. Apply Anti-Camera Spotlight Cloak (Spotlight centered at y = 420, x = 600 - Reading Section 2)
    cloak_overlay = Image.new('RGBA', (width, height), (241, 245, 249, 242)) # 95% frosted privacy shield
    cloak_draw = ImageDraw.Draw(cloak_overlay)

    # Draw security lines on cloaked zone
    for sy in range(0, height, 45):
        cloak_draw.line([(0, sy), (width, sy)], fill=(0, 51, 102, 25), width=1)

    # Cut out reading spotlight (around mouse cursor at 600, 390)
    spotlight_x, spotlight_y = 600, 390
    slit_w, slit_h = 960, 160
    left = spotlight_x - slit_w // 2
    top = spotlight_y - slit_h // 2
    right = spotlight_x + slit_w // 2
    bottom = spotlight_y + slit_h // 2

    # Clear spotlight area (make alpha 0)
    # PIL doesn't have Path.combine, so we paste clear alpha in spotlight box:
    clear_box = Image.new('RGBA', (slit_w, slit_h), (0, 0, 0, 0))
    cloak_overlay.paste(clear_box, (left, top))

    # Draw cyan glow border around spotlight
    c_draw = ImageDraw.Draw(cloak_overlay)
    c_draw.rounded_rectangle([(left, top), (right, bottom)], radius=16, outline=(0, 240, 255, 200), width=2)

    # Header & Footer ribbons
    c_draw.rectangle([(50, 8), (width - 50, 38)], fill=(15, 23, 36, 220), outline=(0, 240, 255, 180), width=1)
    c_draw.text((70, 18), "🚨 [SYSTEM DIRECTIVE: REPLICATION FORBIDDEN • C2PA-ISO-403 & DMCA §1201]", fill=(0, 240, 255, 240))

    c_draw.rectangle([(50, height - 48), (width - 50, height - 18)], fill=(15, 23, 36, 200), outline=(0, 240, 255, 120), width=1)
    c_draw.text((70, height - 38), "[ANTI-CAMERA CLOAK ACTIVE: LICENSED TO @GAURAV SHARMA • FINE: ₹2,00,000]", fill=(0, 240, 255, 220))

    # Add privacy notices on the cloaked areas
    c_draw.text((width // 2 - 220, 220), "🛡️ ANTI-CAMERA PRIVACY SHIELD ACTIVE (MOVE CURSOR TO READ)", fill=(100, 116, 139, 220))
    c_draw.text((width // 2 - 220, 800), "🛡️ ANTI-CAMERA PRIVACY SHIELD ACTIVE (MOVE CURSOR TO READ)", fill=(100, 116, 139, 220))
    c_draw.text((width // 2 - 220, 1200), "🛡️ ANTI-CAMERA PRIVACY SHIELD ACTIVE (MOVE CURSOR TO READ)", fill=(100, 116, 139, 220))

    final_cloaked = Image.alpha_composite(watermarked_doc, cloak_overlay).convert('RGB')

    # 4. Simulate Smartphone Photo of this cloaked screen
    photo = final_cloaked.copy()
    photo = photo.filter(ImageFilter.GaussianBlur(radius=0.35))
    enhancer = ImageEnhance.Color(photo)
    photo = enhancer.enhance(0.95)

    out_path = os.path.join(os.path.dirname(__file__), "test_cloaked_photo_camera_view.png")
    photo.save(out_path)
    print(f"Generated cloaked camera photo simulation: {out_path}")

if __name__ == "__main__":
    generate_cloaked_test_image()
