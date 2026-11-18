"""Build an offline catalog from the public USDA SR Legacy CSV archive.

Usage: python tool/import_usda_bundle.py path/to/official-2018-archive.zip
No API key, third-party packages, network requests or Firestore writes.
"""
import argparse
import csv
import hashlib
import io
import json
import math
from pathlib import Path
import re
import unicodedata
import zipfile
from usda_vietnamese import vietnamese_name, HEADS

ROOT = Path(__file__).resolve().parent.parent
SOURCE_URL = "https://fdc.nal.usda.gov/fdc-datasets/FoodData_Central_sr_legacy_food_csv_2018-04.zip"
SOURCE_SHA256 = "b80817294b8850530aaedf2e515c02593b1824f763a0ff356e5c2081643e6fd0"
NUTRIENTS = {
    "1008": "kcalPer100g", "1003": "proteinGPer100g",
    "1005": "carbsGPer100g", "1004": "fatGPer100g", "1079": "fiberGPer100g",
    "2000": "sugar", "1258": "saturatedFat", "1093": "sodium",
    "1092": "potassium", "1087": "calcium", "1089": "iron",
    "1162": "vitaminC", "1253": "cholesterol",
}
CORE = ("kcalPer100g", "proteinGPer100g", "carbsGPer100g", "fatGPer100g")
CATEGORIES = {
    "1": "Sữa và trứng", "2": "Gia vị", "4": "Dầu và chất béo",
    "5": "Gia cầm", "6": "Súp và nước sốt", "7": "Thịt chế biến",
    "8": "Ngũ cốc ăn sáng", "9": "Trái cây", "10": "Thịt heo",
    "11": "Rau củ", "12": "Hạt và đậu", "13": "Thịt bò",
    "14": "Đồ uống", "15": "Hải sản", "16": "Hạt và đậu",
    "17": "Thịt khác", "18": "Bánh", "19": "Đồ ngọt",
    "20": "Ngũ cốc", "21": "Đồ ăn nhanh", "22": "Món chế biến",
    "23": "Đồ ăn vặt", "24": "Món quốc tế", "25": "Món nhà hàng",
}
# Search aliases only. Original English descriptions remain visible and cited;
# aliases never change food state, nutrient values or product identity.
TERMS = {
    "chicken": "thịt gà", "turkey": "gà tây", "duck": "thịt vịt",
    "beef": "thịt bò", "pork": "thịt heo thịt lợn", "lamb": "thịt cừu",
    "veal": "thịt bê", "goat": "thịt dê", "rabbit": "thịt thỏ",
    "breast": "ức", "thigh": "đùi", "wing": "cánh", "liver": "gan",
    "salmon": "cá hồi", "tuna": "cá ngừ", "tilapia": "cá rô phi",
    "catfish": "cá da trơn", "mackerel": "cá thu", "sardine": "cá mòi",
    "cod": "cá tuyết", "shrimp": "tôm", "crab": "cua", "squid": "mực",
    "clam": "nghêu sò", "oyster": "hàu", "lobster": "tôm hùm",
    "egg": "trứng", "eggs": "trứng", "milk": "sữa", "yogurt": "sữa chua",
    "cheese": "phô mai", "butter": "bơ sữa", "cream": "kem sữa",
    "rice": "gạo cơm", "brown rice": "gạo lứt cơm gạo lứt",
    "oat": "yến mạch", "oats": "yến mạch", "wheat": "lúa mì",
    "corn": "ngô bắp", "bread": "bánh mì", "noodles": "mì bún",
    "pasta": "mì ý nui", "spaghetti": "mì ý", "quinoa": "hạt diêm mạch",
    "barley": "lúa mạch", "buckwheat": "kiều mạch", "flour": "bột",
    "potato": "khoai tây", "potatoes": "khoai tây", "sweet potato": "khoai lang",
    "carrot": "cà rốt", "carrots": "cà rốt", "tomato": "cà chua",
    "tomatoes": "cà chua", "cucumber": "dưa leo dưa chuột",
    "spinach": "rau bina cải bó xôi", "broccoli": "bông cải xanh súp lơ",
    "cabbage": "bắp cải", "lettuce": "xà lách", "mushroom": "nấm",
    "mushrooms": "nấm", "onion": "hành tây", "onions": "hành tây",
    "garlic": "tỏi", "ginger": "gừng", "pumpkin": "bí đỏ",
    "eggplant": "cà tím", "celery": "cần tây", "okra": "đậu bắp",
    "banana": "chuối", "bananas": "chuối", "apple": "táo", "apples": "táo",
    "orange": "cam", "oranges": "cam", "mango": "xoài", "mangos": "xoài",
    "pineapple": "dứa thơm", "papaya": "đu đủ", "watermelon": "dưa hấu",
    "grape": "nho", "grapes": "nho", "avocado": "quả bơ",
    "avocados": "quả bơ", "strawberry": "dâu tây", "strawberries": "dâu tây",
    "blueberry": "việt quất", "blueberries": "việt quất", "kiwi": "kiwi",
    "lemon": "chanh vàng", "lime": "chanh", "peach": "đào", "pear": "lê",
    "pears": "lê", "plum": "mận", "coconut": "dừa", "guava": "ổi",
    "tofu": "đậu phụ đậu hũ tàu hũ", "soybean": "đậu nành",
    "soybeans": "đậu nành", "lentils": "đậu lăng", "chickpeas": "đậu gà",
    "peanuts": "đậu phộng lạc", "almonds": "hạnh nhân", "walnuts": "óc chó",
    "cashew": "hạt điều", "cashews": "hạt điều", "sesame": "mè vừng",
    "chia": "hạt chia", "flaxseed": "hạt lanh", "sunflower": "hướng dương",
    "olive": "ô liu", "oil": "dầu", "sugar": "đường", "honey": "mật ong",
    "coffee": "cà phê", "tea": "trà chè", "juice": "nước ép",
    "raw": "sống", "cooked": "chín", "boiled": "luộc", "steamed": "hấp",
    "roasted": "nướng", "fried": "chiên rán", "dried": "khô sấy",
    "canned": "đóng hộp", "frozen": "đông lạnh", "unsweetened": "không đường",
}
MEAT = re.compile(r"\b(beef|pork|chicken|turkey|duck|goose|lamb|veal|venison|goat|rabbit|meat|fish|anchov\w*|salmon|tuna|shrimp|prawn|crab|lobster|oyster|clam|scallop|mussel|gelatin|lard|tallow|suet|bacon|ham|broth|bouillon)\b", re.I)
DAIRY = re.compile(r"\b(milk|cream|butter|cheese|whey|casein|egg\w*|yogurt|yoghurt|honey)\b", re.I)
PLANT_RECIPES = {
    "vn-rice-base", "vn-bun-tuoi", "vn-com-gao-lut", "vn-xoi-trang",
    "vn-xoi-dau-xanh", "vn-mien-xao-rau", "vn-chao-dau-xanh", "vn-dau-sot-ca",
    "vn-rau-muong-luoc", "vn-rau-muong-xao", "vn-che-dau-xanh", "vn-che-dau-den",
    "vn-com-dau-rau", "vn-bun-dau-rau",
}


