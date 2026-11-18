"""Read-only comparison against the cached official VDD PDF and USDA archive.

Usage: python tool/verify_fruit_drink_sources.py <VDD.pdf> <USDA-2018.zip>
Foundation records retain their existing source lineage; this verifier reports
only the 147 SR records and 27 new VDD rows it can independently reproduce.
"""
import csv
import hashlib
import io
import json
from pathlib import Path
import sys
import zipfile

from expand_fruit_drink_catalog import extract
from import_usda_bundle import NUTRIENTS, SOURCE_SHA256

ROOT = Path(__file__).resolve().parent.parent


def verify(pdf_path, archive_path):
    expected = json.loads((ROOT / 'data/food_catalog/fruits-drinks-2026-11-10.json').read_text(encoding='utf-8'))
    if extract(pdf_path) != expected:
        raise ValueError('VDD food values/evidence differ from source extraction.')
    if hashlib.sha256(archive_path.read_bytes()).hexdigest() != SOURCE_SHA256:
        raise ValueError('Unexpected USDA source archive.')
    browse = json.loads((ROOT / 'data/food_catalog/fruit-drink-browse.json').read_text(encoding='utf-8'))['groups']
    selected = {f['id'].split('-')[-1]: f for group in browse.values() for f in group if f['id'].startswith('usda-sr-')}
    refs = {str(f['fdcId']): f for f in json.loads((ROOT / 'assets/nutrition/usda-sr-legacy.json').read_text(encoding='utf-8'))['foods']}
    with zipfile.ZipFile(archive_path) as archive:
        def rows(suffix):
            return csv.DictReader(io.TextIOWrapper(archive.open(next(n for n in archive.namelist() if n.endswith('/' + suffix))), encoding='utf-8-sig'))
        values = {key: {} for key in selected}
        for row in rows('food_nutrient.csv'):
            if row['fdc_id'] in selected and row['nutrient_id'] in NUTRIENTS:
                values[row['fdc_id']][NUTRIENTS[row['nutrient_id']]] = float(row['amount'])
        for key, item in selected.items():
            reference = refs[key]
            for metric in ['kcalPer100g', 'proteinGPer100g', 'carbsGPer100g', 'fatGPer100g', 'fiberGPer100g']:
                if metric in reference and reference[metric] != values[key].get(metric):
                    raise ValueError(f'Changed source nutrient: {key}/{metric}')
            for metric, value in reference.get('extraNutrientsPer100g', {}).items():
                if value != values[key].get(metric):
                    raise ValueError(f'Changed source extra nutrient: {key}/{metric}')
            if 'sourceServing' in item:
                for field, value in item['sourceServing'].items():
                    if reference[field] != value:
                        raise ValueError(f'Changed source portion: {key}/{field}')
        identities = {row['fdc_id']: row['description'] for row in rows('food.csv') if row['fdc_id'] in selected}
        for key, item in selected.items():
            if identities.get(key) != item['originalName']:
                raise ValueError(f'Changed USDA food identity: {key}')
        portions = {str(f['sourceServing']['portionSource']['foodPortionId']): f for f in selected.values() if 'sourceServing' in f}
        verified_portions = set()
        for row in rows('food_portion.csv'):
            item = portions.get(row['id'])
            if item:
                source = item['sourceServing']['portionSource']
                if (row['fdc_id'] != item['id'].split('-')[-1] or
                        float(row['gram_weight']) != source['gramWeight'] or float(row['amount']) != source['amount']):
                    raise ValueError('Portion provenance mismatch.')
                verified_portions.add(row['id'])
        if len(verified_portions) != len(portions):
            raise ValueError('Missing source portion.')
    return {'vddRows': len(expected['foods']), 'usdaSrRecords': len(selected),
            'sourceCupPortions': len(portions), 'withheldInconsistentSugar': len(expected['withheldNutrients'])}


if __name__ == '__main__':
    print(json.dumps(verify(Path(sys.argv[1]), Path(sys.argv[2]))))
