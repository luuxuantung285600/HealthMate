"""Import reviewed official Foundation 04/2026 and FNDDS 2021-2023 downloads.

Offline, standard library only. SHA-256 guards prevent silently changing inputs.
No API key, Firestore writes, edits to historical assets or meal snapshots.
"""
import argparse
from collections import Counter
from datetime import datetime
from fractions import Fraction
import hashlib
import json
import math
from pathlib import Path
import re
import zipfile

from import_usda_bundle import ROOT, CORE, NUTRIENTS, CATEGORIES, TERMS
from import_usda_bundle import dietary_class, source_ingredients_known
from usda_vietnamese import HEADS, vietnamese_name

SOURCES = {
    'foundation': {
        'file': 'FoodData_Central_foundation_food_json_2026-04-30.zip',
        'sha256': '186e988ec542e913f51ef62b86a47758e8cdd0d1dc3889e7b055581f3c09c77a',
        'key': 'FoundationFoods', 'release': '2026-04-30', 'dataType': 'Foundation',
    },
    'fndds': {
        'file': 'FoodData_Central_survey_food_json_2024-10-31.zip',
        'sha256': 'dfb06ae7ddc397ccd570b91c14b75438ab2ba39f64f22d321f61d4a52a77f3eb',
        'key': 'SurveyFoods', 'release': '2024-10-31', 'dataType': 'Survey (FNDDS)',
    },
}
FOUNDATION_CATEGORIES = dict(zip([
    'Dairy and Egg Products', 'Spices and Herbs', 'Fats and Oils',
    'Poultry Products', 'Soups, Sauces, and Gravies', 'Sausages and Luncheon Meats',
    'Breakfast Cereals', 'Fruits and Fruit Juices', 'Pork Products',
    'Vegetables and Vegetable Products', 'Nut and Seed Products', 'Beef Products',
    'Beverages', 'Finfish and Shellfish Products', 'Legumes and Legume Products',
    'Lamb, Veal, and Game Products', 'Baked Products', 'Sweets',
    'Cereal Grains and Pasta', 'Fast Foods', 'Meals, Entrees, and Side Dishes',
    'Snacks', 'American Indian/Alaska Native Foods', 'Restaurant Foods',
], CATEGORIES))

# Additional reviewed food heads. Unknown survey heads are excluded instead of
# adding thousands of opaque English dish names to Vietnamese discovery.
CURRENT_HEADS = {**HEADS, **dict(line.split('=', 1) for line in '''
anchovies=Cá cơm
apricot=Quả mơ
avocado=Quả bơ
blackeye pea=Đậu mắt đen
cod=Cá tuyết
cottage cheese=Phô mai cottage
cream cheese=Phô mai kem
einkorn=Lúa mì einkorn
farro=Lúa mì farro
flour=Bột
fonio=Hạt fonio
green onion=Hành lá
halibut=Cá bơn halibut
khorasan=Lúa mì khorasan
kiwifruit (kiwi)=Kiwi
mahi mahi=Cá nục heo mahi mahi
mandarin=Quýt
pawpaw=Quả pawpaw
pear=Lê
plum=Mận
rutabaga=Củ cải Thụy Điển
sea bass=Cá vược
snapper=Cá hồng
snow crab=Cua tuyết
sorghum=Cao lương
sorghum bran=Cám cao lương
squid (calamari)=Mực
swordfish=Cá kiếm
tuna=Cá ngừ
egg omelet or scrambled egg=Trứng tráng hoặc trứng khuấy
cereal=Ngũ cốc
chicken or turkey=Thịt gà hoặc gà tây
roll=Bánh mì cuộn
chicken thigh=Đùi gà
chicken drumstick=Đùi tỏi gà
cake or cupcake=Bánh ngọt hoặc bánh cupcake
soft drink=Nước ngọt
hot dog sandwich=Bánh mì kẹp xúc xích
green peas=Đậu Hà Lan
chicken leg=Đùi gà nguyên phần
candy=Kẹo
hot chocolate / cocoa=Sô cô la nóng hoặc ca cao
pasta with tomato-based sauce=Mì Ý sốt cà chua
chicken fillet sandwich=Bánh mì kẹp phi lê gà
chicken wing=Cánh gà
bagel=Bánh mì vòng bagel
classic mixed vegetables=Rau củ hỗn hợp
chocolate candy=Kẹo sô cô la
summer squash=Bí mùa hè
coffee creamer=Kem pha cà phê
doughnut=Bánh vòng doughnut
cereal or granola bar=Thanh ngũ cốc hoặc granola
pasta with cream sauce=Mì Ý sốt kem
frozen coffee drink=Đồ uống cà phê đông lạnh
'''.strip().splitlines())}


def finite_number(value):
    return isinstance(value, (int, float)) and not isinstance(value, bool) and math.isfinite(value) and value >= 0


