#!/usr/bin/env python3
"""
Render Manim scene to GIF/MP4
Usage: python render-manim.py input.py SceneName [asset-name] [format] [quality]
"""

import subprocess
import sys
import os
import shutil
from datetime import datetime
from pathlib import Path

def render_manim(input_file, scene_name, asset_name=None, output_format='gif', quality='h'):
    """
    Render a Manim scene to the output directory.

    Args:
        input_file: Path to the Python file containing the scene
        scene_name: Name of the Scene class to render
        asset_name: Optional custom name for output files
        output_format: Output format (gif, mp4, webm, png)
        quality: Quality preset (l=480p, m=720p, h=1080p, k=4K)
    """
    name = asset_name or scene_name.lower()
    timestamp = datetime.now().strftime('%Y%m%d-%H%M%S')
    output_base = Path.home() / 'Library/Mobile Documents/iCloud~md~obsidian/Documents/my_vault/Resources'
    output_dir = output_base / f'{name}-{timestamp}'

    output_dir.mkdir(parents=True, exist_ok=True)

    # Copy source file
    shutil.copy(input_file, output_dir / 'source.py')

    # Build manim command
    cmd = [
        'manim',
        f'-q{quality}',
        f'--format={output_format}',
        f'--media_dir={output_dir}',
        '-o', name,
        input_file,
        scene_name
    ]

    print(f"Rendering {scene_name}...")
    print(f"Command: {' '.join(cmd)}")

    try:
        result = subprocess.run(cmd, check=True, capture_output=True, text=True)
        print(result.stdout)

        # Move output from nested manim structure to output_dir root
        media_dir = output_dir / 'videos' / Path(input_file).stem / f'{quality}0p60'
        if media_dir.exists():
            for f in media_dir.iterdir():
                shutil.move(str(f), str(output_dir / f.name))
            # Clean up nested directories
            shutil.rmtree(output_dir / 'videos', ignore_errors=True)

        print(f"\nExported to: {output_dir}")
        print("Files:")
        for f in output_dir.iterdir():
            print(f"  {f.name}")

    except subprocess.CalledProcessError as e:
        print(f"Error rendering: {e}")
        print(e.stderr)
        sys.exit(1)

def main():
    if len(sys.argv) < 3:
        print("Usage: python render-manim.py input.py SceneName [asset-name] [format] [quality]")
        print("")
        print("Arguments:")
        print("  input.py    - Python file containing the Manim scene")
        print("  SceneName   - Name of the Scene class to render")
        print("  asset-name  - (optional) Custom name for output files")
        print("  format      - (optional) Output format: gif, mp4, webm, png (default: gif)")
        print("  quality     - (optional) Quality: l=480p, m=720p, h=1080p, k=4K (default: h)")
        sys.exit(1)

    input_file = sys.argv[1]
    scene_name = sys.argv[2]
    asset_name = sys.argv[3] if len(sys.argv) > 3 else None
    output_format = sys.argv[4] if len(sys.argv) > 4 else 'gif'
    quality = sys.argv[5] if len(sys.argv) > 5 else 'h'

    render_manim(input_file, scene_name, asset_name, output_format, quality)

if __name__ == '__main__':
    main()
