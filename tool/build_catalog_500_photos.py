"""Append reviewed, licensed crops; never replaces existing media/admin edits.

Research caches are inputs, the committed selection/manifest retain provenance.
Originals are fetched only if a selected crop needs more native resolution.
"""
import hashlib
import html
import json
from pathlib import Path
import re
import urllib.request
from PIL import Image, ImageOps, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RESEARCH = ROOT / 'build/catalog-500-research'


def clean(value):
    return html.unescape(re.sub('<[^>]+>', '', value)).strip()


def main():
    selection = json.loads((ROOT / 'data/food_catalog/catalog-500-photo-selection.json').read_text(encoding='utf-8'))
    foods = {f['id']: f for f in json.loads((ROOT / 'assets/nutrition/vietnamese-foods.json').read_text(encoding='utf-8'))['foods']}
    metadata = {}
    for directory in ['commons', 'expanded-photos', 'wiki-photos']:
        rows = json.loads((RESEARCH / directory / 'candidates.json').read_text(encoding='utf-8'))
        for row in rows:
            metadata[row['pageid']] = (row, RESEARCH / directory / (str(row['pageid']) + '.jpg'))
    manifest_path = ROOT / 'assets/food_photos/manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    additions = []

    def render(fid, path, crop, record, allow_small_product=False):
        im = ImageOps.exif_transpose(Image.open(path)).convert('RGB')
        bounds = tuple(round(v * d) for v, d in zip(crop, [im.width, im.height, im.width, im.height]))
        source = im.crop(bounds)
        assert min(source.size) >= (300 if allow_small_product else 200), (fid, source.size)
        assert max(source.size) >= (400 if allow_small_product else 512), (fid, source.size)
        scale = min(1, 492 / max(source.size))
        size = tuple(round(v * scale) for v in source.size)
        pic = source.resize(size, Image.Resampling.LANCZOS)
        canvas = Image.new('RGB', (512, 512), 'white')
        canvas.paste(pic, ((512 - size[0]) // 2, (512 - size[1]) // 2))
        dest = ROOT / 'assets/food_photos' / (fid + '.webp')
        canvas.save(dest, 'WEBP', quality=90, method=6)
        return dict(foodId=fid, foodName=foods[fid]['name'], assetPath=dest.relative_to(ROOT).as_posix(),
                    **record, retrievedOn='2026-11-10',
                    changes='Cropped to the named food; centered on a white 512×512 canvas, reduced only, never enlarged; converted to WebP. Original image license retained.',
                    cropNormalized=crop, sourceCropPixels=list(source.size), fit='contain',
                    renderScale=scale, width=512, height=512,
                    sha256=hashlib.sha256(dest.read_bytes()).hexdigest())

    for fid, pid, crop in selection['commons']:
        row, path = metadata[pid]
        info = row['imageinfo'][0]
        ext = info['extmetadata']
        license = ext['LicenseShortName']['value']
        assert license in ['CC0', 'Public domain'] or re.fullmatch(r'CC BY(?:-SA)? [1-4]\.\d', license)
        im = Image.open(path)
        crop_size = ((crop[2] - crop[0]) * im.width, (crop[3] - crop[1]) * im.height)
        if min(crop_size) < 200 or max(crop_size) < 512:
            original = RESEARCH / 'originals' / (str(pid) + '.jpg')
            original.parent.mkdir(exist_ok=True)
            if not original.exists():
                with urllib.request.urlopen(urllib.request.Request(info['url'], headers={
                        'User-Agent': 'HealthMateCatalog/1.0 (selected licensed crop)'}), timeout=50) as response:
                    original.write_bytes(response.read())
            path = original
        record = dict(title=row['title'][5:], author=clean(ext.get('Artist', {}).get('value') or ext.get('Attribution', {}).get('value') or ''),
                      sourceUrl=info['descriptionurl'], license=license,
                      licenseUrl=(ext.get('LicenseUrl', {}).get('value') or 'https://commons.wikimedia.org/wiki/Commons:Public_domain').replace('http://creativecommons.org', 'https://creativecommons.org'), originalUrl=info['url'])
        assert record['author']
        additions.append(render(fid, path, crop, record))
    for fid, code, crop, author in selection['openFoodFacts']:
        product = json.loads((RESEARCH / 'org-haohao.json').read_text(encoding='utf-8'))['product']
        assert code == product['code'] and product['quantity'] == '75 g'
        record = dict(title='Hảo Hảo tôm chua cay 75 g — mặt trước', author=author + ' / Open Food Facts',
                      sourceUrl='https://world.openfoodfacts.org/product/' + code,
                      license='CC BY-SA 3.0', licenseUrl='https://creativecommons.org/licenses/by-sa/3.0/',
                      originalUrl=product['image_front_url'].replace('.400.jpg', '.full.jpg'), barcode=code)
        additions.append(render(fid, RESEARCH / 'product-photos' / (code + '.jpg'), crop, record, True))
    existing = {r['foodId']: r for r in manifest['photos']}
    for record in additions:
        if record['foodId'] in existing and existing[record['foodId']] != record and manifest['version'] != 'food-photos-catalog-500-2026-11-10':
            raise ValueError('This release must not replace existing images.')
        existing[record['foodId']] = record
    manifest['version'] = 'food-photos-catalog-500-2026-11-10'
    manifest['photos'] = list(existing.values())
    manifest_path.write_text(json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    font = ImageFont.truetype(str(ROOT / 'assets/fonts/public_sans/PublicSans-Regular.ttf'), 14)
    for offset in range(0, len(additions), 28):
        part = additions[offset:offset + 28]
        sheet = Image.new('RGB', (1400, 255 * ((len(part) + 6) // 7)), '#f2f4f5')
        draw = ImageDraw.Draw(sheet)
        for j, row in enumerate(part):
            pic = Image.open(ROOT / row['assetPath']).resize((194, 194))
            x, y = j % 7 * 200 + 3, j // 7 * 255
            sheet.paste(pic, (x, y))
            draw.multiline_text((x, y + 196), row['foodId'] + '\n' + row['foodName'][:27], font=font, fill='black')
        sheet.save(RESEARCH / f'approved-{offset // 28 + 1}.jpg', quality=94)
    print('Added', len(additions), 'photos; total', len(existing))


if __name__ == '__main__':
    main()
