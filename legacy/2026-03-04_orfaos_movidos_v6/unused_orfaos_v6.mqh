// Backup de funcoes removidas do caminho ativo do v6.
// Data: 2026-03-04
// Motivo: funcoes sem chamada no grafo atual (orfans), movidas para legacy.

void MarcarMergeProcessadoNoEvento(const datetime tempoEvento) {
   g_tempoEventoMerge = tempoEvento;
   g_mergeExecutadoNoEvento = true;
}

double ObterMargemVerticalProgress() {
   double m = InpMargemVerticalProgress;
   if(m < 0.0) m = 0.0;
   if(m > 0.45) m = 0.45;
   return m;
}

double ObterFallbackAlturaProgress(const double atr) {
   double fatorATR = InpFallbackAlturaProgressATR;
   if(fatorATR < 0.0) fatorATR = 0.0;
   if(fatorATR > 5.0) fatorATR = 5.0;
   int pontos = InpFallbackAlturaProgressPontos;
   if(pontos < 1) pontos = 1;
   if(pontos > 5000) pontos = 5000;
   return MathMax(atr * fatorATR, _Point * (double)pontos);
}

double ObterFaixaEstreitaBucketPreco() {
   int pontos = InpFaixaEstreitaBucketPontos;
   if(pontos < 1) pontos = 1;
   if(pontos > 100000) pontos = 100000;
   return _Point * (double)pontos;
}

int ObterMinBarrasZigZagMedia() {
   int barras = InpMinBarrasZigZagMedia;
   if(barras < 2) barras = 2;
   if(barras > 2000) barras = 2000;
   return barras;
}

double ObterToleranciaDuplicidadePivotPreco() {
   double pontos = InpToleranciaDuplicidadePivotPontos;
   if(pontos < 0.0) pontos = 0.0;
   if(pontos > 100000.0) pontos = 100000.0;
   return _Point * pontos;
}

double DistanciaPrecoParaFaixaZona(const double preco,
                                   const double faixaSuperior,
                                   const double faixaInferior) {
   double sup = MathMax(faixaSuperior, faixaInferior);
   double inf = MathMin(faixaSuperior, faixaInferior);
   if(preco > sup) return (preco - sup);
   if(preco < inf) return (inf - preco);
   return 0.0;
}

void CriarProgressBar(int pivoIndex, datetime tempoInicio, datetime tempoFim, double precoSuperior, double precoInferior) {
   string nomeProgressBar = g_prefixo + "Progress_" + IntegerToString(pivoIndex);
   if(ObjectFind(g_chartID, nomeProgressBar) >= 0) ObjectDelete(g_chartID, nomeProgressBar);
}

color ObterCorPorVolume(ENUM_VOLUME_INTENSIDADE intensidade) {
   switch(intensidade) {
      case VOLUME_EXTREMO: return g_palCorVolExtremo;
      case VOLUME_ALTO:    return g_palCorVolAlto;
      case VOLUME_MEDIO:   return g_palCorVolMedio;
      case VOLUME_BAIXO:
      default:             return g_palCorVolBaixo;
   }
}

double CalcularDistanciaMediaPivosZigZagImportado(const int rates_total,
                                                  const int idxRef,
                                                  const datetime &time[]) {
   if(g_zigzagHandle == INVALID_HANDLE) return 0.0;
   if(rates_total < 3 || idxRef <= 0 || idxRef >= rates_total) return 0.0;

   int maxBarras = InpZigZagMaxBarras;
   int minBarras = ObterMinBarrasZigZagMedia();
   if(maxBarras < minBarras) maxBarras = minBarras;

   datetime diaRef = time[idxRef] - (time[idxRef] % 86400);
   int inicio = idxRef;
   int cont = 0;
   while(inicio > 0 && cont < maxBarras) {
      datetime diaPrev = time[inicio - 1] - (time[inicio - 1] % 86400);
      if(diaPrev != diaRef) break;
      inicio--;
      cont++;
   }

   double pivPrices[];
   int n = 0;
   double ultimoValido = EMPTY_VALUE;

   for(int i = inicio; i <= idxRef; i++) {
      int shift = idxRef - i;
      double zz1[];
      ArrayResize(zz1, 1);
      int copiados = CopyBuffer(g_zigzagHandle, 0, shift, 1, zz1);
      if(copiados != 1) continue;

      double valor = zz1[0];
      if(valor == EMPTY_VALUE || valor == 0.0) continue;

      if(ultimoValido != EMPTY_VALUE &&
         MathAbs(valor - ultimoValido) <= ObterToleranciaDuplicidadePivotPreco())
         continue;

      ArrayResize(pivPrices, n + 1);
      pivPrices[n] = valor;
      n++;
      ultimoValido = valor;
   }

   if(n < 2) return 0.0;

   double somaDist = 0.0;
   int qtdDist = 0;
   for(int k = 1; k < n; k++) {
      somaDist += MathAbs(pivPrices[k] - pivPrices[k - 1]);
      qtdDist++;
   }
   if(qtdDist <= 0) return 0.0;

   double mediaDist = somaDist / qtdDist;
   mediaDist *= InpDistMinFatorZigZag;
   if(mediaDist <= 0.0) return 0.0;
   return mediaDist;
}

void LimparProfile() {
   for(int i = 0; i < 20; i++) {
      string nomePivo = g_prefixo + "Pivo_" + IntegerToString(i);
      string nomeTexto = nomePivo + "_Text";
      string nomeProgress = g_prefixo + "Progress_" + IntegerToString(i);

      if(ObjectFind(g_chartID, nomePivo) >= 0) {
         ObjectDelete(g_chartID, nomePivo);
      }

      if(ObjectFind(g_chartID, nomeTexto) >= 0) {
         ObjectDelete(g_chartID, nomeTexto);
      }

      if(ObjectFind(g_chartID, nomeProgress) >= 0) {
         ObjectDelete(g_chartID, nomeProgress);
      }
   }

   ChartRedraw(g_chartID);
}
