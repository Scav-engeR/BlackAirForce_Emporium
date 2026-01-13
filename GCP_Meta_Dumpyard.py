#!/usr/bin/env python3
import urllib.request
import urllib.error
import socket

BASE_URL = "http://metadata.google.internal/computeMetadata/v1"
HEADER = {"Metadata-Flavor": "Google"}
OUTPUT = "gcp_metadata_dump.txt"

# ---- HTTP Helper -----------------------------------------------------------

def http_get(path):
    """Perform an HTTP GET with proper headers, timeouts, and error handling."""
    url = BASE_URL + path
    req = urllib.request.Request(url, headers=HEADER)

    try:
        with urllib.request.urlopen(req, timeout=3) as resp:
            return resp.read().decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return f"[HTTPError {e.code}]"
    except urllib.error.URLError as e:
        return f"[URLError {e.reason}]"
    except socket.timeout:
        return "[Timeout]"
    except Exception as e:
        return f"[Error {e}]"

# ---- Recursive Walker ------------------------------------------------------

visited = set()

def fetch_metadata(path, output_file):
    """
    Recursively walk all metadata endpoints.
    Directories end with '/', files do not.
    """
    if path in visited:
        return
    visited.add(path)

    listing = http_get(path)

    # If listing contains an HTTP error, treat as file.
    if listing.startswith("["):
        output_file.write(f"[FILE] {path} = {listing}\n")
        output_file.flush()
        return

    # Split into entries: metadata always returns newline-separated list
    entries = [e.strip() for e in listing.splitlines() if e.strip()]

    for entry in entries:
        full_path = f"{path}/{entry}".replace("//", "/")

        # Directory (metadata directories end with '/')
        if entry.endswith("/"):
            output_file.write(f"[DIR] {full_path}\n")
            output_file.flush()
            fetch_metadata(full_path, output_file)
        else:
            # File
            value = http_get(full_path)
            output_file.write(f"[FILE] {full_path} = {value}\n")
            output_file.flush()

# ---- Main ------------------------------------------------------------------

def main():
    with open(OUTPUT, "w", encoding="utf-8") as out:
        out.write("=== GCP Metadata Dump ===\n")
        fetch_metadata("", out)

if __name__ == "__main__":
    main()
