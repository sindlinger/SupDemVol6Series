//+------------------------------------------------------------------+
//|                                       SupDemVol_MergeRules_v4.mqh|
//| Regras de merge das zonas S/R                                    |
//+------------------------------------------------------------------+
#ifndef __SUPDEMVOL_MERGE_RULES_V4_MQH__
#define __SUPDEMVOL_MERGE_RULES_V4_MQH__

class CSupDemVolMergeManager {
private:
   double NormalizarAltura(const double altura) {
      return (altura > 0.0) ? altura : (_Point * 2.0);
   }

   double ObterPrecoReferenciaEscala() {
      double precoRef = 0.0;
      if(!SymbolInfoDouble(_Symbol, SYMBOL_BID, precoRef) || precoRef <= 0.0) {
         if(!SymbolInfoDouble(_Symbol, SYMBOL_LAST, precoRef) || precoRef <= 0.0) {
            double refAtual = MathMax(MathAbs(g_extremoMaxDiaAtual), MathAbs(g_extremoMinDiaAtual));
            double refAnterior = MathMax(MathAbs(g_extremoMaxDiaAnterior), MathAbs(g_extremoMinDiaAnterior));
            precoRef = MathMax(refAtual, refAnterior);
         }
      }
      if(!MathIsValidNumber(precoRef) || precoRef <= 0.0) precoRef = 1.0;
      return precoRef;
   }

   double ObterPisoEscalaPercentualPreco() {
      double pct = SDV4_RegrasEscalaRelativaMinPctPreco();
      return ObterPrecoReferenciaEscala() * (pct / 100.0);
   }

   double ObterFatorEscalaFaixaDia() {
      return SDV4_RegrasEscalaRelativaFatorFaixaDia();
   }

   double ObterEscalaReferencia(const double atrReferencia) {
      if(!SDV4_RegrasEscalaRelativaSemATR()) {
         double atr = MathAbs(atrReferencia);
         if(atr <= 0.0) atr = _Point * 100.0;
         return atr;
      }

      double faixaAtual = MathAbs(g_extremoMaxDiaAtual - g_extremoMinDiaAtual);
      double faixaAnterior = MathAbs(g_extremoMaxDiaAnterior - g_extremoMinDiaAnterior);
      double escala = MathMax(faixaAtual, faixaAnterior);
      if(!MathIsValidNumber(escala) || escala <= 0.0) escala = 0.0;
      escala *= ObterFatorEscalaFaixaDia();

      double pisoEscala = ObterPisoEscalaPercentualPreco();
      if(!MathIsValidNumber(pisoEscala) || pisoEscala <= 0.0) pisoEscala = 1.0;
      if(escala < pisoEscala) escala = pisoEscala;
      return escala;
   }

   double ObterAlturaMaximaPermitida(const double atrReferencia) {
      if(SDV4_RegrasMaxATRPercent() <= 0.0) return DBL_MAX;
      double escala = ObterEscalaReferencia(atrReferencia);
      double limite = escala * (SDV4_RegrasMaxATRPercent() / 100.0);
      return (limite < (_Point * 2.0)) ? (_Point * 2.0) : limite;
   }

   void AplicarLimiteAlturaFaixa(double &precoSuperior,
                                double &precoInferior,
                                const ENUM_LINE_TYPE tipo,
                                const double atrReferencia) {
      double largura = MathAbs(precoSuperior - precoInferior);
      double larguraMaxima = ObterAlturaMaximaPermitida(atrReferencia);
      if(!MathIsValidNumber(larguraMaxima) || larguraMaxima <= 0.0) return;
      if(largura <= larguraMaxima) return;
      if(tipo == LINE_TOP) {
         double topo = MathMax(precoSuperior, precoInferior);
         precoSuperior = topo;
         precoInferior = topo - larguraMaxima;
      } else {
         double fundo = MathMin(precoSuperior, precoInferior);
         precoInferior = fundo;
         precoSuperior = fundo + larguraMaxima;
      }
   }

   void RecalcularVolumeTotalZona(const int idx) {
      if(idx < 0 || idx >= g_numeroZonas) return;
      double volBuy = MathMax(0.0, g_pivos[idx].volumeBuy);
      double volSell = MathMax(0.0, g_pivos[idx].volumeSell);
      g_pivos[idx].volumeBuy = volBuy;
      g_pivos[idx].volumeSell = volSell;
      g_pivos[idx].volumeTotal = volBuy + volSell;
   }

