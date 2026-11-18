"""Cache exact VDD 2007 value cells for manual selection; no product writes."""
import hashlib
import json
from pathlib import Path
import re
import pdfplumber

ROOT = Path(__file__).resolve().parent.parent
SHA = '6c4838ba5623df6d62b2bf4ef1a82968bbfad8a10980247c32b7e60c0c9ca281'


def main():
    source = ROOT / 'build/vietnam-food-composition-2007.pdf'
    assert hashlib.sha256(source.read_bytes()).hexdigest() == SHA
    dest = ROOT / 'build/catalog-500-research/vdd-all-rows.json'
    out = json.loads(dest.read_text(encoding='utf-8')) if dest.exists() else []
    done = {row['page'] for row in out}
    with pdfplumber.open(source) as pdf:
        for page in range(13, len(pdf.pages)):
            if page + 1 in done:
                continue
            pg = pdf.pages[page]
            words = pg.extract_words()
            code = next((w['text'] for w in words if re.fullmatch(r'\d{4,5}', w['text']) and w['top'] < 100), None)
            if not code:
                continue
            lines = pg.extract_text().splitlines()
            english = next((s for s in lines if '(English)' in s), '')
            vietnamese = next((s for s in lines if '(Vietnamese)' in s), '')
            cells = {}
            for label, unit in [('Energy', 'kcal'), ('Protein', 'g'), ('Lipid', 'g'),
                                ('Glucid', 'g'), ('Sugar', 'g'), ('Sodium', 'mg')]:
                row = next((w for w in words if label.lower() in w['text'].lower() and w['x0'] < 205), None)
                if not row:
                    break
                top = next(w for w in words if w['text'].lower() == 'kcal' and w['x0'] < 220)['top'] if label == 'Energy' else row['top']
                value = ' '.join(w['text'] for w in words if 225 < w['x0'] < 268 and abs(w['top'] - top) < 3)
                ref = ' '.join(w['text'] for w in words if 275 < w['x0'] < 292 and abs(w['top'] - top) < 3)
                cells[label] = dict(valueCell=value, referenceCell=ref, unit=unit)
            if len(cells) != 6:
                continue
            def number(label):
                value = cells[label]['valueCell']
                return float(value) if re.fullmatch(r'\d+(?:\.\d+)?', value) else None
            values = {key: number(label) for key, label in [('kcal', 'Energy'), ('proteinG', 'Protein'),
                                                           ('carbsG', 'Glucid'), ('fatG', 'Lipid')]}
            out.append(dict(code=code, page=page + 1, english=english, vietnamese=vietnamese, per100g=values, cells=cells))
            if len(out) % 25 == 0:
                dest.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
                print('Cached rows', len(out), flush=True)
    dest.write_text(json.dumps(out, ensure_ascii=False, indent=2), encoding='utf-8')
    print('Cached rows', len(out), flush=True)


if __name__ == '__main__':
    main()
