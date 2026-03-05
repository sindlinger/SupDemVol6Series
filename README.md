# SupDemVol6Series

Indicador principal da série v6:
- `SupDemVol_-NextZero_v6.mq5`

## Estrutura
- `modules_v6/` módulos ativos do indicador
- `legacy/` histórico e arquivos obsoletos/versionados

## Pipeline (ordem de execução)
1. Criação de zonas
2. Enriquecimento
3. Merge
4. Organização contínua
5. Visualização/atualização de UI

## Inputs (agrupados)
- `01. Basico`
- `02. Criacao e Merge`
- `03. Organizacao Continua`
- `04. Percentuais e Distribuicao`
- `05. Visual Zonas`
- `06. Linhas de Referencia`
- `07. Painel e Logs`
- `08. Tecnico (Avancado)`
- `09. Volume Real (Feed Externo)`
- `10. Book Real (DOM)`

## Política de legacy
Arquivos obsoletos, snapshots e logs de compilação antigos são movidos para `legacy/` com pasta datada.

## Build local (MetaEditor)
Exemplo (Windows):
- `MetaEditor64.exe /compile:"...\\SupDemVol_-NextZero_v6.mq5" /log:"...\\compile.log"`

## Volume real (HTTP/WS -> MT5)
O indicador pode usar volume real externo sem socket direto no MQL5:

1. Um bridge externo (Python) consome HTTP ou WebSocket.
2. O bridge grava 1 linha CSV em `Common\\Files`.
3. O indicador lê esse CSV e injeta o volume na barra alvo.

### CSV esperado
`symbol,period_sec,bar_time_unix,volume,source_time_unix`

Exemplo:
`EURUSD,300,1727325900,297.0,1727325901`

### Inputs importantes
- `InpUsarVolumeRealFeed = true`
- `InpArquivoVolumeRealFeed = SupDemVol/real_volume_feed.csv`
- `InpVolumeRealFeedBarraFechada = true` (estável) ou `false` (barra 0)
- `InpVolumeRealFeedRefreshMs`
- `InpVolumeRealFeedMaxAtrasoSeg`

### Bridge HTTP
Arquivo: `tools/http_volume_feed_bridge.py`

Exemplo:
`python tools/http_volume_feed_bridge.py --url "https://SUA_API" --symbol EURUSD --period-sec 300 --output "C:\\Users\\pichau\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\SupDemVol\\real_volume_feed.csv" --volume-key volume --bar-time-key bar_time --source-time-key source_time`

### Bridge WebSocket
Arquivo: `tools/ws_volume_feed_bridge.py`

Requer:
`pip install websockets`

Exemplo:
`python tools/ws_volume_feed_bridge.py --url "wss://SEU_WS" --symbol EURUSD --period-sec 300 --output "C:\\Users\\pichau\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\SupDemVol\\real_volume_feed.csv" --volume-key volume --bar-time-key bar_time --source-time-key source_time --symbol-key symbol --subscribe "{\"type\":\"subscribe\",\"symbol\":\"EURUSD\"}"`

Depuração para payload aninhado (muito comum):
`python tools/ws_volume_feed_bridge.py --url "wss://SEU_WS" --symbol EURUSD --period-sec 300 --output "C:\\Users\\pichau\\AppData\\Roaming\\MetaQuotes\\Terminal\\Common\\Files\\SupDemVol\\real_volume_feed.csv" --payload-key data --volume-key tick.volume --bar-time-key tick.bar_time --source-time-key tick.source_time --symbol-key tick.symbol --subscribe-file ws_subscribe.json --debug-raw --debug-every 1 --debug-file "C:\\temp\\duk_ws_debug.log"`

## Book real no grafico (DOM)
O indicador agora suporta DOM nativo do MT5 (`MarketBookAdd` + `OnBookEvent`):

- Desenha blocos por nivel de preco no chart principal.
- Azul escuro para BUY e vermelho escuro para SELL.
- Texto com volume total por nivel.
- Quando o nivel reduz/some, o modulo pode acumular como execucao estimada no mesmo preco.

Inputs principais:
- `InpBookAtivo`
- `InpBookDesenhar`
- `InpBookAcumularReducaoComoExecutado`
- `InpBookMaxNiveisDesenho`
- `InpBookVolumeMinimoExibicao`
- `InpBookOffsetDireitaBarras`
- `InpBookLarguraBarras`
- `InpBookAlturaPontos`
- `InpBookPollMs`
- `InpBookRefreshVisualMs`

Observacao:
- A acumulacao por reducao no book e uma estimativa de execucao (book nao distingue cancelamento de negocio executado).
