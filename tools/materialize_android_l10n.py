from __future__ import annotations

from pathlib import Path
import json
import re
import xml.etree.ElementTree as ET
from xml.sax.saxutils import escape as xml_escape

ROOT = Path(__file__).resolve().parents[1]
# Resource generation is deterministic and does not contact external services.
GENERATED = ROOT / "lib" / "l10n" / "generated_translations.dart"
BASE = ROOT / "android" / "app" / "src" / "main" / "res" / "values" / "strings.xml"

RESOURCE_DIRS = {
    "en": "values-en",
    "es": "values-es",
    "fr": "values-fr",
    "de": "values-de",
    "pt": "values-pt-rBR",
    "ru": "values-ru",
    "zh": "values-zh-rCN",
    "ja": "values-ja",
    "ko": "values-ko",
    "ar": "values-ar",
    "hi": "values-hi",
}

LANGUAGE_RE = re.compile(r'^  "([a-z]{2})": <String, String>\{$')
ENTRY_RE = re.compile(
    r'^\s*"((?:\\.|[^"\\])*)":\s*"((?:\\.|[^"\\])*)",\s*$',
    re.DOTALL,
)


def decode_dart_string(value: str) -> str:
    # Generated strings are JSON-compatible except Dart's escaped dollar.
    return json.loads('"' + value.replace(r"\$", "$") + '"')


def generated_maps() -> dict[str, dict[str, str]]:
    result: dict[str, dict[str, str]] = {}
    current: str | None = None
    statement: list[str] = []
    in_exact_map = False

    for line in GENERATED.read_text(encoding="utf-8").splitlines():
        if "generatedPhraseTranslations =" in line:
            break
        if "generatedTranslations =" in line:
            in_exact_map = True
            continue
        if not in_exact_map:
            continue

        language = LANGUAGE_RE.match(line)
        if language:
            current = language.group(1)
            result[current] = {}
            statement.clear()
            continue

        if current is None:
            continue

        if line == "  },":
            statement.clear()
            current = None
            continue

        statement.append(line)
        if not line.rstrip().endswith(","):
            continue

        candidate = "\n".join(statement)
        statement.clear()
        entry = ENTRY_RE.match(candidate)
        if entry is None:
            continue

        source = decode_dart_string(entry.group(1))
        target = decode_dart_string(entry.group(2))
        result[current][source] = target

    return result


def base_strings() -> list[tuple[str, str]]:
    root = ET.parse(BASE).getroot()
    result: list[tuple[str, str]] = []
    for node in root.findall("string"):
        name = node.attrib.get("name")
        if not name:
            continue
        result.append((name, "".join(node.itertext()).strip()))
    return result


def android_text(value: str) -> str:
    # aapt treats ASCII apostrophes/backslashes specially even though XML does not.
    escaped = value.replace("\\", "\\\\").replace("'", "\\'")
    return xml_escape(escaped, {'"': "&quot;"})


def main() -> None:
    maps = generated_maps()
    base = base_strings()
    res_root = BASE.parent.parent

    for code, folder in RESOURCE_DIRS.items():
        mapping = maps.get(code)
        if mapping is None:
            raise RuntimeError(f"Missing generated translation map for {code}")

        lines = ['<?xml version="1.0" encoding="utf-8"?>', "<resources>"]
        for name, source in base:
            target = source if name == "app_name" else mapping.get(source, source)
            lines.append(
                f'    <string name="{name}" formatted="false">'
                f'{android_text(target)}</string>'
            )
        lines.extend(["</resources>", ""])

        target_dir = res_root / folder
        target_dir.mkdir(parents=True, exist_ok=True)
        (target_dir / "strings.xml").write_text(
            "\n".join(lines),
            encoding="utf-8",
        )

    print(f"Generated {len(RESOURCE_DIRS)} Android locale resource files.")


if __name__ == "__main__":
    main()
