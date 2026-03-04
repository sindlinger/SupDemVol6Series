#ifndef SUPDEMVOL_MODULE_ENRIQUECIMENTO_V5_MQH
#define SUPDEMVOL_MODULE_ENRIQUECIMENTO_V5_MQH

void SDV4_CalcularFracaoSombraBarra(const int idxBarra,
                                    const double &open[],
                                    const double &high[],
                                    const double &low[],
                                    const double &close[],
                                    const ENUM_LINE_TYPE tipoReferencia,
                                    double &fracaoCompraSombra,
                                    double &fracaoVendaSombra) {
   fracaoCompraSombra = 0.5;
   fracaoVendaSombra = 0.5;
   if(idxBarra < 0) return;
   if(idxBarra >= ArraySize(open) || idxBarra >= ArraySize(high) ||
      idxBarra >= ArraySize(low) || idxBarra >= ArraySize(close)) return;

   double sombraSup = high[idxBarra] - MathMax(open[idxBarra], close[idxBarra]);
   double sombraInf = MathMin(open[idxBarra], close[idxBarra]) - low[idxBarra];
   if(sombraSup < 0.0) sombraSup = 0.0;
   if(sombraInf < 0.0) sombraInf = 0.0;
   double maiorSombra = MathMax(sombraSup, sombraInf);
   double menorSombra = MathMin(sombraSup, sombraInf);

   // Regra operacional:
   // 1) sombra inferior > superior => 100% compra;
   // 2) sombra superior > inferior => 100% venda;
   // 3) diferença relativa <= 10% => 50/50.
   if(maiorSombra <= 1e-12) {
      fracaoCompraSombra = 0.5;
   } else {
      double diferencaRelativa = (maiorSombra - menorSombra) / maiorSombra;
      if(diferencaRelativa <= 0.10) {
         fracaoCompraSombra = 0.5;
      } else if(sombraInf > sombraSup) {
         fracaoCompraSombra = 1.0;
      } else {
         fracaoCompraSombra = 0.0;
      }
   }
   if(fracaoCompraSombra < 0.0) fracaoCompraSombra = 0.0;
   if(fracaoCompraSombra > 1.0) fracaoCompraSombra = 1.0;
   fracaoVendaSombra = 1.0 - fracaoCompraSombra;
}