def normalized(value):
    return " ".join(unicodedata.normalize("NFKC", value).casefold().split())


def dietary_class(description, category):
    """Conservative source-category classification; mixed/unclear stays unknown."""
    if category in {"5", "7", "10", "13", "15", "17"} or MEAT.search(description):
        return "nonVegetarian"
    if re.search(r"\b(gel|rennet|enzyme|marshmallow|dressing|sauce|soup)\b", description, re.I):
        return "unknown"
    if category == "1" and re.match(r"^(milk|egg|butter|yogurt|yoghurt|cream|buttermilk|kefir|whey)\b", description, re.I):
        return "vegetarian"
    if DAIRY.search(description):
        return "unknown"
    if re.search(r"\b(fried|refried|breaded|battered|souffle|patties|fritter|gravy|mixed dishes|burger\w*|soyburger\w*|meatless|substitute\w*|coated|glazed|candied|chocolate|flavored|flavoured|puffs|hummus|falafel|yokan)\b|beans, baked|home[ -]prepared", description, re.I):
        return "unknown"
    if category in {"2", "9", "12", "16"}:
        return "vegan"
    if category == "11" and re.search(r"\b(raw|cooked|dried|canned|frozen)\b", description, re.I):
        return "vegan"
    if category == "4" and description.lower().startswith("oil,"):
        return "vegan"
    if category == "20" and not re.search(r"pasta|noodle|bread|mix|prepared", description, re.I):
        return "vegan"
    return "unknown"


