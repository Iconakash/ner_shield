"""Notification channel providers (master upgrade §21).

Adapter architecture mirroring backend/integrations/base.py:
  * IN_APP   — always available (rows are the in-app inbox itself)
  * WEB_PUSH / EMAIL / SMS — require deployment credentials via env vars;
    unconfigured providers report ProviderUnavailable and the delivery is
    recorded as SUPPRESSED/FAILED — never silently dropped.
"""
import logging
import os

import httpx

logger = logging.getLogger("ner-shield.notifications")


class ProviderUnavailable(Exception):
    pass


SEVERITY_ORDER = {"INFO": 0, "LOW": 1, "MEDIUM": 2, "HIGH": 3, "CRITICAL": 4}


class BaseProvider:
    channel = "IN_APP"
    required_env: tuple[str, ...] = ()

    @classmethod
    def is_configured(cls) -> bool:
        return all(os.environ.get(k) for k in cls.required_env)

    async def send(self, target: str, title: str, body: str) -> str:
        """Return a provider message reference on success."""
        raise NotImplementedError


class InAppProvider(BaseProvider):
    """The in-app notification row IS the delivery; nothing external to send."""
    channel = "IN_APP"

    async def send(self, target: str, title: str, body: str) -> str:
        return "in-app"


class WebPushProvider(BaseProvider):
    """VAPID web-push. Requires WEB_PUSH_VAPID_KEY + WEB_PUSH_ENDPOINT
    (a push-service relay). Adapter contract documented in docs/INTEGRATIONS.md;
    browser subscription payloads arrive via /api/v1/notifications/devices."""
    channel = "WEB_PUSH"
    required_env = ("WEB_PUSH_VAPID_KEY", "WEB_PUSH_ENDPOINT")

    async def send(self, target: str, title: str, body: str) -> str:
        endpoint, key = os.environ["WEB_PUSH_ENDPOINT"], \
            os.environ["WEB_PUSH_VAPID_KEY"]
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(endpoint, json={
                "to": target, "title": title, "body": body,
            }, headers={"Authorization": f"vapid key={key}"})
        resp.raise_for_status()
        return resp.headers.get("msg-id", "webpush-accepted")


class EmailProvider(BaseProvider):
    """Transactional-email relay (HTTP contract). Requires EMAIL_RELAY_URL +
    EMAIL_API_KEY. Direct SMTP is intentionally avoided in serverless-style
    deployments; an SMTP transport can be added as another subclass."""
    channel = "EMAIL"
    required_env = ("EMAIL_RELAY_URL", "EMAIL_API_KEY")

    async def send(self, target: str, title: str, body: str) -> str:
        url, key = os.environ["EMAIL_RELAY_URL"], os.environ["EMAIL_API_KEY"]
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, json={
                "to": target, "subject": title, "text": body,
            }, headers={"Authorization": f"Bearer {key}"})
        resp.raise_for_status()
        data = resp.json() if resp.content else {}
        return str(data.get("message_id", "email-accepted"))


class SmsProvider(BaseProvider):
    """SMS gateway (generic HTTP contract). Requires SMS_GATEWAY_URL +
    SMS_API_KEY + approved sender ID from the licensed operator."""
    channel = "SMS"
    required_env = ("SMS_GATEWAY_URL", "SMS_API_KEY")

    async def send(self, target: str, title: str, body: str) -> str:
        url, key = os.environ["SMS_GATEWAY_URL"], os.environ["SMS_API_KEY"]
        sender = os.environ.get("SMS_SENDER_ID", "NER-SHIELD")
        async with httpx.AsyncClient(timeout=10) as client:
            resp = await client.post(url, json={
                "to": target, "from": sender,
                "text": f"{title}: {body}"[:480],
            }, headers={"Authorization": f"Bearer {key}"})
        resp.raise_for_status()
        data = resp.json() if resp.content else {}
        return str(data.get("message_id", "sms-accepted"))


PROVIDERS: dict[str, type[BaseProvider]] = {
    p.channel: p for p in
    (InAppProvider, WebPushProvider, EmailProvider, SmsProvider)
}


def get_provider(channel: str) -> BaseProvider:
    cls = PROVIDERS.get(channel)
    if cls is None:
        raise ProviderUnavailable(f"unknown channel {channel}")
    provider = cls()
    if not provider.channel == "IN_APP" and not cls.is_configured():
        raise ProviderUnavailable(
            f"{channel} provider not configured "
            f"(missing env: {', '.join(cls.required_env)})")
    return provider