bool SDV4_TentarEnriquecimentoRealtimeDaCriacao(const int idx0,
                                                const datetime &time[],
                                                const double &open[],
                                                const double &high[],
                                                const double &low[],
                                                const double &close[],
                                                const ENUM_LINE_TYPE tipoAtualBarra,
                                                const double volumeEventoCriacao,
                                                const bool modoMixSombra,
                                                const double fracaoCompraSombra,
                                                const double fracaoVendaSombra,
                                                bool &deveRecalcular) {
   if(!(g_tempoUltimaCriacaoBarra == time[idx0] &&
        g_idxZonaDestinoCriacaoRealtime >= 0 &&
        g_idxZonaDestinoCriacaoRealtime < g_numeroZonas &&
        g_pivos[g_idxZonaDestinoCriacaoRealtime].estado != PIVO_REMOVIDO)) return false;

   int idxDestinoRT = g_idxZonaDestinoCriacaoRealtime;
   if(idxDestinoRT < 0 || idxDestinoRT >= g_numeroZonas) return false;

   if(modoMixSombra) {
      // Runtime da mesma barra: mantém a zona de destino já definida no evento inicial.
      int idxDestinoBuyRT = idxDestinoRT;
      int idxDestinoSellRT = idxDestinoRT;

      double volBuyRT = volumeEventoCriacao * fracaoCompraSombra;
      double volSellRT = volumeEventoCriacao - volBuyRT;
      if(volBuyRT < 0.0) volBuyRT = 0.0;
      if(volSellRT < 0.0) volSellRT = 0.0;

      bool aplicouMixRT = false;
      double volAplicadoBuyRT = 0.0;
      double volAplicadoSellRT = 0.0;
      double alturaCandRT = MathAbs(high[idx0] - low[idx0]);
      double alturaMinRT = ObterAlturaMinimaZonaPreco();
      if(alturaCandRT < alturaMinRT) alturaCandRT = alturaMinRT;
      double candSupBuyRT = low[idx0] + alturaCandRT;
      double candInfBuyRT = low[idx0];
      double candSupSellRT = high[idx0];
      double candInfSellRT = high[idx0] - alturaCandRT;

      if(volBuyRT > 1e-9 &&
         idxDestinoBuyRT >= 0 &&
         idxDestinoBuyRT < g_numeroZonas &&
         g_pivos[idxDestinoBuyRT].estado != PIVO_REMOVIDO) {
         if(MergeQuandoCriacaoProxima(idxDestinoBuyRT,
                                      LINE_BOTTOM,
                                      time[idx0],
                                      volBuyRT,
                                      candSupBuyRT,
                                      candInfBuyRT,
                                      true)) {
            volAplicadoBuyRT = volBuyRT;
            RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-RT-MIX-BUY",
                                                   time[idx0],
                                                   idxDestinoBuyRT,
                                                   volBuyRT);
            aplicouMixRT = true;
         }
      }

      if(volSellRT > 1e-9 &&
         idxDestinoSellRT >= 0 &&
         idxDestinoSellRT < g_numeroZonas &&
         g_pivos[idxDestinoSellRT].estado != PIVO_REMOVIDO) {
         if(MergeQuandoCriacaoProxima(idxDestinoSellRT,
                                      LINE_TOP,
                                      time[idx0],
                                      volSellRT,
                                      candSupSellRT,
                                      candInfSellRT,
                                      true)) {
            volAplicadoSellRT = volSellRT;
            RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-RT-MIX-SELL",
                                                   time[idx0],
                                                   idxDestinoSellRT,
                                                   volSellRT);
            aplicouMixRT = true;
         }
      }

      double volAplicadoMixRT = volAplicadoBuyRT + volAplicadoSellRT;
      if(aplicouMixRT && volAplicadoMixRT > 1e-9) {
         if(volAplicadoBuyRT >= volAplicadoSellRT &&
            idxDestinoBuyRT >= 0 &&
            idxDestinoBuyRT < g_numeroZonas &&
            g_pivos[idxDestinoBuyRT].estado != PIVO_REMOVIDO) {
            g_idxZonaDestinoCriacaoRealtime = idxDestinoBuyRT;
         } else if(idxDestinoSellRT >= 0 &&
                   idxDestinoSellRT < g_numeroZonas &&
                   g_pivos[idxDestinoSellRT].estado != PIVO_REMOVIDO) {
            g_idxZonaDestinoCriacaoRealtime = idxDestinoSellRT;
         } else {
            g_idxZonaDestinoCriacaoRealtime = idxDestinoRT;
         }
         g_volumeCriacaoAplicadoBarra += volAplicadoMixRT;
         g_tempoEventoVolumeConsumidoCriacao = time[idx0];
         g_pivosInicializados = true;
         deveRecalcular = true;
         RegistrarDebugAlocacaoBarraNoGrafico("RT-MIX",
                                              time[idx0],
                                              idxDestinoBuyRT,
                                              volAplicadoBuyRT,
                                              idxDestinoSellRT,
                                              volAplicadoSellRT);
         return true;
      }
   }

   if(g_pivos[idxDestinoRT].tipo != tipoAtualBarra) {
      int idxMesmoTipoToque = -1;
      double menorDistDir = DBL_MAX;
      double precoRef = (tipoAtualBarra == LINE_BOTTOM) ? low[idx0] : high[idx0];
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         if(g_pivos[i].tipo != tipoAtualBarra) continue;
         double distDir = MathAbs(g_pivos[i].preco - precoRef);
         if(BarraInterseccionaFaixa(high[idx0], low[idx0],
                                    g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
            if(idxMesmoTipoToque < 0 || distDir < menorDistDir) {
               idxMesmoTipoToque = i;
               menorDistDir = distDir;
            }
         }
      }
      if(idxMesmoTipoToque >= 0) idxDestinoRT = idxMesmoTipoToque;
      g_idxZonaDestinoCriacaoRealtime = idxDestinoRT;
   }

   double alturaCandRT2 = MathAbs(high[idx0] - low[idx0]);
   double alturaMinRT2 = ObterAlturaMinimaZonaPreco();
   if(alturaCandRT2 < alturaMinRT2) alturaCandRT2 = alturaMinRT2;
   double candSupRT2 = (tipoAtualBarra == LINE_TOP) ? high[idx0] : (low[idx0] + alturaCandRT2);
   double candInfRT2 = (tipoAtualBarra == LINE_TOP) ? (high[idx0] - alturaCandRT2) : low[idx0];

   bool aplicouRT = MergeQuandoCriacaoProxima(idxDestinoRT,
                                              tipoAtualBarra,
                                              time[idx0],
                                              volumeEventoCriacao,
                                              candSupRT2,
                                              candInfRT2,
                                              true);
   if(!aplicouRT) return false;

   g_volumeCriacaoAplicadoBarra += volumeEventoCriacao;
   g_tempoEventoVolumeConsumidoCriacao = time[idx0];
   RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-RT-DELTA",
                                          time[idx0],
                                          idxDestinoRT,
                                          volumeEventoCriacao);
   if(tipoAtualBarra == LINE_BOTTOM) {
      RegistrarDebugAlocacaoBarraNoGrafico("RT-1Z",
                                           time[idx0],
                                           idxDestinoRT,
                                           volumeEventoCriacao,
                                           -1,
                                           0.0);
   } else {
      RegistrarDebugAlocacaoBarraNoGrafico("RT-1Z",
                                           time[idx0],
                                           -1,
                                           0.0,
                                           idxDestinoRT,
                                           volumeEventoCriacao);
   }
   g_pivosInicializados = true;
   deveRecalcular = true;
   return true;
}

