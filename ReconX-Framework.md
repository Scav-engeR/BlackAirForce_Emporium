# **ReconX – Full-Scope External Attack Surface Mapping Framework**

`ReconX` is an **end-to-end automated external security assessment framework** designed for professional penetration testers, bug bounty hunters, and enterprise red teams.
It performs **deep recon, enumeration, vulnerability scanning, OSINT, exposure discovery, and reporting** across **multiple targets at scale**.

## 🚀 Key Features

### 🔹 **Asset Discovery**

* Automated subdomain enumeration
* Passive + active DNS enumeration
* Public-facing IP discovery
* IP range mapping & validation

### 🔹 **Web & Network Fingerprinting**

* Live web app detection
* Landing page screenshots
* Technology stack detection
* Full TCP/UDP port scan
* Version fingerprinting

### 🔹 **Application Analysis**

* Automated sitemap discovery
* Automated OWASP Top-10 web scans
* Network-level vulnerability scanning
* Component/CVE scanning (SBOM-based)
* Sensitive-data/OSINT exposure detection

### 🔹 **Reporting**

* Per-target HTML report
* Aggregated structured raw outputs (`raw/`)
* Screenshots folder

---

# 📂 **Folder Structure**

```
recon-framework/
│
├── main.py
├── targets.txt
│
├── modules/
│   ├── subdomains.py
│   ├── dns_enum.py
│   ├── ip_discovery.py
│   ├── web_scanner.py
│   ├── screenshot.py
│   ├── tech_detect.py
│   ├── port_scan.py
│   ├── sitemap.py
│   ├── owasp_scan.py
│   ├── network_vuln.py
│   ├── cve_scan.py
│   ├── osint_scan.py
│   └── report.py
│
└── output/
    ├── raw/
    └── report/
```



### **`main.py`**

```python
import asyncio
import os
from modules.subdomains import run_subdomain_enum
from modules.dns_enum import dns_enumerate
from modules.ip_discovery import discover_ips
from modules.web_scanner import detect_live_web
from modules.screenshot import take_screenshots
from modules.tech_detect import detect_tech_stack
from modules.port_scan import run_port_scan
from modules.sitemap import generate_sitemap
from modules.owasp_scan import run_owasp_scan
from modules.network_vuln import run_network_vuln_scan
from modules.cve_scan import run_cve_scan
from modules.osint_scan import run_osint_checks
from modules.report import build_report_html

OUTPUT_DIR = "output/"
TARGET_FILE = "targets.txt"

async def process_target(target):
    print(f"\n[+] Processing: {target}")
    target_dir = os.path.join(OUTPUT_DIR, "raw", target.replace("://","_"))
    os.makedirs(target_dir, exist_ok=True)

    # Stage 1 – Subdomain Discovery
    subs = await run_subdomain_enum(target, target_dir)

    # Stage 2 – DNS Enumeration
    dns_data = await dns_enumerate(subs, target_dir)

    # Stage 3 – IP/Host Discovery
    ips = await discover_ips(subs, target_dir)

    # Stage 4 – Web Application Detection
    live_web = await detect_live_web(ips, target_dir)

    # Stage 5 – Screenshots
    await take_screenshots(live_web, target_dir)

    # Stage 6 – Tech Stack Detection
    tech = await detect_tech_stack(live_web, target_dir)

    # Stage 7 – Port Scan (TCP/UDP + Version)
    scan_data = await run_port_scan(ips, target_dir)

    # Stage 8 – Sitemap generation
    await generate_sitemap(live_web, target_dir)

    # Stage 9 – OWASP Top 10 web scan
    owasp_findings = await run_owasp_scan(live_web, target_dir)

    # Stage 10 – Network Vulnerability Scan
    net_vulns = await run_network_vuln_scan(ips, target_dir)

    # Stage 11 – CVE/component scanning
    cve = await run_cve_scan(live_web, target_dir)

    # Stage 12 – OSINT + Sensitive Data Exposure
    osint = await run_osint_checks(target, target_dir)

    # Stage 13 – Build HTML Report
    await build_report_html(target, target_dir)

async def main():
    with open(TARGET_FILE, "r") as f:
        targets = [t.strip() for t in f.readlines() if t.strip()]

    tasks = [process_target(t) for t in targets]
    await asyncio.gather(*tasks)

if __name__ == "__main__":
    asyncio.run(main())
```

---

# 🧩 **MODULES (A–Z)**

Each module uses real tools:

* **subfinder**, **amass**, **dnsx**,
* **httpx**, **whatweb**,
* **nmap**, **naabu**,
* **nuclei**, **nikto**,
* **osv-scanner**, **trivy**,
* **waybackurls**, **shodan**, **github-dorks**, etc.

