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

## Política de legacy
Arquivos obsoletos, snapshots e logs de compilação antigos são movidos para `legacy/` com pasta datada.

## Build local (MetaEditor)
Exemplo (Windows):
- `MetaEditor64.exe /compile:"...\\SupDemVol_-NextZero_v6.mq5" /log:"...\\compile.log"`

