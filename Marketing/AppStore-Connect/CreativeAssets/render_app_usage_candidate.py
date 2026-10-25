#!/usr/bin/env python3
"""Render a localized MaskID walkthrough candidate from current simulator captures.

The source frames are authentic app screenshots. This is a visual walkthrough
montage, not a continuous device screen recording; keep it as a review candidate
until a live in-app recording can be captured.
"""

from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageOps


ROOT = Path(__file__).resolve().parents[3]
RAW = ROOT / ".asc/screenshots/raw_captures"
OUTPUT = ROOT / ".asc/app-previews"
WIDTH, HEIGHT, FPS = 886, 1920, 30
SCENE_SECONDS = 4
TRANSITION_SECONDS = 0.5
SCENES = {
    "en-US": (
        "07-library-dashboard.png",
        "03-smart-scanner.png",
        "08-batch-processing.png",
        "09-mask-styles.png",
        "06-vault-security.png",
    ),
    "es-ES": (
        "07-library-dashboard.png",
        "03-smart-scanner.png",
        "08-batch-processing.png",
        "09-mask-styles.png",
        "06-vault-security.png",
    ),
}


def load_frame(path: Path) -> Image.Image:
    with Image.open(path) as source:
        fitted = ImageOps.fit(source.convert("RGB"), (WIDTH, HEIGHT), method=Image.Resampling.LANCZOS, centering=(0.5, 0.5))
    return fitted


def ease(value: float) -> float:
    value = min(1.0, max(0.0, value))
    return value * value * (3.0 - 2.0 * value)


def render(locale: str, ffmpeg: str) -> Path:
    frames = tuple(load_frame(RAW / locale / filename) for filename in SCENES[locale])
    output = OUTPUT / locale / "MaskID-1.1.6-Usage-Preview-Candidate.mp4"
    output.parent.mkdir(parents=True, exist_ok=True)
    output.unlink(missing_ok=True)

    command = [
        ffmpeg,
        "-hide_banner", "-loglevel", "error",
        "-f", "rawvideo", "-pixel_format", "rgb24",
        "-video_size", f"{WIDTH}x{HEIGHT}", "-framerate", str(FPS), "-i", "-",
        "-an", "-frames:v", str(SCENE_SECONDS * len(frames) * FPS),
        "-c:v", "libx264", "-preset", "medium", "-crf", "17",
        "-pix_fmt", "yuv420p", "-movflags", "+faststart", str(output),
    ]
    process = subprocess.Popen(command, stdin=subprocess.PIPE)
    assert process.stdin is not None
    total_frames = SCENE_SECONDS * len(frames) * FPS
    transition_frames = int(TRANSITION_SECONDS * FPS)

    try:
        for frame_number in range(total_frames):
            scene_index = min(len(frames) - 1, frame_number // (SCENE_SECONDS * FPS))
            within_scene = frame_number % (SCENE_SECONDS * FPS)
            frame = frames[scene_index]
            if scene_index < len(frames) - 1 and within_scene >= SCENE_SECONDS * FPS - transition_frames:
                progress = ease((within_scene - (SCENE_SECONDS * FPS - transition_frames)) / transition_frames)
                frame = Image.blend(frame, frames[scene_index + 1], progress)
            process.stdin.write(frame.tobytes())
    except BrokenPipeError:
        pass
    finally:
        process.stdin.close()

    if process.wait() != 0:
        raise RuntimeError(f"FFmpeg failed to render {output}")
    return output


def main() -> int:
    ffmpeg = shutil.which("ffmpeg")
    if not ffmpeg:
        print("FFmpeg was not found.", file=sys.stderr)
        return 2
    for locale in SCENES:
        print(render(locale, ffmpeg))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