def nutrition(row, kind):
    values = {}
    for item in row.get('foodNutrients', []):
        nutrient = item.get('nutrient', {})
        nutrient_id = str(nutrient.get('id'))
        amount = item.get('amount')
        expected = 'kcal' if nutrient_id in {'1008', '2047', '2048'} else (
            'g' if nutrient_id in {'1003', '1004', '1005', '1079', '2000', '1258'} else 'mg')
        if finite_number(amount) and str(nutrient.get('unitName', '')).lower() == expected:
            if nutrient_id in values and values[nutrient_id] != amount:
                raise ValueError('Conflicting nutrient values for one food')
            values[nutrient_id] = amount
    # HealthMate policy: prefer food-specific Atwater, then general Atwater,
    # then historical Energy for Foundation. USDA describes these as distinct
    # alternatives, not values to add. Survey uses its supplied Energy (1008).
    priority = ('2048', '2047', '1008') if kind == 'foundation' else ('1008',)
    energy_id = next((key for key in priority if key in values), None)
    data = {field: values[key] for key, field in NUTRIENTS.items() if key in values and key != '1008'}
    if energy_id:
        data['kcalPer100g'] = values[energy_id]
    return data, int(energy_id) if energy_id else None


def source_portion(row, kind):
    """Use only unambiguous household measures, normalized to one unit."""
    unit_labels = {
        'cup': 'cốc USDA', 'tablespoon': 'muỗng canh USDA',
        'tbsp': 'muỗng canh USDA', 'teaspoon': 'muỗng cà phê USDA',
        'tsp': 'muỗng cà phê USDA', 'slice': 'lát USDA',
        'piece': 'miếng USDA', 'fl oz': 'fl oz USDA', 'oz': 'oz USDA',
    }
    for item in row.get('foodPortions', []):
        if kind == 'foundation':
            amount = item.get('amount')
            label = item.get('modifier') or item.get('measureUnit', {}).get('name', '')
        else:
            text = item.get('portionDescription', '')
            match = re.fullmatch(r'(\d+(?:\.\d+)?|\d+/\d+) (cup|tablespoon|tbsp|teaspoon|tsp|slice|piece|fl oz|oz)s?', text, re.I)
            if not match:
                continue
            try:
                amount = float(Fraction(match[1]))
            except (ValueError, ZeroDivisionError):
                continue
            label = match[2].lower()
        weight = item.get('gramWeight')
        if not finite_number(amount) or not finite_number(weight) or amount <= 0 or not 0 < weight / amount <= 2000:
            continue
        # Do not reinterpret RACC, numeric modifier codes or unspecified/yield
        # quantities as a serving. Unhandled measures fall back to grams.
        label = label.strip().lower()
        if label.endswith('s') and label[:-1] in unit_labels:
            label = label[:-1]
        if label not in unit_labels:
            continue
        return {
            'servingLabel': unit_labels[label], 'servingGrams': round(weight / amount, 6),
            'defaultServingGrams': round(weight / amount, 6),
            'portionSource': {'foodPortionId': item.get('id'), 'amount': amount,
                              'gramWeight': weight, 'description': label},
        }
    return {}


def convert(row, kind):
    if not isinstance(row, dict):
        return None, 'null_or_invalid_record'
    original = row.get('description', '').strip()
    if row.get('dataType') != SOURCES[kind]['dataType']:
        return None, 'unexpected_data_type'
    if re.search(r'\b(infant|baby|toddler|formula|human milk|breast milk|nutritional drink|meal replacement)\b|as ingredient', original, re.I):
        return None, 'outside_general_adult_catalog'
    data, energy_id = nutrition(row, kind)
    if not all(key in data for key in CORE):
        return None, 'missing_core_nutrient'
    if data['kcalPer100g'] > 1000 or any(data[k] > 100 for k in CORE[1:]) or sum(data[k] for k in CORE[1:]) > 101:
        return None, 'outside_catalog_bounds'
    if original.split(',')[0].lower() not in CURRENT_HEADS:
        return None, 'unreviewed_vietnamese_head'
    fdc_id = row['fdcId']
    publication = datetime.strptime(row['publicationDate'], '%m/%d/%Y')
    category_id = FOUNDATION_CATEGORIES.get(row.get('foodCategory', {}).get('description')) if kind == 'foundation' else None
    category = CATEGORIES.get(category_id, 'Món quốc tế')
    aliases = [v for k, v in TERMS.items() if re.search(r'\b' + re.escape(k) + r'\b', original, re.I)]
    details = {
        'method': f'usda_{kind}', 'fdcId': fdc_id, 'description': original,
        'basis': 'per_100g', 'datasetRelease': SOURCES[kind]['release'],
        'publicationDate': publication.date().isoformat(), 'energyNutrientId': energy_id,
    }
    if kind == 'fndds':
        details.update({'foodCode': row.get('foodCode'), 'surveyStart': row.get('startDate'),
                        'surveyEnd': row.get('endDate'),
                        'surveyCategory': row.get('wweiaFoodCategory', {}).get('wweiaFoodCategoryDescription')})
    label = (f'USDA Foundation · bản 04/2026 · công bố {publication:%d/%m/%Y}' if kind == 'foundation'
             else 'USDA FNDDS 2021–2023 · bản 10/2024')
    food = {
        'id': f'usda-{kind}-{fdc_id}', 'fdcId': fdc_id, 'dataSource': 'usda',
        'name': vietnamese_name(original, category, fdc_id, heads=CURRENT_HEADS),
        'originalName': original, 'alternateNames': [original[:100], ' '.join(dict.fromkeys(aliases))[:100]],
        'category': category, 'servingBasis': 'per_100g', 'unit': 'g',
        **{key: data[key] for key in CORE}, 'isEstimated': True,
        'sourceLabel': f'{label} · FDC {fdc_id}',
        'sourceUrl': f'https://fdc.nal.usda.gov/food-details/{fdc_id}/nutrients',
        'sourceDetails': details, 'ingredientNames': [original],
        # Survey dishes do not provide a verified complete ingredient list.
        'ingredientsKnown': kind == 'foundation' and source_ingredients_known(original, category_id),
        'dietaryClass': dietary_class(original, category_id) if kind == 'foundation' else 'unknown',
        **source_portion(row, kind),
    }
    if 'fiberGPer100g' in data and data['fiberGPer100g'] <= 100:
        food['fiberGPer100g'] = data['fiberGPer100g']
    extras = {k: v for k, v in data.items() if k not in (*CORE, 'fiberGPer100g')}
    if extras:
        food['extraNutrientsPer100g'] = extras
    return food, None


