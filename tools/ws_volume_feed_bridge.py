#!/usr/bin/env python3
"""
Bridge simples WebSocket -> arquivo CSV para SupDemVol v6.

Formato de saída (1 linha):
symbol,period_sec,bar_time_unix,volume,source_time_unix

Requer:
  pip install websockets
"""

from __future__ import annotations

import argparse
import asyncio
import json
import math
import os
import time

try:
    import websockets
except Exception as exc:  # pragma: no cover
    raise SystemExit(
        "Dependência ausente: websockets. Instale com: pip install websockets"
    ) from exc


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


def safe_int(v, fallback: int) -> int:
    try:
        return int(float(v))
    except Exception:
        return fallback


def write_line_atomic(path: str, line: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    tmp = f"{path}.tmp"
    with open(tmp, "w", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")
    os.replace(tmp, path)


def extract_payload_data(payload, args):
    ts_now = now_unix()

    if isinstance(payload, list):
        if not payload:
            raise ValueError("payload vazio")
        payload = payload[-1]

    if isinstance(payload, (int, float, str)):
        vol = safe_float(payload)
        if not math.isfinite(vol):
            raise ValueError("volume inválido em payload escalar")
        return vol, align_bar_time(ts_now, args.period_sec), ts_now, args.symbol

    if not isinstance(payload, dict):
        raise ValueError("payload JSON deve ser objeto, lista ou escalar")

    if args.symbol_key:
        msg_sym = str(payload.get(args.symbol_key, "")).strip()
        if msg_sym and msg_sym != args.symbol and msg_sym != "*":
            raise ValueError("símbolo diferente")

    if args.volume_key not in payload:
        raise KeyError(f"chave de volume ausente: {args.volume_key}")

    vol = safe_float(payload.get(args.volume_key))
    if not math.isfinite(vol):
        raise ValueError("volume inválido no JSON")

    bar_time = safe_int(payload.get(args.bar_time_key, ts_now), ts_now)
    src_time = safe_int(payload.get(args.source_time_key, ts_now), ts_now)
    return vol, bar_time, src_time, args.symbol


async def run_bridge(args) -> None:
    while True:
        try:
            async with websockets.connect(
                args.url,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=5,
                max_size=2_000_000,
            ) as ws:
                if args.subscribe:
                    await ws.send(args.subscribe)

                async for raw in ws:
                    try:
                        payload = json.loads(raw)
                        vol, bar_ts, src_ts, symbol = extract_payload_data(payload, args)
                        line = f"{symbol},{args.period_sec},{int(bar_ts)},{vol:.10f},{int(src_ts)}"
                        write_line_atomic(args.output, line)
                    except (ValueError, KeyError, json.JSONDecodeError):
                        continue
        except Exception:
            await asyncio.sleep(max(0.2, args.reconnect_delay))


def main() -> int:
    ap = argparse.ArgumentParser(description="WebSocket -> CSV feed bridge para SupDemVol")
    ap.add_argument("--url", required=True, help="Endpoint WebSocket")
    ap.add_argument("--symbol", required=True, help="Símbolo exato do chart no MT5 (ex: EURUSD)")
    ap.add_argument("--period-sec", type=int, required=True, help="Período em segundos (ex: M5=300)")
    ap.add_argument("--output", required=True, help="Arquivo CSV de saída (Common/Files/SupDemVol/real_volume_feed.csv)")
    ap.add_argument("--volume-key", default="volume", help="Chave JSON do volume")
    ap.add_argument("--bar-time-key", default="bar_time", help="Chave JSON do horário da barra (unix)")
    ap.add_argument("--source-time-key", default="source_time", help="Chave JSON do horário de origem (unix)")
    ap.add_argument("--symbol-key", default="symbol", help="Chave JSON do símbolo (vazio para ignorar)")
    ap.add_argument("--subscribe", default="", help="Payload de assinatura para enviar ao conectar")
    ap.add_argument("--reconnect-delay", type=float, default=1.0, help="Delay de reconexão em segundos")
    args = ap.parse_args()

    if args.period_sec <= 0:
        raise SystemExit("--period-sec deve ser > 0")

    asyncio.run(run_bridge(args))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