def portion(row):
    """Normalize source amount to one unit without inventing a gram weight."""
    try:
        amount, weight = float(row["amount"]), float(row["gram_weight"])
    except (ValueError, KeyError):
        return None
    if not (math.isfinite(amount) and math.isfinite(weight) and amount > 0 and weight > 0):
        return None
    grams = weight / amount
    label = (row.get("modifier") or row.get("portion_description") or "").strip()
    if not label or not 0 < grams <= 2000 or re.search(r"yield|refuse|bone|shell|purchase", label, re.I):
        return None
    translations = {"cup": "cốc USDA", "tbsp": "muỗng canh USDA", "tsp": "muỗng cà phê USDA", "slice": "lát", "piece": "miếng", "serving": "phần USDA", "large": "cỡ lớn", "medium": "cỡ vừa", "small": "cỡ nhỏ", "whole": "nguyên phần", "oz": "oz USDA"}
    for term, vi in translations.items():
        label = re.sub(r"\b" + term + r"\b", lambda _: vi, label, flags=re.I)
    label = label[:60]
    return {"servingLabel": label, "servingGrams": round(grams, 6), "defaultServingGrams": round(grams, 6),
            "portionSource": {"foodPortionId": int(row["id"]), "amount": amount, "gramWeight": weight,
                              "description": row.get("modifier") or row.get("portion_description")}}


def local_diets():
    source = json.loads((ROOT / "data/food_catalog/ingredients.json").read_text(encoding="utf-8"))
    recipes = json.loads((ROOT / "data/food_catalog/recipes.json").read_text(encoding="utf-8"))
    definitions = {f["id"]: f for f in source["foods"] + recipes["recipes"]}
    memo = {}

    def classify(key):
        key = f"vn2007-{key}" if key.isdigit() else key
        if key in memo:
            return memo[key]
        item = definitions.get(key)
        if not item:
            return "unknown"
        name, group = item["name"], item["category"]
        if "ingredients" in item:
            kinds = {classify(str(i)) for i, _ in item["ingredients"]}
            result = "nonVegetarian" if "nonVegetarian" in kinds else "unknown"
            if key in PLANT_RECIPES and kinds == {"vegan"}:
                result = "vegan"
            if key in {"vn-chao-trung", "vn-com-chien-trung"} and kinds <= {"vegan", "vegetarian"}:
                result = "vegetarian"
        elif key == "vn2007-3032":
            result = "vegan"  # Source row is unsweetened soy milk.
        elif "phô mai" in name.lower():
            result = "unknown"  # The source does not identify the rennet.
        elif name.lower().startswith(("trứng", "bơ động vật")) or group == "Sữa và chế phẩm":
            result = "vegetarian"
        elif group in {"Thịt và trứng", "Hải sản"}:
            result = "nonVegetarian"
        elif group in {"Rau củ", "Củ quả", "Trái cây", "Hạt và đậu", "Dầu và chất béo"}:
            result = "vegan"
        elif group == "Ngũ cốc" and (re.match(r"^(gạo|ngô|bột|miến|yến|khoai)", name, re.I) or key == "vn2007-1013"):
            result = "vegan"
        elif group == "Gia vị" and re.match(r"^(đường|muối)", name, re.I):
            result = "vegan"
        else:
            result = "unknown"
        memo[key] = result
        return result

    for key in definitions:
        classify(key)
    memo.update({"apple-raw-skin": "vegan", "banana-raw": "vegan", "rice-cooked": "vegan", "egg-boiled": "vegetarian"})
    return memo