   void SomarVolumeNaZona(const int idx, const ENUM_LINE_TYPE tipo, const double volume) {
      if(idx < 0 || idx >= g_numeroZonas) return;
      double vol = MathMax(0.0, volume);
      if(vol <= 0.0) return;
      if(tipo == LINE_BOTTOM) g_pivos[idx].volumeBuy += vol;
      else g_pivos[idx].volumeSell += vol;
      RecalcularVolumeTotalZona(idx);
   }

   void SubtrairVolumeContrarioNaZona(const int idx, const ENUM_LINE_TYPE tipo, const double volume) {
      if(idx < 0 || idx >= g_numeroZonas) return;
      double vol = MathMax(0.0, volume);
      if(vol <= 0.0) return;
      if(tipo == LINE_BOTTOM) {
         g_pivos[idx].volumeSell = MathMax(0.0, g_pivos[idx].volumeSell - vol);
      } else {
         g_pivos[idx].volumeBuy = MathMax(0.0, g_pivos[idx].volumeBuy - vol);
      }
      RecalcularVolumeTotalZona(idx);
   }

   double ObterFatorLimiteIntervaloPorSoma() {
      return SDV4_RegrasFatorGapPorSomaMerge();
   }

   bool EstaDistanciaAceitaPorSoma(const double distFaixa, const double hBase, const double hOutra) {
      if(distFaixa < 0.0) return true; // faixas sobrepostas

      double alturaBase = NormalizarAltura(hBase);
      double alturaOutra = NormalizarAltura(hOutra);
      double fator = ObterFatorLimiteIntervaloPorSoma();
      // Padrão padrão (fator=1.00): distância máxima permitida = soma das alturas.
      if(fator <= 0.0) return false;
      double limiarSoma = (alturaBase + alturaOutra) * fator;
      if(limiarSoma <= 0.0) return false;
      if(distFaixa >= limiarSoma) return false;

      return true;
   }

public:
   void LimparSlotPivo(const int idx) {
      if(idx < 0 || idx >= 20) return;
      g_pivos[idx].preco = 0.0;
      g_pivos[idx].precoSuperior = 0.0;
      g_pivos[idx].precoInferior = 0.0;
      g_pivos[idx].tempoInicio = 0;
      g_pivos[idx].tempoMaisRecente = 0;
      g_pivos[idx].volumeTotal = 0.0;
      g_pivos[idx].volumeBuy = 0.0;
      g_pivos[idx].volumeSell = 0.0;
      g_pivos[idx].volumeDistribuicao = 0.0;
      g_pivos[idx].scoreOrigem = 0.0;
      g_pivos[idx].espessuraZona = 1;
      g_pivos[idx].volumeMaximo = 0.0;
      g_pivos[idx].percentualVolume = 0.0;
      g_pivos[idx].percentualVolumeInterno = 0.0;
      g_pivos[idx].quantidadeBarras = 0;
      g_pivos[idx].quantidadeTopos = 0;
      g_pivos[idx].quantidadeFundos = 0;
      g_pivos[idx].tipo = LINE_TOP;
      g_pivos[idx].tipoMajoritario = LINE_TOP;
      g_pivos[idx].estado = PIVO_REMOVIDO;
      g_pivos[idx].corAtual = g_palCorVolBaixo;
      g_pivos[idx].atr = 0.0;
      g_pivos[idx].barraInicio = 0;
      g_pivos[idx].barraRompimento = 0;
      g_pivos[idx].tempoRompimento = 0;
      g_pivos[idx].barrasAposRompimento = 0;
      g_pivos[idx].precoAssentado = false;
      g_pivos[idx].distanciaPrecoAtual = 0.0;
      g_pivos[idx].score = 0.0;
      g_pivos[idx].foiMergeada = false;
      g_pivos[idx].cooldownMergeTicket = 0;
      g_pivos[idx].pivoID = 0;
      g_pivos[idx].pivosIncorporados = "";
      g_pivos[idx].intensidadeVolume = VOLUME_BAIXO;
      g_pivos[idx].ultimoTempoToqueContabilizado = 0;
   }

