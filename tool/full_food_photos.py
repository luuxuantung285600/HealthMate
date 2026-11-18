"""Food-photo acquisition and review helpers. No Firebase writes.

Sources are cached, rate limited and never accepted without visual review.
Original images avoid a separate thumbnail-rendering dependency. Respect a
429 Retry-After with bounded backoff; repeated failures stop acquisition.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/full-food-photos'
UA = 'HealthMateCatalog/1.0 (food photo source and attribution review)'


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def get(url):
    for attempt in range(3):
        try:
            with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=60) as r:
                data = r.read(30_000_001)
                if len(data) > 30_000_000:
                    raise ValueError('Source exceeds image acquisition limit.')
                return data
        except urllib.error.HTTPError as error:
            retry = error.headers.get('Retry-After', '')
            if error.code != 429 or not retry.isdigit() or int(retry) > 58 or attempt == 2:
                raise
            delay = max(10, int(retry) + 2)
            print('Source requested backoff', delay, 'seconds', flush=True)
            time.sleep(delay)


def free_license(row):
    license = row.get('imageinfo', [{}])[0].get('extmetadata', {}).get('LicenseShortName', {}).get('value', '')
    return license in ['CC0', 'Public domain'] or bool(re.fullmatch(r'CC BY(?:-SA)? [1-4]\.\d(?: [a-z]{2})?', license))


def metadata():
    rows = {}
    for file in (ROOT / 'build/catalog-500-research').rglob('*.json'):
        if not ('license' in file.name or file.name == 'candidates.json'):
            continue
        payload = read(file)
        entries = payload if isinstance(payload, list) else payload.get('query', {}).get('pages', {}).values()
        for row in entries:
            if isinstance(row, dict) and row.get('imageinfo') and row.get('pageid'):
                rows[str(row['pageid'])] = row
    for file in (OUT / 'search').glob('*.json'):
        for row in read(file).get('query', {}).get('pages', {}).values():
            if row.get('imageinfo'):
                rows[str(row['pageid'])] = row
    save(OUT / 'metadata.json', rows)
    return rows


def search(file):
    queries = read(file)
    for key, query in queries.items():
        dest = OUT / 'search' / (key + '.json')
        if dest.exists():
            continue
        params = dict(action='query', format='json', generator='search',
                      gsrsearch='filetype:bitmap ' + query, gsrnamespace=6, gsrlimit=4,
                      prop='imageinfo', iiprop='url|size|extmetadata|mime', maxlag=5)
        try:
            raw = get('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params))
            payload = json.loads(raw)
            if payload.get('error'):
                raise ValueError(payload['error'].get('code'))
            save(dest, payload)
        except urllib.error.HTTPError as error:
            print('Source stopped', key, error.code, 'Retry-After', error.headers.get('Retry-After'), flush=True)
            break
        print('Searched', key, flush=True)
        time.sleep(2)
    metadata()


def download(ids, preview_width=None):
    rows = metadata()
    if preview_width:
        # A reduced source image is sufficient for 512 px catalog artwork.
        # Obtain the canonical preview URL from MediaWiki; do not construct it.
        for start in range(0, len(ids), 40):
            params = dict(action='query', format='json', pageids='|'.join(str(n) for n in ids[start:start+40]),
                          prop='imageinfo', iiprop='url|size|extmetadata|mime', iiurlwidth=preview_width, maxlag=5)
            payload = json.loads(get('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params)))
            for row in payload.get('query', {}).get('pages', {}).values():
                rows[str(row['pageid'])] = row
            time.sleep(2)
        save(OUT / 'preview-metadata.json', rows)
    downloaded = []
    for pid in ids:
        row = rows[str(pid)]
        info = row['imageinfo'][0]
        if not free_license(row) or info.get('mime') not in ['image/jpeg', 'image/png', 'image/webp']:
            continue
        path = OUT / 'candidates' / (str(pid) + '.jpg')
        if not path.exists():
            # Reuse an original already obtained for crop review.
            original = ROOT / 'build/catalog-500-research/originals' / (str(pid) + '.jpg')
            if original.exists():
                raw = original.read_bytes()
            else:
                try:
                    # Use the canonical original URL, without analytics query
                    # parameters, so repeat downloads reuse the source cache.
                    source_url = info.get('thumburl') if preview_width else info['url'].split('?')[0]
                    raw = get(source_url or info['url'].split('?')[0])
                except urllib.error.HTTPError as error:
                    print('Source stopped', pid, error.code, 'Retry-After', error.headers.get('Retry-After'), flush=True)
                    break
                time.sleep(20)
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(raw)
        try:
            Image.open(path).load()
            downloaded.append(pid)
            print('Cached', pid, row['title'], flush=True)
        except Exception as error:
            print('Invalid image', pid, type(error).__name__, flush=True)
    return downloaded


def sheets(ids, prefix):
    rows = metadata()
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/public_sans/PublicSans-Regular.ttf'), 13)
    valid = [pid for pid in ids if (OUT / 'candidates' / (str(pid) + '.jpg')).exists()]
    for offset in range(0, len(valid), 35):
        part = valid[offset:offset + 35]
        canvas = Image.new('RGB', (1400, 260 * ((len(part) + 6) // 7)), '#f2f4f5')
        draw = ImageDraw.Draw(canvas)
        for j, pid in enumerate(part):
            pic = ImageOps.contain(ImageOps.exif_transpose(Image.open(OUT / 'candidates' / (str(pid) + '.jpg'))).convert('RGB'), (194, 190))
            x, y = j % 7 * 200 + 3, j // 7 * 260
            canvas.paste(pic, (x, y))
            title = rows[str(pid)]['title'][5:]
            lines = [str(pid), title[:27], title[27:54]]
            draw.multiline_text((x, y + 194), '\n'.join(lines), fill='black', font=font)
        dest = OUT / f'{prefix}-{offset // 35 + 1}.jpg'
        canvas.save(dest, quality=93)
        print(dest.relative_to(ROOT), flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['metadata', 'search', 'download', 'sheets'])
    parser.add_argument('input', nargs='?')
    parser.add_argument('--prefix', default='contact')
    parser.add_argument('--preview-width', type=int, choices=[960, 1280])
    args = parser.parse_args()
    OUT.mkdir(parents=True, exist_ok=True)
    if args.mode == 'metadata':
        print('Metadata', len(metadata()))
    elif args.mode == 'search':
        search(Path(args.input))
    else:
        ids = read(Path(args.input))
        if args.mode == 'download':
            ids = download(ids, args.preview_width)
        sheets(ids, args.prefix)


if __name__ == '__main__':
    main()
