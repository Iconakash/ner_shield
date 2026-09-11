"""Junction merging + OD snapping (pure geometry helpers, equirectangular)."""
import math
from typing import Iterable

from app.routing.graph import SNAP_EPS_DEG


def _key(lon: float, lat: float) -> tuple:
    return (round(lon, 6), round(lat, 6))


def merge_endpoints(endpoints: Iterable[tuple[int, int, float, float]],
                    eps_deg: float = SNAP_EPS_DEG) -> dict[tuple, int]:
    """Union-find merge of segment endpoints into junction ids.

    endpoints yields (segment_index, end_index(0|1), lon, lat).
    Returns {exact_coord_key: junction_id}.
    """
    parent: dict[tuple, tuple] = {}

    def find(k):
        parent.setdefault(k, k)
        while parent[k] != k:
            parent[k] = parent[parent[k]]
            k = parent[k]
        return k

    def union(a, b):
        ra, rb = find(a), find(b)
        if ra != rb:
            parent[rb] = ra

    pts = list(endpoints)
    grid: dict[tuple, list[tuple]] = {}
    for _si, _ei, lon, lat in pts:
        cell = (int(lon / eps_deg), int(lat / eps_deg))
        grid.setdefault(cell, []).append((lon, lat))

    def near(lon1, lat1, lon2, lat2) -> bool:
        dlon = (lon2 - lon1) * math.cos(math.radians((lat1 + lat2) / 2))
        dlat = lat2 - lat1
        return math.hypot(dlon, dlat) <= eps_deg

    for cell, members in grid.items():
        # compare within this cell and its right/lower neighbours to halve work
        neighbours = [members] + [grid.get(nc, []) for nc in (
            (cell[0] + 1, cell[1]), (cell[0], cell[1] - 1),
            (cell[0] + 1, cell[1] - 1))]
        for i in range(len(members)):
            lon1, lat1 = members[i]
            for group in neighbours:
                for lon2, lat2 in group:
                    if (lon2, lat2) == (lon1, lat1):
                        continue
                    if near(lon1, lat1, lon2, lat2):
                        union(_key(lon1, lat1), _key(lon2, lat2))

    junction_of: dict[tuple, int] = {}
    roots = {}
    for _si, _ei, lon, lat in pts:
        k = _key(lon, lat)
        r = find(k)
        if r not in roots:
            roots[r] = len(roots)
        junction_of[k] = roots[r]
    return junction_of


def snap_to_junction(junctions: dict[tuple, int],
                     lon: float, lat: float) -> int | None:
    """Nearest junction id to a coordinate (equirectangular km)."""
    best, best_km = None, math.inf
    for (jlon, jlat), jid in junctions.items():
        dlon = (jlon - lon) * math.cos(math.radians(lat))
        dlat = jlat - lat
        km = math.hypot(dlon, dlat) * 111.32
        if km < best_km:
            best, best_km = jid, km
    return best
