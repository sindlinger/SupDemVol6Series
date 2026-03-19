#ifndef SUPDEMVOL_MODULE_LINHAS_REFERENCIA_V5_MQH
#define SUPDEMVOL_MODULE_LINHAS_REFERENCIA_V5_MQH

int ObterPeriodoLinhaMaiorMaxima() {
   int p = SDV4_RegrasPeriodoLinhaMaiorMaxima();
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

int ObterLarguraLinhaMaiorMaxima() {
   int largura = SDV4_RegrasLarguraLinhaMaiorMaxima();
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

double ObterMaiorMaximaUltimosPeriodos(const int rates_total, const double &high[]) {
   if(rates_total <= 0) return 0.0;
   int periodo = ObterPeriodoLinhaMaiorMaxima();
   int inicio = rates_total - periodo;
   if(inicio < 0) inicio = 0;

   double maior = high[inicio];
   for(int i = inicio + 1; i < rates_total; i++) {
      if(high[i] > maior) maior = high[i];
   }
   return maior;
}

void AtualizarLinhaMaiorMaxima(const int rates_total, const double &high[]) {
   string nomeLinha = g_prefixo + "LinhaMaiorMaxima";
   if(!SDV4_RegrasMostrarLinhaMaiorMaxima() || rates_total <= 0) {
      if(ObjectFind(g_chartID, nomeLinha) >= 0) ObjectDelete(g_chartID, nomeLinha);
      return;
   }
   if(rates_total > ArraySize(high)) return;

   double maiorMaxima = ObterMaiorMaximaUltimosPeriodos(rates_total, high);
   if(!MathIsValidNumber(maiorMaxima) || maiorMaxima <= 0.0) return;

   double precoLinha = maiorMaxima;
   double tolerancia = _Point * 0.5;
   if(SDV4_RegrasMaximaReal()) {
      if(!g_maximaRealInicializada) {
         g_precoMaximaReal = maiorMaxima;
         g_maximaRealInicializada = true;
      } else {
         double highAtual = high[rates_total - 1];
         if(highAtual > g_precoMaximaReal + tolerancia) {
            g_precoMaximaReal = maiorMaxima;
         }
      }
      precoLinha = g_precoMaximaReal;
   } else {
      g_precoMaximaReal = maiorMaxima;
      g_maximaRealInicializada = false;
   }

   if(ObjectFind(g_chartID, nomeLinha) < 0) {
      ObjectCreate(g_chartID, nomeLinha, OBJ_HLINE, 0, 0, precoLinha);
   }
   ObjectSetDouble(g_chartID, nomeLinha, OBJPROP_PRICE, precoLinha);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_COLOR, SDV4_RegrasCorLinhaMaiorMaxima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_STYLE, SDV4_RegrasEstiloLinhaMaiorMaxima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_WIDTH, ObterLarguraLinhaMaiorMaxima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_HIDDEN, true);
   ObjectSetString(g_chartID, nomeLinha, OBJPROP_TOOLTIP,
                   StringFormat("Maior máxima (%d): %.5f | Máxima real: %s",
                                ObterPeriodoLinhaMaiorMaxima(),
                                precoLinha,
                                SDV4_RegrasMaximaReal() ? "SIM" : "NAO"));
}

int ObterPeriodoLinhaMenorMinima() {
   int p = SDV4_RegrasPeriodoLinhaMenorMinima();
   if(p < 1) p = 1;
   if(p > 5000) p = 5000;
   return p;
}

int ObterLarguraLinhaMenorMinima() {
   int largura = SDV4_RegrasLarguraLinhaMenorMinima();
   if(largura < 1) largura = 1;
   if(largura > 5) largura = 5;
   return largura;
}

double ObterMenorMinimaUltimosPeriodos(const int rates_total, const double &low[]) {
   if(rates_total <= 0) return 0.0;
   int periodo = ObterPeriodoLinhaMenorMinima();
   int inicio = rates_total - periodo;
   if(inicio < 0) inicio = 0;

   double menor = low[inicio];
   for(int i = inicio + 1; i < rates_total; i++) {
      if(low[i] < menor) menor = low[i];
   }
   return menor;
}

void AtualizarLinhaMenorMinima(const int rates_total, const double &low[]) {
   string nomeLinha = g_prefixo + "LinhaMenorMinima";
   if(!SDV4_RegrasMostrarLinhaMenorMinima() || rates_total <= 0) {
      if(ObjectFind(g_chartID, nomeLinha) >= 0) ObjectDelete(g_chartID, nomeLinha);
      return;
   }
   if(rates_total > ArraySize(low)) return;

   double menorMinima = ObterMenorMinimaUltimosPeriodos(rates_total, low);
   if(!MathIsValidNumber(menorMinima) || menorMinima <= 0.0) return;

   double precoLinha = menorMinima;
   double tolerancia = _Point * 0.5;
   if(SDV4_RegrasMaximaReal()) {
      if(!g_minimaRealInicializada) {
         g_precoMinimaReal = menorMinima;
         g_minimaRealInicializada = true;
      } else {
         double lowAtual = low[rates_total - 1];
         if(lowAtual < g_precoMinimaReal - tolerancia) {
            g_precoMinimaReal = menorMinima;
         }
      }
      precoLinha = g_precoMinimaReal;
   } else {
      g_precoMinimaReal = menorMinima;
      g_minimaRealInicializada = false;
   }

   if(ObjectFind(g_chartID, nomeLinha) < 0) {
      ObjectCreate(g_chartID, nomeLinha, OBJ_HLINE, 0, 0, precoLinha);
   }
   ObjectSetDouble(g_chartID, nomeLinha, OBJPROP_PRICE, precoLinha);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_COLOR, SDV4_RegrasCorLinhaMenorMinima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_STYLE, SDV4_RegrasEstiloLinhaMenorMinima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_WIDTH, ObterLarguraLinhaMenorMinima());
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_BACK, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(g_chartID, nomeLinha, OBJPROP_HIDDEN, true);
   ObjectSetString(g_chartID, nomeLinha, OBJPROP_TOOLTIP,
                   StringFormat("Menor mínima (%d): %.5f | Máxima real: %s",
                                ObterPeriodoLinhaMenorMinima(),
                                precoLinha,
                                SDV4_RegrasMaximaReal() ? "SIM" : "NAO"));
}

#endif
