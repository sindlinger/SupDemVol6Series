#ifndef SUPDEMVOL_MODULE_MERGE_V3_MQH
#define SUPDEMVOL_MODULE_MERGE_V3_MQH

void SDV4_ModuloMergeProcessar(const int rates_total,
                               const bool barraNova,
                               const datetime &time[],
                               const double &high[],
                               const double &low[],
                               const double &close[],
                               const long &tick_volume[],
                               bool &deveRecalcular,
                               bool &houveIncrementoVolumeToque) {
   // Incremento de volume: so barras que TOCARAM a zona, e apenas uma vez por barra.
   if(!g_pivosInicializados || !barraNova || rates_total < 2) return;

   int idxFechada = rates_total - 2;
   if(idxFechada < 0) return;

   int zonasTocadas[20];
   int totalZonasTocadas = 0;

   // Primeiro: detectar todas as zonas tocadas pela barra fechada.
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(time[idxFechada] <= g_pivos[i].tempoInicio) continue; // so outra barra
      if(BarraInterseccionaFaixa(high[idxFechada], low[idxFechada],
                                 g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
         if(totalZonasTocadas < 20) zonasTocadas[totalZonasTocadas++] = i;
      }
   }

   // Merge por interseccao/toque na mesma barra foi removido por regra do usuario.
   // Toques agora apenas acumulam volume; a compactacao fica com organizacao e overflow.
   if(totalZonasTocadas > 1 && InpLogDetalhado) {
      Print("MERGE[mesma-barra][OFF]: desativado. Toques apenas acumulam volume.");
   }

   // Agora acumula volume apenas uma vez por barra nas zonas sobreviventes.
   for(int k = 0; k < totalZonasTocadas; k++) {
      int i = zonasTocadas[k];
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(g_pivos[i].ultimoTempoToqueContabilizado == time[idxFechada]) continue;
      g_pivos[i].volumeTotal += (double)tick_volume[idxFechada];
      if(BandaSuperiorBuffer[idxFechada] > 0.0 &&
         VolumeBuffer[idxFechada] > BandaSuperiorBuffer[idxFechada]) {
         g_pivos[i].volumeDistribuicao += (double)tick_volume[idxFechada];
      }
      g_pivos[i].quantidadeBarras++;
      g_pivos[i].tempoMaisRecente = MathMax(g_pivos[i].tempoMaisRecente, time[idxFechada]);
      g_pivos[i].ultimoTempoToqueContabilizado = time[idxFechada];
      houveIncrementoVolumeToque = true;
   }

   // Overflow suave: compacta so quando passar do limite suave (alvo + margem).
   if(g_mergeCorretivoPendente &&
      time[idxFechada] > g_tempoCriacaoOverflow &&
      DeveCompactarPorExcessoDeZonas()) {
      bool podeMergeCorretivo = PodeProcessarMergeDoEvento(time[idxFechada]);
      if(podeMergeCorretivo) {
         datetime diaFechada = time[idxFechada] - (time[idxFechada] % 86400);
         if(ExecutarMergeCorretivoOverflow(close[idxFechada], diaFechada, time[idxFechada])) {
            MarcarMergeProcessadoNoEvento(time[idxFechada]);
            deveRecalcular = true;
            houveIncrementoVolumeToque = true;
            if(InpLogDetalhado) {
               Print("MERGE[overflow]: compactacao corretiva aplicada na barra seguinte.");
            }
         } else if(InpLogDetalhado) {
            Print("MERGE[overflow][SKIP]: nenhum par valido para compactacao nesta barra.");
         }
      }
   }

   if(ContarZonasAtivas() <= ObterLimiteAtivosParaCompactar()) {
      g_mergeCorretivoPendente = false;
      g_tempoCriacaoOverflow = 0;
   }
}

#endif
