from __future__ import annotations

from pathlib import Path
from urllib.parse import urlencode
from urllib.request import Request, urlopen
import json
import re
import time

ROOT = Path(__file__).resolve().parents[1]
LIB = ROOT / "lib"
GENERATED = LIB / "l10n" / "generated_translations.dart"
STATS = ROOT / "tools" / "l10n_stats.json"

TARGETS = {
    "en": "en",
    "es": "es",
    "fr": "fr",
    "de": "de",
    "pt": "pt",
    "ru": "ru",
    "zh": "zh-CN",
    "ja": "ja",
    "ko": "ko",
    "ar": "ar",
    "hi": "hi",
}

SOURCE_DIRS = ("screens", "widgets", "services", "models")
SKIP_FILES = {
    "lib/services/finance_schema_service.dart",
    "lib/services/data_integrity_service.dart",
}

STRING_RE = re.compile(r"""(?P<q>['"])(?P<s>(?:\\.|(?!\1).)*?)(?P=q)""")
PLACEHOLDER_RE = re.compile(r"\$\{[^{}]*\}|\$[A-Za-z_][A-Za-z0-9_]*")
SQL_RE = re.compile(r"^(SELECT|INSERT|UPDATE|DELETE|CREATE|ALTER|DROP|PRAGMA|WITH)\b", re.I)
IDENTIFIER_RE = re.compile(r"^[a-z0-9_./:@-]+$")
REGEXY_RE = re.compile(r"(?:\\[bdsw]|\(\?:|\[\^|\{\d|\?=|\?!)")

ENGLISH_OVERRIDES = {
    "Entrata": "Income",
    "Entrate": "Income",
    "Spesa": "Expense",
    "Spese": "Expenses",
    "Movimento": "Transaction",
    "Movimenti": "Transactions",
    "Nuovo movimento": "New transaction",
    "Modifica movimento": "Edit transaction",
    "Ultimi movimenti": "Recent transactions",
    "Conto": "Account",
    "Conti": "Accounts",
    "Saldo": "Balance",
    "Categorie": "Categories",
    "Categoria": "Category",
    "Trasferimento": "Transfer",
    "Trasferimenti": "Transfers",
    "Anticipo": "IOU",
    "Anticipi": "IOUs",
    "Pianifica": "Plan",
    "Non assegnato": "Unassigned",
    "Impostazioni": "Settings",
    "Analisi": "Analytics",
    "Valuta principale": "Primary currency",
    "Lingua": "Language",
}

def human_candidate(s: str, *, dynamic_fragment: bool = False) -> bool:
    value = s.strip()
    if len(value) < 2:
        return False
    if value.startswith(("package:", "dart:", "assets/", "android/", "http://", "https://")):
        return False
    if SQL_RE.match(value):
        return False
    if REGEXY_RE.search(value):
        return False
    if value in {"TEXT", "INTEGER", "REAL", "BLOB", "NULL", "ASC", "DESC"}:
        return False
    if re.fullmatch(r"[A-Z0-9_ .:+\-/]+", value) and not re.search(r"[À-ÿ]", value):
        if len(value.split()) <= 2:
            return False
    if IDENTIFIER_RE.fullmatch(value) and value.lower() == value:
        return False
    if not re.search(r"[A-Za-zÀ-ÿА-Яа-я]", value):
        return False
    if any(token in value for token in (" = ?", "_id", "sqlite", "com.dadafinanza", "dadafinanza/")):
        return False
    if dynamic_fragment and len(value) < 4:
        return False
    return (
        " " in value
        or value[:1].isupper()
        or re.search(r"[À-ÿ]", value) is not None
        or any(ch in value for ch in "?!…“”’")
    )

def source_files() -> list[Path]:
    files: list[Path] = []
    for path in LIB.rglob("*.dart"):
        rel = path.relative_to(ROOT).as_posix()
        if rel.startswith("lib/l10n/") or rel in SKIP_FILES:
            continue
        if rel in {"lib/main.dart", "lib/app_state.dart"}:
            files.append(path)
            continue
        parts = path.relative_to(LIB).parts
        if parts and parts[0] in SOURCE_DIRS:
            files.append(path)
    return sorted(files)

