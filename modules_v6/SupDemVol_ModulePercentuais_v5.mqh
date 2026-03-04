#ifndef SUPDEMVOL_MODULE_PERCENTUAIS_V5_MQH
#define SUPDEMVOL_MODULE_PERCENTUAIS_V5_MQH

double DistanciaPrecoParaFaixaZona(const double preco,
                                   const double faixaSuperior,
                                   const double faixaInferior) {
   double sup = MathMax(faixaSuperior, faixaInferior);
   double inf = MathMin(faixaSuperior, faixaInferior);
   if(preco > sup) return (preco - sup);
   if(preco < inf) return (inf - preco);
   return 0.0;
}

bool DistribuirVolumeAltoJanelaEmZonas(const int rates_total,
                                       const datetime &time[],
                                       const double &high[],
                                       const double &low[],
                                       const int diasBase,
                                       double &totalVolumeAltoJanela,
                                       double &totalDistribuido,
                                       double &erroResidual,
                                       double &volumesZonas[]) {
   totalVolumeAltoJanela = 0.0;
   totalDistribuido = 0.0;
   erroResidual = 0.0;
   for(int i = 0; i < 20; i++) volumesZonas[i] = 0.0;

   if(rates_total <= 0) return false;
   if(rates_total > ArraySize(time) || rates_total > ArraySize(high) || rates_total > ArraySize(low)) return false;

   int dias = diasBase;
   if(dias < 1) dias = 1;
   if(dias > 30) dias = 30;

   datetime diaAtual = ObterInicioDia(time[rates_total - 1]);
   datetime diaLimite = diaAtual - (datetime)((dias - 1) * 86400);

   int ativos[20];
   int nAtivos = 0;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      ativos[nAtivos++] = i;
   }
   if(nAtivos <= 0) {
      // Sem zonas ativas: ainda mede o total de mercado para log/diagnóstico.
      for(int b = rates_total - 1; b >= 0; b--) {
         datetime diaBarra = ObterInicioDia(time[b]);
         if(diaBarra < diaLimite) break;
         if(b >= ArraySize(VolumeBuffer) || b >= ArraySize(BandaSuperiorBuffer)) continue;
         double vol = VolumeBuffer[b];
         double banda = BandaSuperiorBuffer[b];
         if(vol > 0.0 && banda > 0.0 && vol > banda) totalVolumeAltoJanela += vol;
      }
      return false;
   }

   for(int b = rates_total - 1; b >= 0; b--) {
      datetime diaBarra = ObterInicioDia(time[b]);
      if(diaBarra < diaLimite) break;
      if(b >= ArraySize(VolumeBuffer) || b >= ArraySize(BandaSuperiorBuffer)) continue;

      double volBarra = VolumeBuffer[b];
      double banda = BandaSuperiorBuffer[b];
      if(!(volBarra > 0.0 && banda > 0.0 && volBarra > banda)) continue;

      double supBarra = MathMax(high[b], low[b]);
      double infBarra = MathMin(high[b], low[b]);

      int idxInter[20];
      double pesoInter[20];
      int nInter = 0;
      double somaPesos = 0.0;

      for(int k = 0; k < nAtivos; k++) {
         int idxZona = ativos[k];
         double supZona = MathMax(g_pivos[idxZona].precoSuperior, g_pivos[idxZona].precoInferior);
         double infZona = MathMin(g_pivos[idxZona].precoSuperior, g_pivos[idxZona].precoInferior);
         double supInt = MathMin(supBarra, supZona);
         double infInt = MathMax(infBarra, infZona);
         double altInt = supInt - infInt;
         if(altInt <= 0.0) continue;

         idxInter[nInter] = idxZona;
         pesoInter[nInter] = altInt;
         somaPesos += altInt;
         nInter++;
      }

      if(nInter > 0 && somaPesos > 0.0) {
         totalVolumeAltoJanela += volBarra;
         for(int k = 0; k < nInter; k++) {
            int idxZona = idxInter[k];
            double parcela = volBarra * (pesoInter[k] / somaPesos);
            if(parcela < 0.0) parcela = 0.0;
            volumesZonas[idxZona] += parcela;
            totalDistribuido += parcela;
         }
      }
   }

   // Fechamento de massa para não sobrar/faltar volume por arredondamento/empates.
   erroResidual = totalVolumeAltoJanela - totalDistribuido;
   if(MathAbs(erroResidual) > 1e-6) {
      int idxAjuste = ativos[0];
      double maiorVol = volumesZonas[idxAjuste];
      for(int k = 1; k < nAtivos; k++) {
         int idxZona = ativos[k];
         if(volumesZonas[idxZona] > maiorVol) {
            maiorVol = volumesZonas[idxZona];
            idxAjuste = idxZona;
         }
      }
      volumesZonas[idxAjuste] += erroResidual;
      if(volumesZonas[idxAjuste] < 0.0) volumesZonas[idxAjuste] = 0.0;

      totalDistribuido = 0.0;
      for(int k = 0; k < nAtivos; k++) {
         int idxZona = ativos[k];
         totalDistribuido += volumesZonas[idxZona];
      }
      erroResidual = totalVolumeAltoJanela - totalDistribuido;
   }

   return true;
}