bool SDV4_TentarEnriquecimentoCriacaoProxima(const int idx0,
                                             const datetime &time[],
                                             const ENUM_LINE_TYPE tipo,
                                             const double volumeEventoCriacao,
                                             const double candSup,
                                             const double candInf,
                                             const int idxZonaPreferencial,
                                             const double distZonaPreferencial,
                                             const double limiarMergeProximo,
                                             bool &mergeExecutadoNestaCriacao,
                                             bool &podeMergeEvento,
                                             int &idxZonaDestinoEvento,
                                             double &volumeAplicadoEvento) {
   if(mergeExecutadoNestaCriacao) return false;
   if(!podeMergeEvento) return false;
   if(idxZonaPreferencial < 0 || idxZonaPreferencial >= g_numeroZonas) return false;
   if(g_pivos[idxZonaPreferencial].foiMergeada) return false;
   if(distZonaPreferencial > limiarMergeProximo) return false;

   bool absorveuProxima = MergeQuandoCriacaoProxima(idxZonaPreferencial,
                                                    tipo,
                                                    time[idx0],
                                                    volumeEventoCriacao,
                                                    candSup,
                                                    candInf,
                                                    true);
   if(!absorveuProxima) {
      if(InpLogDetalhado) {
         Print("MERGE[proxima][SKIP]: transferencia de volume nao aplicada.");
      }
      return false;
   }

   mergeExecutadoNestaCriacao = true;
   podeMergeEvento = false;
   idxZonaDestinoEvento = idxZonaPreferencial;
   volumeAplicadoEvento = volumeEventoCriacao;
   RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-PROXIMA",
                                          time[idx0],
                                          idxZonaPreferencial,
                                          volumeEventoCriacao);
   if(tipo == LINE_BOTTOM) {
      RegistrarDebugAlocacaoBarraNoGrafico("CRIACAO-PROX",
                                           time[idx0],
                                           idxZonaPreferencial,
                                           volumeEventoCriacao,
                                           -1,
                                           0.0);
   } else {
      RegistrarDebugAlocacaoBarraNoGrafico("CRIACAO-PROX",
                                           time[idx0],
                                           -1,
                                           0.0,
                                           idxZonaPreferencial,
                                           volumeEventoCriacao);
   }
   if(InpLogDetalhado) {
      Print("MERGE[proxima]: zona existente recebeu volume da candidata (",
            "dist=", DoubleToString(distZonaPreferencial, _Digits),
            " limiar=", DoubleToString(limiarMergeProximo, _Digits), ").");
   }
   return true;
}

