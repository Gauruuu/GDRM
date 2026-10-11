import os
from PIL import Image, ImageDraw, ImageFont

def test_perfect_ms_word_watermark():
    width, height = 1200, 1600
    img = Image.new('RGB', (width, height), color='#FFFFFF')
    draw = ImageDraw.Draw(img)

    # Document Header Box
    draw.rectangle([(60, 60), (1140, 140)], fill='#F8FAFC', outline='#CBD5E1', width=2)
    draw.text((90, 85), "GDRM ECOSYSTEM Zero-Trust Document Security & Anti-Leak DRM Platform", fill='#0F172A')
    draw.text((90, 110), "Project Code: GDRM-2026 • Category: Engineering & Technology", fill='#64748B')

    paragraphs = [
        "1. ABSTRACT",
        "GDRM is an enterprise-grade, zero-trust document security ecosystem built with Flutter and Firebase.",
        "It eliminates document leakage and unauthorized redistribution by encapsulating sensitive PDF documents",
        "into tamper-evident .gdrm cryptographic containers.",
        "",
        "3. INTRODUCTION",
        "Conventional PDF documents suffer from structural security deficiencies. Once shared, static password",
        "protected files can be duplicated infinitely, decrypted by brute-force tools, or stripped of protection",
        "via virtual PDF print-to-file circumvention (e.g. Microsoft Print to PDF) and clipboard extractors.",
        "GDRM solves this with an active client-server zero-trust architecture.",
        "",
        "4. OBJECTIVES",
        "1. Cryptographic Encapsulation: Package PDFs into encrypted .gdrm binary containers with integrity headers.",
        "2. Identity-Bound Distribution: Enforce 1-to-1 recipient username locking verified via Firebase Cloud Firestore.",
        "3. Client-Side Anti-Leak Protection: Intercept and suppress text selection, hotkeys (Ctrl+C, Ctrl+A), and prints.",
        "4. Hardware Anchoring: Bind decrypted payloads to the first authorized device UUID.",
        "",
        "5. ARCHITECTURE & WORKFLOW",
        "1. Sender Configures Policies & Target Recipient (@handle).",
        "2. Packer Encrypts Payload & Generates GDRM Fingerprint.",
        "3. Recipient Opens File -> App Verifies Firebase Cloud Auth.",
        "4. Hardware Key Validated -> Alarms on Machine Mismatch.",
        "",
        "8. METHODOLOGY",
        "Under Section 66C and Section 66E of the Information Technology Act, 2000, and Section 65A of the Copyright Act,",
        "any circumvention of technological protection measures is punishable by statutory imprisonment and ₹2,00,000 fine."
    ]

    y = 170
    for line in paragraphs:
        if line.startswith(("1.", "3.", "4.", "5.", "8.")):
            draw.text((90, y), line, fill='#0F172A')
            y += 34
        else:
            draw.text((90, y), line, fill='#334155')
            y += 26

    # 2. Perfect MS Word Diagonal Watermark
    overlay = Image.new('RGBA', (width, height), (255, 255, 255, 0))

    stamp_w, stamp_h = 1000, 360
    stamp = Image.new('RGBA', (stamp_w, stamp_h), (255, 255, 255, 0))
    s_draw = ImageDraw.Draw(stamp)

    # Classic MS Word Slate Gray: RGB(100, 116, 139) with 15% opacity (alpha = 38)
    alpha = 38
    c = (100, 116, 139, alpha)

    # Line 1: Big Word-style Banner
    s_draw.text((160, 20), "CONFIDENTIAL • GDRM PROTECTED", fill=c)
    # Line 2: Licensee & UID
    s_draw.text((170, 75), "LICENSED TO: GAURAV SHARMA • USER ID: @GAURUUU", fill=c)
    # Line 3: Proprietor & Sig
    s_draw.text((210, 115), "PROPRIETOR: GAURAV • SIG: SIG-GDRM-8F32", fill=c)
    # Line 4: Statutory Penalty & Anti-Tampering
    s_draw.text((70, 160), "WATERMARK REMOVAL, REPLICATION & DOCUMENT TAMPERING STRICTLY RESTRICTED", fill=c)
    s_draw.text((90, 195), "SEC 66C/66E IT ACT & SEC 65A COPYRIGHT ACT: IMPRISONMENT + ₹2,00,000 FINE", fill=c)
    # Line 5: Session Telemetry
    s_draw.text((150, 235), "SESSION: 11 OCT 2026 UTC • IP: 192.168.1.15 • MAC: 00:1A:2B:3C:4D:5E", fill=c)

    # Rotate by -35 degrees
    rotated_stamp = stamp.rotate(35, resample=Image.BICUBIC, expand=True)
    rw, rh = rotated_stamp.size

    # Paste in center of page
    cx = (width - rw) // 2
    cy = (height - rh) // 2
    overlay.paste(rotated_stamp, (cx, cy), rotated_stamp)

    final_img = Image.alpha_composite(img.convert('RGBA'), overlay).convert('RGB')
    out_path = os.path.join(os.path.dirname(__file__), "perfect_ms_word_watermark_test.png")
    final_img.save(out_path)
    print(f"Generated perfect MS Word test: {out_path}")

if __name__ == "__main__":
    test_perfect_ms_word_watermark()
