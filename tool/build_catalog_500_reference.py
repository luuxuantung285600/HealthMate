"""Materialize the reviewed 114-row selection from exact official PDF cells.

Run extract_catalog_reference.py first. This never publishes to Firebase.
Missing data is rejected; cellulose is never substituted for total dietary fiber.
"""
import csv
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SHA = '6c4838ba5623df6d62b2bf4ef1a82968bbfad8a10980247c32b7e60c0c9ca281'
URL = 'https://www.fao.org/fileadmin/templates/food_composition/documents/pdf/VTN_FCT_2007.pdf'


def main():
    source = {row['code']: row for row in json.loads(
        (ROOT / 'build/catalog-500-research/vdd-all-rows.json').read_text(encoding='utf-8'))}
    with (ROOT / 'data/food_catalog/catalog-500-selection.tsv').open(encoding='utf-8') as file:
        selection = list(csv.DictReader(file, delimiter='\t'))
    foods = []
    for selected in selection:
        row = source[selected['code']]
        if any(value is None for value in row['per100g'].values()):
            raise ValueError('Missing source macro: ' + row['code'])
        extras = {}
        for key, label in [('sodium', 'Sodium'), ('sugar', 'Sugar')]:
            cell = row['cells'][label]['valueCell']
            try:
                value = float(cell)
            except ValueError:
                continue
            if key == 'sugar' and value > row['per100g']['carbsG']:
                continue
            extras[key] = value
        evidence = dict(reviewedOn='2026-11-10', sourceSha256=SHA,
                        originalEnglish=row['english'], originalVietnamese=row['vietnamese'], cells=row['cells'])
        item = dict(id='vn2007-' + row['code'], name=selected['name'],
                    alternateNames=[], category=selected['category'],
                    sourceFoodCode=row['code'], sourcePdfPage=row['page'],
                    catalogVersion='vn-catalog-500-2026-11-10', per100g=row['per100g'],
                    compositionEvidence=evidence)
        if 11001 <= int(row['code']) <= 11021:
            item['packageLabel'] = 'đồ hộp tham khảo · nhập khối lượng (g)'
        if selected['category'] in ['Rau củ', 'Củ quả', 'Hạt và đậu', 'Ngũ cốc'] or row['code'] == '3002':
            item.update(dietaryClass='vegan', ingredientNames=[selected['name']], ingredientsKnown=True)
        if extras:
            item.update(extraNutrientsPer100g=extras, additionalNutrientEvidence=evidence)
        foods.append(item)
    assert len(foods) == 114 and len({f['id'] for f in foods}) == 114
    payload = dict(version='vn-catalog-500-2026-11-10', reviewedOn='2026-11-10',
                   sourceUrl=URL, sourceSha256=SHA,
                   basis='100 g phần ăn được theo trạng thái trong bảng; không quy đổi ml thành g.',
                   limitation='Dữ liệu tham khảo VDD 2007, không phải nhãn của sản phẩm đang bán. '
                              'Mục không nhãn hàng không đại diện cho một hãng cụ thể. '
                              'Bảng không nói rõ để ráo ở một số đồ hộp; không tự suy ra khối lượng ráo. '
                              'Không điền 0 vào ô thiếu; cellulose không phải tổng chất xơ.', foods=foods)
    (ROOT / 'data/food_catalog/expanded-vietnamese-2026-11-10.json').write_text(
        json.dumps(payload, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print('Materialized', len(foods), 'source rows; no cloud writes.')


if __name__ == '__main__':
    main()
