"""Public, freely licensed Flickr photo candidates; no API keys or account use.

Read only the photo models already rendered by public search pages. Do not
execute page scripts. Only allow CC BY/BY-SA, CC0 and public-domain records.
Every final assignment still requires visual food/state/crop review.
"""
import argparse
import html
import json
from pathlib import Path
import re
import time
import urllib.error
import urllib.parse
import urllib.request
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/full-food-photos/flickr'
LICENSES = {
    4: ('CC BY 2.0', 'https://creativecommons.org/licenses/by/2.0/'),
    5: ('CC BY-SA 2.0', 'https://creativecommons.org/licenses/by-sa/2.0/'),
    9: ('CC0', 'https://creativecommons.org/publicdomain/zero/1.0/'),
    10: ('Public domain', 'https://creativecommons.org/publicdomain/mark/1.0/'),
    11: ('CC BY 4.0', 'https://creativecommons.org/licenses/by/4.0/'),
    12: ('CC BY-SA 4.0', 'https://creativecommons.org/licenses/by-sa/4.0/'),
}


def save(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={
            'User-Agent': 'HealthMateCatalog/1.0 (licensed food photo and attribution review)'}), timeout=50) as response:
        return response.read()


def parse(raw):
    marker = 'modelExport: '
    if marker not in raw:
        raise ValueError('Public photo data unavailable')
    data, _ = json.JSONDecoder().raw_decode(raw[raw.index(marker)+len(marker):])
    entries = data['main'].get('search-photos-lite-models', [])
    photos = []
    for entry in entries:
        for row in entry['data'].get('photos', {}).get('data', {}).get('_data', []):
            item = row['data']
            license_id = item.get('license')
            if license_id not in LICENSES:
                continue
            sizes = [v['data'] for v in item.get('sizes', {}).get('data', {}).values()]
            sizes = [s for s in sizes if s.get('displayUrl', '').startswith('//live.staticflickr.com/')
                     and min(s.get('width', 0), s.get('height', 0)) >= 200
                     and max(s.get('width', 0), s.get('height', 0)) >= 480]
            if not sizes:
                continue
            large = min(sizes, key=lambda s: abs(max(s['width'], s['height'])-1280))
            preview = min(sizes, key=lambda s: abs(max(s['width'], s['height'])-500))
            photos.append(dict(id=str(item['id']), title=html.unescape(item.get('title') or str(item['id'])),
                               description=html.unescape(re.sub('<[^>]+>', '', item.get('description') or ''))[:1600],
                               author=item['username'], sourceUrl='https://www.flickr.com/photos/'+item['ownerNsid']+'/'+str(item['id'])+'/',
                               originalUrl='https:'+large['displayUrl'], previewUrl='https:'+preview['displayUrl'],
                               width=large['width'], height=large['height'], licenseId=license_id,
                               license=LICENSES[license_id][0], licenseUrl=LICENSES[license_id][1]))
    return photos


def sheets(rows, prefix):
    valid = [r for r in rows if (OUT / 'candidates' / (r['id']+'.jpg')).exists()]
    font = ImageFont.truetype(str(ROOT/'assets/fonts/public_sans/PublicSans-Regular.ttf'), 13)
    for offset in range(0, len(valid), 36):
        part = valid[offset:offset+36]
        canvas = Image.new('RGB', (1440, 260*((len(part)+5)//6)), '#f2f4f5')
        draw = ImageDraw.Draw(canvas)
        for index, row in enumerate(part):
            pic = ImageOps.contain(ImageOps.exif_transpose(Image.open(OUT/'candidates'/(row['id']+'.jpg'))).convert('RGB'), (232, 190))
            x, y = index%6*240+4, index//6*260
            canvas.paste(pic, (x, y))
            draw.multiline_text((x, y+194), row['queryKey']+' '+row['id']+'\n'+row['title'][:34]+'\n'+row['title'][34:68], font=font, fill='black')
        canvas.save(OUT/(prefix+'-'+str(offset//36+1)+'.jpg'), quality=94)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('queries', type=Path)
    parser.add_argument('--prefix', default='contact')
    args = parser.parse_args()
    queries = json.loads(args.queries.read_text(encoding='utf-8'))
    rows = []
    for key, query in queries.items():
        cache = OUT/'search'/(key+'.json')
        try:
            if cache.exists():
                photos = json.loads(cache.read_text(encoding='utf-8'))
            else:
                url = 'https://www.flickr.com/search/?'+urllib.parse.urlencode(dict(text=query, license='4,5,9,10,11,12', media='photos'))
                photos = parse(get(url).decode('utf-8'))
                save(cache, photos)
                time.sleep(3)
            words = set(query.lower().split())
            selected = sorted(photos, key=lambda r: sum(w in (r['title']+' '+r['description']).lower() for w in words), reverse=True)[:6]
            for row in selected:
                path = OUT/'candidates'/(row['id']+'.jpg')
                if not path.exists():
                    path.parent.mkdir(parents=True, exist_ok=True)
                    path.write_bytes(get(row['previewUrl']))
                    time.sleep(1.5)
                rows.append(dict(queryKey=key, **row))
            print('Candidates', key, len(selected), flush=True)
        except urllib.error.HTTPError as error:
            print('Source stopped', key, error.code, 'Retry-After', error.headers.get('Retry-After'), flush=True)
            break
        except Exception as error:
            print('Withheld', key, type(error).__name__, str(error)[:100], flush=True)
            break
    save(OUT/(args.prefix+'-candidates.json'), rows)
    sheets(rows, args.prefix)
    print('Total', len(rows), flush=True)


if __name__ == '__main__':
    main()
