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
from typing import Any

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


def append_debug_line(path: str, line: str) -> None:
    if not path:
        return
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "a", encoding="utf-8", newline="\n") as f:
        f.write(line + "\n")


def parse_json_if_needed(value: Any) -> Any:
    if isinstance(value, str):
        txt = value.strip()
        if txt.startswith("{") or txt.startswith("["):
            return json.loads(txt)
    return value


def deep_get(obj: Any, path: str):
    if not path:
        return obj
    cur = obj
    for part in path.split("."):
        if cur is None:
            return None
        if isinstance(cur, dict):
            cur = cur.get(part)
            cur = parse_json_if_needed(cur)
            continue
        if isinstance(cur, list):
            try:
                idx = int(part)
            except Exception:
                return None
            if idx < 0 or idx >= len(cur):
                return None
            cur = cur[idx]
            cur = parse_json_if_needed(cur)
            continue
        return None
    return cur


def normalize_payload(payload: Any, args):
    payload = parse_json_if_needed(payload)
    if args.payload_key:
        payload = deep_get(payload, args.payload_key)
        payload = parse_json_if_needed(payload)
    return payload


def extract_payload_data(payload, args):
    payload = normalize_payload(payload, args)
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
        msg_sym = str(deep_get(payload, args.symbol_key) or "").strip()
        if msg_sym and msg_sym != args.symbol and msg_sym != "*":
            raise ValueError("símbolo diferente")

    vol_raw = deep_get(payload, args.volume_key)
    if vol_raw is None:
        raise KeyError(f"chave de volume ausente: {args.volume_key}")

    vol = safe_float(vol_raw)
    if not math.isfinite(vol):
        raise ValueError("volume inválido no JSON")

    bar_time = safe_int(deep_get(payload, args.bar_time_key), ts_now)
    src_time = safe_int(deep_get(payload, args.source_time_key), ts_now)
    return vol, bar_time, src_time, args.symbol


async def run_bridge(args) -> None:
    msg_count = 0
    ok_count = 0
    while True:
        try:
            async with websockets.connect(
                args.url,
                ping_interval=20,
                ping_timeout=20,
                close_timeout=5,
                max_size=2_000_000,
            ) as ws:
                sub_payload = args.subscribe
                if args.subscribe_file:
                    with open(args.subscribe_file, "r", encoding="utf-8") as f:
                        sub_payload = f.read().strip()
                if sub_payload:
                    await ws.send(sub_payload)

                async for raw in ws:
                    msg_count += 1
                    if args.debug_raw and msg_count % args.debug_every == 0:
                        line = f"[RAW #{msg_count}] {raw[:1000]}"
                        print(line)
                        append_debug_line(args.debug_file, line)
                    try:
                        payload = json.loads(raw)
                        vol, bar_ts, src_ts, symbol = extract_payload_data(payload, args)
                        line = f"{symbol},{args.period_sec},{int(bar_ts)},{vol:.10f},{int(src_ts)}"
                        write_line_atomic(args.output, line)
                        ok_count += 1
                        if args.debug_raw and ok_count % args.debug_every == 0:
                            dbg = f"[OK #{ok_count}] {line}"
                            print(dbg)
                            append_debug_line(args.debug_file, dbg)
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
    ap.add_argument("--payload-key", default="", help="Caminho (dot path) do payload real, ex: data.tick")
    ap.add_argument("--subscribe", default="", help="Payload de assinatura para enviar ao conectar")
    ap.add_argument("--subscribe-file", default="", help="Arquivo com payload de assinatura WS")
    ap.add_argument("--debug-raw", action="store_true", help="Imprime mensagens cruas e linhas válidas periodicamente")
    ap.add_argument("--debug-every", type=int, default=20, help="Frequência de logs debug")
    ap.add_argument("--debug-file", default="", help="Arquivo opcional para salvar logs debug")
    ap.add_argument("--reconnect-delay", type=float, default=1.0, help="Delay de reconexão em segundos")
    args = ap.parse_args()

    if args.period_sec <= 0:
        raise SystemExit("--period-sec deve ser > 0")
    if args.debug_every < 1:
        args.debug_every = 1

    asyncio.run(run_bridge(args))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