def local_ingredients():
    source = json.loads((ROOT / 'data/food_catalog/ingredients.json').read_text(encoding='utf-8'))['foods']
    recipes = json.loads((ROOT / 'data/food_catalog/recipes.json').read_text(encoding='utf-8'))['recipes']
    definitions = {f['id']: f for f in source + recipes}
    memo = {}
    def resolve(key):
        key = f'vn2007-{key}' if key.isdigit() else key
        if key in memo: return memo[key]
        f = definitions.get(key)
        if not f: return {'ingredientNames': [], 'ingredientsKnown': False}
        if 'ingredients' in f:
            children = [resolve(str(ref)) for ref, grams in f['ingredients']]
            names = list(dict.fromkeys(n for child in children for n in child['ingredientNames']))
            known = all(child['ingredientsKnown'] for child in children)
        else:
            names = [f['name']]
            # Processed reference foods lack a full product ingredient list.
            known = not any(word in f['name'].lower() for word in ('sản phẩm', 'xúc xích', 'phô mai', 'sữa chua', 'pa tê', 'chả lụa', 'lạp xưởng', 'nem chua', 'quẩy', 'bánh mì', 'bánh đúc', 'mì sợi', 'dầu ăn thực vật'))
        memo[key] = {'ingredientNames': names, 'ingredientsKnown': known}
        return memo[key]
    for key in definitions: resolve(key)
    for key, name in {'apple-raw-skin':'Táo', 'banana-raw':'Chuối', 'rice-cooked':'Gạo', 'egg-boiled':'Trứng'}.items():
        memo[key] = {'ingredientNames':[name], 'ingredientsKnown':True}
    return memo


def source_ingredients_known(description, category):
    # A plain reference composition can be screened. Mixed/processed products
    # lack a complete ingredient list in SR Legacy, so remain unknown.
    if re.search(r'\b(with|mix|mixed|prepared|fried|breaded|battered|sauce|soup|burger|puffs|flavor\w*|sweetened|fortified)\b', description, re.I):
        return False
    return category in {'9','11','12','16','20'} and dietary_class(description, category) == 'vegan'


