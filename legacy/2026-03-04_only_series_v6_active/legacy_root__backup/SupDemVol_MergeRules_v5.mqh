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
      double pct = InpEscalaRelativaMinPctPreco;
      if(!MathIsValidNumber(pct)) pct = 0.05;
      if(pct < 0.0001) pct = 0.0001;
      if(pct > 5.0) pct = 5.0;
      return ObterPrecoReferenciaEscala() * (pct / 100.0);
   }

   double ObterFatorEscalaFaixaDia() {
      double f = InpEscalaRelativaFatorFaixaDia;
      if(!MathIsValidNumber(f)) f = 0.10;
      if(f < 0.01) f = 0.01;
      if(f > 1.00) f = 1.00;
      return f;
   }

   double ObterEscalaReferencia(const double atrReferencia) {
      if(!InpEscalaRelativaSemATR) {
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
      if(InpMaxATRPercent <= 0.0) return DBL_MAX;
      double escala = ObterEscalaReferencia(atrReferencia);
      double limite = escala * (InpMaxATRPercent / 100.0);
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

   double ObterFatorLimiteIntervaloPorSoma() {
      double fator = InpFatorGapPorSomaMerge;
      if(fator < 0.0) fator = 0.0;
      if(fator > 1.0) fator = 1.0;
      return fator;
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
      g_pivos[idx].volumeDistribuicao = 0.0;
      g_pivos[idx].scoreOrigem = 0.0;
      g_pivos[idx].espessuraZona = 1;
      g_pivos[idx].volumeMaximo = 0.0;
      g_pivos[idx].percentualVolume = 0.0;
      g_pivos[idx].percentualVolumeInterno = 0.0;
      g_pivos[idx].percentualVolumeMercado = 0.0;
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
      double fracaoAbsorcao = InpFatorAbsorcaoMerge;
      if(fracaoAbsorcao < 0.0) fracaoAbsorcao = 0.0;
      if(fracaoAbsorcao > 1.0) fracaoAbsorcao = 1.0;

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
         if(InpLogDetalhado) {
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
      g_pivos[idxZonaBase].volumeTotal = base.volumeTotal + volumeCandidato;
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

      return true;
   }

   // Regra: sem slot livre -> funde a mais fraca/fina com a mais próxima para abrir 1 slot.
   // Critério extra: protege zonas próximas do preço atual.
   bool FundirZonaMaisFracaParaAbrirSlot(const ENUM_LINE_TYPE tipoPreferido, const double precoAtualRef) {
      int ativos[20];
      int nAtivos = 0;
      for(int i = 0; i < g_numeroZonas; i++) {
         if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
         ativos[nAtivos++] = i;
      }
      if(nAtivos < 2) return false;

      int idxFraca = -1;
      double maiorDistPreco = -DBL_MAX;
      double menorVolumeEmpate = DBL_MAX;
      for(int k = 0; k < nAtivos; k++) {
         int idx = ativos[k];
         if(EhZonaProtegidaOrganizacao(idx)) continue;
         double distPreco = MathAbs(g_pivos[idx].preco - precoAtualRef);
         double volumeAtual = g_pivos[idx].volumeTotal;

         // Novo critério pedido: sem slot, sacrifica primeiro a zona mais longe do preço.
         // Empate: remove a de menor volume.
         g_pivos[idx].score = distPreco;
         if(distPreco > maiorDistPreco + 1e-9) {
            maiorDistPreco = distPreco;
            idxFraca = idx;
            menorVolumeEmpate = volumeAtual;
         } else if(MathAbs(distPreco - maiorDistPreco) <= 1e-9) {
            if(volumeAtual < menorVolumeEmpate) {
               idxFraca = idx;
               menorVolumeEmpate = volumeAtual;
            }
         }
      }
      if(idxFraca < 0) return false;

      int idxVizinha = -1;
      double distMin = DBL_MAX;
      for(int k = 0; k < nAtivos; k++) {
         int idx = ativos[k];
         if(idx == idxFraca) continue;
         double dist = MathAbs(g_pivos[idx].preco - g_pivos[idxFraca].preco);
         if(dist < distMin) {
            distMin = dist;
            idxVizinha = idx;
         }
      }
      if(idxVizinha < 0) return false;

      PivoAtivo fraca = g_pivos[idxFraca];
      PivoAtivo viz = g_pivos[idxVizinha];

      double alturaFraca = MathAbs(fraca.precoSuperior - fraca.precoInferior);
      double alturaViz = MathAbs(viz.precoSuperior - viz.precoInferior);
      double alturaMinima = ObterAlturaMinimaZonaPreco();
      if(alturaFraca < alturaMinima) alturaFraca = alturaMinima;
      if(alturaViz < alturaMinima) alturaViz = alturaMinima;

      // Sem slot: a zona sobrevivente precisa crescer de forma visível.
      double fatorAbsorcao = InpFatorAbsorcaoMerge;
      if(fatorAbsorcao < 0.0) fatorAbsorcao = 0.0;
      if(fatorAbsorcao > 1.00) fatorAbsorcao = 1.00;
      double alturaNova = alturaViz + (alturaFraca * fatorAbsorcao);
      if(alturaNova < alturaMinima) alturaNova = alturaMinima;

      double alturaMaxima = ObterAlturaMaximaPermitida((fraca.atr + viz.atr) * 0.5);
      if(alturaMaxima > 0.0) {
         if(alturaNova > alturaMaxima) alturaNova = alturaMaxima;
      }

      int topos = fraca.quantidadeTopos + viz.quantidadeTopos;
      int fundos = fraca.quantidadeFundos + viz.quantidadeFundos;
      ENUM_LINE_TYPE tipoNovo = tipoPreferido;
      if(topos > fundos) tipoNovo = LINE_TOP;
      else if(fundos > topos) tipoNovo = LINE_BOTTOM;
      else if(fraca.tipo == viz.tipo) tipoNovo = viz.tipo;

      // Mantém a âncora da zona sobrevivente (vizinha) e expande apenas a borda oposta.
      double novoSup, novoInf;
      if(tipoNovo == LINE_TOP) {
         double ancora = MathMax(viz.precoSuperior, viz.precoInferior);
         novoSup = ancora;
         novoInf = ancora - alturaNova;
      } else {
         double ancora = MathMin(viz.precoSuperior, viz.precoInferior);
         novoInf = ancora;
         novoSup = ancora + alturaNova;
      }
      AplicarLimiteAlturaFaixa(novoSup, novoInf, tipoNovo, (fraca.atr + viz.atr) * 0.5);
      if(novoSup < novoInf) {
         double t = novoSup;
         novoSup = novoInf;
         novoInf = t;
      }

      g_pivos[idxVizinha].precoSuperior = novoSup;
      g_pivos[idxVizinha].precoInferior = novoInf;
      g_pivos[idxVizinha].tipo = tipoNovo;
      g_pivos[idxVizinha].tipoMajoritario = tipoNovo;
      g_pivos[idxVizinha].preco = (tipoNovo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxVizinha].corAtual = ObterCorZona(tipoNovo);
      g_pivos[idxVizinha].volumeTotal = viz.volumeTotal + fraca.volumeTotal;
      g_pivos[idxVizinha].volumeDistribuicao = viz.volumeDistribuicao + fraca.volumeDistribuicao;
      double pesoVizOrig = MathMax(1.0, viz.volumeDistribuicao);
      double pesoFracaOrig = MathMax(1.0, fraca.volumeDistribuicao);
      double scoreNovoVF = ((viz.scoreOrigem * pesoVizOrig) + (fraca.scoreOrigem * pesoFracaOrig)) /
                           (pesoVizOrig + pesoFracaOrig);
      if(scoreNovoVF < 0.0) scoreNovoVF = 0.0;
      if(scoreNovoVF > 1.0) scoreNovoVF = 1.0;
      g_pivos[idxVizinha].scoreOrigem = scoreNovoVF;
      g_pivos[idxVizinha].espessuraZona = ConverterScoreEmEspessura(scoreNovoVF);
      g_pivos[idxVizinha].quantidadeBarras = viz.quantidadeBarras + fraca.quantidadeBarras;
      g_pivos[idxVizinha].quantidadeTopos = topos;
      g_pivos[idxVizinha].quantidadeFundos = fundos;
      g_pivos[idxVizinha].tempoInicio = (viz.tempoInicio < fraca.tempoInicio) ? viz.tempoInicio : fraca.tempoInicio;
      g_pivos[idxVizinha].tempoMaisRecente = (viz.tempoMaisRecente > fraca.tempoMaisRecente) ? viz.tempoMaisRecente : fraca.tempoMaisRecente;
      g_pivos[idxVizinha].ultimoTempoToqueContabilizado =
         (viz.ultimoTempoToqueContabilizado > fraca.ultimoTempoToqueContabilizado) ?
         viz.ultimoTempoToqueContabilizado : fraca.ultimoTempoToqueContabilizado;
      g_pivos[idxVizinha].atr = (viz.atr + fraca.atr) * 0.5;
      g_pivos[idxVizinha].foiMergeada = true;
      g_pivos[idxVizinha].estado = PIVO_ATIVO;

      string idIncorp = (fraca.pivoID > 0) ? IntegerToString(fraca.pivoID) : "";
      if(StringLen(idIncorp) > 0) {
         if(StringLen(g_pivos[idxVizinha].pivosIncorporados) > 0)
            g_pivos[idxVizinha].pivosIncorporados += "," + idIncorp;
         else
            g_pivos[idxVizinha].pivosIncorporados = idIncorp;
      }

      LimparSlotPivo(idxFraca);
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

      double alturaMinima = ObterAlturaMinimaZonaPreco();
      double supCand = MathMax(supCandidato, infCandidato);
      double infCand = MathMin(supCandidato, infCandidato);
      double alturaCand = MathAbs(supCand - infCand);
      if(alturaCand < alturaMinima) alturaCand = alturaMinima;

      double supAnc = MathMax(g_pivos[idxZonaProxima].ancoraSup, g_pivos[idxZonaProxima].ancoraInf);
      double infAnc = MathMin(g_pivos[idxZonaProxima].ancoraSup, g_pivos[idxZonaProxima].ancoraInf);
      double alturaBase = MathAbs(supAnc - infAnc);
      if(alturaBase < alturaMinima) alturaBase = alturaMinima;

      double fatorAbsorcao = InpFatorAbsorcaoMerge;
      if(fatorAbsorcao < 0.0) fatorAbsorcao = 0.0;
      if(fatorAbsorcao > 1.0) fatorAbsorcao = 1.0;

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

      g_pivos[idxZonaProxima].volumeTotal += volumeCandidato;
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

   // Merge explícito entre a zona recém-criada e sua vizinha próxima.
   // Mantém a vizinha como base e absorve a recém-criada.
   bool MesclarZonasPorIndices(const int idxNova, const int idxVizinha, const double precoAtualRef) {
      if(idxNova < 0 || idxNova >= g_numeroZonas) return false;
      if(idxVizinha < 0 || idxVizinha >= g_numeroZonas) return false;
      if(idxNova == idxVizinha) return false;
      if(g_pivos[idxNova].estado == PIVO_REMOVIDO) return false;
      if(g_pivos[idxVizinha].estado == PIVO_REMOVIDO) return false;
      if(g_pivos[idxNova].foiMergeada || g_pivos[idxVizinha].foiMergeada) return false;

      PivoAtivo nova = g_pivos[idxNova];
      PivoAtivo viz = g_pivos[idxVizinha];

      double atrBase = (nova.atr + viz.atr) * 0.5;
      double limiarMerge = ObterLimiarDistanciaATR(atrBase, (InpMergeATRPercent + InpDistanciaMinATR) * 0.5);
      double distEntreFaixas = DistanciaEntreFaixas(nova.precoSuperior, nova.precoInferior,
                                                   viz.precoSuperior, viz.precoInferior);
      if(!EstaMuitoProximaParaMerge(distEntreFaixas, limiarMerge)) return false;
      double hNova = MathAbs(nova.precoSuperior - nova.precoInferior);
      double hViz = MathAbs(viz.precoSuperior - viz.precoInferior);
      if(!EstaDistanciaAceitaPorSoma(distEntreFaixas, hNova, hViz)) return false;

      double wN = MathMax(1.0, nova.volumeTotal);
      double wV = MathMax(1.0, viz.volumeTotal);
      double wT = wN + wV;
      double novoSup = (nova.precoSuperior * wN + viz.precoSuperior * wV) / wT;
      double novoInf = (nova.precoInferior * wN + viz.precoInferior * wV) / wT;
      if(novoSup < novoInf) {
         double t = novoSup;
         novoSup = novoInf;
         novoInf = t;
      }

      int topos = nova.quantidadeTopos + viz.quantidadeTopos;
      int fundos = nova.quantidadeFundos + viz.quantidadeFundos;
      ENUM_LINE_TYPE tipoNovo = viz.tipo;
      if(topos > fundos) tipoNovo = LINE_TOP;
      else if(fundos > topos) tipoNovo = LINE_BOTTOM;
      AplicarLimiteAlturaFaixa(novoSup, novoInf, tipoNovo, atrBase);

      g_pivos[idxVizinha].precoSuperior = novoSup;
      g_pivos[idxVizinha].precoInferior = novoInf;
      g_pivos[idxVizinha].tipo = tipoNovo;
      g_pivos[idxVizinha].tipoMajoritario = tipoNovo;
      g_pivos[idxVizinha].preco = (tipoNovo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxVizinha].corAtual = ObterCorZona(tipoNovo);
      g_pivos[idxVizinha].volumeTotal = viz.volumeTotal + nova.volumeTotal;
      g_pivos[idxVizinha].volumeDistribuicao = viz.volumeDistribuicao + nova.volumeDistribuicao;
      double pesoVizOrig2 = MathMax(1.0, viz.volumeDistribuicao);
      double pesoNovaOrig = MathMax(1.0, nova.volumeDistribuicao);
      double scoreNovoVN = ((viz.scoreOrigem * pesoVizOrig2) + (nova.scoreOrigem * pesoNovaOrig)) /
                           (pesoVizOrig2 + pesoNovaOrig);
      if(scoreNovoVN < 0.0) scoreNovoVN = 0.0;
      if(scoreNovoVN > 1.0) scoreNovoVN = 1.0;
      g_pivos[idxVizinha].scoreOrigem = scoreNovoVN;
      g_pivos[idxVizinha].espessuraZona = ConverterScoreEmEspessura(scoreNovoVN);
      g_pivos[idxVizinha].quantidadeBarras = viz.quantidadeBarras + nova.quantidadeBarras;
      g_pivos[idxVizinha].quantidadeTopos = topos;
      g_pivos[idxVizinha].quantidadeFundos = fundos;
      g_pivos[idxVizinha].tempoInicio = (viz.tempoInicio < nova.tempoInicio) ? viz.tempoInicio : nova.tempoInicio;
      g_pivos[idxVizinha].tempoMaisRecente = (viz.tempoMaisRecente > nova.tempoMaisRecente) ? viz.tempoMaisRecente : nova.tempoMaisRecente;
      g_pivos[idxVizinha].ultimoTempoToqueContabilizado =
         (viz.ultimoTempoToqueContabilizado > nova.ultimoTempoToqueContabilizado) ?
         viz.ultimoTempoToqueContabilizado : nova.ultimoTempoToqueContabilizado;
      g_pivos[idxVizinha].atr = (viz.atr + nova.atr) * 0.5;
      g_pivos[idxVizinha].foiMergeada = true;
      g_pivos[idxVizinha].estado = PIVO_ATIVO;

      string idIncorp = (nova.pivoID > 0) ? IntegerToString(nova.pivoID) : "";
      if(StringLen(idIncorp) > 0) {
         if(StringLen(g_pivos[idxVizinha].pivosIncorporados) > 0)
            g_pivos[idxVizinha].pivosIncorporados += "," + idIncorp;
         else
            g_pivos[idxVizinha].pivosIncorporados = idIncorp;
      }

      // Em empate de força, privilegia a zona mais perto do preço atual como base visual.
      double forcaViz = viz.volumeTotal + (double)viz.quantidadeBarras;
      double forcaNova = nova.volumeTotal + (double)nova.quantidadeBarras;
      if(MathAbs(forcaViz - forcaNova) <= 1e-9) {
         double dViz = MathAbs(viz.preco - precoAtualRef);
         double dNova = MathAbs(nova.preco - precoAtualRef);
         if(dNova < dViz) {
            // Se a nova estava mais perto do preço atual, centraliza pelo anchor da nova.
            if(tipoNovo == LINE_TOP) {
               double h = MathAbs(novoSup - novoInf);
               g_pivos[idxVizinha].precoSuperior = nova.precoSuperior;
               g_pivos[idxVizinha].precoInferior = nova.precoSuperior - h;
               g_pivos[idxVizinha].preco = g_pivos[idxVizinha].precoSuperior;
            } else {
               double h = MathAbs(novoSup - novoInf);
               g_pivos[idxVizinha].precoInferior = nova.precoInferior;
               g_pivos[idxVizinha].precoSuperior = nova.precoInferior + h;
               g_pivos[idxVizinha].preco = g_pivos[idxVizinha].precoInferior;
            }
         }
      }

      if(EhZonaProtegidaOrganizacao(idxNova)) return false;
      LimparSlotPivo(idxNova);
      return true;
   }

   // Mescla direcional em zona de topo/fundo quando as duas zonas foram tocadas pela mesma barra.
   // Mantém a zona base e só aumenta a margem da base para o lado do fluxo da zona.
   bool MesclarZonasMesmoBarraMesmoTipo(const int idxBase,
                                      const int idxOutra,
                                      const double barraSuperior,
                                      const double barraInferior,
                                      const bool validarDistanciaSoma = true) {
      if(idxBase < 0 || idxBase >= g_numeroZonas) return false;
      if(idxOutra < 0 || idxOutra >= g_numeroZonas) return false;
      if(idxBase == idxOutra) return false;
      if(g_pivos[idxBase].estado == PIVO_REMOVIDO) return false;
      if(g_pivos[idxOutra].estado == PIVO_REMOVIDO) return false;
      if(g_pivos[idxBase].foiMergeada || g_pivos[idxOutra].foiMergeada) return false;
      double supBase = MathMax(g_pivos[idxBase].precoSuperior, g_pivos[idxBase].precoInferior);
      double infBase = MathMin(g_pivos[idxBase].precoSuperior, g_pivos[idxBase].precoInferior);
      double supOutra = MathMax(g_pivos[idxOutra].precoSuperior, g_pivos[idxOutra].precoInferior);
      double infOutra = MathMin(g_pivos[idxOutra].precoSuperior, g_pivos[idxOutra].precoInferior);
      double supBarra = MathMax(barraSuperior, barraInferior);
      double infBarra = MathMin(barraSuperior, barraInferior);
      if(supBarra < infBase || infBarra > supBase) {
         if(InpLogDetalhado) {
            Print("MERGE[mesma-barra][REJECT]: barra não toca zona base idx=", idxBase);
         }
         return false;
      }
      if(supBarra < infOutra || infBarra > supOutra) {
         if(InpLogDetalhado) {
            Print("MERGE[mesma-barra][REJECT]: barra não toca zona absorvida idx=", idxOutra);
         }
         return false;
      }

      int idxBaseAtivo = idxBase;
      int idxOutraAtivo = idxOutra;
      PivoAtivo base = g_pivos[idxBaseAtivo];
      PivoAtivo outra = g_pivos[idxOutraAtivo];

      double alturaBase = MathAbs(base.precoSuperior - base.precoInferior);
      double alturaOutra = MathAbs(outra.precoSuperior - outra.precoInferior);
      // Sempre mantém o maior tamanho como base ativa para manter a zona principal realmente "engolindo" a menor.
      if(alturaOutra > alturaBase) {
         idxBaseAtivo = idxOutra;
         idxOutraAtivo = idxBase;
         PivoAtivo temp = base;
         base = outra;
         outra = temp;
         double tempAlt = alturaBase;
         alturaBase = alturaOutra;
         alturaOutra = tempAlt;
      }

      double intervalo = DistanciaEntreFaixas(base.precoSuperior, base.precoInferior,
                                             outra.precoSuperior, outra.precoInferior);
      if(validarDistanciaSoma && !EstaDistanciaAceitaPorSoma(intervalo, alturaBase, alturaOutra)) {
         if(InpLogDetalhado) {
            double limiarSoma = (MathAbs(base.precoSuperior - base.precoInferior) + MathAbs(outra.precoSuperior - outra.precoInferior))
                                 * ((InpFatorGapPorSomaMerge < 0.0) ? 0.0 : InpFatorGapPorSomaMerge);
            PrintFormat("MERGE[mesma-barra][REJECT]: idxBase=%d idxOutra=%d distancia=%.5f limiarSoma=%.5f",
                        idxBaseAtivo, idxOutraAtivo, intervalo, limiarSoma);
         }
         return false;
      }

      // Regras de absorção: a zona que mergeia ganha a fração parametrizada da altura da zona absorvida.
      // Mantém-se a faixa da "cara da zona mergeadora"; apenas a margem oposta é expandida.
      double fracaoAbsorcao = InpFatorAbsorcaoMerge;
      if(fracaoAbsorcao < 0.0) fracaoAbsorcao = 0.0;
      if(fracaoAbsorcao > 1.0) fracaoAbsorcao = 1.0;
      double absorcao = alturaOutra * fracaoAbsorcao;
      double novaAlturaBase = alturaBase + absorcao;
      novaAlturaBase = MathMin(novaAlturaBase, ObterAlturaMaximaPermitida((base.atr + outra.atr) * 0.5));
      double novoSupCand1 = base.precoSuperior;
      double novoInfCand1 = base.precoInferior;
      double novoSupCand2 = outra.precoSuperior;
      double novoInfCand2 = outra.precoInferior;

      if(base.tipo == LINE_TOP) {
         novoSupCand1 = base.precoSuperior;
         novoInfCand1 = base.precoSuperior - novaAlturaBase;
         novoSupCand2 = outra.precoSuperior;
         novoInfCand2 = outra.precoSuperior - novaAlturaBase;
      } else {
         novoInfCand1 = base.precoInferior;
         novoSupCand1 = base.precoInferior + novaAlturaBase;
         novoInfCand2 = outra.precoInferior;
         novoSupCand2 = outra.precoInferior + novaAlturaBase;
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

      double distCand1 = DistanciaMinimaParaOutrasZonas(idxBaseAtivo, idxOutraAtivo, novoSupCand1, novoInfCand1);
      double distCand2 = DistanciaMinimaParaOutrasZonas(idxBaseAtivo, idxOutraAtivo, novoSupCand2, novoInfCand2);

      double novoSup = novoSupCand1;
      double novoInf = novoInfCand1;
      // Padrão de controle: buscar a posição com maior separação de vizinhas no mesmo sentido.
      if(distCand2 > distCand1 + (_Point * 1.0)) {
         novoSup = novoSupCand2;
         novoInf = novoInfCand2;
      } else if(MathAbs(distCand2 - distCand1) <= (_Point * 1.0)) {
         // Empate: manter o extremo mais próximo do pivo-base (menos deslocamento).
         double ancBaseSup = MathMax(base.precoSuperior, base.precoInferior);
         double ancBaseInf = MathMin(base.precoSuperior, base.precoInferior);
         double deslocCand1 = (base.tipo == LINE_TOP) ? MathAbs(ancBaseSup - novoSupCand1) : MathAbs(ancBaseInf - novoInfCand1);
         double deslocCand2 = (base.tipo == LINE_TOP) ? MathAbs(ancBaseSup - novoSupCand2) : MathAbs(ancBaseInf - novoInfCand2);
         if(deslocCand2 < deslocCand1) {
            novoSup = novoSupCand2;
            novoInf = novoInfCand2;
         }
      }
      AplicarLimiteAlturaFaixa(novoSup, novoInf, base.tipo, (base.atr + outra.atr) * 0.5);

      if(!MathIsValidNumber(novoSup) || !MathIsValidNumber(novoInf) ||
         novoSup <= novoInf) {
         if(InpLogDetalhado) {
            PrintFormat("MERGE[mesma-barra][REJECT]: resultado inválido base=%d outra=%d novaFaixa=(%.5f, %.5f)",
                        idxBaseAtivo, idxOutraAtivo, novoSup, novoInf);
         }
         return false;
      }

      // Garante espessura mínima para não ficar "invisível".
      if((novoSup - novoInf) < (_Point * 2.0)) {
         novoInf = (base.tipo == LINE_TOP) ? (novoInf - _Point * 2.0) : novoInf;
         novoSup = (base.tipo == LINE_TOP) ? novoSup : (novoSup + _Point * 2.0);
      }

      int topos = base.quantidadeTopos + outra.quantidadeTopos;
      int fundos = base.quantidadeFundos + outra.quantidadeFundos;

      g_pivos[idxBaseAtivo].precoSuperior = novoSup;
      g_pivos[idxBaseAtivo].precoInferior = novoInf;
      g_pivos[idxBaseAtivo].preco = (base.tipo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxBaseAtivo].tipo = base.tipo;
      g_pivos[idxBaseAtivo].tipoMajoritario = base.tipo;
      g_pivos[idxBaseAtivo].corAtual = ObterCorZona(base.tipo);
      g_pivos[idxBaseAtivo].volumeTotal = base.volumeTotal + outra.volumeTotal;
      g_pivos[idxBaseAtivo].volumeDistribuicao = base.volumeDistribuicao + outra.volumeDistribuicao;
      double pesoBaseOrig3 = MathMax(1.0, base.volumeDistribuicao);
      double pesoOutraOrig = MathMax(1.0, outra.volumeDistribuicao);
      double scoreNovoBO = ((base.scoreOrigem * pesoBaseOrig3) + (outra.scoreOrigem * pesoOutraOrig)) /
                           (pesoBaseOrig3 + pesoOutraOrig);
      if(scoreNovoBO < 0.0) scoreNovoBO = 0.0;
      if(scoreNovoBO > 1.0) scoreNovoBO = 1.0;
      g_pivos[idxBaseAtivo].scoreOrigem = scoreNovoBO;
      g_pivos[idxBaseAtivo].espessuraZona = ConverterScoreEmEspessura(scoreNovoBO);
      g_pivos[idxBaseAtivo].quantidadeBarras = base.quantidadeBarras + outra.quantidadeBarras;
      g_pivos[idxBaseAtivo].quantidadeTopos = topos;
      g_pivos[idxBaseAtivo].quantidadeFundos = fundos;
      g_pivos[idxBaseAtivo].tempoInicio = (base.tempoInicio < outra.tempoInicio) ? base.tempoInicio : outra.tempoInicio;
      g_pivos[idxBaseAtivo].tempoMaisRecente = (base.tempoMaisRecente > outra.tempoMaisRecente) ? base.tempoMaisRecente : outra.tempoMaisRecente;
      g_pivos[idxBaseAtivo].ultimoTempoToqueContabilizado =
         (base.ultimoTempoToqueContabilizado > outra.ultimoTempoToqueContabilizado) ?
         base.ultimoTempoToqueContabilizado : outra.ultimoTempoToqueContabilizado;
      g_pivos[idxBaseAtivo].atr = (base.atr + outra.atr) * 0.5;
      g_pivos[idxBaseAtivo].foiMergeada = true;
      g_pivos[idxBaseAtivo].estado = PIVO_ATIVO;

      string idIncorp = (outra.pivoID > 0) ? IntegerToString(outra.pivoID) : "";
      if(StringLen(idIncorp) > 0) {
         if(StringLen(g_pivos[idxBaseAtivo].pivosIncorporados) > 0)
            g_pivos[idxBaseAtivo].pivosIncorporados += "," + idIncorp;
         else
            g_pivos[idxBaseAtivo].pivosIncorporados = idIncorp;
      }

      if(EhZonaProtegidaOrganizacao(idxOutraAtivo)) return false;
      LimparSlotPivo(idxOutraAtivo);
      return true;
   }

   // Consolidação contínua: funde no máximo 1 par por ciclo para evitar "apagões".
   int ConsolidarZonasMuitoProximas(const double distanciaMerge, const double precoAtualRef) {
      if(distanciaMerge <= 0.0) return 0;

      int idxA = -1, idxB = -1;
      double menorDist = DBL_MAX;

      for(int i = 0; i < g_numeroZonas; i++) {
            if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
            for(int j = i + 1; j < g_numeroZonas; j++) {
               if(g_pivos[j].estado == PIVO_REMOVIDO) continue;
               if(g_pivos[i].foiMergeada || g_pivos[j].foiMergeada) continue;

            double supI = MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
            double infI = MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
            double supJ = MathMax(g_pivos[j].precoSuperior, g_pivos[j].precoInferior);
            double infJ = MathMin(g_pivos[j].precoSuperior, g_pivos[j].precoInferior);

            // Distância entre faixas: 0 se sobrepõem/intersectam.
            double d = 0.0;
            if(supI < infJ) d = infJ - supI;
            else if(supJ < infI) d = infI - supJ;
            else d = 0.0;

            double hI = MathAbs(g_pivos[i].precoSuperior - g_pivos[i].precoInferior);
            double hJ = MathAbs(g_pivos[j].precoSuperior - g_pivos[j].precoInferior);
            if(!EstaDistanciaAceitaPorSoma(d, hI, hJ)) continue;

            if(d < distanciaMerge && d < menorDist) {
               menorDist = d;
               idxA = i;
               idxB = j;
            }
         }
      }

      if(idxA < 0 || idxB < 0) return 0;

      // Escolhe manter a zona mais forte; em empate, a mais perto do preço atual.
      double forcaA = g_pivos[idxA].volumeTotal + (double)g_pivos[idxA].quantidadeBarras;
      double forcaB = g_pivos[idxB].volumeTotal + (double)g_pivos[idxB].quantidadeBarras;
      int idxKeep = idxA;
      int idxDrop = idxB;
      if(forcaB > forcaA) {
         idxKeep = idxB;
         idxDrop = idxA;
      } else if(MathAbs(forcaA - forcaB) <= 1e-9) {
         double dA = MathAbs(g_pivos[idxA].preco - precoAtualRef);
         double dB = MathAbs(g_pivos[idxB].preco - precoAtualRef);
         if(dB < dA) {
            idxKeep = idxB;
            idxDrop = idxA;
         }
      }

      if(EhZonaProtegidaOrganizacao(idxDrop)) {
         if(!EhZonaProtegidaOrganizacao(idxKeep)) {
            int troca = idxKeep;
            idxKeep = idxDrop;
            idxDrop = troca;
         }
      }
      if(EhZonaProtegidaOrganizacao(idxDrop)) return 0;

      PivoAtivo keep = g_pivos[idxKeep];
      PivoAtivo drop = g_pivos[idxDrop];

      double wK = MathMax(1.0, keep.volumeTotal);
      double wD = MathMax(1.0, drop.volumeTotal);
      double wT = wK + wD;
      double novoSup = (keep.precoSuperior * wK + drop.precoSuperior * wD) / wT;
      double novoInf = (keep.precoInferior * wK + drop.precoInferior * wD) / wT;
      if(novoSup < novoInf) {
         double t = novoSup;
         novoSup = novoInf;
         novoInf = t;
      }

      int topos = keep.quantidadeTopos + drop.quantidadeTopos;
      int fundos = keep.quantidadeFundos + drop.quantidadeFundos;
      ENUM_LINE_TYPE tipoNovo = keep.tipo;
      if(topos > fundos) tipoNovo = LINE_TOP;
      else if(fundos > topos) tipoNovo = LINE_BOTTOM;
      AplicarLimiteAlturaFaixa(novoSup, novoInf, tipoNovo, (keep.atr + drop.atr) * 0.5);

      g_pivos[idxKeep].precoSuperior = novoSup;
      g_pivos[idxKeep].precoInferior = novoInf;
      g_pivos[idxKeep].tipo = tipoNovo;
      g_pivos[idxKeep].tipoMajoritario = tipoNovo;
      g_pivos[idxKeep].preco = (tipoNovo == LINE_TOP) ? novoSup : novoInf;
      g_pivos[idxKeep].corAtual = ObterCorZona(tipoNovo);
      g_pivos[idxKeep].volumeTotal = keep.volumeTotal + drop.volumeTotal;
      g_pivos[idxKeep].volumeDistribuicao = keep.volumeDistribuicao + drop.volumeDistribuicao;
      double pesoKeepOrig = MathMax(1.0, keep.volumeDistribuicao);
      double pesoDropOrig = MathMax(1.0, drop.volumeDistribuicao);
      double scoreNovoKD = ((keep.scoreOrigem * pesoKeepOrig) + (drop.scoreOrigem * pesoDropOrig)) /
                           (pesoKeepOrig + pesoDropOrig);
      if(scoreNovoKD < 0.0) scoreNovoKD = 0.0;
      if(scoreNovoKD > 1.0) scoreNovoKD = 1.0;
      g_pivos[idxKeep].scoreOrigem = scoreNovoKD;
      g_pivos[idxKeep].espessuraZona = ConverterScoreEmEspessura(scoreNovoKD);
      g_pivos[idxKeep].quantidadeBarras = keep.quantidadeBarras + drop.quantidadeBarras;
      g_pivos[idxKeep].quantidadeTopos = topos;
      g_pivos[idxKeep].quantidadeFundos = fundos;
      g_pivos[idxKeep].tempoInicio = (keep.tempoInicio < drop.tempoInicio) ? keep.tempoInicio : drop.tempoInicio;
      g_pivos[idxKeep].tempoMaisRecente = (keep.tempoMaisRecente > drop.tempoMaisRecente) ? keep.tempoMaisRecente : drop.tempoMaisRecente;
      g_pivos[idxKeep].ultimoTempoToqueContabilizado =
         (keep.ultimoTempoToqueContabilizado > drop.ultimoTempoToqueContabilizado) ?
         keep.ultimoTempoToqueContabilizado : drop.ultimoTempoToqueContabilizado;
      g_pivos[idxKeep].atr = (keep.atr + drop.atr) * 0.5;
      g_pivos[idxKeep].foiMergeada = true;
      g_pivos[idxKeep].estado = PIVO_ATIVO;

      string idIncorp = (drop.pivoID > 0) ? IntegerToString(drop.pivoID) : "";
      if(StringLen(idIncorp) > 0) {
         if(StringLen(g_pivos[idxKeep].pivosIncorporados) > 0)
            g_pivos[idxKeep].pivosIncorporados += "," + idIncorp;
         else
            g_pivos[idxKeep].pivosIncorporados = idIncorp;
      }

      LimparSlotPivo(idxDrop);
      return 1;
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

bool FundirZonaMaisFracaParaAbrirSlot(const ENUM_LINE_TYPE tipoPreferido, const double precoAtualRef) {
   return g_mergeManager.FundirZonaMaisFracaParaAbrirSlot(tipoPreferido, precoAtualRef);
}

bool MergeQuandoCriacaoProxima(const int idxZonaProxima,
                               const ENUM_LINE_TYPE tipoCandidato,
                               const datetime tempoCandidato,
                               const double volumeCandidato,
                               const double supCandidato,
                               const double infCandidato,
                               const bool acumularNoDistribuicao) {
   return g_mergeManager.MergeQuandoCriacaoProxima(idxZonaProxima,
                                                   tipoCandidato,
                                                   tempoCandidato,
                                                   volumeCandidato,
                                                   supCandidato,
                                                   infCandidato,
                                                   acumularNoDistribuicao);
}

bool MesclarZonasPorIndices(const int idxNova, const int idxVizinha, const double precoAtualRef) {
   return g_mergeManager.MesclarZonasPorIndices(idxNova, idxVizinha, precoAtualRef);
}

bool MesclarZonasMesmoBarraMesmoTipo(const int idxBase,
                                     const int idxOutra,
                                     const double barraSuperior,
                                     const double barraInferior,
                                     const bool validarDistanciaSoma) {
   return g_mergeManager.MesclarZonasMesmoBarraMesmoTipo(idxBase,
                                                          idxOutra,
                                                          barraSuperior,
                                                          barraInferior,
                                                          validarDistanciaSoma);
}

int ConsolidarZonasMuitoProximas(const double distanciaMerge, const double precoAtualRef) {
   return g_mergeManager.ConsolidarZonasMuitoProximas(distanciaMerge, precoAtualRef);
}

// </editor-fold>

#endif // __SUPDEMVOL_MERGE_RULES_MQH__
