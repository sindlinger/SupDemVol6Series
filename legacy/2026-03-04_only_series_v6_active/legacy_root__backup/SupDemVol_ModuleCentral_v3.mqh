#ifndef SUPDEMVOL_MODULE_CENTRAL_V3_MQH
#define SUPDEMVOL_MODULE_CENTRAL_V3_MQH

#include "SupDemVol_ModuleOrganizacao_v3.mqh"
#include "SupDemVol_ModuleCriacao_v3.mqh"
#include "SupDemVol_ModuleMerge_v3.mqh"

void SDV3_ModuloCentralProcessar(const int rates_total,
                                 const int prev_calculated,
                                 const datetime &time[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[]) {
   bool deveRecalcular = false;
   bool barraNova = (prev_calculated > 0 && rates_total > prev_calculated);
   bool houveMudancaEstado = false;
   bool houveCriacaoNova = false;
   bool houveIncrementoVolumeToque = false;

   // Reseta flags temporarias para nao travar merges em barras seguintes.
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      g_pivos[i].foiMergeada = false;
   }

   // Verificar se mudou o dia.
   datetime agora = time[rates_total - 1];
   datetime hojeMidnight = agora - (agora % 86400); // meia-noite de hoje

   if(prev_calculated == 0) {
      g_ultimoDiaAnalise = hojeMidnight;
      if(InpLogDetalhado) Print("Primeira execucao");
   } else if(g_ultimoDiaAnalise != hojeMidnight) {
      g_ultimoDiaAnalise = hojeMidnight;
      if(InpLogDetalhado) Print("Novo dia detectado");
   }

   SDV3_ModuloOrganizacaoProcessar(rates_total, agora, hojeMidnight, close, deveRecalcular);
   SDV3_ModuloCriacaoProcessar(rates_total, time, high, low, close, tick_volume, deveRecalcular, houveCriacaoNova);
   SDV3_ModuloMergeProcessar(rates_total, barraNova, time, high, low, close, tick_volume, deveRecalcular, houveIncrementoVolumeToque);

   if(g_pivosInicializados && InpHabilitarTravaAncora) {
      AplicarTravaAncoraPivos();
   }

   // Validacao de rompimento apenas quando necessario.
   if(g_pivosInicializados && (barraNova || !InpAtualizarUIApenasBarraNova))
      houveMudancaEstado = VerificarRompimentosEAssentamento(rates_total, close);

   if(g_pivosInicializados && (deveRecalcular || houveCriacaoNova || houveIncrementoVolumeToque))
      CalcularPercentuaisVolume();

   bool deveAtualizarUI = deveRecalcular || houveCriacaoNova || houveIncrementoVolumeToque ||
                          houveMudancaEstado || barraNova || !InpAtualizarUIApenasBarraNova;
   if(deveAtualizarUI) {
      DesenharPivos(rates_total, time);
      AtualizarCoordenadasPivos(rates_total, time);
   }
}

#endif
