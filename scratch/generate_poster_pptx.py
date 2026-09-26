import os
import collections.abc
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from pptx.enum.shapes import MSO_SHAPE

def create_poster_pptx():
    prs = Presentation()
    
    # 1 Meter x 1 Meter = 100 cm = 39.3701 inches
    prs.slide_width = Inches(39.37)
    prs.slide_height = Inches(39.37)
    
    blank_slide_layout = prs.slide_layouts[6]
    slide = prs.slides.add_slide(blank_slide_layout)
    
    # Exact Colors from Logo & Project
    c_bg = RGBColor(244, 249, 246)          # Soft light mint/sage
    c_dark = RGBColor(10, 60, 47)            # #0A3C2F Deep forest evergreen
    c_logo_green = RGBColor(55, 126, 34)     # #377E22 Exact GDRM Logo Green
    c_green = RGBColor(55, 126, 34)          # Primary green
    c_accent = RGBColor(40, 110, 30)         # Forest vibrant green
    c_mint = RGBColor(52, 211, 153)          # #34D399 Mint green
    c_white = RGBColor(255, 255, 255)
    c_body = RGBColor(17, 34, 17)            # Dark readable text
    c_muted = RGBColor(70, 80, 90)
    c_card_border = RGBColor(55, 126, 34)    # Border matching logo green
    
    # Dark UI Theme Colors for Mockups
    ui_bg = RGBColor(11, 15, 25)             # #0B0F19 Dark theme
    ui_sidebar = RGBColor(22, 27, 38)        # #161B26
    ui_panel = RGBColor(30, 37, 56)          # #1E2538
    ui_cyan = RGBColor(0, 240, 255)          # Cyan highlight
    ui_border = RGBColor(46, 55, 77)
    
    # Background full rect
    bg_shape = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, 0, 0, prs.slide_width, prs.slide_height)
    bg_shape.fill.solid()
    bg_shape.fill.fore_color.rgb = c_bg
    bg_shape.line.fill.background()
    
    font_family = "Times New Roman"
    font_ui = "Segoe UI"
    
    # ── HEADER ─────────────────────────────────────────────────────────────
    h_x = Inches(0.9)
    h_y = Inches(0.9)
    h_w = Inches(27.8)
    h_h = Inches(3.8)
    
    h_box = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, h_x, h_y, h_w, h_h)
    h_box.fill.solid()
    h_box.fill.fore_color.rgb = c_white
    h_box.line.color.rgb = c_card_border
    h_box.line.width = Pt(3.5)
    
    # Insert Exact Logo Image on Top Left of Header
    logo_path = os.path.abspath(r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\scratch\gdrm_logo.png")
    if os.path.exists(logo_path):
        slide.shapes.add_picture(logo_path, h_x + Inches(0.4), h_y + Inches(0.35), width=Inches(4.5))
    
    # Header Text Frame (Offset to the right of logo)
    text_left = h_x + Inches(5.2)
    text_width = h_w - Inches(5.5)
    
    h_txt_box = slide.shapes.add_textbox(text_left, h_y + Inches(0.2), text_width, Inches(3.4))
    tf = h_txt_box.text_frame
    tf.word_wrap = True
    tf.margin_left = 0
    tf.margin_top = 0
    tf.margin_right = 0
    tf.margin_bottom = 0
    
    p = tf.paragraphs[0]
    p.text = "GDRM Ecosystems"
    p.font.name = font_family
    p.font.size = Pt(40)
    p.font.bold = True
    p.font.color.rgb = c_dark
    p.space_after = Pt(2)
    
    p2 = tf.add_paragraph()
    p2.text = "Granular Digital Right Manager — Zero-Trust Cryptographic Document Security Platform"
    p2.font.name = font_family
    p2.font.size = Pt(17.5)
    p2.font.bold = True
    p2.font.color.rgb = c_logo_green
    p2.space_after = Pt(6)
    
    p3 = tf.add_paragraph()
    p3.text = "Encapsulate  •  Hardware Key Binding  •  Anti-Piracy Interceptor  •  Dynamic Watermark  •  ChronoLock Self-Destruct"
    p3.font.name = font_family
    p3.font.size = Pt(12.5)
    p3.font.italic = True
    p3.font.color.rgb = c_muted
    
    # Header Right (Metadata Box)
    m_x = Inches(29.1)
    m_y = Inches(0.9)
    m_w = Inches(9.37)
    m_h = Inches(3.8)
    
    m_box = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, m_x, m_y, m_w, m_h)
    m_box.fill.solid()
    m_box.fill.fore_color.rgb = c_white
    m_box.line.color.rgb = c_card_border
    m_box.line.width = Pt(3.5)
    
    mtf = m_box.text_frame
    mtf.word_wrap = True
    mtf.vertical_anchor = MSO_ANCHOR.MIDDLE
    mtf.margin_left = Inches(0.3)
    mtf.margin_right = Inches(0.3)
    
    meta_items = [
        ("Project Code", "CS-DRM-2026-09"),
        ("Category", "Cyber Security & Infosec"),
        ("Academic Level", "UG / Capstone Project")
    ]
    
    for i, (k, v) in enumerate(meta_items):
        mp = mtf.paragraphs[0] if i == 0 else mtf.add_paragraph()
        mp.text = f"{k} :  "
        mp.font.name = font_family
        mp.font.size = Pt(14)
        mp.font.bold = True
        mp.font.color.rgb = c_dark
        if i > 0:
            mp.space_before = Pt(12)
        
        run = mp.add_run()
        run.text = v
        run.font.name = font_family
        run.font.size = Pt(13.5)
        run.font.bold = False
        run.font.color.rgb = c_body
        
    # ── 12 SECTION GRID CONFIGURATION ──────────────────────────────────────
    col_w = Inches(11.95)
    gap_x = Inches(0.85)
    
    row_configs = [
        (Inches(5.1), Inches(8.5)),   # Row 1
        (Inches(14.0), Inches(7.5)),  # Row 2
        (Inches(21.9), Inches(7.5)),  # Row 3
        (Inches(29.8), Inches(6.8))   # Row 4
    ]
    
    def add_card(col_idx, row_idx, num_str, title_str):
        x = Inches(0.9) + col_idx * (col_w + gap_x)
        y, h = row_configs[row_idx]
        
        card = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, x, y, col_w, h)
        card.fill.solid()
        card.fill.fore_color.rgb = c_white
        card.line.color.rgb = c_card_border
        card.line.width = Pt(2.5)
        
        ctf = card.text_frame
        ctf.word_wrap = True
        ctf.margin_left = Inches(0.35)
        ctf.margin_right = Inches(0.35)
        ctf.margin_top = Inches(0.28)
        ctf.margin_bottom = Inches(0.25)
        
        hp = ctf.paragraphs[0]
        hp.text = f"{num_str}  {title_str}"
        hp.font.name = font_family
        hp.font.size = Pt(15.5)
        hp.font.bold = True
        hp.font.color.rgb = c_dark
        hp.space_after = Pt(8)
        
        return card, ctf
    
    # ── 1. ABSTRACT ────────────────────────────────────────────────────────
    _, c1 = add_card(0, 0, "1.", "ABSTRACT")
    p = c1.add_paragraph()
    p.text = "GDRM (Granular Digital Right Manager) is an enterprise-grade, zero-trust document security ecosystem built with Flutter and Firebase. It eliminates document leakage and unauthorized redistribution by encapsulating sensitive PDF documents into tamper-evident .gdrm cryptographic containers."
    p.font.name = font_family
    p.font.size = Pt(12)
    p.font.color.rgb = c_body
    p.space_after = Pt(8)
    
    p = c1.add_paragraph()
    p.text = "The system integrates active multi-factor enforcement: Cloud username recipient locking, automatic machine hardware binding, zero-selection anti-copy UI hooks, live countdown ChronoLock timers with data-melting triggers, and watermark-enforced physical printing while intercepting virtual PDF writers."
    p.font.name = font_family
    p.font.size = Pt(12)
    p.font.color.rgb = c_body
    
    # ── 2. SYSTEM INTERFACE (EXACT DESKTOP & MOBILE MOCKUPS) ───────────────
    card2, c2 = add_card(1, 0, "2.", "SYSTEM INTERFACE (MOCKUPS)")
    c2_x = Inches(0.9) + 1 * (col_w + gap_x)
    c2_y, c2_h = row_configs[0]
    
    # Desktop Mockup Window Frame (Left inside Box 2)
    dt_x = c2_x + Inches(0.4)
    dt_y = c2_y + Inches(0.9)
    dt_w = Inches(6.8)
    dt_h = Inches(6.8)
    
    dt_frame = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, dt_x, dt_y, dt_w, dt_h)
    dt_frame.fill.solid()
    dt_frame.fill.fore_color.rgb = ui_bg
    dt_frame.line.color.rgb = c_green
    dt_frame.line.width = Pt(1.5)
    
    dt_tb = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, dt_x, dt_y, dt_w, Inches(0.45))
    dt_tb.fill.solid()
    dt_tb.fill.fore_color.rgb = RGBColor(18, 24, 38)
    dt_tb.line.fill.background()
    tb_tf = dt_tb.text_frame
    tb_tf.margin_left = Inches(0.15)
    tb_p = tb_tf.paragraphs[0]
    tb_p.text = "● ● ●   GDRM Desktop Console - Reader & Security"
    tb_p.font.name = font_ui
    tb_p.font.size = Pt(8)
    tb_p.font.bold = True
    tb_p.font.color.rgb = RGBColor(160, 175, 200)
    
    dt_sb = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, dt_x, dt_y + Inches(0.45), Inches(2.2), dt_h - Inches(0.45))
    dt_sb.fill.solid()
    dt_sb.fill.fore_color.rgb = ui_sidebar
    dt_sb.line.fill.background()
    sb_tf = dt_sb.text_frame
    sb_tf.margin_left = Inches(0.1)
    sb_tf.margin_top = Inches(0.1)
    sb_p = sb_tf.paragraphs[0]
    sb_p.text = "GDRM ECOSYSTEMS\nGranular Digital Rights"
    sb_p.font.name = font_ui
    sb_p.font.size = Pt(7)
    sb_p.font.bold = True
    sb_p.font.color.rgb = ui_cyan
    sb_p.space_after = Pt(4)
    
    sb_items = [
        "▶ READER CONSOLE",
        "  PACKER CONSOLE",
        "  ────────────",
        "👤 @gaurav (Active)",
        "  ────────────",
        "MANIFEST:",
        "• Lic: Alice Corp",
        "• FP: GDRM-8F42",
        "• HW: BOUND-OK",
        "• Timer: ACTIVE"
    ]
    for it in sb_items:
        it_p = sb_tf.add_paragraph()
        it_p.text = it
        it_p.font.name = font_ui
        it_p.font.size = Pt(6.5)
        it_p.font.color.rgb = c_mint if "▶" in it or "BOUND" in it else RGBColor(180, 190, 205)
        it_p.space_after = Pt(2)
        
    dt_mp = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, dt_x + Inches(2.2), dt_y + Inches(0.45), dt_w - Inches(2.2), dt_h - Inches(0.45))
    dt_mp.fill.solid()
    dt_mp.fill.fore_color.rgb = RGBColor(245, 248, 250)
    dt_mp.line.fill.background()
    mp_tf = dt_mp.text_frame
    mp_tf.margin_left = Inches(0.15)
    mp_tf.margin_top = Inches(0.15)
    mp_p = mp_tf.paragraphs[0]
    mp_p.text = "CONFIDENTIAL LEGAL SPECIFICATION"
    mp_p.font.name = font_family
    mp_p.font.size = Pt(8.5)
    mp_p.font.bold = True
    mp_p.font.color.rgb = RGBColor(20, 30, 40)
    mp_p.space_after = Pt(4)
    
    doc_lines = [
        "1. Executive Architecture Scope",
        "This container is cryptographically bound to",
        "target username @alice and hardware UUID.",
        "Zero text drag selection is enforced.",
        "Screenshot & Print spooler hooks active.",
        "",
        "[ WATERMARK OVERLAY ]",
        "LICENSED TO: @alice",
        "IP: 192.168.1.104 • 2026-09-20",
        "",
        "🔒 PROTECTED VIEW ACTIVE"
    ]
    for dl in doc_lines:
        dl_p = mp_tf.add_paragraph()
        dl_p.text = dl
        dl_p.font.name = font_family
        dl_p.font.size = Pt(6.8)
        if "WATERMARK" in dl or "LICENSED" in dl:
            dl_p.font.color.rgb = RGBColor(180, 50, 50)
            dl_p.font.bold = True
        elif "PROTECTED" in dl:
            dl_p.font.color.rgb = c_green
            dl_p.font.bold = True
        else:
            dl_p.font.color.rgb = RGBColor(80, 90, 100)
        dl_p.space_after = Pt(1.5)

    # Mobile Mockup Device Frame (Right inside Box 2)
    mb_x = c2_x + Inches(7.55)
    mb_y = c2_y + Inches(0.9)
    mb_w = Inches(3.9)
    mb_h = Inches(6.8)
    
    mb_frame = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, mb_x, mb_y, mb_w, mb_h)
    mb_frame.fill.solid()
    mb_frame.fill.fore_color.rgb = ui_bg
    mb_frame.line.color.rgb = c_green
    mb_frame.line.width = Pt(1.8)
    
    mb_ab = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, mb_x + Inches(0.15), mb_y + Inches(0.15), mb_w - Inches(0.3), Inches(0.65))
    mb_ab.fill.solid()
    mb_ab.fill.fore_color.rgb = ui_sidebar
    mb_ab.line.fill.background()
    ab_tf = mb_ab.text_frame
    ab_tf.margin_left = Inches(0.1)
    ab_p = ab_tf.paragraphs[0]
    ab_p.text = "GDRM App  •  @gaurav"
    ab_p.font.name = font_ui
    ab_p.font.size = Pt(8.5)
    ab_p.font.bold = True
    ab_p.font.color.rgb = ui_cyan
    
    mb_cc = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, mb_x + Inches(0.15), mb_y + Inches(0.9), mb_w - Inches(0.3), Inches(5.0))
    mb_cc.fill.solid()
    mb_cc.fill.fore_color.rgb = ui_panel
    mb_cc.line.color.rgb = ui_border
    mb_cc.line.width = Pt(0.8)
    
    cc_tf = mb_cc.text_frame
    cc_tf.margin_left = Inches(0.1)
    cc_tf.margin_top = Inches(0.1)
    cc_p = cc_tf.paragraphs[0]
    cc_p.text = "PACKER CONSOLE"
    cc_p.font.name = font_ui
    cc_p.font.size = Pt(8.5)
    cc_p.font.bold = True
    cc_p.font.color.rgb = c_mint
    cc_p.space_after = Pt(4)
    
    mob_fields = [
        "📄 File: confidential_doc.pdf",
        "👤 Target: @alice_eng [✓ VERIFIED]",
        "⏱ ChronoLock: 24h Auto-Melt",
        "🔑 Password FileRip: ENABLED",
        "👁 Max Opens: 3 Views Limit",
        "",
        "▶ [ PACK & ENCRYPT .GDRM ]"
    ]
    for mf in mob_fields:
        mf_p = cc_tf.add_paragraph()
        mf_p.text = mf
        mf_p.font.name = font_ui
        mf_p.font.size = Pt(6.8)
        if "VERIFIED" in mf:
            mf_p.font.color.rgb = c_mint
            mf_p.font.bold = True
        elif "PACK & ENCRYPT" in mf:
            mf_p.font.color.rgb = ui_cyan
            mf_p.font.bold = True
        else:
            mf_p.font.color.rgb = RGBColor(200, 215, 230)
        mf_p.space_after = Pt(2.5)

    mb_nb = slide.shapes.add_shape(MSO_SHAPE.RECTANGLE, mb_x + Inches(0.15), mb_y + Inches(6.0), mb_w - Inches(0.3), Inches(0.55))
    mb_nb.fill.solid()
    mb_nb.fill.fore_color.rgb = ui_sidebar
    mb_nb.line.fill.background()
    nb_tf = mb_nb.text_frame
    nb_p = nb_tf.paragraphs[0]
    nb_p.text = "📖 Reader           📦 Packer (Active)"
    nb_p.font.name = font_ui
    nb_p.font.size = Pt(7.5)
    nb_p.font.bold = True
    nb_p.font.color.rgb = c_mint
    nb_p.alignment = PP_ALIGN.CENTER
    
    lbl_box = slide.shapes.add_textbox(c2_x + Inches(0.4), c2_y + Inches(7.75), col_w - Inches(0.8), Inches(0.5))
    ltf = lbl_box.text_frame
    ltf.margin_top = 0
    lp = ltf.paragraphs[0]
    lp.text = "Desktop Multi-Pane Console (Left)  |  Mobile App Interface (Right)"
    lp.font.name = font_family
    lp.font.size = Pt(10)
    lp.font.bold = True
    lp.font.color.rgb = c_dark
    lp.alignment = PP_ALIGN.CENTER

    # ── 3. INTRODUCTION ────────────────────────────────────────────────────
    _, c3 = add_card(2, 0, "3.", "INTRODUCTION")
    p = c3.add_paragraph()
    p.text = "Conventional PDF documents suffer from structural security deficiencies. Once shared, static password protected files can be duplicated infinitely, decrypted by brute-force tools, or stripped of protection via virtual PDF writers (e.g. Microsoft Print to PDF) and clipboard extractors."
    p.font.name = font_family
    p.font.size = Pt(12)
    p.font.color.rgb = c_body
    p.space_after = Pt(8)
    
    p = c3.add_paragraph()
    p.text = "GDRM (Granular Digital Right Manager) solves this with an active client-server zero-trust architecture. Decryption keys are never stored in plaintext and files strictly require cryptographic identity validation, hardware key matching, and real-time execution sandboxing."
    p.font.name = font_family
    p.font.size = Pt(12)
    p.font.color.rgb = c_body
    
    # ── 4. OBJECTIVES ──────────────────────────────────────────────────────
    _, c4 = add_card(0, 1, "4.", "OBJECTIVES")
    objs = [
        "1. Cryptographic Encapsulation: Package PDFs into encrypted .gdrm binary containers with custom integrity headers.",
        "2. Identity-Bound Distribution: Enforce 1-to-1 recipient username locking verified via Firebase Cloud Firestore.",
        "3. Client-Side Anti-Leak Protection: Intercept and suppress text selection, hotkeys (Ctrl+C, Ctrl+A), and unauthorized prints.",
        "4. Hardware Anchoring: Bind decrypted payloads to the first authorized device UUID to prevent file copying.",
        "5. Auditable Paper Printing: Provide rasterized watermarked physical printing while blocking virtual print drivers."
    ]
    for o in objs:
        p = c4.add_paragraph()
        p.text = o
        p.font.name = font_family
        p.font.size = Pt(11.2)
        p.font.color.rgb = c_body
        p.space_after = Pt(4)
        
    # ── 5. SYSTEM WORKFLOW ─────────────────────────────────────────────────
    _, c5 = add_card(1, 1, "5.", "ARCHITECTURE & WORKFLOW")
    flow = [
        "1. Sender Configures Policies & Target Recipient (@handle)",
        "   ↓",
        "2. Packer Encrypts Payload & Generates GDRM Fingerprint",
        "   ↓",
        "3. Recipient Opens File ➔ App Verifies Firebase Cloud Auth",
        "   ↓",
        "4. Hardware Key Validated (Alarms on Machine Mismatch)",
        "   ↓",
        "5. Secure Reader Enforces Zero-Copy, ChronoLock & Print Rules"
    ]
    for f in flow:
        p = c5.add_paragraph()
        p.text = f
        p.font.name = font_family
        p.font.size = Pt(11 if "↓" not in f else 10)
        p.font.bold = "↓" not in f
        p.font.color.rgb = c_dark if "↓" not in f else c_accent
        p.alignment = PP_ALIGN.CENTER if "↓" in f else PP_ALIGN.LEFT
        p.space_after = Pt(2)
        
    # ── 6. LITERATURE SURVEY ───────────────────────────────────────────────
    _, c6 = add_card(2, 1, "6.", "LITERATURE SURVEY")
    lit = [
        ("1. Standard Adobe PDF DRM (2018):", " Vulnerable to master key extractors and virtual PDF print-to-file circumvention."),
        ("2. Enterprise Cloud DRM (Azure AIP, 2021):", " Robust but involves high recurring license costs, heavy agents, and lack of offline self-destruction."),
        ("3. Hardware Cryptographic Anchors (NIST SP 800-57, 2022):", " Establishes device binding guidelines adapted in GDRM hardware locks."),
        ("4. Client Anti-Scraping Hooks (IEEE TIFS, 2023):", " Confirms efficacy of low-level OS input interception in data exfiltration defense.")
    ]
    for k, v in lit:
        p = c6.add_paragraph()
        p.text = k
        p.font.name = font_family
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = c_dark
        
        run = p.add_run()
        run.text = v
        run.font.name = font_family
        run.font.size = Pt(11)
        run.font.bold = False
        run.font.color.rgb = c_body
        p.space_after = Pt(3.5)
        
    # ── 7. RESEARCH GAP & THREATS ──────────────────────────────────────────
    _, c7 = add_card(0, 2, "7.", "RESEARCH GAP & THREATS")
    gaps = [
        "• Lack of Recipient Exclusivity: Once a traditional password-protected file is unlocked, it can be shared with infinite unauthorized third parties.",
        "• Clipboard Extraction: Most viewers allow highlight-copy text extraction into memory buffers with no forensic audit trail.",
        "• Virtual PDF Re-printing: Users easily bypass read-only restrictions by printing to a virtual PDF driver to generate unprotected files.",
        "• No Self-Destruct Mechanisms: Absence of time-bomb locks or view-counter auto-destruction for sensitive time-bound documents."
    ]
    for g in gaps:
        p = c7.add_paragraph()
        p.text = g
        p.font.name = font_family
        p.font.size = Pt(11)
        p.font.color.rgb = c_body
        p.space_after = Pt(3.5)
        
    # ── 8. METHODOLOGY ─────────────────────────────────────────────────────
    _, c8 = add_card(1, 2, "8.", "METHODOLOGY")
    meth = [
        "1. Threat Modeling: Analysis of document leakage attack vectors across memory, clipboard, disk caching, and virtual spooling.",
        "2. Container Cryptography: Specification of .gdrm binary headers, XOR keystream encryption, and cryptographic checksums.",
        "3. Cross-Platform Engine: Developed Flutter frontend with custom Native Win32 / macOS hooks for input suppression.",
        "4. Cloud Auth & Firestore: User identity registration, handle lookup, and real-time recipient verification backend.",
        "5. Security Validation: Penetration tests against piracy trips, spoofing, and file tampering."
    ]
    for m in meth:
        p = c8.add_paragraph()
        p.text = m
        p.font.name = font_family
        p.font.size = Pt(11)
        p.font.color.rgb = c_body
        p.space_after = Pt(3)
        
    # ── 9. FEATURES VS STANDARD PDF ────────────────────────────────────────
    _, c9 = add_card(2, 2, "9.", "FEATURES VS STANDARD PDF")
    feats = [
        ("• Username Recipient Lock:", " Decryption strictly restricted to authorized @username via Firebase Cloud registry."),
        ("• Hardware Machine Binding:", " Automatically bonds to the first opening computer; blocks unauthorized replication."),
        ("• Virtual Printer Blocking:", " Filters out Adobe/CutePDF drivers; allows only physical paper with dynamic watermarks."),
        ("• ChronoLock & Rigged Timers:", " Supports countdown self-destruct time-bombs and max view count quotas.")
    ]
    for k, v in feats:
        p = c9.add_paragraph()
        p.text = k
        p.font.name = font_family
        p.font.size = Pt(11)
        p.font.bold = True
        p.font.color.rgb = c_dark
        
        run = p.add_run()
        run.text = v
        run.font.name = font_family
        run.font.size = Pt(11)
        run.font.bold = False
        run.font.color.rgb = c_body
        p.space_after = Pt(3.5)
        
    # ── 10. FUTURE SCOPE ───────────────────────────────────────────────────
    _, c10 = add_card(0, 3, "10.", "FUTURE SCOPE")
    futures = [
        "1. AI Screen Recording Detection: Camera gaze tracking to prevent external smartphone recording.",
        "2. Zero-Knowledge Proofs: Anonymous yet cryptographically verified recipient authorization.",
        "3. Multi-Format Container: Extend .gdrm encapsulation to CAD blueprints, audio, and video.",
        "4. Decentralized Audit Logs: Immutable SnailTrail notarization on distributed ledgers."
    ]
    for f in futures:
        p = c10.add_paragraph()
        p.text = f
        p.font.name = font_family
        p.font.size = Pt(10.8)
        p.font.color.rgb = c_body
        p.space_after = Pt(2.5)
        
    # ── 11. CONCLUSION ─────────────────────────────────────────────────────
    _, c11 = add_card(1, 3, "11.", "CONCLUSION")
    p = c11.add_paragraph()
    p.text = "GDRM Ecosystems successfully establishes a comprehensive zero-trust security paradigm for sensitive electronic documents. By unifying cryptographic container packaging, cloud recipient authentication, hardware device binding, anti-copy reader suppression, and dynamic watermarked physical printing, Granular Digital Right Manager prevents unauthorized data leaks at every stage."
    p.font.name = font_family
    p.font.size = Pt(11)
    p.font.color.rgb = c_body
    
    # ── 12. REFERENCES ─────────────────────────────────────────────────────
    _, c12 = add_card(2, 3, "12.", "REFERENCES")
    refs = [
        "1. Stallings, W. (2020) - Cryptography & Network Security: Principles and Practice, 8th Ed.",
        "2. Adobe Systems Inc. (2020) - PDF Reference & Security Architecture Specification, ISO 32000-2.",
        "3. NIST SP 800-175B (2022) - Guideline for Using Cryptographic Standards in Organizations.",
        "4. IEEE TIFS (2023) - Defending Against Client-Side Data Leakage in Zero-Trust Systems."
    ]
    for r in refs:
        p = c12.add_paragraph()
        p.text = r
        p.font.name = font_family
        p.font.size = Pt(10.2)
        p.font.color.rgb = c_body
        p.space_after = Pt(2)
        
    # ── FOOTER BAR ─────────────────────────────────────────────────────────
    foot_x = Inches(0.9)
    foot_y = Inches(37.3)
    foot_w = Inches(37.57)
    foot_h = Inches(1.1)
    
    foot_box = slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE, foot_x, foot_y, foot_w, foot_h)
    foot_box.fill.solid()
    foot_box.fill.fore_color.rgb = c_dark
    foot_box.line.fill.background()
    
    ftf = foot_box.text_frame
    ftf.vertical_anchor = MSO_ANCHOR.MIDDLE
    fp = ftf.paragraphs[0]
    fp.text = "GDRM Ecosystems • Granular Digital Right Manager Architecture    |    Department of Computer Engineering & Cyber Security    |    1000mm × 1000mm Flex Format"
    fp.font.name = font_family
    fp.font.size = Pt(13)
    fp.font.bold = True
    fp.font.color.rgb = c_white
    fp.alignment = PP_ALIGN.CENTER
    
    output_path = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster.pptx"
    try:
        prs.save(output_path)
        print(f"Editable PPTX generated successfully at: {output_path}")
    except PermissionError:
        output_path_v2 = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster_v2.pptx"
        prs.save(output_path_v2)
        print(f"File was open in PowerPoint, saved to: {output_path_v2}")

if __name__ == "__main__":
    create_poster_pptx()
