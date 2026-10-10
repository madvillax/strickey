#!/usr/bin/env python3
"""Import pinned, MIT-licensed Mechvibes recordings. Python + afconvert, or ffmpeg."""
import array
import base64
import hashlib
import json
import shutil
import subprocess
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
REVISION = '326252a13e7bef4f1c35d08ef0189b5af6f8ba02'
API = 'https://api.github.com/repos/hainguyents13/mechvibes'
CACHE = ROOT / '.build' / 'cherry-mx-source'
DEST = ROOT / 'Sources' / 'StrickeyCore' / 'Resources' / 'CherryMX'
SOUNDS = {'red': '7c5e8ee440211bf303e33691120015fe22ec7a1f',
          'brown': 'bba9c3b04e2c8d3214d52ac088dd3ce4407167ef',
          'blue': '440f14283131c0bc95a2f2d9de639f61b81e53df'}
KEYS = [('regular-0', '30'), ('regular-1', '31'), ('regular-2', '32'),
        ('regular-3', '33'), ('space', '57'), ('enter', '28'), ('delete', '14')]


def download_json(url, name):
    path = CACHE / name
    if not path.exists():
        subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                        '--connect-timeout', '10', '--max-time', '90', '--retry', '2',
                        url, '--output', str(path)], check=True)
    return json.loads(path.read_text())


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    DEST.mkdir(parents=True, exist_ok=True)
    license_data = download_json(f'{API}/contents/LICENSE?ref={REVISION}', 'license.json')
    (DEST / 'LICENSE-Mechvibes.txt').write_bytes(base64.b64decode(license_data['content']))
    manifest = {'source': 'https://github.com/hainguyents13/mechvibes', 'revision': REVISION,
                'license': 'MIT', 'sample_rate': 44100, 'clips': []}
    for color, blob in SOUNDS.items():
        print(f'Importing Cherry MX {color.title()}…', flush=True)
        config_data = download_json(f'{API}/contents/src/audio/cherrymx-{color}-pbt/config.json?ref={REVISION}', f'{color}-config.json')
        config = json.loads(base64.b64decode(config_data['content']))
        audio_data = download_json(f'{API}/git/blobs/{blob}', f'{color}-audio.json')
        audio = base64.b64decode(audio_data['content'])
        actual = hashlib.sha1(f'blob {len(audio)}\0'.encode() + audio).hexdigest()
        if actual != blob:
            sys.exit(f'Source hash mismatch for {color}')
        ogg = CACHE / f'{color}.ogg'
        ogg.write_bytes(audio)
        decoded = CACHE / f'{color}-decoded.wav'
        native = subprocess.run(['afconvert', '-f', 'WAVE', '-d', 'LEI16@44100', '-c', '1',
                                 str(ogg), str(decoded)], capture_output=True)
        if native.returncode == 0:
            with wave.open(str(decoded), 'rb') as recording:
                pcm = recording.readframes(recording.getnframes())
        elif shutil.which('ffmpeg'):
            pcm = subprocess.check_output(['ffmpeg', '-v', 'error', '-i', str(ogg),
                                           '-f', 's16le', '-ac', '1', '-ar', '44100', '-'])
        else:
            sys.exit('Native Ogg decoding unavailable. Install ffmpeg to import recordings.')
        values = array.array('h', pcm)
        if sys.byteorder != 'little':
            values.byteswap()
        for name, scan_code in KEYS:
            start_ms, duration_ms = config['defines'][scan_code]
            start = round(start_ms * 44.1)
            count = round(duration_ms * 44.1)
            clip = values[start:start + count]
            if len(clip) != count or not clip:
                sys.exit(f'Invalid source slice: {color}/{name}')
            # Linear peak normalization preserves the recorded tone; no synthesis/saturation.
            gain = 0.90 * 32767 / max(abs(v) for v in clip)
            fade = min(44, len(clip) // 2)
            normalized = array.array('h')
            for i, value in enumerate(clip):
                envelope = min(1, i / fade, (len(clip) - 1 - i) / fade)
                normalized.append(round(value * gain * envelope))
            if sys.byteorder != 'little':
                normalized.byteswap()
            filename = f'{color}-{name}.wav'
            with wave.open(str(DEST / filename), 'wb') as output:
                output.setnchannels(1)
                output.setsampwidth(2)
                output.setframerate(44100)
                output.writeframes(normalized.tobytes())
            manifest['clips'].append({'file': filename, 'pack': config['name'],
                                      'source_scan_code': scan_code, 'start_ms': start_ms,
                                      'duration_ms': duration_ms, 'source_blob': blob,
                                      'sha256': hashlib.sha256((DEST / filename).read_bytes()).hexdigest()})
    (DEST / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n')
    print('Imported 21 recorded keystrokes with source hashes and attribution.', flush=True)


if __name__ == '__main__':
    main()
