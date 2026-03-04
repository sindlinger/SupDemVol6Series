#ifndef SUPDEMVOL_MODULE_MERGE_V3_MQH
#define SUPDEMVOL_MODULE_MERGE_V3_MQH

void SDV3_ModuloMergeProcessar(const int rates_total,
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

   // Regra de merge por barra: somente UM merge por evento de fechamento.
   // Uma zona pode participar de no maximo um merge por evento (sem cascata).
   bool podeMergeFechamento = PodeProcessarMergeDoEvento(time[idxFechada]);
   if(totalZonasTocadas > 1 &&
      podeMergeFechamento &&
      InpHabilitarMergeMesmaBarra &&
      InpPermitirRemoverZonasNoMerge &&
      (ContarZonasAtivas() > ObterLimiteAtivosParaCompactar())) {
      int idxCandA = -1, idxCandB = -1;
      double melhorDist = DBL_MAX;

      for(int a = 0; a < totalZonasTocadas; a++) {
         int idxA = zonasTocadas[a];
         if(idxA < 0 || idxA >= g_numeroZonas) continue;
         if(g_pivos[idxA].estado == PIVO_REMOVIDO) continue;
         if(g_pivos[idxA].foiMergeada) continue;
         if(ZonaRecemCriadaProtegida(idxA, time[idxFechada])) continue;

         for(int b = a + 1; b < totalZonasTocadas; b++) {
            int idxB = zonasTocadas[b];
            if(idxB < 0 || idxB >= g_numeroZonas) continue;
            if(g_pivos[idxB].estado == PIVO_REMOVIDO) continue;
            if(g_pivos[idxB].foiMergeada) continue;
            if(ZonaRecemCriadaProtegida(idxB, time[idxFechada])) continue;

            double supA = MathMax(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior);
            double infA = MathMin(g_pivos[idxA].precoSuperior, g_pivos[idxA].precoInferior);
            double supB = MathMax(g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
            double infB = MathMin(g_pivos[idxB].precoSuperior, g_pivos[idxB].precoInferior);
            double distEntre = DistanciaEntreFaixas(supA, infA, supB, infB);

            if(distEntre < melhorDist) {
               melhorDist = distEntre;
               idxCandA = idxA;
               idxCandB = idxB;
            }
         }
      }

      if(idxCandA >= 0 && idxCandB >= 0) {
         int idxManter = idxCandA;
         int idxAbsorver = idxCandB;
         if(g_pivos[idxCandA].tipo == LINE_TOP) {
            if(g_pivos[idxCandB].precoSuperior > g_pivos[idxCandA].precoSuperior) {
               idxManter = idxCandB;
               idxAbsorver = idxCandA;
            }
         } else {
            if(g_pivos[idxCandB].precoInferior < g_pivos[idxCandA].precoInferior) {
               idxManter = idxCandB;
               idxAbsorver = idxCandA;
            }
         }

         bool manterProtegido = ZonaRecemCriadaProtegida(idxManter, time[idxFechada]);
         bool absorverProtegido = ZonaRecemCriadaProtegida(idxAbsorver, time[idxFechada]);
         if(absorverProtegido && !manterProtegido) {
            int tmp = idxManter;
            idxManter = idxAbsorver;
            idxAbsorver = tmp;
         } else if(absorverProtegido && manterProtegido) {
            if(InpLogDetalhado) {
               Print("MERGE[mesma-barra][SKIP]: par protegido por recem-criacao.");
            }
            idxCandA = -1;
            idxCandB = -1;
         }

         if(idxCandA < 0 || idxCandB < 0) {
            // Par bloqueado por protecao de recem-criacao.
         } else if(AbsorverZonaSemMoverAncora(idxManter, idxAbsorver, time[idxFechada])) {
            // Garante que uma unica fusao ocorre nesse fechamento.
            houveIncrementoVolumeToque = true;
            MarcarMergeProcessadoNoEvento(time[idxFechada]);
            if(InpLogDetalhado) {
               Print("MERGE[mesma-barra][", (g_pivos[idxManter].tipo == LINE_TOP ? "TOP" : "BOTTOM"),
                     "]: zonas ", idxAbsorver, " + ", idxManter, " absorvidas sem deslocar ancora. dist=",
                     DoubleToString(melhorDist / _Point, 1), " pts.");
            }
         } else if(InpLogDetalhado) {
            Print("MERGE[mesma-barra][", (g_pivos[idxCandA].tipo == LINE_TOP ? "TOP" : "BOTTOM"),
                  "]: tentativa bloqueada para par ", idxCandA, "/", idxCandB, ".");
         }
      } else if(InpLogDetalhado) {
         Print("MERGE[mesma-barra][SKIP]: sem par valido para fusao. total tocadas=", totalZonasTocadas);
      }
   } else if(totalZonasTocadas > 1 && InpLogDetalhado) {
      Print("MERGE[mesma-barra][SKIP]: bloqueado por regra suave (evento ja consumido, modo remocao off ou zonas dentro do limite).");
   }

   // Agora acumula volume apenas uma vez por barra nas zonas sobreviventes.
   for(int k = 0; k < totalZonasTocadas; k++) {
      int i = zonasTocadas[k];
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      if(g_pivos[i].ultimoTempoToqueContabilizado == time[idxFechada]) continue;
      g_pivos[i].volumeTotal += (double)tick_volume[idxFechada];
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
