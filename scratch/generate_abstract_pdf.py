from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.platypus import SimpleDocTemplate, Paragraph, Spacer
from reportlab.lib.enums import TA_CENTER, TA_JUSTIFY, TA_LEFT

def generate_pdf():
    pdf_path = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_Project_Abstract.pdf"
    
    # Standard academic page setup (A4, 1 inch / 72pt margins)
    doc = SimpleDocTemplate(
        pdf_path,
        pagesize=A4,
        leftMargin=72,
        rightMargin=72,
        topMargin=80,
        bottomMargin=72
    )

    styles = getSampleStyleSheet()

    # Academic Typography Styles (Times-Roman, Black and White, No decoration)
    title_style = ParagraphStyle(
        'DocTitle',
        fontName='Times-Bold',
        fontSize=13,
        leading=18,
        alignment=TA_CENTER,
        spaceAfter=18
    )

    abstract_heading_style = ParagraphStyle(
        'AbstractHeading',
        fontName='Times-Bold',
        fontSize=12,
        leading=16,
        alignment=TA_CENTER,
        spaceAfter=14
    )

    body_style = ParagraphStyle(
        'Body',
        fontName='Times-Roman',
        fontSize=11,
        leading=16.5,
        alignment=TA_JUSTIFY,
        spaceAfter=14
    )

    keywords_style = ParagraphStyle(
        'Keywords',
        fontName='Times-Roman',
        fontSize=11,
        leading=16,
        alignment=TA_JUSTIFY,
        spaceBefore=16
    )

    story = []

    # Title
    title_text = "Granular Digital Right Manager: A Zero-Trust Document Security and Anti-Leak Platform for Digital Rights Management"
    story.append(Paragraph(title_text, title_style))

    # Abstract Subtitle
    story.append(Paragraph("Abstract", abstract_heading_style))

    # Paragraph 1
    p1_text = (
        "In today's digital environment, sharing confidential documents carries serious risks of unauthorized "
        "copying, leakage, and redistribution. Traditional security solutions, such as basic password protection "
        "and standard PDF permissions, are often ineffective because they can be easily bypassed using third-party "
        "decryption utilities, virtual PDF printers, or simple copy-paste operations. This project introduces the "
        "<b>Granular Digital Right Manager (GDRM Ecosystem)</b>, a zero-trust document security platform designed to "
        "protect sensitive electronic documents across their entire lifecycle. The system works by encapsulating "
        "standard PDF files into encrypted, tamper-evident <code>.gdrm</code> container files. Access to each container is "
        "strictly locked to a verified recipient username registered in a cloud backend using Firebase Authentication "
        "and Cloud Firestore. When an authorized user opens the file, the application also binds the document to the "
        "primary hardware signature of that device, preventing the file from being opened if it is forwarded to an "
        "unauthorized computer or phone."
    )
    story.append(Paragraph(p1_text, body_style))

    # Paragraph 2
    p2_text = (
        "During document viewing, the built-in reader enforces strict client-side protections by disabling text "
        "selection, blocking operating system clipboard shortcuts (such as Ctrl+C), and preventing unauthorized screen "
        "capture. To secure physical paper workflows, the platform incorporates a dedicated print spooler filter that "
        "blocks virtual 'Print to PDF' drivers and only permits physical printing with dynamic, traceable forensic "
        "watermarks. Additionally, senders can set timed access rules, including scheduled opening dates, self-destruct "
        "countdown timers (ChronoLock), and maximum view limits that destroy decrypted local data upon expiration. By "
        "combining cryptographic packaging, cloud identity verification, device hardware locking, and anti-leak reading "
        "controls, the GDRM Ecosystem provides an effective, lightweight, and practical security framework for legal, "
        "corporate, academic, and government document exchange."
    )
    story.append(Paragraph(p2_text, body_style))

    story.append(Spacer(1, 10))

    # Keywords
    keywords_text = (
        "<b>Keywords:</b> Granular Digital Right Manager, GDRM, Document Security, Zero-Trust Architecture, "
        "Cryptographic Containers, Hardware Binding, Anti-Copy Protection, Forensic Watermarking, Firebase Authentication."
    )
    story.append(Paragraph(keywords_text, keywords_style))

    doc.build(story)
    print(f"Abstract PDF generated successfully at: {pdf_path}")

if __name__ == "__main__":
    generate_pdf()
