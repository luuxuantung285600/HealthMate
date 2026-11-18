"""Batch article illustrations, then exact Commons licenses; local candidates.

Article pictures are not accepted automatically: plants, wrong states, diagrams,
clutter and non-free images must be rejected during contact-sheet review.
"""
import concurrent.futures
import argparse
import json
from pathlib import Path
import re
import time
import urllib.parse
import urllib.request
import urllib.error
import threading
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/catalog-500-research/wiki-photos'
TITLES = {
    'vn2007-1015': 'Popcorn', 'vn2007-1019': 'Cornmeal', 'vn2007-1021': 'Cốm',
    'vn2007-2011': 'Taro', 'vn2007-3003': 'Navy bean', 'vn2007-3005': 'Cowpea',
    'vn2007-3011': 'Chestnut', 'vn2007-3027': 'Tahu goreng', 'vn2007-3028': 'Pumpkin seed',
    'vn2007-4011': 'Red cabbage', 'vn2007-4014': 'Watercress', 'vn2007-4019': 'Cooking banana',
    'vn2007-4032': 'Winged bean', 'vn2007-4034': 'Gac', 'vn2007-4035': 'Soybean sprout',
    'vn2007-4037': 'Scallion', 'vn2007-4041': 'Lotus seed', 'vn2007-4051': 'Bamboo shoot',
    'vn2007-4058': 'Baby corn', 'vn2007-4061': 'Chili pepper', 'vn2007-4062': 'Bell pepper',
    'vn2007-4067': 'Nori', 'vn2007-4068': 'Wakame', 'vn2007-4075': 'Thai basil',
    'vn2007-4081': 'Coriander', 'vn2007-4082': 'Parsley', 'vn2007-7011': 'Goat meat',
    'vn2007-7023': 'Buffalo meat', 'vn2007-7066': 'Ham', 'vn2007-7070': 'Head cheese',
    'vn2007-7074': 'Meat floss', 'vn2007-8055': 'Prawn cracker',
    'vn2007-12020': 'Brittle (food)', 'vn2007-12024': 'Sesame seed candy',
    'vn2007-12026': 'Honey', 'vn2007-13003': 'Ginger',
    'vn2007-5011': 'Watermelon', 'vn2007-5017': 'Papaya',
    'vn2007-5018': 'Syzygium samarangense', 'vn2007-5025': 'Soursop',
    'vn2007-5042': 'Avocado', 'vn2007-5032': 'Dried apricot',
    'vn2007-5036': 'Longan', 'vn2007-5045': 'Canistel', 'vn2007-5050': 'Jujube',
    'vn2007-14005': 'Orange juice', 'vn2007-14006': 'Pineapple juice',
    'vn2007-14007': 'Tomato juice', 'vn-banh-chung': 'Bánh chưng',
    'vn-mi-quang': 'Mì Quảng', 'vn2007-7073': 'Nem chua',
    'vn2007-1012': 'Baguette', 'vn2007-1005': 'Brown rice',
    'vn2007-3004': 'Black turtle bean', 'vn2007-3010': 'Mung bean',
}
STOP = threading.Event()


def fetch(url):
    if STOP.is_set():
        raise RuntimeError('Source unavailable or rate limited; acquisition stopped.')
    try:
        with urllib.request.urlopen(urllib.request.Request(url, headers={
                'User-Agent': 'HealthMateCatalog/1.0 (food illustration license review)'}), timeout=45) as response:
            return response.read()
    except urllib.error.HTTPError as error:
        if error.code in [429, 503]:
            STOP.set()
        raise


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    articles = []
    titles = list(dict.fromkeys(TITLES.values()))
    for start in range(0, len(titles), 45):
        file = OUT / f'articles-{start}.json'
        if not file.exists():
            query = dict(action='query', format='json', prop='pageimages', piprop='original',
                         titles='|'.join(titles[start:start + 45]), redirects=1)
            file.write_bytes(fetch('https://en.wikipedia.org/w/api.php?' + urllib.parse.urlencode(query)))
            time.sleep(2)
        articles.extend(json.loads(file.read_text(encoding='utf-8')).get('query', {}).get('pages', {}).values())
    file_to_foods = {}
    # Resolve redirects through the returned article title and redirect list.
    redirects = {}
    for file in OUT.glob('articles-*.json'):
        payload = json.loads(file.read_text(encoding='utf-8'))
        redirects.update({r['from']: r['to'] for r in payload.get('query', {}).get('redirects', [])})
    for article in articles:
        url = article.get('original', {}).get('source', '')
        if '/wikipedia/commons/' not in url:
            continue  # Never include local Wikipedia fair-use pictures.
        title = 'File:' + urllib.parse.unquote(urllib.parse.urlparse(url).path.split('/')[-1]).replace('_', ' ')
        for fid, term in TITLES.items():
            if redirects.get(term, term) == article['title']:
                file_to_foods.setdefault(title, []).append(fid)
    metadata = []
    titles = list(file_to_foods)
    for start in range(0, len(titles), 40):
        file = OUT / f'licenses-{start}.json'
        if not file.exists():
            query = dict(action='query', format='json', prop='imageinfo',
                         iiprop='url|size|extmetadata|mime', iiurlwidth=1000,
                         titles='|'.join(titles[start:start + 40]))
            file.write_bytes(fetch('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(query)))
            time.sleep(2)
        metadata.extend(json.loads(file.read_text(encoding='utf-8')).get('query', {}).get('pages', {}).values())
    rows = []
    for row in metadata:
        info = row.get('imageinfo', [{}])[0]
        license = info.get('extmetadata', {}).get('LicenseShortName', {}).get('value', '')
        if (info.get('mime') not in ['image/jpeg', 'image/png', 'image/webp'] or
                not (license in ['CC0', 'Public domain'] or re.fullmatch(r'CC BY(?:-SA)? [1-4]\.\d', license)) or
                max(info.get('width', 0), info.get('height', 0)) < 512):
            continue
        for fid in file_to_foods.get(row['title'], []):
            rows.append(dict(foodId=fid, **row))
    def download(row):
        try:
            path = OUT / (str(row['pageid']) + '.jpg')
            if not path.exists():
                path.write_bytes(fetch(row['imageinfo'][0].get('thumburl') or row['imageinfo'][0]['url']))
                time.sleep(1)
            Image.open(path).load()
            return row
        except Exception as error:
            print('Withheld', row['foodId'], str(error), flush=True)
    with concurrent.futures.ThreadPoolExecutor(max_workers=2) as pool:
        rows = [row for row in pool.map(download, rows) if row]
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
    parser = argparse.ArgumentParser()
    parser.add_argument('--titles', type=Path)
    parser.add_argument('--output', default='wiki-photos')
    args = parser.parse_args()
    if args.titles:
        TITLES = json.loads(args.titles.read_text(encoding='utf-8'))
    if not args.output.replace('-', '').isalnum():
        raise ValueError('Output must be a local research folder name.')
    OUT = ROOT / 'build/catalog-500-research' / args.output
    main()
