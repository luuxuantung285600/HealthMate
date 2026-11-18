"""Pinned Tabler outline/filled offline subset. Tooling fontTools only; no app dependency.
Build: python tool/build_app_icons.py (downloads verified pinned inputs to build/).
Verify: python tool/build_app_icons.py --verify
"""

import argparse, hashlib, json, re, urllib.request
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.merge import Merger

ROOT = Path(__file__).resolve().parent.parent
P = ROOT / "assets/fonts/healthmate_icons"
CACHE = ROOT / "build/tabler-ui/upstream"
DART = ROOT / "lib/core/theme/app_icons.dart"
BASE = "https://cdn.jsdelivr.net/npm/@tabler/icons-webfont@3.52.0/"
SOURCES = {
    "dist/fonts/tabler-icons.ttf": "cd4af77212fd4a83679362fb12c7e585078c2498719799d646e50518a5397cc6",
    "dist/fonts/tabler-icons-filled.ttf": "a8b79e93f01d01ec3626424ae44bf7c6461f0ce1919c3cd9dc452b6617930cc8",
    "dist/tabler-icons.css": "018366f7810b88ae9a032437e090c6ec4fb3a6570b6a33291d66f18274056884",
    "dist/tabler-icons-filled.css": "84695559714c8315f9f811c93b1839d0a89c994cba9694e7fad36e4e0e33fab7",
}
# All previous public aliases retained. Explicit semantic equivalents, no generic fallback.
GROUPS = {
    "activity": "activity heartPulse",
    "arrow-left": "arrowLeft",
    "arrows-left-right": "arrowLeftRight",
    "arrow-right": "arrowRight moveRight",
    "arrow-up-right": "arrowUpRight externalLink",
    "at": "atSign",
    "bell-slash": "bellOff",
    "bookmark-simple": "bookmarkMinus bookmarkPlus",
    "robot": "botMessageSquare chatbot",
    "heart": "brand",
    "bug": "bug",
    "cake": "cake",
    "calculator": "calculator",
    "calendar": "calendar",
    "calendar-dots": "calendarDays",
    "calendar-blank": "calendarRange",
    "fire": "calories flame",
    "camera": "camera",
    "camera-slash": "cameraOff",
    "grains": "carbs wheat",
    "chart-bar": "chartColumnIncreasing",
    "chart-line-up": "chartNoAxesCombined progress report trendingUp",
    "chart-pie": "chartPie",
    "check": "check",
    "caret-down": "chevronDown",
    "caret-left": "chevronLeft",
    "caret-right": "chevronRight",
    "caret-up": "chevronUp",
    "circle": "circle",
    "warning-circle": "circleAlert",
    "check-circle": "circleCheck",
    "minus-circle": "circleMinus",
    "play-circle": "circlePlay",
    "plus-circle": "circlePlus",
    "stop-circle": "circleStop",
    "clipboard-text": "clipboardCheck",
    "clock": "clock3",
    "cloud-warning": "cloudAlert",
    "cloud-check": "cloudCheck",
    "coffee": "coffee",
    "compass": "compass",
    "identification-card": "contactRound",
    "cookie": "cookie",
    "cooking-pot": "cookingPot recipes",
    "crown": "crown premium",
    "download-simple": "download",
    "drop": "droplet water",
    "barbell": "dumbbell workout",
    "dots-three": "ellipsis",
    "eye": "eye",
    "eye-slash": "eyeOff",
    "avocado": "fat",
    "note-pencil": "filePenLine squarePen",
    "file-text": "fileText notepadText",
    "flag": "flag goals quest",
    "footprints": "footprints steps",
    "headset": "headset support",
    "clock-counter-clockwise": "history",
    "house": "home house",
    "image": "image",
    "images": "images",
    "info": "info",
    "notebook": "journal notebookTabs",
    "key": "keyRound",
    "squares-four": "layoutGrid",
    "leaf": "leaf wellness",
    "lightbulb": "lightbulb",
    "lock-key": "lockKeyhole",
    "sign-out": "logOut",
    "envelope": "mail",
    "chat-circle-dots": "messageCirclePlus",
    "moon": "moon sleep",
    "note": "notebookPen",
    "bowl-food": "nutrition",
    "pause": "pause",
    "play": "play",
    "plus": "plus",
    "user-circle": "profile userRound",
    "egg-crack": "protein",
    "qr-code": "qrCode",
    "arrows-clockwise": "refreshCw",
    "rows": "rows3",
    "ruler": "ruler",
    "bread": "sandwich",
    "gauge": "scale weight",
    "barcode": "scanBarcode",
    "scan": "scanSearch scanner",
    "magnifying-glass": "search searchX",
    "paper-plane-tilt": "send",
    "gear-six": "settings2",
    "shield-check": "shieldCheck",
    "shopping-bag": "shoppingBag",
    "skip-forward": "skipForward",
    "sliders-horizontal": "slidersHorizontal",
    "device-mobile": "smartphone",
    "sparkle": "sparkles",
    "sun": "sun",
    "camera-rotate": "switchCamera",
    "timer": "timer",
    "trash": "trash2",
    "trend-down": "trendingDown",
    "warning": "triangleAlert",
    "user-gear": "userRoundCog",
    "fork-knife": "utensils",
    "vibrate": "vibrate",
    "video-camera": "video",
    "wrench": "wrench",
    "x": "x",
    "lightning": "zap",
    "lightning-slash": "zapOff",
}
# Translate the previous semantic aliases together; no per-screen icon fallback.
TABLER_NAMES = {
    "activity": "activity-heartbeat", "bell-slash": "bell-off",
    "bookmark-simple": "bookmark", "robot": "message-chatbot",
    "calendar-dots": "calendar-week", "calendar-blank": "calendar-event",
    "fire": "flame", "camera-slash": "camera-off", "grains": "wheat",
    "chart-line-up": "chart-area-line", "caret-down": "chevron-down",
    "caret-left": "chevron-left", "caret-right": "chevron-right",
    "caret-up": "chevron-up", "warning-circle": "alert-circle",
    "check-circle": "circle-check", "minus-circle": "circle-minus",
    "play-circle": "player-play", "plus-circle": "circle-plus",
    "stop-circle": "player-stop", "clipboard-text": "clipboard-check",
    "cloud-warning": "cloud-exclamation", "identification-card": "address-book",
    "cooking-pot": "cooker", "download-simple": "download", "drop": "droplet",
    "dots-three": "dots", "eye-slash": "eye-off", "note-pencil": "edit",
    "footprints": "footsteps", "clock-counter-clockwise": "history",
    "house": "home", "image": "photo", "images": "library-photo",
    "info": "info-circle", "notebook": "book", "squares-four": "layout-grid",
    "lightbulb": "bulb", "lock-key": "lock", "sign-out": "logout",
    "envelope": "mail", "chat-circle-dots": "message-circle-plus",
    "bowl-food": "bowl-spoon", "pause": "player-pause", "play": "player-play",
    "egg-crack": "egg", "qr-code": "qrcode", "arrows-clockwise": "refresh",
    "rows": "layout-rows", "ruler": "ruler-measure", "gauge": "scale-outline",
    "magnifying-glass": "search", "paper-plane-tilt": "send",
    "gear-six": "settings", "skip-forward": "player-skip-forward",
    "sliders-horizontal": "adjustments-horizontal", "sparkle": "sparkles",
    "timer": "stopwatch", "trend-down": "trending-down", "warning": "alert-triangle",
    "user-gear": "user-cog", "fork-knife": "tools-kitchen-2",
    "vibrate": "device-mobile-vibration", "video-camera": "video", "wrench": "tool",
    "lightning": "bolt", "lightning-slash": "bolt-off",
}
GROUPS = {TABLER_NAMES.get(name, name): aliases for name, aliases in GROUPS.items()}
# Preserve both playback aliases after merging the circle/play source shape.
GROUPS["player-play"] = "circlePlay play"
GROUPS.pop("bookmark")
GROUPS.update({"bookmark-minus": "bookmarkMinus", "bookmark-plus": "bookmarkPlus"})
GROUPS["flag"] = "flag"
GROUPS["target-arrow"] = "goals"
GROUPS["checklist"] = "quest"
SELECTED = {
    "homeSelected": "home",
    "journalSelected": "book",
    "workoutSelected": "barbell",
    "progressSelected": "chart-area-line",
}
RTL = set(
    "arrowLeft arrowRight arrowUpRight chevronLeft chevronRight logOut send skipForward moveRight".split()
)


