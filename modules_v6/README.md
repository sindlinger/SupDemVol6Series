# modules_v6

Pacote versionado dos módulos ativos do `SupDemVol_-NextZero_v6`.

## Módulos
- `SupDemVol_ModuleCentral_v5.mqh`
- `SupDemVol_ModuleCriacao_v5.mqh`
- `SupDemVol_ModuleCriacaoGatilho_v5.mqh`
- `SupDemVol_ModuleCriacaoCandidata_v5.mqh`
- `SupDemVol_ModuleCriacaoAlocacao_v5.mqh`
- `SupDemVol_ModuleEnriquecimento_v5.mqh`
- `SupDemVol_ModuleMerge_v5.mqh`
- `SupDemVol_ModuleOrganizacao_v5.mqh`
- `SupDemVol_ModuleOrganizacaoCore_v5.mqh`
- `SupDemVol_ModuleLinhasReferencia_v5.mqh`
- `SupDemVol_ModulePercentuais_v5.mqh`
- `SupDemVol_ModuleRuntimeOps_v5.mqh`
- `SupDemVol_ModuleVisual_v5.mqh`
- `SupDemVol_MergeRules_v5.mqh`

## Ordem de pipeline (aplainada)
1. Criação (`ModuleCriacao`)
: internamente dividido em `CriacaoGatilho` -> `CriacaoCandidata` -> `CriacaoAlocacao`
2. Enriquecimento de criação (`ModuleEnriquecimento`)
3. Merge/Toque de barra fechada (`ModuleMerge`)
4. Organização contínua (`ModuleOrganizacao`)

## Por que existem módulos "em dupla"
- `ModuleMerge` + `MergeRules`:  
`ModuleMerge` orquestra quando processar merge no ciclo de execução.  
`MergeRules` concentra as regras de decisão e critérios de fusão.
- `ModuleOrganizacao` + `ModuleOrganizacaoCore`:  
`ModuleOrganizacao` agenda/orquestra a organização contínua.  
`ModuleOrganizacaoCore` executa a lógica pesada de ordenação/compactação.
- `ModuleRuntimeOps`:  
utilitários de runtime compartilhados (operações comuns de faixa/interseção/estado visual e suporte de execução).

## Uso pelo indicador principal
O arquivo `SupDemVol_-NextZero_v6.mq5` inclui este pacote por:
- `#include "modules_v6/SupDemVol_MergeRules_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModuleLinhasReferencia_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModuleOrganizacaoCore_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModulePercentuais_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModuleRuntimeOps_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModuleVisual_v5.mqh"`
- `#include "modules_v6/SupDemVol_ModuleCentral_v5.mqh"`

Isso permite evoluir os módulos sem perder o histórico dos arquivos anteriores na raiz.
