"""Extract reviewed VDD rows. Local only; does not publish or change old foods.

Usage: python tool/expand_fruit_drink_catalog.py <official VDD 2007 PDF>
The SHA and separate value/reference columns prevent OCR/reference-number errors.
"""
import hashlib
import json
from pathlib import Path
import re
import sys

import pdfplumber

ROOT = Path(__file__).resolve().parent.parent
SHA = '6c4838ba5623df6d62b2bf4ef1a82968bbfad8a10980247c32b7e60c0c9ca281'
URL = 'https://www.fao.org/fileadmin/templates/food_composition/documents/pdf/VTN_FCT_2007.pdf'
# Code, 1-based PDF page, reviewed Vietnamese identity and search aliases.
ROWS = [
    (5003, 233, 'Chanh (tươi)', ['chanh', 'lemon']),
    (5005, 235, 'Chuối khô', ['chuối sấy', 'dried banana']),
    (5006, 236, 'Chuối tây (tươi)', ['chuối tây']),
    (5007, 237, 'Chuối tiêu (tươi)', ['chuối tiêu']),
    (5010, 240, 'Dưa bở (tươi)', ['dưa bở']),
    (5012, 242, 'Dưa hồng (tươi)', ['dưa hồng']),
    (5013, 243, 'Dưa lê (tươi)', ['dưa lê']),
    (5016, 246, 'Đào (tươi)', ['đào', 'peach']),
    (5020, 250, 'Hồng đỏ (tươi)', ['hồng đỏ', 'persimmon']),
    (5022, 252, 'Hồng xiêm (tươi)', ['hồng xiêm', 'sa pô chê', 'sapoche', 'sapodilla']),
    (5024, 254, 'Lựu (tươi)', ['lựu', 'pomegranate']),
    (5027, 257, 'Mận miền Bắc (tươi)', ['mận bắc', 'mận hậu', 'plum']),
    (5031, 261, 'Mơ (tươi)', ['mơ', 'apricot']),
    (5032, 262, 'Mơ khô', ['mơ sấy', 'dried apricot']),
    (5033, 263, 'Muỗm / quéo (xanh)', ['muỗm', 'quéo']),
    (5036, 266, 'Nhãn khô', ['long nhãn', 'dried longan']),
    (5041, 271, 'Bơ vỏ tím (tươi)', ['bơ tím', 'avocado']),
    (5045, 275, 'Quả trứng gà (lê ki ma)', ['lê ki ma', 'lekima', 'canistel']),
    (5050, 280, 'Táo ta (tươi)', ['táo ta', 'jujube']),
    (5051, 281, 'Táo tây (tươi, VDD 2007)', ['táo tây', 'apple']),
    (5053, 283, 'Vải khô', ['vải sấy', 'dried lychee']),
    (5056, 286, 'Kiwi (tươi, VDD 2007)', ['kiwi', 'kiwifruit']),
    (14005, 555, 'Nước cam tươi (VDD 2007)', ['nước cam', 'nước ép cam', 'orange juice']),
    (14006, 556, 'Nước dứa (VDD 2007)', ['nước thơm', 'nước ép dứa', 'pineapple juice']),
    (14007, 557, 'Nước ép cà chua (VDD 2007)', ['nước cà chua', 'tomato juice']),
    (14008, 558, 'Nước khoáng (VDD 2007)', ['nước lọc', 'mineral water']),
    (14009, 559, 'Nước quýt tươi (VDD 2007)', ['nước quýt', 'nước ép quýt', 'tangerine juice']),
]


def extract(pdf_path):
    if hashlib.sha256(pdf_path.read_bytes()).hexdigest() != SHA:
        raise ValueError('Unexpected PDF; review the source before extracting.')
    foods, withheld = [], []
    with pdfplumber.open(pdf_path) as pdf:
        for code, page, name, aliases in ROWS:
            words = pdf.pages[page - 1].extract_words()
            if not any(w['text'] == str(code) and w['top'] < 100 for w in words):
                raise ValueError(f'Source code/page mismatch: {code}/{page}')
            cells = {}
            for label, unit in [('Energy', 'kcal'), ('Protein', 'g'), ('Lipid', 'g'),
                                ('Glucid', 'g'), ('Sugar', 'g'), ('Sodium', 'mg')]:
                row = next(w for w in words if label.lower() in w['text'].lower() and w['x0'] < 205)
                top = (next(w for w in words if w['text'].lower() == 'kcal' and w['x0'] < 220)
                       if label == 'Energy' else row)['top']
                value = ' '.join(w['text'] for w in words if 225 < w['x0'] < 268 and abs(w['top'] - top) < 3)
                ref = ' '.join(w['text'] for w in words if 275 < w['x0'] < 292 and abs(w['top'] - top) < 3)
                cells[label] = {'valueCell': value, 'referenceCell': ref, 'unit': unit}
            def number(label):
                value = cells[label]['valueCell']
                return float(value) if re.fullmatch(r'\d+(?:\.\d+)?', value) else None
            per100g = {key: number(label) for key, label in
                       [('kcal', 'Energy'), ('proteinG', 'Protein'), ('carbsG', 'Glucid'), ('fatG', 'Lipid')]}
            if any(value is None for value in per100g.values()):
                raise ValueError(f'Incomplete macros: {code}')
            extras = {key: number(label) for key, label in [('sodium', 'Sodium'), ('sugar', 'Sugar')]
                      if number(label) is not None}
            # Mixed source references can contain more sugar than total carbs.
            # Retain the source cells in evidence but do not publish that sugar.
            if extras.get('sugar', 0) > per100g['carbsG']:
                withheld.append({'id': f'vn2007-{code}', 'nutrient': 'sugar',
                                 'reason': 'source_sugar_exceeds_total_carbohydrate', 'cells': cells})
                del extras['sugar']
            evidence = {'reviewedOn': '2026-11-10', 'sourceSha256': SHA, 'cells': cells}
            foods.append({'id': f'vn2007-{code}', 'name': name, 'alternateNames': aliases,
                          'category': 'Trái cây' if code < 10000 else 'Đồ uống',
                          'dietaryClass': 'vegan', 'ingredientNames': [name], 'ingredientsKnown': True,
                          'sourceFoodCode': str(code), 'sourcePdfPage': page, 'per100g': per100g,
                          'compositionEvidence': evidence,
                          **({'extraNutrientsPer100g': extras, 'additionalNutrientEvidence': evidence} if extras else {})})
    return {'sourceTitle': 'Viện Dinh dưỡng, Bảng thành phần thực phẩm Việt Nam (2007)',
            'sourceUrl': URL, 'basis': '100 g phần ăn được, không tính vỏ/hạt bỏ đi; không quy đổi ml thành g',
            'reviewedOn': '2026-11-10', 'sourceSha256': SHA,
            'limitations': ['Giá trị tham khảo, không phải phép đo của quả/đồ uống cụ thể.',
                           'Không coi cellulose là tổng chất xơ; không thay ô thiếu bằng 0.',
                           'Chưa thêm cóc (5043), thanh long (5044), vú sữa (5054): bảng thiếu lipid.'],
            'withheldNutrients': withheld, 'foods': foods}


if __name__ == '__main__':
    result = extract(Path(sys.argv[1]))
    (ROOT / 'data/food_catalog/fruits-drinks-2026-11-10.json').write_text(
        json.dumps(result, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
    print(f"Extracted {len(result['foods'])} foods; withheld {len(result['withheldNutrients'])} inconsistent sugar cells.")
