import fitz  # PyMuPDF
import os

def export_pdf_to_images():
    pdf_path = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster.pdf"
    png_path = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster.png"
    jpg_path = r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster.jpg"
    
    if not os.path.exists(pdf_path):
        print(f"Error: {pdf_path} not found!")
        return

    doc = fitz.open(pdf_path)
    page = doc[0]
    
    # 1000mm = 39.37 inches. At 72 DPI base points, page is ~2835 x 2835 pt.
    # A zoom matrix of 1.411 gives ~4000 x 4000 pixels (Ultra-Crisp, crystal clear text)
    # A zoom matrix of 2.0 gives ~5670 x 5670 pixels (Super High-Res for Flex Printing)
    
    print("Rendering High-Resolution PNG (4000x4000 px)...")
    matrix = fitz.Matrix(1.5, 1.5)  # ~4250 x 4250 px
    pix = page.get_pixmap(matrix=matrix, alpha=False)
    pix.save(png_path)
    print(f"PNG saved ({pix.width}x{pix.height} px): {png_path}")
    
    print("Rendering High-Quality JPG...")
    pix.save(jpg_path)
    print(f"JPG saved ({pix.width}x{pix.height} px): {jpg_path}")

    # Also export PowerPoint slide if PowerPoint is installed
    try:
        import win32com.client
        pptx_path = os.path.abspath(r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster.pptx")
        pptx_png = os.path.abspath(r"d:\Kabada\GDRM Flutter\gdrm_ecosystem\GDRM_1m_Flex_Poster_from_PPTX.png")
        if os.path.exists(pptx_path):
            powerpoint = win32com.client.Dispatch("PowerPoint.Application")
            deck = powerpoint.Presentations.Open(pptx_path, WithWindow=False)
            deck.Slides[1].Export(pptx_png, "PNG", 3500, 3500)
            deck.Close()
            powerpoint.Quit()
            print(f"PPTX slide exported: {pptx_png}")
    except Exception as e:
        print(f"Note on PPTX direct export: {e}")

if __name__ == "__main__":
    export_pdf_to_images()
