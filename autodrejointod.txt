#!/data/data/com.termux/files/usr/bin/env python3
"""
Multi Rejoin + Launcher Tool (MT Manager Clones)
Auto detect package, Launch, Monitoring, Force Close Recovery
"""

import subprocess
import time
import json
import os
import re
from datetime import datetime
from rich.console import Console
from rich.table import Table
from rich.panel import Panel
from rich.prompt import Prompt, Confirm, IntPrompt

console = Console()

CONFIG_FILE = os.path.expanduser("\~/.rejoin_multi_config.json")

def run_su(cmd, timeout=12):
    try:
        result = subprocess.run(["su", "-c", cmd], capture_output=True, text=True, timeout=timeout)
        return result.stdout.strip()
    except Exception as e:
        return f"ERROR: {e}"

def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE) as f:
            return json.load(f)
    return {"managed_packages": [], "interval": 35, "reconnect_y_percent": 0.68}

def save_config(cfg):
    with open(CONFIG_FILE, "w") as f:
        json.dump(cfg, f, indent=2)

def auto_detect_roblox_packages():
    output = run_su("pm list packages | grep -i roblox")
    packages = []
    for line in output.splitlines():
        if "package:" in line:
            pkg = line.replace("package:", "").strip()
            packages.append(pkg)
    return packages

def get_main_activity(package):
    return f"{package}/.Activity"

def launch_package(package):
    activity = get_main_activity(package)
    cmd = f"am start -n {activity} -f 0x10000000"
    result = run_su(cmd)
    return "Error" not in result

def scan_windows_for_packages(packages):
    output = run_su("dumpsys window windows")
    found = []
    for pkg in packages:
        pattern = rf'package={re.escape(pkg)}.*?mBounds=\[(\d+),(\d+)\]\[(\d+),(\d+)\]'
        match = re.search(pattern, output, re.DOTALL)
        if match:
            left, top, right, bottom = map(int, match.groups())
            width = right - left
            height = bottom - top
            tap_x = left + int(width * 0.50)
            tap_y = top + int(height * 0.68)
            found.append({
                "package": pkg,
                "name": pkg.split(".")[-1],
                "x": tap_x,
                "y": tap_y,
                "width": width,
                "height": height
            })
    return found

def main():
    cfg = load_config()

    while True:
        console.clear()
        console.print(Panel.fit(
            "[bold cyan]MULTI REJOIN + LAUNCHER[/bold cyan]\n"
            "[white]MT Manager Clone • Freeform • Force Close Recovery[/white]"
        ))

        console.print("\n[bold]Menu:[/bold]")
        console.print("1. [cyan]Auto Detect Semua Roblox Clone[/cyan] (MT Manager)")
        console.print("2. [green]Launch Semua Clone[/green] (Buka ke Freeform)")
        console.print("3. [yellow]Mulai Monitoring + Rejoin + Recovery[/yellow]")
        console.print("4. [magenta]Lihat Managed Packages[/magenta]")
        console.print("5. [blue]Pengaturan Interval[/blue]")
        console.print("6. [red]Exit[/red]")

        choice = Prompt.ask("Pilih menu", choices=["1","2","3","4","5","6"], default="1")

        if choice == "1":
            console.print("\n[yellow]Mencari semua package Roblox...[/yellow]")
            pkgs = auto_detect_roblox_packages()
            if not pkgs:
                console.print("[red]Tidak ada package Roblox ditemukan.[/red]")
                continue
            console.print(f"[green]Ditemukan {len(pkgs)} package:[/green]")
            for p in pkgs:
                console.print(f"  - {p}")
            if Confirm.ask("Gunakan semua package ini?"):
                cfg["managed_packages"] = pkgs
                save_config(cfg)
                console.print("[green]Berhasil disimpan![/green]")

        elif choice == "2":
            if not cfg.get("managed_packages"):
                console.print("[red]Belum ada package. Lakukan Auto Detect dulu.[/red]")
                continue
            console.print("\n[yellow]Mencoba launch semua clone...[/yellow]")
            for pkg in cfg["managed_packages"]:
                success = launch_package(pkg)
                status = "[green]Berhasil[/green]" if success else "[red]Gagal[/red]"
                console.print(f"  {pkg} → {status}")
                time.sleep(1.5)
            console.print("\n[bold yellow]Catatan:[/bold yellow] Susun window ke freeform secara manual sekali saja.")

        elif choice == "3":
            if not cfg.get("managed_packages"):
                console.print("[red]Belum ada package![/red]")
                continue
            console.print(f"\n[green]Monitoring {len(cfg['managed_packages'])} clone...[/green]")
            console.print("Tekan Ctrl+C untuk stop\n")
            try:
                while True:
                    current = scan_windows_for_packages(cfg["managed_packages"])
                    missing = [p for p in cfg["managed_packages"] if p not in [w["package"] for w in current]]
                    if missing:
                        console.print(f"[red]Force close terdeteksi: {missing}[/red]")
                        for pkg in missing:
                            console.print(f"  Mencoba relaunch {pkg}...")
                            launch_package(pkg)
                            time.sleep(5)
                    for win in current:
                        run_su(f"input tap {win['x']} {win['y']}")
                        console.print(f"[{datetime.now().strftime('%H:%M:%S')}] Tap {win['name']}")
                        time.sleep(1.2)
                    time.sleep(cfg["interval"])
            except KeyboardInterrupt:
                console.print("\n[yellow]Monitoring dihentikan.[/yellow]")

        elif choice == "4":
            console.print("\n[bold]Managed Packages:[/bold]")
            for p in cfg.get("managed_packages", []):
                console.print(f"  - {p}")

        elif choice == "5":
            cfg["interval"] = IntPrompt.ask("Interval antar cycle (detik)", default=cfg["interval"])
            save_config(cfg)
            console.print("[green]Disimpan.[/green]")

        elif choice == "6":
            break

if __name__ == "__main__":
    main()
