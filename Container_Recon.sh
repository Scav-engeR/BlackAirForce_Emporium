#!/usr/bin/env bash
# container_recon.sh
# A safe, non-destructive container reconnaissance script for advanced users.
# Purpose: gather capability, namespace, cgroup, mount, device, network and quick secrets hints.
# Usage: ./container_recon.sh [-o /path/to/output] [-d] [-v]
#  -o OUTPUT   : write report to OUTPUT (default: /tmp/container_recon_<ts>.txt)
#  -d          : deep scan mode (may take longer and search deeper for writable dirs and secrets)
#  -v          : verbose (prints progress markers to stderr)
#  -h          : help

set -u

VERBOSE=0
DEEP=0
OUT=""

timestamp() { date +%s; }
log() { if [ "$VERBOSE" -eq 1 ]; then echo "[+] $*" >&2; fi }

usage(){ cat <<USAGE
Usage: $0 [-o output] [-d] [-v] [-h]
  -o OUTPUT : Set output path (default /tmp/container_recon_<ts>.txt)
  -d        : Deep scan (deeper find/grep - may be slow)
  -v        : Verbose
  -h        : Show this help
USAGE
}

while getopts ":o:vdh" opt; do
  case $opt in
    o) OUT="$OPTARG" ;;
    v) VERBOSE=1 ;;
    d) DEEP=1 ;;
    h) usage; exit 0 ;;
    \?) echo "Invalid option: -$OPTARG" >&2; usage; exit 2 ;;
    :) echo "Option -$OPTARG requires an argument." >&2; usage; exit 2 ;;
  esac
done

if [ -z "$OUT" ]; then
  OUT="/tmp/container_recon_$(timestamp).txt"
fi

# Redirect all output to OUT while also printing to stdout
exec 3>&1
exec 1> >(tee "$OUT")

echo "=== CONTAINER RECON REPORT ==="
echo "Generated: $(date -u)"

# Helper: safe command executor
run_safe(){
  # run command, ignore error but return 0
  if [ "$VERBOSE" -eq 1 ]; then
    echo "\n--- $* ---" >&2
  fi
  ( eval "$*" ) 2>/dev/null || true
}

# 1. Host & Kernel
echo "\n=== HOST & KERNEL ==="
run_safe "uname -a"
run_safe "cat /etc/os-release"
run_safe "cat /proc/version"
run_safe "hostname"

# 2. UIDs & groups
echo "\n=== UIDs & GROUPS ==="
run_safe "id"
run_safe "groups || true"

# 3. Capabilities
echo "\n=== CAPABILITIES ==="
if command -v capsh >/dev/null 2>&1; then
  run_safe "capsh --print"
else
  run_safe "awk '/CapEff/ {print \"CapEff: \" $2}' /proc/self/status"
fi

# 4. Namespaces
echo "\n=== NAMESPACES ==="
run_safe "ls -l /proc/self/ns"
run_safe "echo \"readlink /proc/1/ns/*:\" && readlink /proc/1/ns/*"
run_safe "echo \"readlink /proc/\$\$/ns/*:\" && readlink /proc/$$/ns/*"

# 5. Cgroups / limits
echo "\n=== CGROUPS / LIMITS ==="
run_safe "cat /proc/self/cgroup"
if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
  run_safe "echo 'cgroup v2 controllers:' && cat /sys/fs/cgroup/cgroup.controllers"
fi
run_safe "ulimit -a"

# cgroup v1 probes (if present)
run_safe "grep -H . /sys/fs/cgroup/*/* 2>/dev/null | head -n 40"

# 6. Mounts & filesystem
echo "\n=== MOUNTS & FILESYSTEM ==="
run_safe "cat /proc/mounts | sed -n '1,200p'"
run_safe "df -h . || true"

# Writable dirs (shallow vs deep)
if [ "$DEEP" -eq 1 ]; then
  echo "\nRunning deep writable-dir scan (this can be slow)..."
  run_safe "find / -xdev -type d -writable 2>/dev/null | sed -n '1,200p'"
else
  echo "\nTop writable dirs (fast scan):"
  if command -v find >/dev/null 2>&1; then
    run_safe "find / -xdev -type d -writable 2>/dev/null | head -n 50"
  else
    echo "find not available"
  fi
fi

# 7. /dev
echo "\n=== /dev (devices) ==="
run_safe "ls -l /dev | sed -n '1,200p'"

# 8. Docker / container indicators
echo "\n=== DOCKER / CONTAINER INDICATORS ==="
[ -e /.dockerenv ] && echo "/.dockerenv present" || true
run_safe "grep -i docker /proc/1/cgroup"
run_safe "ps -eo pid,comm,args | egrep 'runc|containerd|dockerd|crio' 2>/dev/null | head -n 30"

# 9. Seccomp & LSM
echo "\n=== SECCOMP & LSM ==="
if [ -r /proc/self/status ]; then
  awk '/Seccomp/ {print "Seccomp: " $2}' /proc/self/status 2>/dev/null || true
fi
run_safe "cat /sys/module/apparmor/parameters/enabled 2>/dev/null || true"
run_safe "cat /sys/module/selinux/parameters/enabled 2>/dev/null || true"

# 10. Network
echo "\n=== NETWORK ==="
if command -v ip >/dev/null 2>&1; then
  run_safe "ip a"
  run_safe "ip route"
else
  run_safe "ifconfig -a"
fi
run_safe "cat /etc/resolv.conf 2>/dev/null || true"

# 11. Processes & CapEff per process (quick)
echo "\n=== PROCESSES & CAPEFF (top 50) ==="
if command -v ps >/dev/null 2>&1; then
  run_safe "ps -eo pid,uid,user,cmd --sort=-uid | head -n 50"
fi
if command -v getpcaps >/dev/null 2>&1; then
  run_safe "getpcaps 1 || true"
  run_safe "getpcaps $$ || true"
fi

# 12. Quick secrets scan (shallow or deep)
echo "\n=== INTERESTING FILES (quick scan of common paths) ==="
SCAN_PATHS=(/root /home /etc /opt /var /run /tmp /usr/local)
GREP_CMD="grep -I -R --line-number -E 'token|secret|password|passwd|AWS|AKIA|gcp|credential|key|passphrase'"
if [ "$DEEP" -eq 1 ]; then
  for d in "${SCAN_PATHS[@]}"; do
    echo "-- scanning $d (deep) --"
    run_safe "$GREP_CMD '$d' 2>/dev/null | sed -n '1,500p' || true"
  done
else
  for d in "${SCAN_PATHS[@]}"; do
    echo "-- scanning $d (shallow) --"
    run_safe "$GREP_CMD '$d' -maxdepth 3 2>/dev/null | sed -n '1,200p' || true"
  done
fi

# 13. Suggested next actions
echo "\n=== SUGGESTED NEXT ACTIONS ==="
echo "- Compare readlink outputs for /proc/1/ns vs /proc/$$/ns to detect host namespace sharing"
echo "- Inspect writable mounts and unix sockets under /var/run or /run for host mounts"
echo "- If CAP_SYS_ADMIN or CAP_SYS_MODULE present, treat as high privilege"
echo "- Use caution before running exec or mounting host paths"

# Final message
echo "\nReport saved to: $OUT"

echo "\nDone."
