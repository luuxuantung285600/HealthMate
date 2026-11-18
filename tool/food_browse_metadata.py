"""Reproducible, reviewed display metadata; never edits nutrient/source fields."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OVERRIDES = json.loads((ROOT / 'data/food_catalog/browse-overrides.json').read_text(encoding='utf-8'))['foods']
BROWSE = json.loads((ROOT / 'data/food_catalog/fruit-drink-browse.json').read_text(encoding='utf-8'))['groups']
for group in BROWSE.values():
    if len(group) != 100:
        raise ValueError('Each reviewed browse group must contain 100 entries.')
    for food in group:
        if 'originalName' in food:
            OVERRIDES[food['id']] = food


def apply_browse_metadata(foods):
    for food in foods:
        patch = OVERRIDES.get(food['id'])
        if patch is None:
            continue
        if patch.get('originalName', food.get('originalName')) != food.get('originalName'):
            raise ValueError(f"Changed source identity: {food['id']}")
        food['name'] = patch['name']
        food['alternateNames'] = list(dict.fromkeys([*food.get('alternateNames', []), *patch['alternateNames']]))
        if 'category' in patch:
            food['category'] = patch['category']
        if 'sourceServing' in patch:
            food.update(patch['sourceServing'])
    return foods


def browse_index():
    rows = ['// Generated from data/food_catalog/fruit-drink-browse.json.',
            '// Run: python tool/food_browse_metadata.py. Nutrition is not changed.',
            'const foodBrowseIndex = <String, ({String group, int order})>{']
    for key, foods in BROWSE.items():
        for order, food in enumerate(foods):
            rows.append(f"  '{food['id']}': (group: '{key}', order: {order}),")
    return '\n'.join([*rows, '};', ''])


if __name__ == '__main__':
    for filename in ['usda-sr-legacy.json', 'usda-current.json']:
        path = ROOT / 'assets/nutrition' / filename
        payload = json.loads(path.read_text(encoding='utf-8'))
        apply_browse_metadata(payload['foods'])
        path.write_text(json.dumps(payload, ensure_ascii=False, separators=(',', ':')) + '\n', encoding='utf-8')
    (ROOT / 'lib/features/nutrition/models/food_browse_index.dart').write_text(browse_index(), encoding='utf-8')
    print(f'Applied {len(OVERRIDES)} reviewed display identities; no cloud changes.')