def build(archive_path):
    digest = hashlib.sha256(archive_path.read_bytes()).hexdigest()
    if digest != SOURCE_SHA256:
        raise ValueError("Archive differs from the reviewed USDA download; review the source before importing.")
    with zipfile.ZipFile(archive_path) as archive:
        prefix = "FoodData_Central_sr_legacy_food_csv_2018-04/"

        def rows(name):
            with archive.open(prefix + name) as raw:
                yield from csv.DictReader(io.TextIOWrapper(raw, encoding="utf-8-sig", newline=""))

        foods = {r["fdc_id"]: r for r in rows("food.csv") if r["data_type"] == "sr_legacy_food" and r["food_category_id"] in CATEGORIES}
        values = {}
        for row in rows("food_nutrient.csv"):
            field = NUTRIENTS.get(row["nutrient_id"])
            if row["fdc_id"] not in foods or not field:
                continue
            try:
                value = float(row["amount"])
            except ValueError:
                continue
            if math.isfinite(value) and value >= 0:
                values.setdefault(row["fdc_id"], {})[field] = value
        portions = {}
        for row in rows("food_portion.csv"):
            if row["fdc_id"] in foods and row["fdc_id"] not in portions:
                choice = portion(row)
                if choice:
                    portions[row["fdc_id"]] = choice

    existing = json.loads((ROOT / "assets/nutrition/vietnamese-foods.json").read_text(encoding="utf-8"))["foods"]
    # Preserve existing Vietnamese/reference IDs and prevent duplicate source records.
    existing_fdc = {str(f.get("sourceDetails", {}).get("fdcId")) for f in existing}
    names = {normalized(f["name"]) for f in existing}
    result, excluded = [], {}
    for fdc_id, row in sorted(foods.items(), key=lambda pair: int(pair[0])):
        data = values.get(fdc_id, {})
        reason = None
        if fdc_id in existing_fdc:
            reason = "existing_source_record"
        elif not all(k in data for k in CORE):
            reason = "missing_core_nutrient"
        elif data["kcalPer100g"] > 1000 or any(data[k] > 100 for k in CORE[1:]) or sum(data[k] for k in CORE[1:]) > 101:
            reason = "outside_catalog_bounds"
        elif normalized(row["description"]) in names:
            reason = "duplicate_description"
        if reason:
            excluded[reason] = excluded.get(reason, 0) + 1
            continue
        original = row["description"].strip()
        names.add(normalized(original))
        aliases = []
        words = [vi for term, vi in TERMS.items() if re.search(r"\b" + re.escape(term) + r"\b", original, re.I)]
        if words:
            # Keep Vietnamese query terms together so multiword searches work.
            aliases.append(" ".join(dict.fromkeys(" ".join(words).split()))[:100])
        full_name = vietnamese_name(original, CATEGORIES[row['food_category_id']], fdc_id)
        food = {
            "id": f"usda-sr-{fdc_id}", "fdcId": int(fdc_id), "name": full_name,
            "alternateNames": [original[:100], *aliases], "originalName": original,
            "ingredientNames": [original],
            "ingredientsKnown": source_ingredients_known(original, row['food_category_id']),
            "category": CATEGORIES[row["food_category_id"]],
            "servingBasis": "per_100g", "unit": "g",
            **{key: data[key] for key in CORE}, "isEstimated": True,
            "sourceLabel": f"USDA SR Legacy 2018 · FDC {fdc_id}",
            "sourceUrl": f"https://fdc.nal.usda.gov/food-details/{fdc_id}/nutrients",
            "dietaryClass": dietary_class(original, row["food_category_id"]),
            "sourceDetails": {"method": "usda_sr_legacy", "fdcId": int(fdc_id), "description": original, "basis": "per_100g"},
        }
        if "fiberGPer100g" in data and data["fiberGPer100g"] <= 100:
            food["fiberGPer100g"] = data["fiberGPer100g"]
        extras = {key: value for key, value in data.items() if key not in (*CORE, "fiberGPer100g")}
        if extras:
            food["extraNutrientsPer100g"] = extras
        if fdc_id in portions:
            food.update(portions[fdc_id])
        result.append(food)
    from food_browse_metadata import apply_browse_metadata
    apply_browse_metadata(result)
    metadata = {
        "version": "usda-sr-legacy-2018-healthmate-2026-10-27",
        "sourceUrl": SOURCE_URL, "archiveSha256": digest, "license": "USDA public domain",
        "release": "SR Legacy April 2018 (final historical release)",
        "note": "Reference composition per 100 g edible portion; not a measurement of a particular meal or current product label. Original food descriptions and states are retained. Dietary classes are conservative ingredient/category screening, not certification or allergy advice.",
        "localDietaryClass": local_diets(), "localIngredients": local_ingredients(), "foods": result,
    }
    destination = ROOT / "assets/nutrition/usda-sr-legacy.json"
    destination.write_text(json.dumps(metadata, ensure_ascii=False, separators=(",", ":")) + "\n", encoding="utf-8")
    report = {"sourceUrl": SOURCE_URL, "archiveSha256": digest, "sourceFoodsInAdultCategories": len(foods),
              "addedFoods": len(result), "originalFoods": len(existing), "bundledTotal": len(existing) + len(result),
              "addedWithPortion": sum("servingGrams" in f for f in result), "excluded": excluded,
              "assetBytes": destination.stat().st_size,
              "vietnameseHeadMatched": sum(f['originalName'].split(',')[0].strip().lower() in HEADS for f in result),
              "vietnameseDisplayNames": len(result),
              "dietaryCounts": {kind: sum(f["dietaryClass"] == kind for f in result) for kind in ("vegan", "vegetarian", "nonVegetarian", "unknown")}}
    (ROOT / "data/food_catalog/usda-import-manifest.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return report


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("archive", type=Path)
    print(json.dumps(build(parser.parse_args().archive), ensure_ascii=False, indent=2))