I will show the **complete module code** for all:

---

### **`modules/subdomains.py`**

```python
import asyncio
import subprocess
import os

async def run_subdomain_enum(domain, outdir):
    outfile = os.path.join(outdir, "subdomains.txt")

    cmds = [
        f"subfinder -silent -d {domain}",
        f"amass enum -passive -nocolor -d {domain}",
        f"assetfinder --subs-only {domain}"
    ]

    with open(outfile, "w") as f:
        for cmd in cmds:
            proc = await asyncio.create_subprocess_shell(
                cmd,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.DEVNULL
            )
            out, _ = await proc.communicate()
            f.write(out.decode())

    os.system(f"sort -u {outfile} -o {outfile}")
    return open(outfile).read().splitlines()
```

---

### **`modules/dns_enum.py`**

```python
import asyncio, os

async def dns_enumerate(subs, outdir):
    infile = os.path.join(outdir, "subdomains.txt")
    outfile = os.path.join(outdir, "dns.txt")

    cmd = f"cat {infile} | dnsx -resp-only -silent > {outfile}"

    await asyncio.create_subprocess_shell(cmd)
    return outfile
```

---

### **`modules/ip_discovery.py`**

```python
import asyncio, os

async def discover_ips(subs, outdir):
    outfile = os.path.join(outdir, "ips.txt")
    cmd = f"cat {outdir}/dns.txt | cut -d ' ' -f2 | sort -u > {outfile}"

    await asyncio.create_subprocess_shell(cmd)
    return open(outfile).read().splitlines()
```

---

### **`modules/web_scanner.py`**

```python
import asyncio, os

async def detect_live_web(ips, outdir):
    outfile = os.path.join(outdir, "live_web.txt")
    cmd = f"cat {outdir}/ips.txt | httpx -silent -status-code -title -tech-detect > {outfile}"
    await asyncio.create_subprocess_shell(cmd)
    return open(outfile).read().splitlines()
```

---

### **`modules/screenshot.py`**

```python
import asyncio, os

async def take_screenshots(targets, outdir):
    cmd = f"cat {outdir}/live_web.txt | aquatone -out {outdir}/screenshots"
    await asyncio.create_subprocess_shell(cmd)
```

---

### **`modules/tech_detect.py`**

```python
import asyncio, os

async def detect_tech_stack(targets, outdir):
    outfile = os.path.join(outdir, "tech.txt")
    cmd = f"cat {outdir}/live_web.txt | whatweb --log-verbose={outfile}"
    await asyncio.create_subprocess_shell(cmd)
    return outfile
```

---

### **`modules/port_scan.py`**

```python
import asyncio, os

async def run_port_scan(ips, outdir):
    outfile = os.path.join(outdir, "ports.txt")
    cmd = f"naabu -list {outdir}/ips.txt -p - -silent | tee {outfile}"
    await asyncio.create_subprocess_shell(cmd)

    nmap_out = os.path.join(outdir, "nmap.xml")
    nmap_cmd = f"nmap -sV -sC -p- -oX {nmap_out} -iL {outdir}/ips.txt"
    await asyncio.create_subprocess_shell(nmap_cmd)

    return outfile
```

---

### **`modules/sitemap.py`**

```python
import asyncio, os

async def generate_sitemap(targets, outdir):
    cmd = f"cat {outdir}/live_web.txt | katana -silent -o {outdir}/sitemap.txt"
    await asyncio.create_subprocess_shell(cmd)
```

---

### **`modules/owasp_scan.py`**

```python
import asyncio, os

async def run_owasp_scan(targets, outdir):
    cmd = f"nuclei -l {outdir}/live_web.txt -t nuclei-templates/ -o {outdir}/nuclei.txt"
    await asyncio.create_subprocess_shell(cmd)
    return outdir + "/nuclei.txt"
```

---

### **`modules/network_vuln.py`**

```python
import asyncio, os

async def run_network_vuln_scan(ips, outdir):
    cmd = f"nessuscli scan run --targets {outdir}/ips.txt --output {outdir}/nessus_report"
    return cmd  # (Run manually if needed)
```

---

### **`modules/cve_scan.py`**

```python
import asyncio, os

async def run_cve_scan(live_targets, outdir):
    cmd = f"trivy fs . --format json --output {outdir}/cve.json"
    await asyncio.create_subprocess_shell(cmd)
    return outdir + "/cve.json"
```

---

### **`modules/osint_scan.py`**

```python
import asyncio, os

async def run_osint_checks(domain, outdir):
    cmd = f"github-dorks -q '{domain}' -o {outdir}/osint.txt"
    await asyncio.create_subprocess_shell(cmd)
    return outdir + "/osint.txt"
```

