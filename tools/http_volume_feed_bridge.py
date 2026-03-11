#!/usr/bin/env python3
"""
Bridge simples HTTP -> arquivo CSV para SupDemVol v6.

Formato de saída (1 linha):
symbol,period_sec,bar_time_unix,volume,source_time_unix
"""

from __future__ import annotations

import argparse
import json
import math
import os
import time
import urllib.error
import urllib.request


def now_unix() -> int:
    return int(time.time())


def align_bar_time(ts: int, period_sec: int) -> int:
    if period_sec <= 0:
        return ts
    return ts - (ts % period_sec)


def safe_float(v) -> float:
    try:
        x = float(v)
        if not math.isfinite(x):
            return float("nan")
        return x
    except Exception:
        return float("nan")


def fetch_json(url: str, timeout: float):
    req = urllib.request.Request(url, method="GET")
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        raw = resp.read().decode("utf-8", errors="replace").strip()
        if not raw:
            raise ValueError("HTTP vazio")
        return json.loads(raw)


def extract_fields(payload, volume_key: str, bar_time_key: str, source_time_key: str, period_sec: int):
    ts_now = now_unix()
    if isinstance(payload, (int, float, str)):
        vol = safe_float(payload)
        if not math.isfinite(vol):
            raise ValueError("volume inválido em payload escalar")
        return vol, align_bar_time(ts_now, period_sec), ts_now

    if not isinstance(payload, dict):
        raise ValueError("payload JSON deve ser objeto ou escalar")

    if volume_key not in payload:
        raise KeyError(f"chave de volume ausente: {volume_key}")
    vol = safe_float(payload.get(volume_key))
    if not math.isfinite(vol):
        raise ValueError("volume inválido no JSON")

    bar_time = payload.get(bar_time_key, ts_now)
    src_time = payload.get(source_time_key, ts_now)
    try:
        bar_time = int(float(bar_time))
    except Exception:
        bar_time = ts_now
    try:
        src_time = int(float(src_time))
    except Exception:
        src_time = ts_now

    return vol, bar_time, src_time


def write_line_atomic(path: str, line: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")
    os.replace(tmp, path)


def main() -> int:
    ap = argparse.ArgumentParser(description="HTTP -> CSV feed bridge para SupDemVol")
    ap.add_argument("--url", required=True, help="Endpoint HTTP JSON")
    ap.add_argument("--symbol", required=True, help="Símbolo exato do chart no MT5 (ex: EURUSD)")
    ap.add_argument("--period-sec", type=int, required=True, help="Período em segundos (ex: M5=300)")
    ap.add_argument("--output", required=True, help="Arquivo CSV de saída (ideal: .../Common/Files/SupDemVol/real_volume_feed.csv)")
    ap.add_argument("--interval", type=float, default=1.0, help="Intervalo de polling em segundos")
    ap.add_argument("--timeout", type=float, default=2.0, help="Timeout HTTP em segundos")
    ap.add_argument("--volume-key", default="volume", help="Chave JSON do volume")
    ap.add_argument("--bar-time-key", default="bar_time", help="Chave JSON do horário da barra (unix)")
    ap.add_argument("--source-time-key", default="source_time", help="Chave JSON do horário de origem (unix)")
    args = ap.parse_args()

    while True:
        try:
            payload = fetch_json(args.url, args.timeout)
            vol, bar_ts, src_ts = extract_fields(
                payload,
                args.volume_key,
                args.bar_time_key,
                args.source_time_key,
                args.period_sec,
            )
            line = f"{args.symbol},{args.period_sec},{int(bar_ts)},{vol:.10f},{int(src_ts)}"
            write_line_atomic(args.output, line)
        except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError, ValueError, KeyError, json.JSONDecodeError):
            # Mantém o loop vivo; indicador continua com fallback para tick_volume.
            pass
        time.sleep(max(0.1, args.interval))


if __name__ == "__main__":
    raise SystemExit(main())

