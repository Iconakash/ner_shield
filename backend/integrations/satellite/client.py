"""Satellite HTTP client transport."""
import httpx


class SatelliteClient:
    def __init__(self, endpoint: str | None, api_key: str | None = None,
                 timeout_s: float = 15.0):
        self.endpoint = endpoint
        self.api_key = api_key
        self.timeout_s = timeout_s

    async def get(self, params: dict) -> object:
        headers = {"User-Agent": "NER-SHIELD/1.0"}
        if self.api_key:
            headers["Authorization"] = f"Bearer {self.api_key}"
        async with httpx.AsyncClient(timeout=self.timeout_s) as client:
            resp = await client.get(self.endpoint, params=params, headers=headers)
            resp.raise_for_status()
            return resp.json()
