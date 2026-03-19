#ifndef SUPDEMVOL_MODULE_CENTRAL_V5_MQH
#define SUPDEMVOL_MODULE_CENTRAL_V5_MQH

#include "organizacao/SupDemVol_ModuleOrganizacao_v5.mqh"
#include "enriquecimento/SupDemVol_ModuleEnriquecimento_v5.mqh"
#include "criacao/SupDemVol_ModuleCriacao_v5.mqh"
#include "merge/SupDemVol_ModuleMerge_v5.mqh"

void SDV4_ModuloCentralProcessar(const int rates_total,
                                 const int prev_calculated,
                                 const datetime &time[],
                                 const double &open[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[]) {
   bool deveRecalcular = false;
   bool barraNova = (prev_calculated > 0 && rates_total > prev_calculated);
   bool houveMudancaEstado = false;
   bool houveCriacaoNova = false;
   bool houveIncrementoVolumeToque = false;

   if(SDV4_RegrasLowCostTotalAtivo() && !barraNova) return;

   SDV4_ExecIniciarCiclo();
   SDV4_ResetarFlagsMergeTemporarias();

   // Verificar se mudou o dia.
   datetime agora = time[rates_total - 1];
   datetime hojeMidnight = agora - (agora % 86400); // meia-noite de hoje

   if(prev_calculated == 0) {
      g_ultimoDiaAnalise = hojeMidnight;
      if(SDV4_RegrasLogDetalhadoAtivo()) Print("Primeira execucao");
   } else if(g_ultimoDiaAnalise != hojeMidnight) {
      g_ultimoDiaAnalise = hojeMidnight;
      if(SDV4_RegrasLogDetalhadoAtivo()) Print("Novo dia detectado");
   }

   // Organização-first: tenta limpar zonas coladas/excesso antes da criação/merge.
   SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_ORG_PRE);
   SDV4_ExecConcederModulo(SDV4_EXEC_MOD_ORGANIZACAO, SDV4_EXEC_FASE_ORG_PRE);
   SDV4_ModuloOrganizacaoProcessar(rates_total, barraNova, time, close, deveRecalcular, false);
   SDV4_ResetarFlagsMergeTemporarias();

   SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_CRIACAO);
   SDV4_ExecConcederModulo(SDV4_EXEC_MOD_CRIACAO, SDV4_EXEC_FASE_CRIACAO);
   SDV4_ModuloCriacaoProcessar(rates_total, barraNova, time, open, high, low, close, tick_volume, deveRecalcular, houveCriacaoNova);
   SDV4_ResetarFlagsMergeTemporarias();

   string motivoOrgDemanda = "";
   if(SDV4_ExecConsumirSolicitacaoOrganizacao(motivoOrgDemanda)) {
      bool forcarExecucaoOrganizacao = (!barraNova);
      SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_ORG_DEMANDA);
      SDV4_ExecConcederModulo(SDV4_EXEC_MOD_ORGANIZACAO, SDV4_EXEC_FASE_ORG_DEMANDA);
      SDV4_ResetarFlagsMergeTemporarias();
      SDV4_ModuloOrganizacaoProcessar(rates_total,
                                      barraNova,
                                      time,
                                      close,
                                      deveRecalcular,
                                      true,
                                      forcarExecucaoOrganizacao);
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("ORGANIZACAO_DEMANDA: solicitação processada pelo módulo central (",
               motivoOrgDemanda,
               ") modo=",
               (forcarExecucaoOrganizacao ? "RT" : "BARRA-FECHADA"),
               ".");
      }
   }
   SDV4_ResetarFlagsMergeTemporarias();

   SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_MERGE);
   SDV4_ExecConcederModulo(SDV4_EXEC_MOD_MERGE, SDV4_EXEC_FASE_MERGE);
   SDV4_ModuloMergeProcessar(rates_total, barraNova, time, open, high, low, close, tick_volume, deveRecalcular, houveIncrementoVolumeToque);
   SDV4_ResetarFlagsMergeTemporarias();

   // Segunda passada: organiza novamente após novos eventos de criação/toque.
   SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_ORG_POS);
   SDV4_ExecConcederModulo(SDV4_EXEC_MOD_ORGANIZACAO, SDV4_EXEC_FASE_ORG_POS);
   SDV4_ModuloOrganizacaoProcessar(rates_total, barraNova, time, close, deveRecalcular, true);
   SDV4_ResetarFlagsMergeTemporarias();
   SDV4_ExecDefinirFaseAtual(SDV4_EXEC_FASE_NONE);
   // Filtro por faixa de preco desativado: nao hiberna/desativa zonas por distancia.

   if(g_pivosInicializados && SDV4_RegrasHabilitarTravaAncora()) {
      AplicarTravaAncoraPivos();
   }

   // Validacao de rompimento apenas quando necessario.
   if(g_pivosInicializados && (barraNova || !SDV4_RegrasAtualizarUIApenasBarraNova()))
      houveMudancaEstado = VerificarRompimentosEAssentamento(rates_total, close);

   if(g_pivosInicializados &&
      (deveRecalcular || houveCriacaoNova || houveIncrementoVolumeToque) &&
      SDV4_RegrasPermitirCalculoPercentuais(rates_total, "CENTRAL-CALC-PCT"))
      CalcularPercentuaisVolume(rates_total, time, high, low);

   bool houveIncrementoVisual = houveIncrementoVolumeToque;
   if(SDV4_ArteEnriquecimentoVisualDesligada()) {
      houveIncrementoVisual = false;
   }

   bool deveAtualizarUI = deveRecalcular || houveCriacaoNova || houveIncrementoVisual ||
                          houveMudancaEstado || barraNova || !SDV4_RegrasAtualizarUIApenasBarraNova();
   if(deveAtualizarUI) {
      if(SDV4_RegrasPermitirAcaoVisual(SDV4_REGRA_ACAO_DESENHAR, rates_total, "CENTRAL-DESENHAR"))
         DesenharPivos(rates_total, time);
      if(SDV4_RegrasPermitirAcaoVisual(SDV4_REGRA_ACAO_ATUALIZAR_COORD, rates_total, "CENTRAL-COORD"))
         AtualizarCoordenadasPivos(rates_total, time);
   }
}

#endif
