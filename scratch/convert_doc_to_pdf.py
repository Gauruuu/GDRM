import os
import json
import subprocess
import time

md_path = os.path.abspath(r"DOCUMENTATION.md")
html_path = os.path.abspath(r"DOCUMENTATION.html")
pdf_path = os.path.abspath(r"DOCUMENTATION.pdf")
pdf_path_alt = os.path.abspath(r"GDRM_Ecosystem_Complete_Documentation.pdf")

with open(md_path, "r", encoding="utf-8") as f:
    md_content = f.read()

# Encode markdown as JSON string to safely embed in JS
md_json = json.dumps(md_content)

html_template = f"""<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>GDRM Ecosystem — Complete Technical Specification</title>
  <!-- Marked.js for Markdown parsing -->
  <script src="https://cdn.jsdelivr.net/npm/marked/marked.min.js"></script>
  <!-- MathJax for LaTeX mathematical formula rendering -->
  <script>
    window.MathJax = {{
      tex: {{
        inlineMath: [['$', '$'], ['\\\\(', '\\\\)']],
        displayMath: [['$$', '$$'], ['\\\\[', '\\\\]']],
        processEscapes: true
      }},
      options: {{
        skipHtmlTags: ['script', 'noscript', 'style', 'textarea', 'pre', 'code']
      }},
      startup: {{
        ready: () => {{
          MathJax.startup.defaultReady();
          window.mathJaxReady = true;
        }}
      }}
    }};
  </script>
  <script src="https://cdn.jsdelivr.net/npm/mathjax@3/es5/tex-mml-chtml.js" id="MathJax-script" async></script>

  <style>
    @page {{
      size: A4;
      margin: 18mm 16mm 18mm 16mm;
      @bottom-right {{
        content: counter(page);
      }}
    }}
    
    body {{
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
      font-size: 10.5pt;
      line-height: 1.6;
      color: #1a202c;
      background-color: #ffffff;
      margin: 0;
      padding: 0;
    }}

    h1 {{
      font-size: 20pt;
      color: #0f172a;
      border-bottom: 2px solid #0284c7;
      padding-bottom: 8px;
      margin-top: 0;
      margin-bottom: 14px;
      font-weight: 800;
    }}

    h2 {{
      font-size: 14pt;
      color: #0369a1;
      border-bottom: 1px solid #e2e8f0;
      padding-bottom: 5px;
      margin-top: 24px;
      margin-bottom: 12px;
      page-break-after: avoid;
      font-weight: 700;
    }}

    h3 {{
      font-size: 11.5pt;
      color: #0f172a;
      margin-top: 18px;
      margin-bottom: 8px;
      page-break-after: avoid;
      font-weight: 600;
    }}

    h4 {{
      font-size: 10.5pt;
      color: #334155;
      margin-top: 12px;
      margin-bottom: 6px;
      page-break-after: avoid;
      font-weight: 600;
    }}

    p, li {{
      color: #334155;
      margin-top: 4px;
      margin-bottom: 6px;
    }}

    code {{
      font-family: "Fira Code", "Cascadia Code", Consolas, Monaco, monospace;
      font-size: 9pt;
      background-color: #f1f5f9;
      color: #0369a1;
      padding: 2px 5px;
      border-radius: 4px;
      border: 1px solid #e2e8f0;
    }}

    pre {{
      background-color: #0b0f19;
      color: #f8fafc;
      padding: 12px 14px;
      border-radius: 6px;
      overflow-x: auto;
      font-family: "Fira Code", "Cascadia Code", Consolas, monospace;
      font-size: 8.5pt;
      line-height: 1.45;
      border: 1px solid #1e293b;
      margin: 12px 0;
      page-break-inside: avoid;
    }}

    pre code {{
      background: transparent;
      color: #f8fafc;
      padding: 0;
      border: none;
      font-size: 8.5pt;
    }}

    table {{
      width: 100%;
      border-collapse: collapse;
      margin: 14px 0;
      font-size: 9.5pt;
      page-break-inside: avoid;
    }}

    th, td {{
      border: 1px solid #cbd5e1;
      padding: 7px 10px;
      text-align: left;
    }}

    th {{
      background-color: #f8fafc;
      color: #0f172a;
      font-weight: 700;
      border-bottom: 2px solid #94a3b8;
    }}

    tr:nth-child(even) {{
      background-color: #f8fafc;
    }}

    blockquote {{
      border-left: 4px solid #0284c7;
      margin: 10px 0;
      padding: 8px 14px;
      background-color: #f0f9ff;
      color: #0369a1;
      font-size: 9.5pt;
    }}

    hr {{
      border: none;
      border-top: 1px solid #e2e8f0;
      margin: 20px 0;
    }}

    .mjx-chtml {{
      font-size: 105% !important;
      color: #0f172a !important;
    }}

    /* Print specific tweaks */
    @media print {{
      body {{
        -webkit-print-color-adjust: exact;
        print-color-adjust: exact;
      }}
      pre, table, blockquote {{
        page-break-inside: avoid;
      }}
      h1, h2, h3, h4 {{
        page-break-after: avoid;
      }}
    }}
  </style>
</head>
<body>
  <div id="content"></div>

  <script>
    const md = {md_json};
    document.getElementById('content').innerHTML = marked.parse(md);
    
    // Trigger MathJax after markdown rendered
    function typeset() {{
      if (window.MathJax && window.MathJax.typesetPromise) {{
        window.MathJax.typesetPromise().then(() => {{
          document.body.classList.add('rendered');
        }});
      }} else {{
        setTimeout(typeset, 100);
      }}
    }}
    window.addEventListener('DOMContentLoaded', typeset);
  </script>
</body>
</html>
"""

with open(html_path, "w", encoding="utf-8") as f:
    f.write(html_template)

print(f"Generated HTML at: {html_path}")

# Find Chrome / Edge
chrome_paths = [
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
]

browser_exe = None
for p in chrome_paths:
    if os.path.exists(p):
        browser_exe = p
        break

if not browser_exe:
    print("No Chrome/Edge executable found.")
    exit(1)

print(f"Using browser: {browser_exe}")

# Run headless Chrome to print PDF
file_url = f"file:///{html_path.replace(os.sep, '/')}"

cmd = [
    browser_exe,
    "--headless=new",
    "--disable-gpu",
    "--no-pdf-header-footer",
    "--run-all-compositor-stages-before-draw",
    "--virtual-time-budget=5000",
    f"--print-to-pdf={pdf_path}",
    file_url
]

print("Printing to PDF via headless browser...")
res = subprocess.run(cmd, capture_output=True, text=True)
print(f"Chrome exit code: {res.returncode}")
if res.stderr:
    print(f"Chrome stderr: {res.stderr}")

if os.path.exists(pdf_path):
    print(f"Successfully generated: {pdf_path} (Size: {os.path.getsize(pdf_path)} bytes)")
    # Also copy to alternate name
    import shutil
    shutil.copyfile(pdf_path, pdf_path_alt)
    print(f"Also copied to: {pdf_path_alt}")
else:
    print("PDF generation failed.")
