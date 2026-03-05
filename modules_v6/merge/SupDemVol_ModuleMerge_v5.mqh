#ifndef SUPDEMVOL_MODULE_MERGE_V5_MQH
#define SUPDEMVOL_MODULE_MERGE_V5_MQH

void SDV4_ModuloMergeProcessar(const int rates_total,
                               const bool barraNova,
                               const datetime &time[],
                               const double &open[],
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
   if(!SDV4_RegrasPermitirEntradaModulo(SDV4_EXEC_MOD_MERGE, time[idxFechada], "MOD-MERGE")) return;
   if(g_tempoEventoVolumeConsumidoCriacao == time[idxFechada]) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("MERGE[toque][SKIP]: barra já consumida pela criação em tempo real.");
      }
      return;
   }

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
   if(totalZonasTocadas > 1 && SDV4_RegrasLogDetalhadoAtivo()) {
      Print("MERGE[mesma-barra][ON]: interseções enriquecem todas as zonas tocadas.");
   }

   // Enriquecimento por toque/interseção: acumula volume e aumenta faixa da zona de forma proporcional.
   double volumeEvento = (double)tick_volume[idxFechada];
   if(volumeEvento < 0.0) volumeEvento = 0.0;
   bool barraAcimaBanda = (BandaSuperiorBuffer[idxFechada] > 0.0 &&
                           VolumeBuffer[idxFechada] > BandaSuperiorBuffer[idxFechada]);
   ENUM_LINE_TYPE tipoSombraBarra = DeterminarTipoLinhaPorSombra(idxFechada, open, high, low, close);
   double fracaoCompraSombra = 0.5;
   double fracaoVendaSombra = 0.5;
   SDV4_CalcularFracaoSombraBarra(idxFechada,
                                  open,
                                  high,
                                  low,
                                  close,
                                  tipoSombraBarra,
                                  fracaoCompraSombra,
                                  fracaoVendaSombra);
   bool modoMixSombra = SDV4_RegrasModoConflitoMixSombra();
   bool permitirEnriquecimentoPorToque = (!SDV4_RegrasEnriquecimentoToqueSomenteAcimaBanda() || barraAcimaBanda);
   if(totalZonasTocadas > 0 && !permitirEnriquecimentoPorToque && SDV4_RegrasLogDetalhadoAtivo()) {
      Print("MERGE[toque][SKIP]: toque detectado, mas enriquecimento exige volume acima da banda.");
   }
   int zonasElegiveis[20];
   double interSupElegiveis[20];
   double interInfElegiveis[20];
   double pesosElegiveis[20];
   int totalElegiveis = 0;
   double somaPesosElegiveis = 0.0;

   if(permitirEnriquecimentoPorToque) {
      for(int k = 0; k < totalZonasTocadas; k++) {
         int i = zonasTocadas[k];
         if(i < 0 || i >= g_numeroZonas) continue;
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         if(g_pivos[i].ultimoTempoToqueContabilizado == time[idxFechada]) continue;
         if(totalElegiveis >= 20) break;

         double peso = pesoIntersecao[k];
         if(!MathIsValidNumber(peso) || peso <= 0.0) peso = 1.0;
         zonasElegiveis[totalElegiveis] = i;
         interSupElegiveis[totalElegiveis] = interSup[k];
         interInfElegiveis[totalElegiveis] = interInf[k];
         pesosElegiveis[totalElegiveis] = peso;
         somaPesosElegiveis += peso;
         totalElegiveis++;
      }
   }

   if(totalZonasTocadas > 0 && permitirEnriquecimentoPorToque && totalElegiveis <= 0 && SDV4_RegrasLogDetalhadoAtivo()) {
      Print("MERGE[toque][SKIP]: toque detectado, mas zonas já contabilizadas nesta barra.");
   }
   if(totalElegiveis > 0 && somaPesosElegiveis <= 0.0) somaPesosElegiveis = (double)totalElegiveis;
   double volumeZonasAntes = 0.0;
   for(int k = 0; k < totalElegiveis; k++) {
      int i = zonasElegiveis[k];
      if(i < 0 || i >= g_numeroZonas) continue;
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      volumeZonasAntes += MathMax(0.0, g_pivos[i].volumeTotal);
   }

   double volumeAplicado = 0.0;
   double volumeAplicadoBuy = 0.0;
   double volumeAplicadoSell = 0.0;
   int idxDebugDestinoBuy = -1;
   int idxDebugDestinoSell = -1;
   for(int k = 0; k < totalElegiveis; k++) {
      int i = zonasElegiveis[k];
      if(i < 0 || i >= g_numeroZonas) continue;
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      double peso = pesosElegiveis[k];
      if(!MathIsValidNumber(peso) || peso <= 0.0) peso = 1.0;
      double volumeParcela = (somaPesosElegiveis > 0.0) ? (volumeEvento * (peso / somaPesosElegiveis)) : 0.0;
      if(volumeParcela < 0.0) volumeParcela = 0.0;
      if(volumeParcela <= 1e-9) continue;

      ENUM_LINE_TYPE tipoParcela = tipoSombraBarra;
      double volumeParcelaAjustada = volumeParcela;
      if(modoMixSombra) {
         if(g_pivos[i].tipo == LINE_BOTTOM) {
            tipoParcela = LINE_BOTTOM;
            volumeParcelaAjustada = volumeParcela * fracaoCompraSombra;
         } else {
            tipoParcela = LINE_TOP;
            volumeParcelaAjustada = volumeParcela * fracaoVendaSombra;
         }
      }
      if(volumeParcelaAjustada <= 1e-9) continue;

      bool enriqueceu = MergeQuandoCriacaoProxima(i,
                                                  tipoParcela,
                                                  time[idxFechada],
                                                  volumeParcelaAjustada,
                                                  interSupElegiveis[k],
                                                  interInfElegiveis[k],
                                                  barraAcimaBanda);
      if(enriqueceu) {
         volumeAplicado += volumeParcelaAjustada;
         if(tipoParcela == LINE_BOTTOM) {
            volumeAplicadoBuy += volumeParcelaAjustada;
            idxDebugDestinoBuy = i;
         } else {
            volumeAplicadoSell += volumeParcelaAjustada;
            idxDebugDestinoSell = i;
         }
         RegistrarEventoEnriquecimentoNoGrafico("TOQUE-BARRA",
                                                time[idxFechada],
                                                i,
                                                volumeParcelaAjustada);
         houveIncrementoVolumeToque = true;
         deveRecalcular = true;
      }
   }

   // Fecha conservação de massa do evento: residual deve respeitar o sinal da barra.
   if(totalElegiveis > 0) {
      double residualBuy = 0.0;
      double residualSell = 0.0;
      if(modoMixSombra) {
         double metaBuy = volumeEvento * fracaoCompraSombra;
         double metaSell = volumeEvento * fracaoVendaSombra;
         residualBuy = metaBuy - volumeAplicadoBuy;
         residualSell = metaSell - volumeAplicadoSell;
      } else {
         double residual = volumeEvento - volumeAplicado;
         if(tipoSombraBarra == LINE_BOTTOM) residualBuy = residual;
         else residualSell = residual;
      }
      if(residualBuy < 0.0) residualBuy = 0.0;
      if(residualSell < 0.0) residualSell = 0.0;

      if(residualBuy > 1e-6) {
         int idxDestinoResidual = -1;
         int kDestinoResidual = -1;
         for(int k = 0; k < totalElegiveis; k++) {
            int idxZ = zonasElegiveis[k];
            if(idxZ < 0 || idxZ >= g_numeroZonas) continue;
            if(g_pivos[idxZ].estado == PIVO_REMOVIDO) continue;
            if(idxDestinoResidual < 0) {
               idxDestinoResidual = idxZ;
               kDestinoResidual = k;
            }
            if(g_pivos[idxZ].tipo == LINE_BOTTOM) {
               idxDestinoResidual = idxZ;
               kDestinoResidual = k;
               break;
            }
         }
         if(idxDestinoResidual >= 0) {
            bool aplicouResidual = MergeQuandoCriacaoProxima(idxDestinoResidual,
                                                             LINE_BOTTOM,
                                                             time[idxFechada],
                                                             residualBuy,
                                                             interSupElegiveis[kDestinoResidual],
                                                             interInfElegiveis[kDestinoResidual],
                                                             barraAcimaBanda);
            if(aplicouResidual) {
               volumeAplicado += residualBuy;
               volumeAplicadoBuy += residualBuy;
               idxDebugDestinoBuy = idxDestinoResidual;
               RegistrarEventoEnriquecimentoNoGrafico("TOQUE-RESIDUAL-BUY",
                                                      time[idxFechada],
                                                      idxDestinoResidual,
                                                      residualBuy);
               houveIncrementoVolumeToque = true;
               deveRecalcular = true;
            }
         }
      }

      if(residualSell > 1e-6) {
         int idxDestinoResidual = -1;
         int kDestinoResidual = -1;
         for(int k = 0; k < totalElegiveis; k++) {
            int idxZ = zonasElegiveis[k];
            if(idxZ < 0 || idxZ >= g_numeroZonas) continue;
            if(g_pivos[idxZ].estado == PIVO_REMOVIDO) continue;
            if(idxDestinoResidual < 0) {
               idxDestinoResidual = idxZ;
               kDestinoResidual = k;
            }
            if(g_pivos[idxZ].tipo == LINE_TOP) {
               idxDestinoResidual = idxZ;
               kDestinoResidual = k;
               break;
            }
         }
         if(idxDestinoResidual >= 0) {
            bool aplicouResidual = MergeQuandoCriacaoProxima(idxDestinoResidual,
                                                             LINE_TOP,
                                                             time[idxFechada],
                                                             residualSell,
                                                             interSupElegiveis[kDestinoResidual],
                                                             interInfElegiveis[kDestinoResidual],
                                                             barraAcimaBanda);
            if(aplicouResidual) {
               volumeAplicado += residualSell;
               volumeAplicadoSell += residualSell;
               idxDebugDestinoSell = idxDestinoResidual;
               RegistrarEventoEnriquecimentoNoGrafico("TOQUE-RESIDUAL-SELL",
                                                      time[idxFechada],
                                                      idxDestinoResidual,
                                                      residualSell);
               houveIncrementoVolumeToque = true;
               deveRecalcular = true;
            }
         }
      }
   }

   if(totalZonasTocadas > 0) {
      double volumeResidualFinal = volumeEvento - volumeAplicado;
      if(!MathIsValidNumber(volumeResidualFinal)) volumeResidualFinal = 0.0;
      if(MathAbs(volumeResidualFinal) < 1e-6) volumeResidualFinal = 0.0;
      double volumeZonasDepois = 0.0;
      for(int k = 0; k < totalElegiveis; k++) {
         int i = zonasElegiveis[k];
         if(i < 0 || i >= g_numeroZonas) continue;
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         volumeZonasDepois += MathMax(0.0, g_pivos[i].volumeTotal);
      }
      RegistrarAuditoriaEnriquecimentoBarraNoGrafico(time[idxFechada],
                                                     volumeEvento,
                                                     volumeAplicado,
                                                     volumeResidualFinal,
                                                     totalZonasTocadas,
                                                     totalElegiveis,
                                                     volumeZonasAntes,
                                                     volumeZonasDepois);
      if(volumeAplicado > 1e-9) {
         RegistrarDebugAlocacaoBarraNoGrafico("TOQUE",
                                              time[idxFechada],
                                              idxDebugDestinoBuy,
                                              volumeAplicadoBuy,
                                              idxDebugDestinoSell,
                                              volumeAplicadoSell);
      }
   }

}

#endif