def extract_phrases() -> tuple[set[str], set[str]]:
    exact: set[str] = set()
    fragments: set[str] = set()
    for path in source_files():
        for line in path.read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if stripped.startswith(("import ", "export ", "part ")):
                continue
            for match in STRING_RE.finditer(line):
                raw = match.group("s")
                value = raw.replace(r"\'", "'").replace(r'\"', '"')
                if "$" not in value:
                    if human_candidate(value):
                        exact.add(value)
                    continue
                simplified = PLACEHOLDER_RE.sub("\u0000", value)
                for piece in simplified.split("\u0000"):
                    piece = piece.strip(" \t\n·:;,.()[]{}+-→")
                    if human_candidate(piece, dynamic_fragment=True):
                        fragments.add(piece)
    fragments.difference_update(exact)
    return exact, fragments

def request_translation(text: str, source: str, target: str) -> str:
    if not text:
        return text
    query = urlencode({
        "client": "gtx",
        "sl": source,
        "tl": target,
        "dt": "t",
        "q": text,
    })
    req = Request(
        "https://translate.googleapis.com/translate_a/single?" + query,
        headers={"User-Agent": "Mozilla/5.0 DadaFinanza-l10n"},
    )
    for attempt in range(5):
        try:
            with urlopen(req, timeout=35) as response:
                payload = json.loads(response.read().decode("utf-8"))
            result = "".join(
                chunk[0] for chunk in payload[0] if chunk and chunk[0]
            ).strip()
            return result or text
        except Exception:
            if attempt == 4:
                raise
            time.sleep(1.5 * (attempt + 1))
    return text

def translate_many(values: list[str], source: str, target: str) -> list[str]:
    if not values:
        return []
    marker = " DADAFINANZAQQSPLITQQ "
    result: list[str] = []
    index = 0
    while index < len(values):
        chunk: list[str] = []
        chars = 0
        while index < len(values) and len(chunk) < 18:
            candidate = values[index]
            projected = chars + len(candidate) + len(marker)
            if chunk and projected > 2800:
                break
            chunk.append(candidate)
            chars = projected
            index += 1
        joined = marker.join(chunk)
        translated = request_translation(joined, source, target)
        parts = [part.strip() for part in translated.split(marker)]
        if len(parts) != len(chunk):
            parts = [request_translation(item, source, target) for item in chunk]
        result.extend(parts)
        time.sleep(0.08)
    return result

def fix_english(source: str, translated: str) -> str:
    if source in ENGLISH_OVERRIDES:
        return ENGLISH_OVERRIDES[source]
    value = translated
    value = re.sub(r"\bmovements\b", "transactions", value, flags=re.I)
    value = re.sub(r"\bmovement\b", "transaction", value, flags=re.I)
    value = re.sub(r"\bentries\b", "income", value, flags=re.I)
    value = re.sub(r"\bentry\b", "income", value, flags=re.I)
    return value

def build_maps(values: list[str]) -> dict[str, dict[str, str]]:
    english_raw = translate_many(values, "it", "en")
    english = [fix_english(src, dst) for src, dst in zip(values, english_raw)]
    maps: dict[str, dict[str, str]] = {
        "en": dict(zip(values, english)),
    }
    for code, target in TARGETS.items():
        if code == "en":
            continue
        translated = translate_many(english, "en", target)
        maps[code] = dict(zip(values, translated))
    return maps

def dart_string(value: str) -> str:
    encoded = json.dumps(value, ensure_ascii=False)
    encoded = encoded.replace("$", r"\$")
    return encoded

def write_generated(
    exact_maps: dict[str, dict[str, str]],
    phrase_maps: dict[str, dict[str, str]],
) -> None:
    lines = [
        "// GENERATED FILE. Run tools/generate_l10n.py to refresh.",
        "",
        "const Map<String, Map<String, String>> generatedTranslations =",
        "    <String, Map<String, String>>{",
    ]
    for code in TARGETS:
        mapping = exact_maps.get(code, {})
        lines.append(f"  {dart_string(code)}: <String, String>{{")
        for source in sorted(mapping, key=str.casefold):
            target = mapping[source]
            if target == source:
                continue
            lines.append(
                f"    {dart_string(source)}: {dart_string(target)},"
            )
        lines.append("  },")
    lines.extend([
        "};",
        "",
        "const Map<String, Map<String, String>> generatedPhraseTranslations =",
        "    <String, Map<String, String>>{",
    ])
    for code in TARGETS:
        mapping = phrase_maps.get(code, {})
        lines.append(f"  {dart_string(code)}: <String, String>{{")
        for source in sorted(mapping, key=str.casefold):
            target = mapping[source]
            if target == source:
                continue
            lines.append(
                f"    {dart_string(source)}: {dart_string(target)},"
            )
        lines.append("  },")
    lines.extend(["};", ""])
    GENERATED.parent.mkdir(parents=True, exist_ok=True)
    GENERATED.write_text("\n".join(lines), encoding="utf-8")