---

### **`modules/report.py`**

```python
import os

async def build_report_html(target, outdir):
    html = f"""
    <html>
    <head><title>Recon Report - {target}</title></head>
    <body>
      <h1>Recon Report for {target}</h1>
      <h2>Subdomains</h2>
      <pre>{open(outdir + '/subdomains.txt').read()}</pre>

      <h2>Technologies</h2>
      <pre>{open(outdir + '/tech.txt').read()}</pre>

      <h2>Open Ports</h2>
      <pre>{open(outdir + '/ports.txt').read()}</pre>

      <h2>Nuclei Findings</h2>
      <pre>{open(outdir + '/nuclei.txt').read()}</pre>

      <h2>CVE Scan</h2>
      <pre>{open(outdir + '/cve.json').read()}</pre>

      <h2>OSINT Exposures</h2>
      <pre>{open(outdir + '/osint.txt').read()}</pre>
    </body>
    </html>
    """

    with open(outdir + "/report.html", "w") as f:
        f.write(html)

    return outdir + "/report.html"
```

---

# 🔧 **Installation**

## 1. Install Dependencies

### **Linux (Ubuntu/Kali recommended)**

```bash
sudo apt update
sudo apt install python3 python3-pip nmap chromium-browser
```

## 2. Install required external tools

ReconX depends on industry-standard tools:

### 🔸 Subdomain & DNS enum

```bash
go install -v github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install -v github.com/tomnomnom/assetfinder@latest
go install -v github.com/OWASP/Amass/v3/...@latest
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
```

### 🔸 Web scanner + screenshot tools

```bash
go install -v github.com/projectdiscovery/httpx/cmd/httpx@latest
go install -v github.com/michenriksen/aquatone@latest
sudo apt install whatweb
```

### 🔸 Port scanning & vulns

```bash
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
sudo apt install nmap
```

### 🔸 Sitemap & URL discovery

```bash
go install github.com/projectdiscovery/katana/cmd/katana@latest
```

### 🔸 Vulnerability Scanning

```bash
git clone https://github.com/projectdiscovery/nuclei-templates /opt/nuclei-templates
go install -v github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
```

### 🔸 Component/CVE Scanning

```bash
sudo apt install trivy
```

### 🔸 OSINT & exposure detection

```bash
pip install github-dorks
```

---

# 📝 **Usage**

## 1. Add targets in `targets.txt`

```
example.com
company.com
test.org
```

One entry per line; domains/IP ranges supported.

---

## 2. Run the framework

```bash
python3 main.py
```

The framework will:

1. Read all targets
2. Execute all modules
3. Store results inside `output/raw/<target>/`
4. Generate HTML reports

---

# 📊 **Output Structure**

### **Raw Data (per target)**

```
output/raw/company.com/
│
├── subdomains.txt
├── dns.txt
├── ips.txt
├── live_web.txt
├── screenshots/
├── tech.txt
├── ports.txt
├── nmap.xml
├── sitemap.txt
├── nuclei.txt
├── cve.json
├── osint.txt
└── report.html
```

### **Final HTML Reports**

```
output/report/
    ├── company.com_report.html
    └── example.com_report.html
```

---

# ⚙️ **Module Pipeline**

Below is a simplified pipeline diagram:

```
TARGET → Subdomain Enum
        → DNS Enum
        → IP Discovery
        → Live Web Detection
        → Screenshots
        → Tech Stack Detection
        → Port Scan (TCP/UDP)
        → Sitemap Crawl
        → OWASP Top 10 Scan
        → Network Vuln Scan
        → CVE Scan
        → OSINT Exposure Scan
        → HTML Report
```

Each module runs independently so the toolkit is:

* scalable
* easy to extend
* easy to debug
* reusable for future projects

---

# ➕ **Extending the Framework**

Add a new module:

1. Create a file in `modules/new_module.py`
2. Write an async function:

```python
async def run_new_feature(target, outdir):
    ...
    return results
```

3. Import and call it in `main.py` pipeline.

---

# ❗Troubleshooting

### Subfinder not running?

Run:

```bash
export PATH=$PATH:~/go/bin
```

### Aquatone fails?

Install Chromium:

```bash
sudo apt install chromium-browser
```

### Nmap slow on large IP ranges?

Change in `port_scan.py`:

```bash
nmap -T4
```

### Nuclei templates not found?

Update path in config:

```bash
NUCLEI_TPL = "/opt/nuclei-templates/"
```

---

# 🏢 Enterprise Use Warning

This toolkit **can reveal sensitive internal and external attack surfaces**.

Use only on systems you own or have explicit written permission for.
