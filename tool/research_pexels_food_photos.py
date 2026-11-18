"""Public Pexels search-page candidates, not automatic food assignments.

Retains source/author/license without collecting unrelated profile data.
Final photos must be visually reviewed and explicitly assigned to catalog IDs.
"""
import argparse
import concurrent.futures
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/full-food-photos/pexels'
UA = 'HealthMateCatalog/1.0 (food imagery and attribution review)'


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={'User-Agent': UA}), timeout=50) as r:
        return r.read()


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('queries', type=Path)
    parser.add_argument('--prefix', default='contact')
    args = parser.parse_args()
    queries = json.loads(args.queries.read_text(encoding='utf-8'))
    rows = []
    unavailable = 0
    for key, query in queries.items():
        cache = OUT / 'search' / (key + '.json')
        unavailable_cache = OUT / 'unavailable' / (key + '.json')
        if unavailable_cache.exists():
            continue
        if cache.exists():
            results = json.loads(cache.read_text(encoding='utf-8'))
        else:
            try:
                raw = get('https://www.pexels.com/search/' + urllib.parse.quote(query, safe='') + '/')
                found = re.search(rb'<script[^>]+id="__NEXT_DATA__"[^>]*>(.*?)</script>', raw, re.S)
                if not found:
                    raise ValueError('Search page has no public photo data.')
                payload = json.loads(found.group(1))['props']['pageProps']['initialData']['data']
                results = []
                for item in payload:
                    a = item.get('attributes', {})
                    if item.get('type') != 'photo' or a.get('license') != 'Pexels' or not a.get('published'):
                        continue
                    user = a['user']
                    author = ((user.get('first_name') or '') + ' ' + (user.get('last_name') or '')).strip()
                    if not author:
                        continue
                    image = (a.get('image') or {}).get('large')
                    if not image or not image.startswith('https://images.pexels.com/photos/'):
                        continue
                    results.append(dict(id=a['id'], title=a.get('title') or a.get('alt') or str(a['id']), description=a.get('description') or a.get('alt') or '',
                                        width=a['width'], height=a['height'], author=author,
                                        sourceUrl='https://www.pexels.com/photo/' + ((a.get('slug') + '-') if a.get('slug') else '') + str(a['id']) + '/',
                                        originalUrl=image.split('?')[0], license='Pexels License',
                                        licenseUrl='https://www.pexels.com/license/'))
                save(cache, results)
                unavailable = 0
                time.sleep(1.6)
            except Exception as error:
                print('Search unavailable', key, type(error).__name__, str(error)[:100], flush=True)
                unavailable += 1
                if isinstance(error, urllib.error.HTTPError) and error.code == 403:
                    save(unavailable_cache, dict(query=query, status=403, withheld=True))
                if isinstance(error, urllib.error.HTTPError) and error.code == 403 and unavailable < 3:
                    # Withhold this public page; do not retry it or change
                    # identity/access controls. Other topics may be public.
                    time.sleep(3)
                    continue
                break
        # A search result is only a candidate. No textual score counts as a
        # visual approval, and rejected images are never assigned to foods.
        for row in results:
            row['title'] = row.get('title') or row.get('description') or str(row['id'])
        negatives = re.compile(r'\b(?:hands?|woman|man|people|person|portrait|holding|preparing|chef|kitchen|market|bartender|bartending|spoiled|rotting|rotten)\b', re.I)
        words = set(query.lower().split())
        def rank(row):
            text = (row['title'] + ' ' + row['description']).lower()
            return sum(word in text for word in words) - 10 * bool(negatives.search(text))
        selected = sorted(results, key=rank, reverse=True)[:6]
        for row in selected:
            path = OUT / 'candidates' / (str(row['id']) + '.jpg')
            if not path.exists():
                try:
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(get(row['originalUrl'] + '?auto=compress&cs=tinysrgb&w=520'))
                    time.sleep(.45)
                except urllib.error.HTTPError as error:
                    print('Image stopped', key, row['id'], error.code, flush=True)
                    if error.code in [429, 503]:
                        save(OUT / (args.prefix + '-candidates.json'), rows)
                        return
                    continue
            rows.append(dict(queryKey=key, **row))
        print('Candidates', key, len(selected), flush=True)
    save(OUT / (args.prefix + '-candidates.json'), rows)
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/public_sans/PublicSans-Regular.ttf'), 13)
    for offset in range(0, len(rows), 36):
        part = rows[offset:offset + 36]
        canvas = Image.new('RGB', (1440, 260 * ((len(part) + 5) // 6)), '#f2f4f5')
        draw = ImageDraw.Draw(canvas)
        for j, row in enumerate(part):
            pic = ImageOps.contain(Image.open(OUT / 'candidates' / (str(row['id']) + '.jpg')).convert('RGB'), (232, 192))
            x, y = j % 6 * 240 + 4, j // 6 * 260
            canvas.paste(pic, (x, y))
            label = row['queryKey'] + ' ' + str(row['id']) + '\n' + row['title'][:34] + '\n' + row['title'][34:68]
            draw.multiline_text((x, y + 195), label, font=font, fill='black')
        canvas.save(OUT / f'{args.prefix}-{offset // 36 + 1}.jpg', quality=94)
    print('Total', len(rows), flush=True)


if __name__ == '__main__':
    main()
