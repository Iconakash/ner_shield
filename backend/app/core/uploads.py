"""Hardened upload validation (Phase 26 · file-upload hardening).

Field officers upload incident/report photos. Per the phase mandate we trust
NOTHING from the client:
    * filename      -> discarded; a randomized server-side name is minted
    * Content-Type  -> treated as a claim only; magic bytes are authoritative
    * client-side validation -> never relied upon; everything re-checked here

Rules enforced by validate_upload():
    * size <= Settings.MAX_UPLOAD_BYTES
    * extension allowlist (jpg/jpeg/png/webp), double extensions rejected
    * declared Content-Type must be in the image allowlist
    * magic-byte sniff must MATCH the declared/extension kind (spoof-proof)
    * storage name = uuid4-hex + safe canonical extension (no user input)
"""
import uuid
from typing import Optional

from app.config import get_settings

class UploadRejected(Exception):
    """Raised when an upload violates any hardening rule."""

    def __init__(self, reason: str):
        super().__init__(reason)
        self.reason = reason

# extension -> (allowed content types, magic sniffers)
_MAGIC: dict[str, list] = {
    "jpg": [lambda b: b[:3] == b"\xff\xd8\xff"],
    "jpeg": [lambda b: b[:3] == b"\xff\xd8\xff"],
    "png": [lambda b: b[:8] == b"\x89PNG\r\n\x1a\n"],
    "webp": [lambda b: b[:4] == b"RIFF" and b[8:12] == b"WEBP"],
}
ALLOWED_EXTENSIONS = tuple(_MAGIC)
ALLOWED_CONTENT_TYPES = ("image/jpeg", "image/png", "image/webp")

# extension <-> content-type compatibility (declared kind must agree)
_KIND_OF_TYPE = {"image/jpeg": {"jpg", "jpeg"}, "image/png": {"png"},
                 "image/webp": {"webp"}}


def _extension_of(filename: Optional[str]) -> str:
    """Single, allowlisted, case-folded extension — or reject."""
    if not filename or "/" in filename or "\\" in filename:
        raise UploadRejected("missing or unsafe filename")
    parts = filename.rsplit(".", 1)
    if len(parts) != 2 or not parts[0]:
        raise UploadRejected("no extension")
    if "." in parts[0]:                       # double extension: a.jpg.png? no —
        raise UploadRejected("multiple extensions")   # a.tar.jpg style tricks
    ext = parts[1].lower()
    if ext not in _MAGIC:
        raise UploadRejected(f"extension not allowed: {ext}")
    return ext


def sniff_kind(data: bytes) -> Optional[str]:
    """Authoritative kind from magic bytes; None when unrecognizable."""
    for kind, checks in _MAGIC.items():
        if any(check(data) for check in checks):
            return kind
    return None


def validate_upload(*, filename: Optional[str], content_type: Optional[str],
                    data: bytes) -> tuple[str, str]:
    """Validate one upload. Returns (storage_name, kind) or raises
    UploadRejected. `data` MUST already be fully read by the caller."""
    limit = get_settings().MAX_UPLOAD_BYTES
    if not data:
        raise UploadRejected("empty upload")
    if len(data) > limit:
        raise UploadRejected(f"upload exceeds {limit} bytes")

    ext = _extension_of(filename)

    if not content_type or content_type.split(";")[0].strip().lower() \
            not in ALLOWED_CONTENT_TYPES:
        raise UploadRejected(f"content-type not allowed: {content_type}")
    ctype = content_type.split(";")[0].strip().lower()
    if ext not in _KIND_OF_TYPE[ctype]:
        raise UploadRejected("extension contradicts declared content-type")

    kind = sniff_kind(data)
    if kind is None:
        raise UploadRejected("content does not match any allowed image format")
    if kind != ext:
        raise UploadRejected("magic bytes contradict declared type")

    # storage name is fully server-generated — client filename is discarded
    return f"{uuid.uuid4().hex}.{ext}", kind


def malware_scan_placeholder(data: bytes, storage_name: str) -> None:
    """Hook for AV scanning where deployment permits (ICAP/ClamAV etc.).

    Deployment note: wire a real scanner here in prod; in its absence the
    magic-byte + size + randomized-name controls above still hold, and
    uploads are served with Content-Disposition: attachment + nosniff so a
    polyglot can never execute in origin context.
    """
    return None
