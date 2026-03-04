#ifndef SUPDEMVOL_MODULE_CRIACAO_V3_MQH
#define SUPDEMVOL_MODULE_CRIACAO_V3_MQH

void SDV3_ModuloCriacaoProcessar(const int rates_total,
                                 const datetime &time[],
                                 const double &high[],
                                 const double &low[],
                                 const double &close[],
                                 const long &tick_volume[],
                                 bool &deveRecalcular,
                                 bool &houveCriacaoNova) {
   // Criacao: SOMENTE barra 0, zona fica fixa na barra de criacao.
   int idx0 = rates_total - 1;
   if(idx0 < InpPeriodoMedia) return;

   bool gatilho = (BandaSuperiorBuffer[idx0] > 0.0 && VolumeBuffer[idx0] > BandaSuperiorBuffer[idx0]);
   if(!gatilho || g_tempoUltimaCriacaoBarra == time[idx0]) return;

   ENUM_LINE_TYPE tipo = DeterminarTipoLinha(idx0, high, low);
   double precoZona = (tipo == LINE_TOP) ? high[idx0] : low[idx0];
   double atrAtual = CalcularATR(idx0, high, low, close);

   // Candidata da barra de origem: zona fina ancorada no topo/fundo.
   double fatorAltura = InpFatorAlturaBarraOrigem;
   double fatorAlturaMin = 0.0;
   double fatorAlturaMax = 0.0;
   ObterLimitesFatorAlturaBarraOrigem(fatorAlturaMin, fatorAlturaMax);
   if(fatorAltura < fatorAlturaMin) fatorAltura = fatorAlturaMin;
   if(fatorAltura > fatorAlturaMax) fatorAltura = fatorAlturaMax;
   double alturaBarraOrigem = MathAbs(high[idx0] - low[idx0]);
   double alturaZonaCand = alturaBarraOrigem * fatorAltura;
   double alturaMaximaZona = ObterLimiarDistanciaATR(atrAtual, InpMaxATRPercent);
   if(alturaZonaCand > alturaMaximaZona) alturaZonaCand = alturaMaximaZona;
   double alturaMinimaZona = ObterAlturaMinimaZonaPreco();
   if(alturaZonaCand < alturaMinimaZona) alturaZonaCand = alturaMinimaZona;
   if(alturaZonaCand > alturaBarraOrigem) alturaZonaCand = alturaBarraOrigem;
   double candSup = (tipo == LINE_TOP) ? high[idx0] : (low[idx0] + alturaZonaCand);
   double candInf = (tipo == LINE_TOP) ? (high[idx0] - alturaZonaCand) : low[idx0];

   // 1) Regras de criacao e merge com controle de distancia.
   int idxZonaAli = -1;
   int idxZonaMaisProxima = -1;
   double menorDistFaixa = DBL_MAX;
   double menorDistToque = DBL_MAX;
   double limiarMinCriacao = ObterLimiarDistanciaATR(atrAtual, InpDistanciaMinATR) *
                             ObterFatorDistanciaMinCriacao();

   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

      double distFaixa = DistanciaEntreFaixas(candSup, candInf,
                                             g_pivos[i].precoSuperior,
                                             g_pivos[i].precoInferior);
      if(distFaixa < menorDistFaixa) {
         menorDistFaixa = distFaixa;
         idxZonaMaisProxima = i;
      }

      if(BarraInterseccionaFaixa(candSup, candInf,
                                 g_pivos[i].precoSuperior, g_pivos[i].precoInferior)) {
         double distToque = DistanciaEntreFaixas(candSup, candInf,
                                                g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
         if(distToque < menorDistToque) {
            menorDistToque = distToque;
            idxZonaAli = i;
         }
      }
   }

   bool mergeExecutadoNestaCriacao = false;
   bool podeMergeEvento = PodeProcessarMergeDoEvento(time[idx0]);
   if(idxZonaAli >= 0) {
      MergeQuandoCriacaoProxima(idxZonaAli,
                                tipo,
                                time[idx0],
                                (double)tick_volume[idx0]);
      mergeExecutadoNestaCriacao = true;
      podeMergeEvento = false;
      if(InpLogDetalhado) Print("MERGE[sobreposicao]: absorcao sem mover ancora da zona.");
   }

   if(!mergeExecutadoNestaCriacao &&
      podeMergeEvento &&
      idxZonaMaisProxima >= 0 &&
      !g_pivos[idxZonaMaisProxima].foiMergeada &&
      menorDistFaixa <= limiarMinCriacao) {
      MergeQuandoCriacaoProxima(idxZonaMaisProxima,
                                tipo,
                                time[idx0],
                                (double)tick_volume[idx0]);
      mergeExecutadoNestaCriacao = true;
      podeMergeEvento = false;
      if(InpLogDetalhado) {
         Print("MERGE[proxima]: absorcao sem mover ancora (",
               DoubleToString(menorDistFaixa / _Point, 1), " pts).");
      }
   }

   if(!mergeExecutadoNestaCriacao) {
      int idxLivre = -1;
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) { idxLivre = i; break; }
      }

      if(idxLivre >= 0) {
         if(menorDistFaixa > limiarMinCriacao) {
            ENUM_VOLUME_INTENSIDADE intensidade = DeterminarIntensidadeVolume((double)tick_volume[idx0], MathMax(MediaBuffer[idx0], 1.0));
            g_pivos[idxLivre].preco = precoZona;
            g_pivos[idxLivre].precoSuperior = candSup;
            g_pivos[idxLivre].precoInferior = candInf;
            g_pivos[idxLivre].tempoInicio = time[idx0];
            g_pivos[idxLivre].tempoMaisRecente = time[idx0];
            g_pivos[idxLivre].volumeTotal = (double)tick_volume[idx0];
            g_pivos[idxLivre].volumeMaximo = 0.0;
            g_pivos[idxLivre].percentualVolume = 0.0;
            g_pivos[idxLivre].quantidadeBarras = 1;
            g_pivos[idxLivre].quantidadeTopos = (tipo == LINE_TOP) ? 1 : 0;
            g_pivos[idxLivre].quantidadeFundos = (tipo == LINE_BOTTOM) ? 1 : 0;
            g_pivos[idxLivre].tipo = tipo;
            g_pivos[idxLivre].tipoMajoritario = tipo;
            g_pivos[idxLivre].estado = PIVO_ATIVO;
            g_pivos[idxLivre].corAtual = ObterCorZona(tipo);
            g_pivos[idxLivre].atr = atrAtual;
            g_pivos[idxLivre].barraInicio = idx0;
            g_pivos[idxLivre].barraRompimento = 0;
            g_pivos[idxLivre].tempoRompimento = 0;
            g_pivos[idxLivre].barrasAposRompimento = 0;
            g_pivos[idxLivre].precoAssentado = false;
            g_pivos[idxLivre].distanciaPrecoAtual = 0.0;
            g_pivos[idxLivre].score = 0.0;
            g_pivos[idxLivre].foiMergeada = false;
            g_pivos[idxLivre].pivoID = g_proximoPivoID++;
            g_pivos[idxLivre].pivosIncorporados = "";
            g_pivos[idxLivre].intensidadeVolume = intensidade;
            g_pivos[idxLivre].ultimoTempoToqueContabilizado = time[idx0];
            DefinirAncoraPivo(idxLivre);

            g_tempoUltimaCriacaoBarra = time[idx0];
            g_pivosInicializados = true;
            houveCriacaoNova = true;
            deveRecalcular = true;

            int zonasAtivas = ContarZonasAtivas();
            int limiteSuave = ObterLimiteAtivosParaCompactar();
            if(DeveCompactarPorExcessoDeZonas()) {
               g_mergeCorretivoPendente = true;
               g_tempoCriacaoOverflow = time[idx0];
               if(InpLogDetalhado) {
                  Print("OVERFLOW: ", zonasAtivas, " zonas ativas (limite suave ", limiteSuave,
                        "). Merge corretivo sera tentado na proxima barra fechada.");
               }
            }
         } else if(InpLogDetalhado) {
            Print("CRIACAO: bloqueada por distancia minima entre zonas (",
                  DoubleToString(menorDistFaixa / _Point, 1), " pts).");
         }
         g_tempoUltimaCriacaoBarra = time[idx0];
      } else {
         bool abriuSlot = false;
         if(InpPermitirRemoverZonasNoMerge) {
            abriuSlot = FundirZonaMaisFracaParaAbrirSlot(tipo, close[idx0]);
            if(abriuSlot) {
               g_pivosInicializados = true;
               deveRecalcular = true;
            }
         }
         if(InpLogDetalhado) {
            if(abriuSlot) {
               Print("MERGE[sem-slot]: abriu 1 slot removendo a zona mais longe do preco atual.");
            } else {
               Print("MERGE[sem-slot]: nao abriu slot (modo remocao off ou sem par valido).");
            }
         }
         g_tempoUltimaCriacaoBarra = time[idx0];
      }
   } else {
      g_tempoUltimaCriacaoBarra = time[idx0];
      g_pivosInicializados = true;
      deveRecalcular = true;
   }
}

#endif
