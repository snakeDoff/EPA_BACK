from __future__ import annotations

import re


def normalize_fio(value: str | None) -> str:
    if not value:
        return ""

    value = value.lower().replace("ё", "е")
    value = value.replace(".", " ")
    value = re.sub(r"\s+", " ", value).strip()
    return value