   // Distância mínima entre duas faixas de preço (0 se sobrepõem/intersectam).
   double DistanciaEntreFaixas(double faixaSuperiorA, double faixaInferiorA, double faixaSuperiorB, double faixaInferiorB) {
      double supA = MathMax(faixaSuperiorA, faixaInferiorA);
      double infA = MathMin(faixaSuperiorA, faixaInferiorA);
      double supB = MathMax(faixaSuperiorB, faixaInferiorB);
      double infB = MathMin(faixaSuperiorB, faixaInferiorB);

      if(supA < infB) return (infB - supA);
      if(supB < infA) return (infA - supB);
      return 0.0;
   }

   // Distância mínima entre um candidato de faixa e todas as outras zonas ativas.
   double DistanciaMinimaParaOutrasZonas(const int idxIgnorarA,
                                         const int idxIgnorarB,
                                         const double faixaSuperior,
                                         const double faixaInferior) {
      double sup = MathMax(faixaSuperior, faixaInferior);
      double inf = MathMin(faixaSuperior, faixaInferior);

      double menorDist = DBL_MAX;
      for(int i = 0; i < g_numeroZonas; i++) {
         if(i == idxIgnorarA || i == idxIgnorarB) continue;
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;

         double d = DistanciaEntreFaixas(sup, inf,
                                         g_pivos[i].precoSuperior,
                                         g_pivos[i].precoInferior);
         if(d < menorDist) menorDist = d;
         if(menorDist <= 0.0) return 0.0;
      }

      if(menorDist == DBL_MAX) return 0.0;
      return menorDist;
   }

   // Limiar de distância baseado em ATR (porcentagem).
   double ObterLimiarDistanciaATR(const double atrReferencia, const double percentualATR) {
      double escala = ObterEscalaReferencia(atrReferencia);
      double limiar = escala * (percentualATR / 100.0);
      if(limiar < (_Point * 1.0)) limiar = (_Point * 1.0);
      return limiar;
   }

   double ObterAlturaMaximaPermitidaExterna(const double atrReferencia) {
      return ObterAlturaMaximaPermitida(atrReferencia);
   }

   bool EstaMuitoProximaParaMerge(const double distFaixa,
                                 const double limiteDistancia) {
      return (distFaixa <= limiteDistancia);
   }