bool SDV4_TentarEnriquecimentoMinDistanciaCriacao(const int idx0,
                                                  const datetime &time[],
                                                  const ENUM_LINE_TYPE tipo,
                                                  const double volumeEventoCriacao,
                                                  const double candSup,
                                                  const double candInf,
                                                  const int idxZonaPreferencialEnriquecimento,
                                                  const double distZonaPreferencial,
                                                  const double limiarMinCriacao,
                                                  bool &mergeExecutadoNestaCriacao,
                                                  int &idxZonaDestinoEvento,
                                                  double &volumeAplicadoEvento,
                                                  bool &deveRecalcular) {
   if(mergeExecutadoNestaCriacao) return false;
   if(idxZonaPreferencialEnriquecimento < 0 ||
      idxZonaPreferencialEnriquecimento >= g_numeroZonas) {
      if(InpLogDetalhado) {
         Print("CRIACAO: bloqueada por distancia minima entre zonas (",
               "dist=", DoubleToString(distZonaPreferencial, _Digits),
               " limiar=", DoubleToString(limiarMinCriacao, _Digits), ").");
      }
      return false;
   }
   if(g_pivos[idxZonaPreferencialEnriquecimento].foiMergeada) {
      if(InpLogDetalhado) {
         Print("CRIACAO: bloqueada por distancia minima entre zonas (",
               "dist=", DoubleToString(distZonaPreferencial, _Digits),
               " limiar=", DoubleToString(limiarMinCriacao, _Digits), ").");
      }
      return false;
   }

   bool enriqueceuPorBloqueio = MergeQuandoCriacaoProxima(idxZonaPreferencialEnriquecimento,
                                                          tipo,
                                                          time[idx0],
                                                          volumeEventoCriacao,
                                                          candSup,
                                                          candInf,
                                                          true);
   if(!enriqueceuPorBloqueio) {
      if(InpLogDetalhado) {
         Print("CRIACAO: bloqueada por distancia minima entre zonas (",
               "dist=", DoubleToString(distZonaPreferencial, _Digits),
               " limiar=", DoubleToString(limiarMinCriacao, _Digits), ").");
      }
      return false;
   }

   mergeExecutadoNestaCriacao = true;
   idxZonaDestinoEvento = idxZonaPreferencialEnriquecimento;
   volumeAplicadoEvento = volumeEventoCriacao;
   g_pivosInicializados = true;
   deveRecalcular = true;
   RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-MIN_DIST",
                                          time[idx0],
                                          idxZonaPreferencialEnriquecimento,
                                          volumeEventoCriacao);
   if(tipo == LINE_BOTTOM) {
      RegistrarDebugAlocacaoBarraNoGrafico("CRIACAO-MINDIST",
                                           time[idx0],
                                           idxZonaPreferencialEnriquecimento,
                                           volumeEventoCriacao,
                                           -1,
                                           0.0);
   } else {
      RegistrarDebugAlocacaoBarraNoGrafico("CRIACAO-MINDIST",
                                           time[idx0],
                                           -1,
                                           0.0,
                                           idxZonaPreferencialEnriquecimento,
                                           volumeEventoCriacao);
   }
   if(InpLogDetalhado) {
      Print("CRIACAO->ENRIQUECIMENTO[min-dist]: candidata absorvida pela zona local (",
            "dist=", DoubleToString(distZonaPreferencial, _Digits),
            " limiar=", DoubleToString(limiarMinCriacao, _Digits), ").");
   }
   return true;
}

