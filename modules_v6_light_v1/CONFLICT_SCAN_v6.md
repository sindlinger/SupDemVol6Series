# Conflict Scan v6

Varredura de conflitos de ordem e execução entre módulos.

## Conflitos encontrados
- Organização rodava antes de merge na barra, podendo compactar antes de consolidar enriquecimento de toque.
- Organização contínua e merge corretivo podiam disputar a mesma barra/evento.
- Modo de organização contínua dependia indiretamente do flag diário (`InpOrganizacaoDiariaAtiva`) por causa de validação interna.

## Aplainamento aplicado
- Pipeline central reordenado para: criação -> merge -> organização.
- Organização contínua bloqueada quando há merge corretivo pendente (`g_mergeCorretivoPendente`).
- Organização contínua bloqueada quando o evento de merge da barra já foi consumido (`PodeProcessarMergeDoEvento`).
- Quando organização executa merge na barra, ela marca o evento (`MarcarMergeProcessadoNoEvento`).
- Função de organização principal passou a permitir execução quando `InpOrganizacaoEmBarraFechada=true` mesmo se o modo diário estiver desligado.

## Integridade de volume
- Em interseções multi-zona, o volume da barra é rateado por peso de interseção.
- Evita duplicação de volume em enriquecimento por toque.

## Status
- Compilação: 0 erros, 0 warnings.
- Inclusões do indicador principal apontam para `modules_v6`.