def sha(b):
    return hashlib.sha256(b).hexdigest()


def fetch(name, url, expected=None):
    p = CACHE / name
    p.parent.mkdir(parents=True, exist_ok=True)
    if not p.exists():
        with urllib.request.urlopen(url, timeout=45) as r:
            p.write_bytes(r.read())
    if expected:
        assert sha(p.read_bytes()) == expected, "Unexpected upstream " + name
    return p


def verify():
    m = json.loads((P / "manifest.json").read_text(encoding="utf-8"))
    f = TTFont(P / "HealthMateIcons.ttf")
    c = f.getBestCmap()
    dart = DART.read_text(encoding="utf-8")
    assert sha((P / "HealthMateIcons.ttf").read_bytes()) == m["fontSha256"]
    assert sorted(c) == list(range(0xE000, 0xE000 + m["glyphCount"]))
    for name, icon in m["icons"].items():
        assert (
            icon["codePoint"] in c
            and f["glyf"][c[icon["codePoint"]]].numberOfContours != 0
        ), name
        assert re.search(
            rf'static const {name} = IconData\(\s*0x{icon["codePoint"]:x}\s*,', dart
        ), name
    assert all(
        m["icons"][n]["weight"] == "outline"
        for n in ["home", "journal", "workout", "progress"]
    )
    assert all(m["icons"][n]["weight"] == "filled" for n in SELECTED)
    assert m["upstream"]["name"] == "@tabler/icons-webfont"
    license = (P / "LICENSE.txt").read_text(encoding="utf-8")
    assert "MIT License" in license and "Kuna" in license
    assert sha((P / "LICENSE.txt").read_bytes()) == m["upstream"]["licenseSha256"]
    legacy_path = ROOT / "admin-web/dist/licenses/lucide-source.json"
    legacy = json.loads(legacy_path.read_text(encoding="utf-8"))
    assert set(legacy["icons"]) <= set(m["icons"]), "Missing legacy public alias"
    assert not any(
        re.search(r"\bIcons\.", p.read_text(encoding="utf-8"))
        for p in (ROOT / "lib").rglob("*.dart")
    ), "Unmigrated product icon"
    print(
        f'Verified {len(c)} distinct nonempty glyphs; {len(m["icons"])} aliases; contiguous remapped cmap, hashes and MIT license.'
    )


