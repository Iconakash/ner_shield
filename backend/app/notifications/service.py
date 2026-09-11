"""Notification service: preference-gated fan-out + delivery tracking."""
import json
import logging
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession

from app.notifications.providers import (ProviderUnavailable, SEVERITY_ORDER,
                                         get_provider)

logger = logging.getLogger("ner-shield.notifications")


async def get_preferences(db: AsyncSession, user_id: str) -> dict:
    row = (await db.execute(text(
        "select channels, min_severity from notification_preferences"
        " where user_id = cast(:u as uuid)"), {"u": user_id})).mappings().first()
    if row is None:
        return {"channels": {"IN_APP": True}, "min_severity": "LOW"}
    return {"channels": row["channels"] if isinstance(row["channels"], dict)
            else {},
            "min_severity": row["min_severity"]}


def channel_allowed(prefs: dict, channel: str, severity: str) -> bool:
    """PURE gate — unit-tested. In-app delivery is unconditional (it IS the
    inbox of record); external channels require explicit opt-in plus minimum
    severity."""
    if channel == "IN_APP":
        return True
    if not prefs["channels"].get(channel):
        return False
    return SEVERITY_ORDER.get(severity, 0) >= \
        SEVERITY_ORDER.get(prefs["min_severity"], 1)


async def notify_user(db: AsyncSession, *, user_id: str,
                      template_code: str, severity: str, title: str,
                      body: str, source_type: str | None = None,
                      source_id: str | None = None,
                      action_url: str | None = None) -> dict:
    """Create the in-app notification + per-channel deliveries.

    Delivery outcomes are ALWAYS recorded; unconfigured providers yield a
    SUPPRESSED delivery with the reason (admin-visible), never silence.
    """
    prefs = await get_preferences(db, user_id)
    ins = await db.execute(text("""
        insert into notifications (user_id, template_code, severity, title,
                                   body, source_type, source_id, action_url)
        values (cast(:u as uuid), :tc, :sev, :ti, :bo, :st, :si, :au)
        returning id::text as id
    """), {"u": user_id, "tc": template_code, "sev": severity, "ti": title,
           "bo": body, "st": source_type, "si": source_id, "au": action_url})
    notification_id = ins.mappings().first()["id"]

    results = {}
    for channel in ("IN_APP", "WEB_PUSH", "EMAIL", "SMS"):
        if not channel_allowed(prefs, channel, severity):
            continue
        device = None
        if channel != "IN_APP":
            device = (await db.execute(text("""
                select id::text as id, target from notification_devices
                where user_id = cast(:u as uuid) and channel = cast(:c as
                      notification_channel)
                  and active order by last_used_at desc nulls last limit 1
            """), {"u": user_id, "c": channel})).mappings().first()
            if device is None:
                continue                      # no bound device for the channel
        try:
            provider = get_provider(channel)
            ref = await provider.send(device["target"] if device else user_id,
                                      title, body)
            status, err, prov = "SENT", None, provider.channel.lower()
        except ProviderUnavailable as exc:
            ref = None
            status, err, prov = "SUPPRESSED", str(exc)[:200], "unconfigured"
        except Exception as exc:  # noqa: BLE001 — delivery failure is data
            ref = None
            status, err, prov = "FAILED", str(exc)[:200], "error"
        await db.execute(text("""
            insert into notification_deliveries (notification_id, device_id,
                channel, status, attempts, provider, provider_ref, error_note,
                sent_at)
            values (cast(:n as uuid), cast(:d as uuid),
                    cast(:c as notification_channel),
                    cast(:s as delivery_status), 1, :p, :r, :e,
                    case when :s in ('SENT','SUPPRESSED','FAILED')
                         then now() else null end)
        """), {"n": notification_id, "d": device["id"] if device else None,
               "c": channel, "s": status, "p": prov, "r": ref, "e": err})
        results[channel] = status
        if status == "FAILED":
            try:
                from app.core import metrics
                metrics.inc("ner_shield_notification_failures_total",
                            {"channel": channel})
            except Exception:  # noqa: BLE001
                pass
            logger.warning("notification delivery failed", extra={"data": {
                "channel": channel, "notification_id": notification_id}})
    return {"notification_id": notification_id, "deliveries": results}


async def list_my_notifications(db: AsyncSession, user_id: str,
                                unread_only: bool = False) -> list[dict]:
    extra = " and read_at is null" if unread_only else ""
    rows = (await db.execute(text(f"""
        select id::text as id, template_code, severity, title, body,
               source_type, source_id, action_url, read_at, created_at
        from notifications where user_id = cast(:u as uuid) {extra}
        order by created_at desc limit 100
    """), {"u": user_id})).mappings().all()
    return [dict(r) for r in rows]


async def acknowledge(db: AsyncSession, user_id: str,
                      notification_id: str) -> bool:
    res = await db.execute(text("""
        update notifications set read_at = coalesce(read_at, now())
        where id = cast(:i as uuid) and user_id = cast(:u as uuid)
          and read_at is null
        returning id::text
    """), {"i": notification_id, "u": user_id})
    acked = res.scalar() is not None
    if acked:
        await db.execute(text("""
            update notification_deliveries
            set status = 'ACKNOWLEDGED', acknowledged_at = now()
            where notification_id = cast(:i as uuid) and status = 'DELIVERED'
        """), {"i": notification_id})
    return acked


async def register_device(db: AsyncSession, user_id: str, channel: str,
                          target: str, label: str = "") -> dict:
    row = (await db.execute(text("""
        insert into notification_devices (user_id, channel, target, label,
                                          verified)
        values (cast(:u as uuid), cast(:c as notification_channel), :t, :l,
                true)
        on conflict (user_id, channel, target) do update
          set active = true, label = excluded.label
        returning id::text as id
    """), {"u": user_id, "c": channel, "t": target, "l": label}
    )).mappings().first()
    return {"device_id": row["id"], "channel": channel}


async def set_preferences(db: AsyncSession, user_id: str,
                          channels: dict, min_severity: str) -> dict:
    clean = {k: bool(v) for k, v in (channels or {}).items()
             if k in ("IN_APP", "WEB_PUSH", "EMAIL", "SMS")}
    clean.setdefault("IN_APP", True)      # in-app cannot be disabled
    await db.execute(text("""
        insert into notification_preferences (user_id, channels, min_severity)
        values (cast(:u as uuid), cast(:c as jsonb),
                cast(:m as text))
        on conflict (user_id) do update
          set channels = excluded.channels, min_severity = excluded.min_severity
    """), {"u": user_id, "c": json.dumps(clean), "m": min_severity})
    return {"channels": clean, "min_severity": min_severity}

