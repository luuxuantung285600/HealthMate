"""Read-only OFF source snapshots for a reviewed release; never writes Firebase.

Respects the documented 10 search requests/minute, caches successful pages,
uses verified TLS, and stops on rate limiting rather than retrying aggressively.
Images/data must be reviewed separately before inclusion in the catalog.
"""
import json
import concurrent.futures
from pathlib import Path
import time
import urllib.parse
import urllib.request
import urllib.error

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / 'build/catalog-500-research'
UA = 'HealthMateCatalog/1.0 (local catalog source and license review)'
FIELDS = ','.join(['code', 'product_name', 'product_name_vi', 'product_name_en',
                   'brands', 'quantity', 'product_quantity', 'product_quantity_unit',
                   'nutrition_data_per', 'nutrition_data_prepared_per', 'nutriments',
                   'image_front_url', 'image_nutrition_url', 'selected_images', 'images',
                   'categories_tags', 'countries_tags', 'data_quality_errors_tags',
                   'last_modified_t', 'rev', 'url'])


def fetch(url):
    request = urllib.request.Request(url, headers={'User-Agent': UA})
    with urllib.request.urlopen(request, timeout=60) as response:
        return response.read()


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    # The production search endpoint may return 503. The public staging index
    # is ONLY a barcode discovery aid. Never publish its data. Every candidate
    # is fetched independently from the production product API below.
    codes = set()
    for page in range(1, 12):
        path = OUT / f'off-discovery-page-{page}.json'
        if not path.exists():
            query = urllib.parse.urlencode(dict(countries_tags='en:vietnam', page_size=100, page=page))
            try:
                path.write_bytes(fetch('https://world.openfoodfacts.net/api/v2/search?' + query))
            except Exception as error:
                print(f'Discovery stopped: {type(error).__name__}; using available barcodes only', flush=True)
                break
            time.sleep(7)
        result = json.loads(path.read_text(encoding='utf-8'))
        for product in result.get('products', []):
            n = product.get('nutriments', {})
            if (product.get('nutrition_data_per') == '100g' and product.get('image_front_url')
                    and all(isinstance(n.get(k + '_100g'), (int, float))
                            for k in ['energy-kcal', 'proteins', 'carbohydrates', 'fat'])):
                codes.add(product['code'])
        print(f'Discovery page {page}: {len(codes)} candidate barcodes (not trusted data)', flush=True)
        if page * 100 >= result['count']:
            break
    # Also use the successful production search snapshot, without trusting the
    # staging copy for any field, source, photograph or nutritional value.
    initial = OUT / 'search-response-2.json'
    if initial.exists():
        codes.update(p['code'] for p in json.loads(initial.read_text(encoding='utf-8'))['products']
                     if p.get('nutrition_data_per') == '100g' and p.get('image_front_url'))
    codes = {code for code in codes if code.startswith('893') and len(code) == 13}
    snapshots = OUT / 'production-products'
    snapshots.mkdir(exist_ok=True)
    def product(code):
        path = snapshots / (code + '.json')
        if not path.exists():
            try:
                path.write_bytes(fetch('https://world.openfoodfacts.org/api/v2/product/' + code + '.json'))
            except urllib.error.HTTPError as error:
                if error.code in [429, 503]:
                    raise RuntimeError('Source rate-limited/unavailable; stop acquisition and resume later.') from error
                print(f'Withheld {code}: HTTP {error.code}', flush=True)
                return None
            except Exception as error:
                print(f'Withheld {code}: {type(error).__name__}', flush=True)
                return None
        return json.loads(path.read_text(encoding='utf-8')).get('product')
    products = {}
    for start in range(0, len(codes), 3):
        batch = sorted(codes)[start:start + 3]
        then = time.monotonic()
        with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
            for item in pool.map(product, batch):
                if item:
                    products[item['code']] = item
        print(f'Production snapshots: {len(products)}', flush=True)
        time.sleep(max(0, 2 - (time.monotonic() - then)))
    (OUT / 'off-vietnam-products.json').write_text(
        json.dumps(list(products.values()), ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


if __name__ == '__main__':
    main()
