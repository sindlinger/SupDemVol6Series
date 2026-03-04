#ifndef SUPDEMVOL_MODULE_MERGE_V5_MQH
#define SUPDEMVOL_MODULE_MERGE_V5_MQH

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
   double interSup[20];
   double interInf[20];
   double pesoIntersecao[20];
   int totalZonasTocadas = 0;

   // Primeiro: detectar todas as zonas tocadas pela barra fechada.
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(time[idxFechada] <= g_pivos[i].tempoInicio) continue; // so outra barra
      if(BarraInterseccionaFaixa(high[idxFechada], low[idxFechada],
                                 g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
         if(totalZonasTocadas < 20) {
            double supZona = MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
            double infZona = MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
            double supInt = MathMin(high[idxFechada], supZona);
            double infInt = MathMax(low[idxFechada], infZona);
            double altInt = supInt - infInt;
            if(altInt <= 0.0) {
               double faixaMin = ObterAlturaMinimaZonaPreco();
               if(faixaMin <= 0.0) faixaMin = _Point * 2.0;
               double meio = (supZona + infZona) * 0.5;
               supInt = meio + (faixaMin * 0.5);
               infInt = meio - (faixaMin * 0.5);
               altInt = faixaMin;
            }
            zonasTocadas[totalZonasTocadas] = i;
            interSup[totalZonasTocadas] = supInt;
            interInf[totalZonasTocadas] = infInt;
            pesoIntersecao[totalZonasTocadas] = altInt;
            totalZonasTocadas++;
         }
      }
   }

   // Interseção/toque em barra fechada conta como enriquecimento da zona tocada.
   if(totalZonasTocadas > 1 && InpLogDetalhado) {
      Print("MERGE[mesma-barra][ON]: interseções enriquecem todas as zonas tocadas.");
   }

   // Enriquecimento por toque/interseção: acumula volume e aumenta faixa da zona de forma proporcional.
   double volumeEvento = (double)tick_volume[idxFechada];
   if(volumeEvento < 0.0) volumeEvento = 0.0;
   bool barraAcimaBanda = (BandaSuperiorBuffer[idxFechada] > 0.0 &&
                           VolumeBuffer[idxFechada] > BandaSuperiorBuffer[idxFechada]);
   double somaPesos = 0.0;
   for(int k = 0; k < totalZonasTocadas; k++) {
      double p = pesoIntersecao[k];
      if(!MathIsValidNumber(p) || p <= 0.0) p = 1.0;
      somaPesos += p;
   }
   if(somaPesos <= 0.0) somaPesos = (double)totalZonasTocadas;

   for(int k = 0; k < totalZonasTocadas; k++) {
      int i = zonasTocadas[k];
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(g_pivos[i].ultimoTempoToqueContabilizado == time[idxFechada]) continue;
      double peso = pesoIntersecao[k];
      if(!MathIsValidNumber(peso) || peso <= 0.0) peso = 1.0;
      double volumeParcela = (somaPesos > 0.0) ? (volumeEvento * (peso / somaPesos)) : 0.0;
      if(volumeParcela < 0.0) volumeParcela = 0.0;

      bool enriqueceu = MergeQuandoCriacaoProxima(i,
                                                  g_pivos[i].tipo,
                                                  time[idxFechada],
                                                  volumeParcela,
                                                  interSup[k],
                                                  interInf[k],
                                                  barraAcimaBanda);
      if(enriqueceu) {
         houveIncrementoVolumeToque = true;
         deveRecalcular = true;
      }
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