   // Mescla uma zona candidata com uma zona ativa existente (sem criar novo slot).
   // Critério: só mescla se a distância entre faixas for muito curta (limite configurado).
   // <editor-fold defaultstate="collapsed" desc="REGRAS_DE_MERGE_SEGURAS (Fechável)">
   bool MesclarZonaComCandidato(int idxZonaBase,
                                ENUM_LINE_TYPE tipoCandidato,
                                double supCandidato,
                                double infCandidato,
                                double volumeCandidato,
                                int barrasCandidato,
                                int toposCandidato,
                                int fundosCandidato,
                                double atrCandidato,
                                datetime tempoCandidato,
                                double limiteDistanciaMerge) {
      if(idxZonaBase < 0 || idxZonaBase >= g_numeroZonas) return false;
      if(g_pivos[idxZonaBase].estado == PIVO_REMOVIDO) return false;
      if(g_pivos[idxZonaBase].foiMergeada) return false;
      if(!SDV4_MergeCooldownPodeMesclarZona(idxZonaBase)) {
         SDV4_RegrasLogBloqueioMerge("COOLDOWN-CANDIDATO",
                                     idxZonaBase,
                                     -1,
                                     StringFormat("ticket=%I64d global=%I64d",
                                                  g_pivos[idxZonaBase].cooldownMergeTicket,
                                                  g_mergeCooldownTicketGlobal));
         return false;
      }

      double supCand = MathMax(supCandidato, infCandidato);
      double infCand = MathMin(supCandidato, infCandidato);

      double distFaixa = DistanciaEntreFaixas(supCand, infCand,
                                              g_pivos[idxZonaBase].precoSuperior,
                                              g_pivos[idxZonaBase].precoInferior);
      if(!EstaMuitoProximaParaMerge(distFaixa, limiteDistanciaMerge)) return false;

      double alturaBase = MathAbs(g_pivos[idxZonaBase].precoSuperior - g_pivos[idxZonaBase].precoInferior);
      double alturaCand = MathAbs(supCand - infCand);
      if(!EstaDistanciaAceitaPorSoma(distFaixa, alturaBase, alturaCand)) return false;

      PivoAtivo base = g_pivos[idxZonaBase];
      double fracaoAbsorcao = SDV4_RegrasFatorAbsorcaoMerge();

      double novaAlturaBase = alturaBase + (alturaCand * fracaoAbsorcao);
      novaAlturaBase = MathMin(novaAlturaBase, ObterAlturaMaximaPermitida((base.atr + atrCandidato) * 0.5));
      double novoSupCand1 = base.precoSuperior;
      double novoInfCand1 = base.precoInferior;
      double novoSupCand2 = supCand;
      double novoInfCand2 = infCand;

      if(base.tipo == LINE_TOP) {
         novoSupCand1 = base.precoSuperior;
         novoInfCand1 = base.precoSuperior - novaAlturaBase;
         novoSupCand2 = supCand;
         novoInfCand2 = supCand - novaAlturaBase;
      } else {
         novoInfCand1 = base.precoInferior;
         novoSupCand1 = base.precoInferior + novaAlturaBase;
         novoInfCand2 = infCand;
         novoSupCand2 = infCand + novaAlturaBase;
      }

      if(novoSupCand1 < novoInfCand1) {
         double t1 = novoSupCand1;
         novoSupCand1 = novoInfCand1;
         novoInfCand1 = t1;
      }
      if(novoSupCand2 < novoInfCand2) {
         double t2 = novoSupCand2;
         novoSupCand2 = novoInfCand2;
         novoInfCand2 = t2;
      }

      double distCand1 = DistanciaMinimaParaOutrasZonas(idxZonaBase, -1, novoSupCand1, novoInfCand1);
      double distCand2 = DistanciaMinimaParaOutrasZonas(idxZonaBase, -1, novoSupCand2, novoInfCand2);

      double novoSup = novoSupCand1;
      double novoInf = novoInfCand1;
      if(distCand2 > distCand1 + (_Point * 1.0)) {
         novoSup = novoSupCand2;
         novoInf = novoInfCand2;
      } else if(MathAbs(distCand2 - distCand1) <= (_Point * 1.0)) {
         double ancBaseSup = MathMax(base.precoSuperior, base.precoInferior);
         double ancBaseInf = MathMin(base.precoSuperior, base.precoInferior);
         double deslocCand1 = (base.tipo == LINE_TOP) ? MathAbs(ancBaseSup - novoSupCand1) : MathAbs(ancBaseInf - novoInfCand1);
         double deslocCand2 = (base.tipo == LINE_TOP) ? MathAbs(ancBaseSup - novoSupCand2) : MathAbs(ancBaseInf - novoInfCand2);
         if(deslocCand2 < deslocCand1) {
            novoSup = novoSupCand2;
            novoInf = novoInfCand2;
         }
      }
      AplicarLimiteAlturaFaixa(novoSup, novoInf, base.tipo, (base.atr + atrCandidato) * 0.5);

      if(!MathIsValidNumber(novoSup) || !MathIsValidNumber(novoInf) ||
         novoSup <= novoInf) {
         if(SDV4_RegrasLogDetalhadoAtivo()) {
            PrintFormat("MERGE[candidato][REJECT]: resultado inválido idx=%d novaFaixa=(%.5f, %.5f)",
                        idxZonaBase, novoSup, novoInf);
         }
         return false;
      }

      // Garante espessura mínima para não ficar "invisível".
      if((novoSup - novoInf) < (_Point * 2.0)) {
         novoInf = (base.tipo == LINE_TOP) ? (novoInf - _Point * 2.0) : novoInf;
         novoSup = (base.tipo == LINE_TOP) ? novoSup : (novoSup + _Point * 2.0);
      }

      if(novoSup < novoInf) {
         double t = novoSup;
         novoSup = novoInf;
         novoInf = t;
      }

      int topos = base.quantidadeTopos + toposCandidato;
      int fundos = base.quantidadeFundos + fundosCandidato;
      ENUM_LINE_TYPE tipoNovo = base.tipo;

      g_pivos[idxZonaBase].precoSuperior = novoSup;
      g_pivos[idxZonaBase].precoInferior = novoInf;
      g_pivos[idxZonaBase].tipo = tipoNovo;
      g_pivos[idxZonaBase].tipoMajoritario = tipoNovo;
      g_pivos[idxZonaBase].preco = (tipoNovo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxZonaBase].corAtual = ObterCorZona(tipoNovo);
      g_pivos[idxZonaBase].volumeBuy = base.volumeBuy + ((tipoCandidato == LINE_BOTTOM) ? volumeCandidato : 0.0);
      g_pivos[idxZonaBase].volumeSell = base.volumeSell + ((tipoCandidato == LINE_TOP) ? volumeCandidato : 0.0);
      RecalcularVolumeTotalZona(idxZonaBase);
      g_pivos[idxZonaBase].volumeDistribuicao = base.volumeDistribuicao + volumeCandidato;
      double pesoBaseOrig = MathMax(1.0, base.volumeDistribuicao);
      double pesoCandOrig = MathMax(1.0, volumeCandidato);
      double scoreCandOrig = (volumeCandidato > 0.0) ? 1.0 : base.scoreOrigem;
      double scoreNovo = ((base.scoreOrigem * pesoBaseOrig) + (scoreCandOrig * pesoCandOrig)) /
                         (pesoBaseOrig + pesoCandOrig);
      if(scoreNovo < 0.0) scoreNovo = 0.0;
      if(scoreNovo > 1.0) scoreNovo = 1.0;
      g_pivos[idxZonaBase].scoreOrigem = scoreNovo;
      g_pivos[idxZonaBase].espessuraZona = ConverterScoreEmEspessura(scoreNovo);
      g_pivos[idxZonaBase].quantidadeBarras = base.quantidadeBarras + MathMax(1, barrasCandidato);
      g_pivos[idxZonaBase].quantidadeTopos = topos;
      g_pivos[idxZonaBase].quantidadeFundos = fundos;
      g_pivos[idxZonaBase].tempoMaisRecente = MathMax(base.tempoMaisRecente, tempoCandidato);
      g_pivos[idxZonaBase].ultimoTempoToqueContabilizado = tempoCandidato;
      g_pivos[idxZonaBase].atr = (base.atr + atrCandidato) * 0.5;
      g_pivos[idxZonaBase].foiMergeada = true;
      g_pivos[idxZonaBase].estado = PIVO_ATIVO;
      SDV4_MergeCooldownMarcarZona(idxZonaBase);

      return true;
   }