void CalcularPercentuaisVolume(const int rates_total,
                               const datetime &time[],
                               const double &high[],
                               const double &low[]) {
   g_volumeMaximoGlobal = 0.0;
   double volumePonderado[20];
   for(int i = 0; i < 20; i++) volumePonderado[i] = 0.0;

   if(InpPercentualNominalSimples) {
      double totalVolumeAltoJanela = 0.0;
      double totalDistribuido = 0.0;
      double erroResidual = 0.0;
      double volumeDistribuidoPorZona[20];
      for(int i = 0; i < 20; i++) volumeDistribuidoPorZona[i] = 0.0;

      bool usouRateioEstrito = false;
      if(InpConservacaoVolumeAltoEstrita) {
         usouRateioEstrito = DistribuirVolumeAltoJanelaEmZonas(rates_total,
                                                               time,
                                                               high,
                                                               low,
                                                               3,
                                                               totalVolumeAltoJanela,
                                                               totalDistribuido,
                                                               erroResidual,
                                                               volumeDistribuidoPorZona);
      }

      if(totalVolumeAltoJanela < 0.0) totalVolumeAltoJanela = 0.0;
      double totalZonasNominal = 0.0;

      if(usouRateioEstrito) {
         int ativos[20];
         int nAtivos = 0;
         for(int i = 0; i < g_numeroZonas; i++) {
            if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
            ativos[nAtivos++] = i;
         }

         if(nAtivos > 0) {
            long baseInt[20];
            double frac[20];
            long somaBaseInt = 0;
            for(int k = 0; k < nAtivos; k++) {
               int idxZona = ativos[k];
               double v = volumeDistribuidoPorZona[idxZona];
               if(v < 0.0) v = 0.0;
               long b = (long)MathFloor(v + 1e-9);
               if(b < 0) b = 0;
               baseInt[k] = b;
               frac[k] = v - (double)b;
               somaBaseInt += b;
            }

            long alvoInt = (long)MathRound(totalVolumeAltoJanela);
            long restante = alvoInt - somaBaseInt;

            while(restante > 0) {
               int melhor = 0;
               double melhorFrac = -DBL_MAX;
               for(int k = 0; k < nAtivos; k++) {
                  if(frac[k] > melhorFrac) {
                     melhorFrac = frac[k];
                     melhor = k;
                  }
               }
               baseInt[melhor] += 1;
               frac[melhor] = -DBL_MAX; // evita receber de novo no mesmo passe
               restante--;
               bool todosConsumidos = true;
               for(int k = 0; k < nAtivos; k++) {
                  if(frac[k] != -DBL_MAX) { todosConsumidos = false; break; }
               }
               if(todosConsumidos) {
                  for(int k = 0; k < nAtivos; k++) frac[k] = 0.0;
               }
            }

            while(restante < 0) {
               int melhor = -1;
               double menorFrac = DBL_MAX;
               for(int k = 0; k < nAtivos; k++) {
                  if(baseInt[k] <= 0) continue;
                  if(frac[k] < menorFrac) {
                     menorFrac = frac[k];
                     melhor = k;
                  }
               }
               if(melhor < 0) break;
               baseInt[melhor] -= 1;
               restante++;
            }

            totalDistribuido = 0.0;
            for(int k = 0; k < nAtivos; k++) {
               int idxZona = ativos[k];
               volumeDistribuidoPorZona[idxZona] = (double)baseInt[k];
               totalDistribuido += volumeDistribuidoPorZona[idxZona];
            }
            totalVolumeAltoJanela = (double)alvoInt;
            erroResidual = totalVolumeAltoJanela - totalDistribuido;
         }
      }

      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

         double volNom = 0.0;
         if(usouRateioEstrito) {
            double volRateado = volumeDistribuidoPorZona[i];
            if(volRateado < 0.0) volRateado = 0.0;
            if(InpAplicarRateioRetroativoNasZonas) {
               g_pivos[i].volumeDistribuicao = volRateado;
               if(g_pivos[i].volumeTotal < volRateado) {
                  double totalLado = g_pivos[i].volumeBuy + g_pivos[i].volumeSell;
                  if(totalLado > 1e-9) {
                     double fator = volRateado / totalLado;
                     g_pivos[i].volumeBuy *= fator;
                     g_pivos[i].volumeSell *= fator;
                  } else if(g_pivos[i].tipo == LINE_BOTTOM) {
                     g_pivos[i].volumeBuy = volRateado;
                     g_pivos[i].volumeSell = 0.0;
                  } else {
                     g_pivos[i].volumeSell = volRateado;
                     g_pivos[i].volumeBuy = 0.0;
                  }
                  g_pivos[i].volumeTotal = g_pivos[i].volumeBuy + g_pivos[i].volumeSell;
               }
               volNom = volRateado;
            } else {
               // Modo incremental: não reescreve acumulado da zona com rateio retroativo.
               volNom = ObterVolumeNominalZona(i);
            }
         } else {
            volNom = ObterVolumeNominalZona(i);
         }
         if(volNom < 0.0) volNom = 0.0;

         volumePonderado[i] = volNom;
         totalZonasNominal += volNom;
      }

      g_volumeMaximoGlobal = totalZonasNominal;

      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         g_pivos[i].volumeMaximo = g_volumeMaximoGlobal;
         double pctInterno = 0.0;
         if(totalZonasNominal > 0.0) pctInterno = (volumePonderado[i] / totalZonasNominal) * 100.0;
         if(pctInterno < 0.0) pctInterno = 0.0;
         g_pivos[i].percentualVolumeInterno = pctInterno;
         g_pivos[i].percentualVolume = pctInterno;
         if(g_pivos[i].percentualVolume < 0.0) g_pivos[i].percentualVolume = 0.0;
      }

      if(InpLogDetalhado) {
         Print("📊 Distribuicao nominal: baseUsada=",
               DoubleToString(g_volumeMaximoGlobal, 0),
               " | totalZonas=", DoubleToString(totalZonasNominal, 0),
               " | retroativo=", (InpAplicarRateioRetroativoNasZonas ? "ON" : "OFF"),
               " | totalDistrib=", DoubleToString(totalDistribuido, 0),
               " | erro=", DoubleToString(erroResidual, 6));
      }
      return;
   }

   double maxVolDiaAtual = 0.0;
   double maxVolDiaAnterior = 0.0;
   double eps = 1e-9;

   datetime diaAtual = g_referenciaDiaAtual;
   datetime diaAnterior = g_referenciaDiaAnterior;
   if(diaAtual <= 0) {
      diaAtual = ObterInicioDia(TimeCurrent());
      diaAnterior = diaAtual - 86400;
   }

   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   int janelaBarras = ObterJanelaInicioDiaBarras();
   datetime limiteInicioDia = diaAtual + (datetime)(passo * janelaBarras);
   bool inicioDoDia = (janelaBarras > 0 && TimeCurrent() <= limiteInicioDia);

   // 1) Descobrir maximos de volume de distribuicao por dia (atual/anterior).
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      datetime tempoRefZona = ObterTempoAtividadeZona(i);
      if(tempoRefZona <= 0) continue;
      datetime diaZona = ObterInicioDia(tempoRefZona);
      if(diaZona != diaAtual && diaZona != diaAnterior) continue;

      double volBase = ObterVolumeNominalZona(i);
      if(volBase < 0.0) volBase = 0.0;
      if(diaZona == diaAtual && volBase > maxVolDiaAtual) maxVolDiaAtual = volBase;
      if(diaZona == diaAnterior && volBase > maxVolDiaAnterior) maxVolDiaAnterior = volBase;
   }

   // 2) Calcular volume ponderado com regras diarias e estado da zona.
   double pesoMaxAnterior = ObterPesoMaxVolDiaAnterior();
   double pesoMaxAtual = ObterPesoMaxVolDiaAtual();
   double pesoExtremosDia = ObterPesoExtremosDia();
   double redutorZonaVencida = ObterRedutorZonaVencida();

   double faixaAtual = MathAbs(g_extremoMaxDiaAtual - g_extremoMinDiaAtual);
   double faixaAnterior = MathAbs(g_extremoMaxDiaAnterior - g_extremoMinDiaAnterior);
   double tolAtual = MathMax(_Point * 10.0, faixaAtual * 0.05);
   double tolAnterior = MathMax(_Point * 10.0, faixaAnterior * 0.05);

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      datetime tempoRefZona = ObterTempoAtividadeZona(i);
      if(tempoRefZona <= 0) continue;
      datetime diaZona = ObterInicioDia(tempoRefZona);
      double volBase = ObterVolumeNominalZona(i);
      if(volBase < 0.0) volBase = 0.0;

      // Regra principal: distribuicao considera apenas dia atual e anterior.
      if(diaZona != diaAtual && diaZona != diaAnterior) volBase = 0.0;

      double peso = 1.0;
      if(volBase > 0.0) {
         if(diaZona == diaAtual && maxVolDiaAtual > eps && volBase >= (maxVolDiaAtual - eps)) {
            peso *= pesoMaxAtual;
         }
         if(diaZona == diaAnterior && maxVolDiaAnterior > eps && volBase >= (maxVolDiaAnterior - eps)) {
            if(inicioDoDia) peso *= pesoMaxAnterior;
            else peso *= pesoMaxAtual;
         }

         double precoZona = g_pivos[i].preco;
         bool pertoExtremoAtual =
            (g_extremoMaxDiaAtual > 0.0 && MathAbs(precoZona - g_extremoMaxDiaAtual) <= tolAtual) ||
            (g_extremoMinDiaAtual > 0.0 && MathAbs(precoZona - g_extremoMinDiaAtual) <= tolAtual);
         bool pertoExtremoAnterior =
            (g_extremoMaxDiaAnterior > 0.0 && MathAbs(precoZona - g_extremoMaxDiaAnterior) <= tolAnterior) ||
            (g_extremoMinDiaAnterior > 0.0 && MathAbs(precoZona - g_extremoMinDiaAnterior) <= tolAnterior);
         if(pertoExtremoAtual || pertoExtremoAnterior) {
            peso *= pesoExtremosDia;
         }
      }

      if(g_pivos[i].estado == PIVO_CONFIRMADO || g_pivos[i].precoAssentado) {
         peso *= redutorZonaVencida;
      }

      volumePonderado[i] = volBase * peso;
      if(volumePonderado[i] > g_volumeMaximoGlobal) {
         g_volumeMaximoGlobal = volumePonderado[i];
      }
   }

   // 3) Converter para percentual interno (0..100).
   double totalInternoPonderado = 0.0;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      totalInternoPonderado += volumePonderado[i];
   }

   double basePercentualFinal = totalInternoPonderado;
   if(basePercentualFinal <= 0.0) basePercentualFinal = g_volumeMaximoGlobal;
   g_volumeMaximoGlobal = basePercentualFinal;

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      g_pivos[i].volumeMaximo = g_volumeMaximoGlobal;

      double pctInterno = 0.0;
      if(totalInternoPonderado > 0.0) pctInterno = (volumePonderado[i] / totalInternoPonderado) * 100.0;
      if(pctInterno < 0.0) pctInterno = 0.0;

      g_pivos[i].percentualVolumeInterno = pctInterno;
      g_pivos[i].percentualVolume = pctInterno;
      if(g_pivos[i].percentualVolume < 0.0) g_pivos[i].percentualVolume = 0.0;
   }

   if(InpLogDetalhado) {
      Print("📊 Distribuicao diária: maxAtual=", DoubleToString(maxVolDiaAtual, 0),
            " | maxAnterior=", DoubleToString(maxVolDiaAnterior, 0),
            " | baseFinal=", DoubleToString(g_volumeMaximoGlobal, 0),
            " | totalInterno=", DoubleToString(totalInternoPonderado, 0));
   }
}

#endif
