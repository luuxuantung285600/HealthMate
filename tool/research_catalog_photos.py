"""Commons candidates/contact sheets, local review only; no catalog writes."""
import html
import json
from pathlib import Path
import time
import urllib.parse
import urllib.request
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/catalog-500-research/commons'
QUERIES = {
    'vn2007-5003': 'lemon fruit white background',
    'vn2007-5004': 'rambutan white background',
    'vn2007-5011': 'watermelon sliced white background',
    'vn2007-5017': 'papaya fruit white background',
    'vn2007-5018': 'Syzygium samarangense fruit white background',
    'vn2007-5025': 'soursop fruit cut',
    'vn2007-5042': 'green avocado fruit cut',
    'vn2007-5047': 'mandarin orange fruit white background',
    'vn2007-5016': 'peach fruit white background',
    'vn2007-5020': 'persimmon fruit white background',
    'vn2007-5022': 'sapodilla fruit cut',
    'vn2007-5024': 'pomegranate white background',
    'vn2007-5027': 'plum fruit white background',
    'vn2007-5031': 'apricot fruit white background',
    'vn2007-5032': 'dried apricots white background',
    'vn2007-5036': 'dried longan bowl',
    'vn2007-5041': 'avocado black skin fruit',
    'vn2007-5045': 'canistel fruit cut',
    'vn2007-5050': 'jujube fresh fruit',
    'vn2007-5056': 'kiwifruit white background',
    'vn2007-14005': 'orange juice glass white background',
    'vn2007-14006': 'pineapple juice glass',
    'vn2007-14007': 'tomato juice glass',
    'vn2007-14008': 'glass water white background',
    'vn-banh-chung': 'bánh chưng cut',
    'vn-banh-beo': 'bánh bèo',
    'vn-bot-chien': 'bột chiên',
    'vn-hu-tieu': 'hủ tiếu nam vang',
    'vn-mi-quang': 'mì quảng gà tôm',
    'vn-thit-kho-tieu': 'thịt kho tiêu',
    'vn-com-chien-trung': 'egg fried rice bowl',
    'vn-xoi-dau-xanh': 'xôi đậu xanh',
    'vn-trung-chien': 'Vietnamese fried egg omelette',
    'vn2007-3032': 'soy milk glass',
    'vn2007-3033': 'tàu hũ nước đường',
    'vn2007-7073': 'nem chua plate',
    'vn2007-1012': 'Vietnamese baguette plain',
    'vn2007-1005': 'brown rice uncooked white background',
    'vn2007-3004': 'black turtle beans dry white background',
    'vn2007-3010': 'mung beans white background',
}


def get(url):
    with urllib.request.urlopen(urllib.request.Request(url, headers={
            'User-Agent': 'HealthMateCatalog/1.0 (licensed food media research)'}), timeout=45) as response:
        return response.read()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    rows = []
    for fid, query in QUERIES.items():
        cache = OUT / (fid + '.json')
        if not cache.exists():
            params = dict(action='query', format='json', generator='search',
                          gsrsearch=query, gsrnamespace=6, gsrlimit=3,
                          prop='imageinfo', iiprop='url|size|extmetadata', iiurlwidth=800,
                          maxlag=5)
            try:
                cache.write_bytes(get('https://commons.wikimedia.org/w/api.php?' + urllib.parse.urlencode(params)))
                time.sleep(.7)
            except Exception as error:
                print(fid, str(error), flush=True)
                continue
        data = json.loads(cache.read_text(encoding='utf-8'))
        for row in data.get('query', {}).get('pages', {}).values():
            info = row.get('imageinfo', [{}])[0]
            license = info.get('extmetadata', {}).get('LicenseShortName', {}).get('value', '')
            if not (license in ['CC0', 'Public domain'] or license.startswith('CC BY')):
                continue
            if min(info.get('width', 0), info.get('height', 0)) < 512:
                continue
            image = OUT / (str(row['pageid']) + '.jpg')
            try:
                if not image.exists():
                    image.write_bytes(get(info.get('thumburl') or info['url']))
                    time.sleep(.6)
                Image.open(image).load()
                rows.append(dict(foodId=fid, **row))
            except Exception as error:
                print(fid, row['pageid'], str(error), flush=True)
        print(fid, len(rows), flush=True)
    (OUT / 'candidates.json').write_text(json.dumps(rows, ensure_ascii=False, indent=2), encoding='utf-8')
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/public_sans/PublicSans-Regular.ttf'), 13)
    for offset in range(0, len(rows), 35):
        part = rows[offset:offset + 35]
        sheet = Image.new('RGB', (1400, 270 * ((len(part) + 6) // 7)), '#f2f4f5')
        draw = ImageDraw.Draw(sheet)
        for index, row in enumerate(part):
            image = ImageOps.contain(Image.open(OUT / (str(row['pageid']) + '.jpg')).convert('RGB'), (194, 195))
            x, y = index % 7 * 200 + 3, index // 7 * 270
            sheet.paste(image, (x, y))
            draw.multiline_text((x, y + 198), str(row['pageid']) + '\n' + row['foodId'] + '\n' + row['title'][5:30], font=font, fill='black')
        sheet.save(OUT / f'contact-{offset // 35 + 1}.jpg', quality=93)
    print('Candidates', len(rows), flush=True)


if __name__ == '__main__':
    main()
