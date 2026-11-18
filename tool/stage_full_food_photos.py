"""Stage explicitly reviewed food photos for the curated 500-food scope.

Never changes Firestore, food nutrients, admin overrides or existing images.
Shared illustrative photos require explicit assignments, not category fallbacks.
"""
import argparse
import hashlib
import html
import json
from pathlib import Path
import re
import shutil
import urllib.request
from PIL import Image, ImageOps

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/full-food-photos'
SELECTION = ROOT / 'data/food_catalog/full-photo-selection.json'
SCOPE = ROOT / 'data/food_catalog/photo-coverage-500.json'


def read(path):
    return json.loads(path.read_text(encoding='utf-8-sig'))


def save(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def clean(value):
    return html.unescape(re.sub('<[^>]+>', '', value)).strip()


def stage():
    scope = read(SCOPE)['foods']
    assert len(scope) == 500 and len({f['id'] for f in scope}) == 500
    foods = {f['id']: f for f in scope}
    base = read(ROOT / 'assets/food_photos/manifest.json')
    records = {p['foodId']: p for p in base['photos']}
    for fid, photo in records.items():
        assert foods[fid]['name'] == photo['foodName']
        assert hashlib.sha256((ROOT / photo['assetPath']).read_bytes()).hexdigest() == photo['sha256']
    selections = read(SELECTION)
    rejected = selections.get('rejectedFoodIds', {})
    assert all(fid in foods and len(reason) > 12 for fid, reason in rejected.items())
    for fid in rejected:
        records.pop(fid, None)
    commons = read(OUT / 'metadata.json')
    pexels = {}
    for file in (OUT / 'pexels/search').glob('*.json'):
        for row in read(file):
            pexels[str(row['id'])] = row
    flickr = {}
    for file in (OUT / 'flickr/search').glob('*.json'):
        for row in read(file):
            flickr[str(row['id'])] = row
    manufacturer = {r['foodId']: r for r in read(OUT / 'manufacturer/candidates.json')}
    packages = {r['id']: r for r in read(ROOT / 'data/food_catalog/packaged.json')['foods']}
    sources = {}
    for key, spec in selections['sources'].items():
        kind = spec['kind']
        if kind == 'bundled':
            p = records[spec['foodId']]
            sources[key] = (ROOT / p['assetPath'], p, spec)
            continue
        if kind == 'commons':
            row = commons[str(spec['pageid'])]
            info = row['imageinfo'][0]
            ext = info['extmetadata']
            license = ext['LicenseShortName']['value']
            assert license in ['CC0', 'Public domain'] or re.fullmatch(r'CC BY(?:-SA)? [1-4]\.\d(?: [a-z]{2})?', license)
            credits = dict(title=row['title'][5:], author=clean(ext.get('Artist', {}).get('value') or ext.get('Attribution', {}).get('value') or ''),
                           sourceUrl=info['descriptionurl'], originalUrl=info['url'].split('?')[0], license=license,
                           licenseUrl=(ext.get('LicenseUrl', {}).get('value') or 'https://commons.wikimedia.org/wiki/Commons:Public_domain').replace('http://creativecommons.org', 'https://creativecommons.org'))
            if not credits['author'] and spec.get('authorCredit'):
                assert len(spec.get('authorCreditEvidence', '')) > 30
                credits['author'] = spec['authorCredit']
            path = OUT / 'candidates' / (str(spec['pageid']) + '.jpg')
        elif kind == 'pexels':
            row = pexels[str(spec['id'])]
            credits = {k: row[k] for k in ['title', 'author', 'sourceUrl', 'originalUrl', 'license', 'licenseUrl']}
            path = OUT / 'selected-pexels' / (str(spec['id']) + '.jpg')
            if not path.exists():
                path.parent.mkdir(parents=True, exist_ok=True)
                with urllib.request.urlopen(urllib.request.Request(row['originalUrl'] + '?auto=compress&cs=tinysrgb&w=1440', headers={
                        'User-Agent': 'HealthMateCatalog/1.0 (selected food photo and attribution review)'}), timeout=60) as r:
                    path.write_bytes(r.read())
        elif kind == 'flickr':
            row = flickr[str(spec['id'])]
            assert row['licenseId'] in [4, 5, 9, 10, 11, 12]
            assert row['originalUrl'].startswith('https://live.staticflickr.com/')
            credits = {k: row[k] for k in ['title', 'author', 'sourceUrl', 'originalUrl', 'license', 'licenseUrl']}
            path = OUT / 'selected-flickr' / (str(spec['id']) + '.jpg')
            if not path.exists():
                path.parent.mkdir(parents=True, exist_ok=True)
                with urllib.request.urlopen(urllib.request.Request(row['originalUrl'], headers={
                        'User-Agent': 'HealthMateCatalog/1.0 (selected licensed food photo review)'}), timeout=60) as r:
                    path.write_bytes(r.read())
        elif kind == 'manufacturer':
            row = manufacturer[spec['foodId']]
            package = packages[spec['foodId']]
            if row['author'] == 'TH':
                products = read(OUT / 'th-products.json')['products']
                product = next(p for p in products if p['id'] == row['manufacturerProductId'])
                assert product['handle'] == row['manufacturerProductHandle']
                assert row['originalUrl'] in [p['src'] for p in product['images']]
                assert row['sourceUrl'] == 'https://thtruemart.vn/products/' + product['handle']
                assert row['manufacturerProductId'] == {
                    'th-yogurt-sweetened-100g': 1075763725,
                    'th-yogurt-natural-100g': 1075763861,
                    'th-yogurt-durian-100g': 1075763751,
                }[spec['foodId']]
            else:
                assert row['originalUrl'] == package['sourceDetails']['packageImageUrl']
            credits = dict(title=package['name'] + ' — bao bì từ nhà sản xuất', author=row['author'], sourceUrl=row['sourceUrl'],
                           originalUrl=row['originalUrl'], license='Bản quyền nhà sản xuất', licenseUrl=row['sourceUrl'])
            path = ROOT / row['path']
        else:
            raise ValueError('Unreviewed source kind: ' + kind)
        assert credits['author'] and credits['title'], key
        assert all(credits[k].startswith('https://') for k in ['sourceUrl', 'originalUrl', 'licenseUrl'])
        if not path.exists():
            raise ValueError('Selected image not acquired: ' + key)
        sources[key] = (path, dict(**credits, sourceKind=kind), spec)
    for fid, assignment in selections['assignments'].items():
        assert fid not in rejected, fid
        if fid in records:
            continue
        assert fid in foods and len(assignment['reviewNote']) >= 12, fid
        key = assignment['source']
        path, credits, spec = sources[key]
        if spec['kind'] == 'manufacturer':
            assert spec['foodId'] == fid  # Branded pictures never cross variants.
        destination = OUT / 'staged-assets' / (fid + '.webp')
        destination.parent.mkdir(parents=True, exist_ok=True)
        if spec['kind'] == 'bundled':
            shutil.copyfile(path, destination)
            record = {k: v for k, v in credits.items() if k not in ['foodId', 'foodName', 'assetPath', 'sha256', 'barcode']}
        else:
            im = ImageOps.exif_transpose(Image.open(path)).convert('RGBA')
            crop = spec.get('crop', [0, 0, 1, 1])
            assert len(crop) == 4 and all(0 <= x <= 1 for x in crop) and crop[2] > crop[0] and crop[3] > crop[1]
            cropped = im.crop(tuple(round(v * d) for v, d in zip(crop, [im.width, im.height, im.width, im.height])))
            assert min(cropped.size) >= 200 and max(cropped.size) >= 480, (key, cropped.size)
            scale = min(1, 492 / max(cropped.size))
            pic = cropped.resize(tuple(round(v * scale) for v in cropped.size), Image.Resampling.LANCZOS)
            canvas = Image.new('RGBA', (512, 512), 'white')
            canvas.alpha_composite(pic, ((512 - pic.width) // 2, (512 - pic.height) // 2))
            canvas.convert('RGB').save(destination, 'WEBP', quality=91, method=6)
            record = dict(**credits, cropNormalized=crop, sourceCropPixels=list(cropped.size), renderScale=scale, fit='contain',
                          width=512, height=512, retrievedOn='2026-11-11',
                          changes='Reviewed crop, reduced without enlargement, centered on a white canvas, converted to WebP. Source rights retained.')
        records[fid] = dict(**record, foodId=fid, foodName=foods[fid]['name'], assetPath='assets/food_photos/' + fid + '.webp',
                            sha256=hashlib.sha256(destination.read_bytes()).hexdigest(), sourcePhotoKey=key, visualReview=assignment['reviewNote'])
    missing = [f for f in scope if f['id'] not in records]
    manifest = dict(version='food-photos-reviewed-2026-11-11', note=base['note'], photos=list(records.values()))
    save(OUT / 'staged-manifest.json', manifest)
    save(OUT / 'missing.json', missing)
    print(json.dumps(dict(covered=500-len(missing), total=500, missing=len(missing), sources=len(sources)), ensure_ascii=False), flush=True)
    return manifest, base, missing


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['stage', 'install'])
    parser.add_argument('--exclude-missing', action='store_true',
                        help='Explicitly exclude foods without reviewed photos, as requested by the user.')
    args = parser.parse_args()
    manifest, base, missing = stage()
    if args.mode == 'install':
        if missing and not args.exclude_missing:
            raise ValueError('Full coverage required before installation: ' + str(len(missing)) + ' missing.')
        scope = read(SCOPE)['foods']
        release = dict(version='photo-visibility-20261111-v1',
                       scopeIds=[f['id'] for f in scope],
                       visibleIds=[p['foodId'] for p in manifest['photos']],
                       excluded=[dict(id=f['id'], name=f['name'],
                                      reason=read(SELECTION).get('rejectedFoodIds', {}).get(f['id'],
                                          'Chưa có ảnh đúng món, trạng thái hoặc nguồn đạt yêu cầu.')) for f in missing])
        assert len(release['visibleIds']) + len(release['excluded']) == len(scope)
        current = {r['foodId']: r for r in base['photos']}
        withdrawn = [row for row in base['photos'] if row['foodId'] not in release['visibleIds']]
        if withdrawn:
            # Preserve a local recovery copy of explicitly rejected assets.
            archive = OUT / 'withdrawn'
            archive.mkdir(parents=True, exist_ok=True)
            save(archive / 'manifest.json', dict(photos=withdrawn))
            for row in withdrawn:
                assert row['assetPath'] == f"assets/food_photos/{row['foodId']}.webp"
                shutil.move(ROOT / row['assetPath'], archive / (row['foodId'] + '.webp'))
        for row in manifest['photos']:
            if row['foodId'] in current:
                assert row == current[row['foodId']]
                continue
            shutil.copyfile(OUT / 'staged-assets' / (row['foodId'] + '.webp'), ROOT / row['assetPath'])
        save(ROOT / 'assets/food_photos/manifest.json', manifest)
        save(ROOT / 'data/food_catalog/photo-release.json', release)
        print(f"Installed {len(release['visibleIds'])} reviewed photos; excluded {len(missing)} foods. Regenerate app/admin registries.", flush=True)


if __name__ == '__main__':
    main()