   // Merge quando houver tentativa de criação próxima.
   bool MergeQuandoCriacaoProxima(const int idxZonaProxima,
                                  const ENUM_LINE_TYPE tipoCandidato,
                                  const datetime tempoCandidato,
                                  const double volumeCandidato,
                                  const double supCandidato,
                                  const double infCandidato,
                                  const bool acumularNoDistribuicao) {
      if(idxZonaProxima < 0 || idxZonaProxima >= g_numeroZonas) return false;
      if(g_pivos[idxZonaProxima].estado == PIVO_REMOVIDO) return false;

      if(!g_pivos[idxZonaProxima].ancoraInicializada) DefinirAncoraPivo(idxZonaProxima);

      // Conflito de sinal: opcionalmente subtrai volume da zona em vez de mesclar.
      bool conflitoSinal = (tipoCandidato != g_pivos[idxZonaProxima].tipo);
      if(conflitoSinal && SDV4_RegrasModoConflitoSubtrair()) {
         double volCand = MathMax(0.0, volumeCandidato);
         if(volCand <= 0.0) return false;

         double volAntes = MathMax(0.0, g_pivos[idxZonaProxima].volumeTotal);
         double distAntes = MathMax(0.0, g_pivos[idxZonaProxima].volumeDistribuicao);
         SubtrairVolumeContrarioNaZona(idxZonaProxima, tipoCandidato, volCand);
         g_pivos[idxZonaProxima].volumeDistribuicao = MathMax(0.0, distAntes - volCand);
         g_pivos[idxZonaProxima].tempoMaisRecente =
            MathMax(g_pivos[idxZonaProxima].tempoMaisRecente, tempoCandidato);
         g_pivos[idxZonaProxima].ultimoTempoToqueContabilizado = tempoCandidato;
         g_pivos[idxZonaProxima].estado = PIVO_ATIVO;

         // Evita score "travado" alto quando o volume foi drenado por sinal contrário.
         double fatorRestante = (volAntes > 1e-9) ? (g_pivos[idxZonaProxima].volumeTotal / volAntes) : 0.0;
         if(fatorRestante < 0.0) fatorRestante = 0.0;
         if(fatorRestante > 1.0) fatorRestante = 1.0;
         g_pivos[idxZonaProxima].scoreOrigem = LimitarScoreUnitario(g_pivos[idxZonaProxima].scoreOrigem * fatorRestante);
         g_pivos[idxZonaProxima].espessuraZona = ConverterScoreEmEspessura(g_pivos[idxZonaProxima].scoreOrigem);
         g_pivos[idxZonaProxima].corAtual = ObterCorZona(g_pivos[idxZonaProxima].tipo);
         return true;
      }

      double alturaMinima = ObterAlturaMinimaZonaPreco();
      double supCand = MathMax(supCandidato, infCandidato);
      double infCand = MathMin(supCandidato, infCandidato);
      double alturaCand = MathAbs(supCand - infCand);
      if(alturaCand < alturaMinima) alturaCand = alturaMinima;

      double supAnc = MathMax(g_pivos[idxZonaProxima].ancoraSup, g_pivos[idxZonaProxima].ancoraInf);
      double infAnc = MathMin(g_pivos[idxZonaProxima].ancoraSup, g_pivos[idxZonaProxima].ancoraInf);
      double alturaBase = MathAbs(supAnc - infAnc);
      if(alturaBase < alturaMinima) alturaBase = alturaMinima;

      double fatorAbsorcao = SDV4_RegrasFatorAbsorcaoMerge();

      double volumeBaseNominal = MathMax(1.0, g_pivos[idxZonaProxima].volumeTotal);
      double volumeCandNominal = MathMax(0.0, volumeCandidato);
      double ganhoPorVolume = alturaBase * (volumeCandNominal / volumeBaseNominal);
      double ganhoAltura = MathMax(alturaCand, ganhoPorVolume) * fatorAbsorcao;
      double novaAltura = alturaBase + ganhoAltura;

      double atrRef = g_pivos[idxZonaProxima].atr;
      if(atrRef <= 0.0) atrRef = MathAbs(supAnc - infAnc);
      double alturaMaxima = ObterAlturaMaximaPermitida(atrRef);
      if(MathIsValidNumber(alturaMaxima) && alturaMaxima > 0.0 && novaAltura > alturaMaxima)
         novaAltura = alturaMaxima;
      if(novaAltura < alturaMinima) novaAltura = alturaMinima;

      double novoSup = supAnc;
      double novoInf = infAnc;
      if(g_pivos[idxZonaProxima].tipo == LINE_TOP) {
         novoSup = supAnc;
         novoInf = supAnc - novaAltura;
      } else {
         novoInf = infAnc;
         novoSup = infAnc + novaAltura;
      }
      AplicarLimiteAlturaFaixa(novoSup, novoInf, g_pivos[idxZonaProxima].tipo, atrRef);
      if(novoSup < novoInf) {
         double t = novoSup;
         novoSup = novoInf;
         novoInf = t;
      }

      double pesoBaseOrig2 = MathMax(1.0, g_pivos[idxZonaProxima].volumeTotal);
      double pesoCandOrig2 = MathMax(1.0, volumeCandidato);
      double scoreCandOrig2 = (volumeCandidato > 0.0) ? 1.0 : g_pivos[idxZonaProxima].scoreOrigem;
      double scoreNovo2 = ((g_pivos[idxZonaProxima].scoreOrigem * pesoBaseOrig2) + (scoreCandOrig2 * pesoCandOrig2)) /
                          (pesoBaseOrig2 + pesoCandOrig2);
      if(scoreNovo2 < 0.0) scoreNovo2 = 0.0;
      if(scoreNovo2 > 1.0) scoreNovo2 = 1.0;

      g_pivos[idxZonaProxima].precoSuperior = novoSup;
      g_pivos[idxZonaProxima].precoInferior = novoInf;
      g_pivos[idxZonaProxima].preco = (g_pivos[idxZonaProxima].tipo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxZonaProxima].ancoraSup = novoSup;
      g_pivos[idxZonaProxima].ancoraInf = novoInf;
      g_pivos[idxZonaProxima].ancoraPreco = g_pivos[idxZonaProxima].preco;
      g_pivos[idxZonaProxima].ancoraInicializada = true;

      SomarVolumeNaZona(idxZonaProxima, tipoCandidato, volumeCandidato);
      if(acumularNoDistribuicao) {
         g_pivos[idxZonaProxima].volumeDistribuicao += volumeCandidato;
      }
      g_pivos[idxZonaProxima].scoreOrigem = scoreNovo2;
      g_pivos[idxZonaProxima].espessuraZona = ConverterScoreEmEspessura(scoreNovo2);
      g_pivos[idxZonaProxima].quantidadeBarras++;
      if(tipoCandidato == LINE_TOP) g_pivos[idxZonaProxima].quantidadeTopos++;
      else g_pivos[idxZonaProxima].quantidadeFundos++;
      g_pivos[idxZonaProxima].tempoMaisRecente = MathMax(g_pivos[idxZonaProxima].tempoMaisRecente, tempoCandidato);
      g_pivos[idxZonaProxima].ultimoTempoToqueContabilizado = tempoCandidato;
      g_pivos[idxZonaProxima].tipoMajoritario =
         (g_pivos[idxZonaProxima].quantidadeTopos >= g_pivos[idxZonaProxima].quantidadeFundos) ? LINE_TOP : LINE_BOTTOM;
      g_pivos[idxZonaProxima].corAtual = ObterCorZona(g_pivos[idxZonaProxima].tipo);
      g_pivos[idxZonaProxima].estado = PIVO_ATIVO;
      return true;
   }

};

