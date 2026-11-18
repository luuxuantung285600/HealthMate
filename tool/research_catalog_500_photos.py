"""Fetch bounded, licensed Commons candidates; selections need visual review."""
import concurrent.futures
import csv
import json
from pathlib import Path
import re
import time
import threading
import urllib.parse
import urllib.request
import urllib.error
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/catalog-500-research/expanded-photos'
STOP = threading.Event()


def fetch(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={
            'User-Agent': 'HealthMateCatalog/1.0 (licensed image review)'}), timeout=40) as response:
        return response.read()


def research(entry):
    if STOP.is_set():
        return []
    fid, query = entry
    cache = OUT / (fid + '.json')
    try:
        if not cache.exists():
            args = dict(action='query', format='json', generator='search',
                        gsrsearch='filetype:bitmap intitle:"' + query + '" -intitle:"(IA"',
                        gsrnamespace=6, gsrlimit=2, prop='imageinfo',
                        iiprop='url|size|extmetadata|mime', iiurlwidth=900, maxlag=5)
            cache.write_bytes(fetch('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(args)))
            time.sleep(.5)
        candidates = []
        for row in json.loads(cache.read_text(encoding='utf-8')).get('query', {}).get('pages', {}).values():
            info = row.get('imageinfo', [{}])[0]
            license = info.get('extmetadata', {}).get('LicenseShortName', {}).get('value', '')
            if (info.get('mime') not in ['image/jpeg', 'image/png', 'image/webp'] or
                    min(info.get('width', 0), info.get('height', 0)) < 512 or
                    not (license in ['CC0', 'Public domain'] or license.startswith('CC BY'))):
                continue
            path = OUT / (str(row['pageid']) + '.jpg')
            try:
                if not path.exists():
                    path.write_bytes(fetch(info.get('thumburl') or info['url']))
                    time.sleep(.7)
                Image.open(path).load()
                candidates.append(dict(foodId=fid, **row))
            except Exception as error:
                print('Withheld image', fid, type(error).__name__, flush=True)
        print(fid, len(candidates), flush=True)
        return candidates
    except urllib.error.HTTPError as error:
        if error.code in [429, 503]:
            STOP.set()
            print('Acquisition stopped; source limit/unavailability. Resume later.', flush=True)
        return []
    except Exception as error:
        print('Withheld search', fid, str(error), flush=True)
        return []


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    with (ROOT / 'data/food_catalog/catalog-500-selection.tsv').open(encoding='utf-8') as file:
        queries = [('vn2007-' + r['code'], r['photoQuery']) for r in csv.DictReader(file, delimiter='\t')]
    queries += [
        ('vn2007-5011', 'Watermelon'), ('vn2007-5017', 'Papaya'),
        ('vn2007-5018', 'Syzygium samarangense fruit'), ('vn2007-5025', 'Soursop'),
        ('vn2007-5042', 'Avocado'), ('vn2007-5032', 'Dried apricots'),
        ('vn2007-5036', 'Dried longan'), ('vn2007-5041', 'Avocado'),
        ('vn2007-5045', 'Canistel'), ('vn2007-5050', 'Jujube fruit'),
        ('vn2007-14005', 'Orange juice'), ('vn2007-14008', 'Glass of water'),
        ('vn-banh-chung', 'Bánh chưng'), ('vn-mi-quang', 'Mì Quảng'),
        ('vn2007-7073', 'Nem chua'), ('vn2007-1012', 'Baguette'),
        ('vn2007-1005', 'Brown rice'), ('vn2007-3004', 'Black beans'),
        ('vn2007-3010', 'Mung beans'),
    ]
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        rows = [row for result in pool.map(research, queries) for row in result]
    (OUT / 'candidates.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/public_sans/PublicSans-Regular.ttf'), 13)
    for offset in range(0, len(rows), 35):
        part = rows[offset:offset + 35]
        sheet = Image.new('RGB', (1400, 270 * ((len(part) + 6) // 7)), '#f2f4f5')
        draw = ImageDraw.Draw(sheet)
        for index, row in enumerate(part):
            pic = ImageOps.contain(Image.open(OUT / (str(row['pageid']) + '.jpg')).convert('RGB'), (194, 195))
            x, y = index % 7 * 200 + 3, index // 7 * 270
            sheet.paste(pic, (x, y))
            draw.multiline_text((x, y + 198), str(row['pageid']) + '\n' + row['foodId'] + '\n' + row['title'][5:30], font=font, fill='black')
        sheet.save(OUT / f'contact-{offset // 35 + 1}.jpg', quality=93)
    print('Candidates', len(rows), flush=True)


if __name__ == '__main__':
    main()
