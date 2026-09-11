"""Field-report photo media API (SIH26002 P1).

  POST /field/reports/{report_id}/media            upload (CREATE_INCIDENT + owner)
  GET  /field/reports/{report_id}/media            metadata (owner/VIEW_INCIDENTS)
  GET  /field/reports/{report_id}/media/{mid}/url  signed URL (short-lived)

Storage is a PRIVATE Supabase bucket; bytes never pass through this API on
read — only short-lived signed URLs are handed to authorized viewers.
"""
from fastapi import APIRouter, Depends, Request, UploadFile
from sqlalchemy.ext.asyncio import AsyncSession

from app.audit import service as audit
from app.core.db import get_db
from app.core.errors import AppError
from app.core.security import Principal
from app.dependencies import get_principal, require_permissions
from app.media import service as media_svc

router = APIRouter(prefix="/field/reports", tags=["field-media"])


class _MediaHTTPError(AppError):
    def __init__(self, status: int, code: str, message: str):
        super().__init__(message)
        self.status_code, self.code = status, code


def _media_error(exc: media_svc.MediaError) -> AppError:
    status = {"FORBIDDEN": 403, "STORAGE_UNAVAILABLE": 503}.get(
        exc.code, 422)
    return _MediaHTTPError(status, exc.code, exc.message)


@router.post("/{report_id}/media", status_code=201,
             dependencies=[Depends(require_permissions("CREATE_INCIDENT"))])
async def upload_media(report_id: str, request: Request,
                       file: UploadFile,
                       principal: Principal = Depends(get_principal),
                       db: AsyncSession = Depends(get_db)):
    data = await file.read()
    try:
        res = await media_svc.upload_media(
            db, report_id=report_id, user_id=str(principal.user_id),
            filename=file.filename, content_type=file.content_type,
            data=data)
    except media_svc.MediaError as exc:
        raise _media_error(exc) from exc
    await db.commit()
    await audit.emit(db, actor_id=principal.user_id,
                     actor_role=principal.role, action="ANALYZE",
                     outcome="SUCCESS", resource_type="field_report_media",
                     resource_id=res["id"],
                     detail={"report": report_id,
                             "bytes": res.get("byte_size"),
                             "deduplicated": res.get("deduplicated", False)},
                     ip=request.client.host if request.client else None)
    return res


@router.get("/{report_id}/media",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def list_media(report_id: str,
                     db: AsyncSession = Depends(get_db)):
    return await media_svc.list_media(db, report_id)


@router.get("/{report_id}/media/{media_id}/url",
            dependencies=[Depends(require_permissions("VIEW_INCIDENTS"))])
async def media_url(report_id: str, media_id: str,
                    db: AsyncSession = Depends(get_db)):
    try:
        url = await media_svc.signed_url_for(db, report_id=report_id,
                                             media_id=media_id)
    except media_svc.MediaError as exc:   # pragma: no cover (defensive)
        raise _media_error(exc) from exc
    return {"url": url, "expires_in_s": 600}