def build():
    CACHE.mkdir(parents=True, exist_ok=True)
    files = {n: fetch(n, BASE + n, h) for n, h in SOURCES.items()}
    license = fetch(
        "LICENSE",
        BASE + "LICENSE",
        "b740a1d46122672da62833e97f7e7c8a13fa85cbc7445b584b297cc00dde93db",
    ).read_text(encoding="utf-8")
    assert (
        "MIT License" in license and "Kuna" in license
    )
    specs = {
        alias: {"tabler": name, "weight": "outline"}
        for name, aliases in GROUPS.items()
        for alias in aliases.split()
    }
    specs.update(
        {
            alias: {"tabler": name, "weight": "filled"}
            for alias, name in SELECTED.items()
        }
    )
    pairs = sorted({(x["weight"], x["tabler"]) for x in specs.values()})
    codes = {pair: 0xE000 + i for i, pair in enumerate(pairs)}
    parts = []
    for weight, fontfile in [
        ("outline", "tabler-icons.ttf"),
        ("filled", "tabler-icons-filled.ttf"),
    ]:
        suffix = "-filled" if weight == "filled" else ""
        css = files[f"dist/tabler-icons{suffix}.css"].read_text(encoding="utf-8")
        mapping = {
            name: int(code, 16)
            for name, code in re.findall(
                r'\.ti-([a-z0-9-]+):before\s*\{\s*content: "\\([a-f0-9]+)";',
                css,
            )
        }
        font = TTFont(files["dist/fonts/" + fontfile], recalcTimestamp=False)
        cmap = font.getBestCmap()
        used = {name: mapping[name] for w, name in pairs if w == weight}
        opt = subset.Options()
        opt.recalc_timestamp = False
        opt.layout_features = []
        sub = subset.Subsetter(options=opt)
        sub.populate(unicodes=list(used.values()))
        sub.subset(font)
        new = {codes[(weight, name)]: cmap[code] for name, code in used.items()}
        for table in font["cmap"].tables:
            if table.isUnicode():
                table.cmap = dict(new)
        # Merger resolves duplicate glyph names while combining disjoint local codepoints.
        part = CACHE / (weight + "-subset.ttf")
        font.save(part)
        parts.append(str(part))
    merged = Merger().merge(parts)
    merged.recalcTimestamp = False
    merged["head"].created = merged["head"].modified = 2082844800
    for record in merged["name"].names:
        if record.nameID in [1, 4, 6]:
            record.string = "HealthMateIcons".encode(record.getEncoding())
    merged.save(P / "HealthMateIcons.ttf")
    (P / "LICENSE.txt").write_bytes((CACHE / "LICENSE").read_bytes())
    icons = {
        alias: {**spec, "codePoint": codes[(spec["weight"], spec["tabler"])]}
        for alias, spec in sorted(specs.items())
    }
    manifest = {
        "version": "healthmate-tabler-icons-2026-11-16",
        "upstream": {
            "name": "@tabler/icons-webfont",
            "version": "3.52.0",
            "url": "https://github.com/tabler/tabler-icons",
            "tarball": "https://registry.npmjs.org/@tabler/icons-webfont/-/icons-webfont-3.52.0.tgz",
            "license": "MIT",
            "licenseSha256": "b740a1d46122672da62833e97f7e7c8a13fa85cbc7445b584b297cc00dde93db",
            "sources": {
                n: {"url": BASE + n, "sha256": h} for n, h in SOURCES.items()
            },
        },
        "fontFamily": "HealthMateIcons",
        "fontAsset": "assets/fonts/healthmate_icons/HealthMateIcons.ttf",
        "fontSha256": sha((P / "HealthMateIcons.ttf").read_bytes()),
        "glyphCount": len(pairs),
        "icons": icons,
    }
    (P / "manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2) + "\n", encoding="utf-8"
    )
    lines = [
        "// Generated by tool/build_app_icons.py. Source and MIT license: assets/fonts/healthmate_icons/.",
        "import 'package:flutter/widgets.dart';",
        "",
        "/// Tabler outline actions and filled selected tabs, bundled offline.",
        "abstract final class AppIcons {",
        "  static const fontFamily = 'HealthMateIcons';",
    ]
    for alias, spec in icons.items():
        lines.append(
            f"  static const {alias} = IconData(0x{spec['codePoint']:x}, fontFamily: fontFamily"
            + (", matchTextDirection: true" if alias in RTL else "")
            + ");"
        )
    DART.write_text("\n".join(lines + ["}"]) + "\n", encoding="utf-8")
    print(
        f'Built {len(pairs)} glyphs, {len(icons)} aliases, {(P/"HealthMateIcons.ttf").stat().st_size} bytes.'
    )


if __name__ == "__main__":
    ap = argparse.ArgumentParser()
    ap.add_argument("--verify", action="store_true")
    args = ap.parse_args()
    if not args.verify:
        build()
    verify()