UI_PROPERTY_RE = re.compile(
    r"(?P<prefix>\b(?:tooltip|hintText|labelText|helperText|errorText|"
    r"semanticLabel|barrierLabel|helpText|hourLabelText|minuteLabelText)"
    r"\s*:\s*)(?P<q>['\"])(?P<value>(?:\\.|(?!\2).)*?)(?P=q)"
)

def transform_source() -> dict[str, int]:
    changed = 0
    wrapped = 0
    locale_replaced = 0
    for path in sorted(LIB.rglob("*.dart")):
        if "l10n" in path.parts:
            continue
        original = path.read_text(encoding="utf-8")
        text = original

        text = text.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:dadafinanza/l10n/localized_material.dart';",
        )

        if path.name == "voice_input_service.dart":
            text = text.replace(
                "String localeId = 'it_IT',",
                "String? localeId,",
            )
            text = text.replace(
                "localeId: localeId,",
                "localeId: localeId ?? AppI18n.speechLocaleId,",
            )

        before_locale = text.count("'it_IT'") + text.count('"it_IT"')
        text = text.replace("'it_IT'", "AppI18n.intlLocale")
        text = text.replace('"it_IT"', "AppI18n.intlLocale")
        locale_replaced += before_locale

        def wrap(match: re.Match[str]) -> str:
            nonlocal wrapped
            raw = match.group(0)
            if "AppI18n.tr(" in raw:
                return raw
            wrapped += 1
            q = match.group("q")
            value = match.group("value")
            return f"{match.group('prefix')}AppI18n.tr({q}{value}{q})"

        text = UI_PROPERTY_RE.sub(wrap, text)

        if "NavigationDestination(" in text:
            text = text.replace("destinations: const [", "destinations: [")
            text = text.replace("const NavigationDestination(", "NavigationDestination(")
            text = re.sub(
                r"(\blabel\s*:\s*)(['\"])((?:\\.|(?!\2).)*?)(\2)",
                lambda m: (
                    m.group(0)
                    if "AppI18n.tr(" in m.group(0)
                    else f"{m.group(1)}AppI18n.tr({m.group(2)}{m.group(3)}{m.group(2)})"
                ),
                text,
            )

        if "AppI18n.tr(" in text:
            text = text.replace("const InputDecoration(", "InputDecoration(")

        if "AppI18n." in text and "localized_material.dart" not in text and "app_i18n.dart" not in text:
            import_line = "import 'package:dadafinanza/l10n/app_i18n.dart';\n"
            insert_at = 0
            import_matches = list(re.finditer(r"^(?:import|export) .+;\n", text, re.M))
            if import_matches:
                insert_at = import_matches[-1].end()
            text = text[:insert_at] + import_line + text[insert_at:]

        if text != original:
            path.write_text(text, encoding="utf-8")
            changed += 1
    return {
        "changed_files": changed,
        "wrapped_properties": wrapped,
        "locale_literals_replaced": locale_replaced,
    }

def main() -> None:
    exact, fragments = extract_phrases()
    exact_values = sorted(exact, key=str.casefold)
    fragment_values = sorted(fragments, key=str.casefold)
    print(f"Exact UI phrases: {len(exact_values)}")
    print(f"Dynamic fragments: {len(fragment_values)}")

    exact_maps = build_maps(exact_values)
    phrase_maps = build_maps(fragment_values)
    write_generated(exact_maps, phrase_maps)
    transform_stats = transform_source()

    stats = {
        "languages": ["it", *TARGETS.keys()],
        "exact_phrases": len(exact_values),
        "dynamic_fragments": len(fragment_values),
        **transform_stats,
    }
    STATS.parent.mkdir(parents=True, exist_ok=True)
    STATS.write_text(
        json.dumps(stats, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    print(json.dumps(stats, ensure_ascii=False))

if __name__ == "__main__":
    main()
