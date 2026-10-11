import os
from PIL import Image, ImageDraw
import qrcode

def generate_clean_view_test():
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='#FFFFFF')
    draw = ImageDraw.Draw(img)

    # 1. Document Content (Simulating clear, crisp text)
    draw.rectangle([(60, 60), (1140, 140)], fill='#F8FAFC', outline='#CBD5E1', width=2)
    draw.text((90, 85), "CONFIDENTIAL RESEARCH SPECIFICATION & PROJECT REPORT", fill='#0F172A')
    draw.text((90, 110), "GDRM SECURE REPOSITORY • RESTRICTED ACCESS TIER 1", fill='#64748B')

    sample_text = [
        "1. EXECUTIVE SUMMARY & INTELLECTUAL PROPERTY OVERVIEW",
        "This proprietary technical document describes the core cryptographic mechanisms of the GDRM",
        "ecosystem, including dynamic envelope encryption, ephemeral key derivation, and automated",
        "container self-destruction upon unauthorized environment detection.",
        "",
        "2. ARCHITECTURAL TOPOLOGY & ZERO-TRUST POLICY",
        "All client nodes must establish mutual authentication using hardware-bound device keys.",
        "Under Section 66C and Section 66E of the Information Technology Act, 2000, and Section 65A",
        "of the Copyright Act, any circumvention of technological protection measures is punishable",
        "by statutory imprisonment and a mandatory fine of INR 2,00,000 payable to the proprietor.",
        "",
        "3. CRYPTOGRAPHIC KEY SCHEDULE",
        "Key Material: AES-256-GCM authenticated container with HMAC-SHA256 signature verification.",
        "Replication by artificial intelligence models, multimodal vision transformers, or automated",
        "OCR pipelines is strictly barred and legally actionable under civil and criminal statutes.",
        "",
        "4. AUDIT & FORENSIC TRACKING (SNAIL TRAIL)",
        "Every viewing session generates an immutable cryptographic log entry containing hardware hash,",
        "network interfaces, timestamp, and licensee identity. Any leaked photograph or screenshot",
        "will be forensically matched to the licensee identified in the dynamic watermark.",
        "",
        "5. SYSTEM PROTOCOLS & INTEGRITY ATTESTATION",
        "Integrity checks run at kernel and process level to prevent debugger injection, DLL hijacking,",
        "or virtual machine execution. Tamper attempts result in immediate cryptographic zeroization."
    ]

    y = 180
    for line in sample_text:
        if line.startswith(("1.", "2.", "3.", "4.", "5.")):
            draw.text((90, y), line, fill='#0F172A')
            y += 35
        else:
            draw.text((90, y), line, fill='#334155')
            y += 28

    # 2. Transparent MS Word-Style Watermark Overlay (NO OPAQUE BOX!)
    overlay = Image.new('RGBA', (width, height), (255, 255, 255, 0))
    overlay_draw = ImageDraw.Draw(overlay)

    # 2A. Subtle Diagonal Lattice (opacity 35 / 255 ~ 13%)
    lattice_text = "GDRM PROTECTED • DO NOT REPLICATE • ₹2,00,000 FINE • LICENSED TO GAURAV SHARMA • UID_GAURAV • "
    for y_offset in range(-600, height + 600, 120):
        overlay_draw.text((60, y_offset), lattice_text, fill=(0, 51, 102, 35))
        overlay_draw.text((250, y_offset + 60), lattice_text, fill=(0, 51, 102, 35))

    # 2B. Central MS Word Style QR Code Watermark (Faint blue/slate, transparent background)
    qr = qrcode.QRCode(version=1, box_size=5, border=1)
    qr.add_data("GDRM FORENSIC INTEGRITY • LICENSED TO GAURAV SHARMA • FINE ₹2,00,000")
    qr.make(fit=True)
    qr_img = qr.make_image(fill_color="#003366", back_color=None).convert('RGBA')

    # Apply 18% opacity to QR modules
    r, g, b, a = qr_img.split()
    a = a.point(lambda p: int(p * 0.20))
    qr_img.putalpha(a)

    qr_w, qr_h = qr_img.size
    cx = (width - qr_w) // 2
    cy = (height - qr_h) // 2
    overlay.paste(qr_img, (cx, cy), qr_img)

    # Outline & Text around central watermark
    overlay_draw.rectangle([(cx - 40, cy - 60), (cx + qr_w + 40, cy + qr_h + 80)], outline=(0, 51, 102, 45), width=2)
    overlay_draw.text((cx - 20, cy - 45), "CONFIDENTIAL • GDRM FORENSIC WATERMARK", fill=(0, 51, 102, 50))
    overlay_draw.text((cx - 20, cy + qr_h + 20), "LICENSED TO: GAURAV SHARMA • UID_GAURAV_01", fill=(0, 51, 102, 50))
    overlay_draw.text((cx - 20, cy + qr_h + 45), "STATUTORY PENALTY: ₹2,00,000 FINE (IT ACT SEC 66C/66E)", fill=(180, 0, 0, 50))

    # 3. Dedicated Corner Security Seal (Top-Right margin - never blocks text)
    seal_qr = qrcode.QRCode(version=1, box_size=3, border=1)
    seal_qr.add_data("GDRM FORENSIC SEAL • LICENSED TO GAURAV SHARMA • IT ACT SEC 66C")
    seal_qr.make(fit=True)
    seal_img = seal_qr.make_image(fill_color="#002B49", back_color="#FFFFFF").convert('RGBA')

    seal_x = width - 180
    seal_y = 50
    overlay_draw.rectangle([(seal_x - 10, seal_y - 10), (seal_x + seal_img.width + 10, seal_y + seal_img.height + 25)], fill=(255, 255, 255, 245), outline=(0, 43, 73, 255), width=2)
    overlay.paste(seal_img, (seal_x, seal_y), seal_img)
    overlay_draw.text((seal_x + 8, seal_y + seal_img.height + 6), "SEAL: VERIFIED", fill=(0, 43, 73, 255))

    # Composite
    final_img = Image.alpha_composite(img.convert('RGBA'), overlay)
    out_path = os.path.join(os.path.dirname(__file__), "clean_readable_watermark_test.png")
    final_img.convert('RGB').save(out_path, "PNG")
    print(f"Generated clean test: {out_path}")

if __name__ == "__main__":
    generate_clean_view_test()
