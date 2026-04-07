#!/usr/bin/env python3
"""
Cleanup script for SmartStudent Backend.
Removes logs, byte-compiled files, and test caches.
"""

import os
import shutil
from pathlib import Path

def cleanup():
    backend_dir = Path(__file__).resolve().parent.parent
    root_dir = backend_dir.parent

    # Patterns to remove (relative to backend or root)
    to_remove = [
        backend_dir / "__pycache__",
        backend_dir / ".pytest_cache",
        backend_dir / "logs",
        backend_dir / "venv",
        backend_dir / ".venv312",
        root_dir / ".DS_Store",
    ]

    # Recursive directory patterns (names Only)
    recursive_dirs = ["__pycache__", ".venv312", "venv"]

    print(f"🧹 Starting cleanup in {root_dir}")

    # Remove specific paths
    for path in to_remove:
        if path.exists():
            if path.is_dir():
                shutil.rmtree(path)
                print(f"🗑️  Removed directory: {path.relative_to(root_dir)}")
            else:
                os.remove(path)
                print(f"🗑️  Removed file: {path.relative_to(root_dir)}")

    # Recursive cleanup
    for root, dirs, files in os.walk(root_dir):
        for d in dirs:
            if d in recursive_dirs:
                full_path = Path(root) / d
                shutil.rmtree(full_path)
                print(f"🗑️  Removed recursive dir: {full_path.relative_to(root_dir)}")

    print("✅ Cleanup complete.")

if __name__ == "__main__":
    cleanup()