CSupDemVolMergeManager g_mergeManager;

// ---------------------------------------------------------------------------
// Wrapper API (mantém chamadas existentes).
// ---------------------------------------------------------------------------
void LimparSlotPivo(const int idx) {
   g_mergeManager.LimparSlotPivo(idx);
}

double DistanciaEntreFaixas(double faixaSuperiorA, double faixaInferiorA, double faixaSuperiorB, double faixaInferiorB) {
   return g_mergeManager.DistanciaEntreFaixas(faixaSuperiorA, faixaInferiorA, faixaSuperiorB, faixaInferiorB);
}

double DistanciaMinimaParaOutrasZonas(const int idxIgnorarA,
                                      const int idxIgnorarB,
                                      const double faixaSuperior,
                                      const double faixaInferior) {
   return g_mergeManager.DistanciaMinimaParaOutrasZonas(idxIgnorarA, idxIgnorarB, faixaSuperior, faixaInferior);
}

double ObterLimiarDistanciaATR(const double atrReferencia, const double percentualATR) {
   return g_mergeManager.ObterLimiarDistanciaATR(atrReferencia, percentualATR);
}

double ObterAlturaMaximaPermitidaMerge(const double atrReferencia) {
   return g_mergeManager.ObterAlturaMaximaPermitidaExterna(atrReferencia);
}