def load_archive(path, spec):
    if hashlib.sha256(path.read_bytes()).hexdigest() != spec['sha256']:
        raise ValueError('Archive differs from reviewed official download; review before import')
    with zipfile.ZipFile(path) as archive:
        names = [n for n in archive.namelist() if n.endswith('.json')]
        if len(names) != 1:
            raise ValueError('Expected exactly one JSON dataset')
        return json.loads(archive.read(names[0]))[spec['key']]


def build(directory):
    existing = [f for filename in ('vietnamese-foods.json', 'usda-sr-legacy.json')
                for f in json.loads((ROOT / 'assets/nutrition' / filename).read_text(encoding='utf-8'))['foods']]
    seen = {f.get('fdcId', f.get('sourceDetails', {}).get('fdcId')) for f in existing}
    foods, reports = [], {}
    for kind, spec in SOURCES.items():
        rows = load_archive(directory / spec['file'], spec)
        added, excluded = [], Counter()
        for row in rows:
            food, reason = convert(row, kind)
            if food and food['fdcId'] in seen:
                reason = 'duplicate_source_record'
            if reason:
                excluded[reason] += 1
                continue
            seen.add(food['fdcId'])
            added.append(food)
        added.sort(key=lambda f: f['fdcId'])
        foods.extend(added)
        reports[kind] = {**spec, 'sourceUrl': f"https://fdc.nal.usda.gov/fdc-datasets/{spec['file']}",
                         'inputRecords': len(rows), 'addedFoods': len(added),
                         'excluded': dict(sorted(excluded.items())),
                         'publicationDates': dict(sorted(Counter(f['sourceDetails']['publicationDate'] for f in added).items())),
                         'withHouseholdPortion': sum('servingGrams' in f for f in added)}
    from food_browse_metadata import apply_browse_metadata
    apply_browse_metadata(foods)
    destination = ROOT / 'assets/nutrition/usda-current.json'
    payload = {'version': 'healthmate-usda-current-2026-10-27',
               'license': 'CC0-1.0 / USDA public domain',
               'licenseUrl': 'https://fdc.nal.usda.gov/api-guide/#licensing',
               'sources': reports, 'foods': foods}
    destination.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    report = {'checkedOn': '2026-10-27', 'sources': reports, 'addedFoods': len(foods),
              'retainedFoods': len(existing), 'bundledTotal': len(existing) + len(foods),
              'assetBytes': destination.stat().st_size,
              'assetSha256': hashlib.sha256(destination.read_bytes()).hexdigest(),
              'energyPolicy': 'Foundation 2048 > 2047 > 1008; FNDDS 1008; only kcal units accepted',
              'notes': ['Dataset release is not food measurement date.',
                        'FNDDS values can be compiled from older reference compositions and recipes.',
                        'Historical IDs and meal snapshots are unchanged.',
                        'Survey ingredients and dietary class remain unknown; no allergy certification.']}
    (ROOT / 'data/food_catalog/usda-current-manifest.json').write_text(json.dumps(report, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('directory', type=Path)
    print(json.dumps(build(parser.parse_args().directory), ensure_ascii=False, indent=2))
