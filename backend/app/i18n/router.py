# -*- coding: utf-8 -*-
"""Language coverage + translated operational surfaces (Phase 17 · FR-C15).

  GET /i18n/languages     coverage status — admin-visible (FR-C15.2)
  GET /i18n/field-schema  translated incident form + field instructions

Both are reference reads: any authenticated principal may call them.
"""
from typing import Optional

from fastapi import APIRouter, Depends, Query

from app.core.security import Principal
from app.dependencies import get_principal
from app.i18n import service as i18n

router = APIRouter(prefix="/i18n", tags=["i18n"])


@router.get("/languages")
async def languages(principal: Principal = Depends(get_principal)):
    """Frozen coverage set with display metadata (honest scope statement).

    The MVP supports EXACTLY these languages; adding more requires a new
    catalog + parity test, never a UI claim.
    """
    return {
        "default": i18n.DEFAULT_LANG,
        "coverage_note":
            "Frozen MVP set (FR-C15.1): English + Hindi + Assamese. "
            "Additional NER languages extend catalog-by-catalog.",
        "languages": [
            {"code": code, **meta}
            for code, meta in i18n.SUPPORTED_LANGUAGES.items()
        ],
        "profile_language": getattr(principal, "language", None),
    }


@router.get("/field-schema")
async def field_schema(lang: Optional[str] = Query(default=None),
                       principal: Principal = Depends(get_principal)):
    """Incident form labels + emergency/field instructions, translated.

    Served separately from the report submission so OFFLINE devices can cache
    one schema per language (C13/C14-friendly).
    """
    resolved = i18n.resolve_lang(principal=principal, explicit=lang)
    return i18n.field_form_schema(resolved)