bool EstaMuitoProximaParaMerge(const double distFaixa,
                               const double limiteDistancia) {
   return g_mergeManager.EstaMuitoProximaParaMerge(distFaixa, limiteDistancia);
}

bool MesclarZonaComCandidato(int idxZonaBase,
                             ENUM_LINE_TYPE tipoCandidato,
                             double supCandidato,
                             double infCandidato,
                             double volumeCandidato,
                             int barrasCandidato,
                             int toposCandidato,
                             int fundosCandidato,
                             double atrCandidato,
                             datetime tempoCandidato,
                             double limiteDistanciaMerge) {
   if(!SDV4_RegrasPermitirMergeZona(idxZonaBase,
                                    tempoCandidato,
                                    volumeCandidato,
                                    "MERGE-WRAP-CANDIDATO")) return false;
   return g_mergeManager.MesclarZonaComCandidato(idxZonaBase,
                                                 tipoCandidato,
                                                 supCandidato,
                                                 infCandidato,
                                                 volumeCandidato,
                                                 barrasCandidato,
                                                 toposCandidato,
                                                 fundosCandidato,
                                                 atrCandidato,
                                                 tempoCandidato,
                                                 limiteDistanciaMerge);
}

bool MergeQuandoCriacaoProxima(const int idxZonaProxima,
                               const ENUM_LINE_TYPE tipoCandidato,
                               const datetime tempoCandidato,
                               const double volumeCandidato,
                               const double supCandidato,
                               const double infCandidato,
                               const bool acumularNoDistribuicao) {
   if(!SDV4_RegrasPermitirEnriquecimentoZona(idxZonaProxima,
                                             tempoCandidato,
                                             volumeCandidato,
                                             "MERGE-WRAP-CRIACAO-PROXIMA")) return false;
   return g_mergeManager.MergeQuandoCriacaoProxima(idxZonaProxima,
                                                   tipoCandidato,
                                                   tempoCandidato,
                                                   volumeCandidato,
                                                   supCandidato,
                                                   infCandidato,
                                                   acumularNoDistribuicao);
}

// </editor-fold>

#endif // __SUPDEMVOL_MERGE_RULES_MQH__