void SDV4_TentarEnriquecimentoLocalCriacaoBloqueada(const int idx0,
                                                    const datetime &time[],
                                                    const double &high[],
                                                    const double &low[],
                                                    const ENUM_LINE_TYPE tipo,
                                                    const bool modoMixSombra,
                                                    const double fracaoCompraSombra,
                                                    const double fracaoVendaSombra,
                                                    const double volumeEventoCriacao,
                                                    const double candSup,
                                                    const double candInf,
                                                    const double alturaZonaCand,
                                                    const double limiarMinCriacao,
                                                    const int idxZonaSobreposicao,
                                                    const int idxZonaPreferencialEnriquecimento,
                                                    const int idxZonaPreferencial,
                                                    const double distZonaPreferencial,
                                                    bool &mergeExecutadoNestaCriacao,
                                                    bool &podeMergeEvento,
                                                    int &idxZonaDestinoEvento,
                                                    double &volumeAplicadoEvento) {
   bool bloqueioPorSobreposicao = (idxZonaSobreposicao >= 0);
   bool bloqueioPorDistanciaMin = (idxZonaPreferencial >= 0 && distZonaPreferencial <= limiarMinCriacao + 1e-9);
   bool criacaoBloqueadaLocal = (bloqueioPorSobreposicao || bloqueioPorDistanciaMin);
   if(!criacaoBloqueadaLocal) return;
   if(!(idxZonaSobreposicao >= 0 || idxZonaPreferencialEnriquecimento >= 0)) return;

   int idxZonaDestinoCompra = -1;
   int idxZonaDestinoVenda = -1;
   int idxZonaProibitivaCompra = -1;
   int idxZonaProibitivaVenda = -1;
   double melhorDistToqueCompra = DBL_MAX;
   double melhorDistToqueVenda = DBL_MAX;
   double melhorDistProibitivaCompra = DBL_MAX;
   double melhorDistProibitivaVenda = DBL_MAX;
   bool achouToqueCompra = false;
   bool achouToqueVenda = false;
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      double supZonaI = MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
      double infZonaI = MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
      bool toca = BarraInterseccionaFaixa(high[idx0], low[idx0], supZonaI, infZonaI);
      double distFaixaLocal = DistanciaEntreFaixas(candSup, candInf, supZonaI, infZonaI);
      bool zonaProibitivaLocal = (distFaixaLocal <= limiarMinCriacao + 1e-9);
      if(g_pivos[i].tipo == LINE_BOTTOM) {
         double distDir = MathAbs(g_pivos[i].preco - low[idx0]);
         if(toca && (!achouToqueCompra || distDir < melhorDistToqueCompra - 1e-9)) {
            achouToqueCompra = true;
            melhorDistToqueCompra = distDir;
            idxZonaDestinoCompra = i;
         }
         if(zonaProibitivaLocal && distDir < melhorDistProibitivaCompra - 1e-9) {
            melhorDistProibitivaCompra = distDir;
            idxZonaProibitivaCompra = i;
         }
      } else {
         double distDir = MathAbs(g_pivos[i].preco - high[idx0]);
         if(toca && (!achouToqueVenda || distDir < melhorDistToqueVenda - 1e-9)) {
            achouToqueVenda = true;
            melhorDistToqueVenda = distDir;
            idxZonaDestinoVenda = i;
         }
         if(zonaProibitivaLocal && distDir < melhorDistProibitivaVenda - 1e-9) {
            melhorDistProibitivaVenda = distDir;
            idxZonaProibitivaVenda = i;
         }
      }
   }
   if(idxZonaDestinoCompra < 0 && bloqueioPorDistanciaMin) idxZonaDestinoCompra = idxZonaProibitivaCompra;
   if(idxZonaDestinoVenda < 0 && bloqueioPorDistanciaMin) idxZonaDestinoVenda = idxZonaProibitivaVenda;

   double candSupTop = high[idx0];
   double candInfTop = high[idx0] - alturaZonaCand;
   double candSupBottom = low[idx0] + alturaZonaCand;
   double candInfBottom = low[idx0];

   double volEvento = volumeEventoCriacao;
   if(volEvento < 0.0) volEvento = 0.0;

   int idxZonaBloqueadora = -1;
   if(idxZonaSobreposicao >= 0 &&
      idxZonaSobreposicao < g_numeroZonas &&
      g_pivos[idxZonaSobreposicao].estado != PIVO_REMOVIDO &&
      !g_pivos[idxZonaSobreposicao].foiMergeada) {
      idxZonaBloqueadora = idxZonaSobreposicao;
   }

   if(idxZonaBloqueadora < 0) {
      double melhorDistBloqueio = DBL_MAX;
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         if(g_pivos[i].foiMergeada) continue;
         double distFaixaLocal = DistanciaEntreFaixas(candSup,
                                                      candInf,
                                                      g_pivos[i].precoSuperior,
                                                      g_pivos[i].precoInferior);
         if(distFaixaLocal > limiarMinCriacao + 1e-9) continue;
         if(idxZonaBloqueadora < 0 || distFaixaLocal < melhorDistBloqueio - 1e-9) {
            idxZonaBloqueadora = i;
            melhorDistBloqueio = distFaixaLocal;
         }
      }
   }

   if(idxZonaBloqueadora < 0 || idxZonaBloqueadora >= g_numeroZonas) return;
   if(g_pivos[idxZonaBloqueadora].estado == PIVO_REMOVIDO) return;
   if(g_pivos[idxZonaBloqueadora].foiMergeada) return;

   double volBuy = volEvento * fracaoCompraSombra;
   if(volBuy < 0.0) volBuy = 0.0;
   if(volBuy > volEvento) volBuy = volEvento;
   double volSell = volEvento - volBuy;
   if(volSell < 0.0) volSell = 0.0;

   bool absorveu = false;
   double volumeAplicado = 0.0;
   double volAplicadoBuy = 0.0;
   double volAplicadoSell = 0.0;
   double volAntes = g_pivos[idxZonaBloqueadora].volumeTotal;

   if(volBuy > 1e-9) {
      if(MergeQuandoCriacaoProxima(idxZonaBloqueadora,
                                   LINE_BOTTOM,
                                   time[idx0],
                                   volBuy,
                                   candSupBottom,
                                   candInfBottom,
                                   true)) {
         absorveu = true;
         volumeAplicado += volBuy;
         volAplicadoBuy = volBuy;
      }
   }

   if(volSell > 1e-9) {
      if(MergeQuandoCriacaoProxima(idxZonaBloqueadora,
                                   LINE_TOP,
                                   time[idx0],
                                   volSell,
                                   candSupTop,
                                   candInfTop,
                                   true)) {
         absorveu = true;
         volumeAplicado += volSell;
         volAplicadoSell = volSell;
      }
   }

   // Fallback defensivo: se por algum motivo o split não aplicou, tenta o fluxo legado.
   if(!absorveu) {
      if(MergeQuandoCriacaoProxima(idxZonaBloqueadora,
                                   tipo,
                                   time[idx0],
                                   volEvento,
                                   candSup,
                                   candInf,
                                   true)) {
         absorveu = true;
         volumeAplicado = volEvento;
         if(tipo == LINE_BOTTOM) volAplicadoBuy = volEvento;
         else volAplicadoSell = volEvento;
      }
   }

   if(!absorveu || volumeAplicado <= 1e-9) {
      if(InpLogDetalhado) {
         Print("MERGE[bloqueio][SKIP]: volume da candidata nao aplicado na zona bloqueadora.");
      }
      return;
   }

   mergeExecutadoNestaCriacao = true;
   podeMergeEvento = false;
   idxZonaDestinoEvento = idxZonaBloqueadora;
   volumeAplicadoEvento = volumeAplicado;
   RegistrarEventoEnriquecimentoNoGrafico("CRIACAO-BLOQUEADA",
                                          time[idx0],
                                          idxZonaBloqueadora,
                                          volumeAplicado);
   RegistrarDebugAlocacaoBarraNoGrafico("BLQ-MIX-1Z",
                                        time[idx0],
                                        idxZonaBloqueadora,
                                        volAplicadoBuy,
                                        idxZonaBloqueadora,
                                        volAplicadoSell);

   if(InpLogDetalhado) {
      double volDepois = g_pivos[idxZonaBloqueadora].volumeTotal;
      PrintFormat("MERGE[bloqueio]: Z%d recebeu %.0f (buy %.0f / sell %.0f) | %.0f -> %.0f",
                  idxZonaBloqueadora + 1,
                  volumeAplicado,
                  volAplicadoBuy,
                  volAplicadoSell,
                  volAntes,
                  volDepois);
   }
}

#endif
