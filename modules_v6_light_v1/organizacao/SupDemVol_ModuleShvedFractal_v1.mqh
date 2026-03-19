#ifndef SUPDEMVOL_MODULE_SHVED_FRACTAL_V1_MQH
#define SUPDEMVOL_MODULE_SHVED_FRACTAL_V1_MQH

int SDV4_ShvedCalcularJanelaFractal(const double fator) {
   double f = fator;
   if(!MathIsValidNumber(f) || f < 1.0) f = 1.0;
   if(f > 20.0) f = 20.0;
   int janela = (int)MathFloor((f * 2.0) + MathCeil(f / 2.0));
   if(janela < 2) janela = 2;
   if(janela > 50) janela = 50;
   return janela;
}

bool SDV4_ShvedEhFractalUp(const double &highSeries[],
                           const int bars,
                           const int shift,
                           const int janela) {
   if(shift < janela || shift > (bars - janela - 1)) return false;
   double h0 = highSeries[shift];
   for(int i = 1; i <= janela; i++) {
      if(highSeries[shift + i] > h0) return false;   // lado esquerdo (mais antigo)
      if(highSeries[shift - i] >= h0) return false;  // lado direito (mais recente)
   }
   return true;
}

bool SDV4_ShvedEhFractalDown(const double &lowSeries[],
                             const int bars,
                             const int shift,
                             const int janela) {
   if(shift < janela || shift > (bars - janela - 1)) return false;
   double l0 = lowSeries[shift];
   for(int i = 1; i <= janela; i++) {
      if(lowSeries[shift + i] < l0) return false;   // lado esquerdo (mais antigo)
      if(lowSeries[shift - i] <= l0) return false;  // lado direito (mais recente)
   }
   return true;
}

bool SDV4_ShvedEscolherAncoraMerge(const double precoAlvo,
                                   double &precoAncora,
                                   ENUM_LINE_TYPE &tipoAncora) {
   precoAncora = 0.0;
   tipoAncora = LINE_TOP;

   int lookback = SDV4_RegrasShvedLookbackBarras();

   int wFast = SDV4_ShvedCalcularJanelaFractal(SDV4_RegrasShvedFractalFastFactor());
   int wSlow = SDV4_ShvedCalcularJanelaFractal(SDV4_RegrasShvedFractalSlowFactor());
   int wMax = (wFast > wSlow) ? wFast : wSlow;

   int barsToCopy = lookback + (wMax * 2) + 10;
   if(barsToCopy < 200) barsToCopy = 200;
   if(barsToCopy > 10000) barsToCopy = 10000;

   double highSeries[];
   double lowSeries[];
   int gotH = CopyHigh(_Symbol, _Period, 0, barsToCopy, highSeries);
   int gotL = CopyLow(_Symbol, _Period, 0, barsToCopy, lowSeries);
   if(gotH <= (wMax * 2 + 5) || gotL <= (wMax * 2 + 5)) return false;
   int bars = (gotH < gotL) ? gotH : gotL;

   ArraySetAsSeries(highSeries, true);
   ArraySetAsSeries(lowSeries, true);

   bool achou = false;
   double melhorScore = DBL_MAX;
   double melhorPreco = 0.0;
   ENUM_LINE_TYPE melhorTipo = LINE_TOP;

   int maxShift = bars - wMax - 1;
   if(maxShift > lookback) maxShift = lookback;
   if(maxShift < wMax) return false;

   for(int shift = wMax; shift <= maxShift; shift++) {
      bool fractalFastUp = SDV4_ShvedEhFractalUp(highSeries, bars, shift, wFast);
      bool fractalFastDn = SDV4_ShvedEhFractalDown(lowSeries, bars, shift, wFast);
      bool fractalSlowUp = SDV4_ShvedEhFractalUp(highSeries, bars, shift, wSlow);
      bool fractalSlowDn = SDV4_ShvedEhFractalDown(lowSeries, bars, shift, wSlow);

      if(!fractalFastUp && !fractalFastDn && !fractalSlowUp && !fractalSlowDn) continue;

      if(fractalFastUp || fractalSlowUp) {
         double preco = highSeries[shift];
         double dist = MathAbs(preco - precoAlvo);
         double fator = fractalSlowUp ? 0.85 : 1.00;
         double score = dist * fator;
         if(score < melhorScore) {
            melhorScore = score;
            melhorPreco = preco;
            melhorTipo = LINE_TOP;
            achou = true;
         }
      }

      if(fractalFastDn || fractalSlowDn) {
         double preco = lowSeries[shift];
         double dist = MathAbs(preco - precoAlvo);
         double fator = fractalSlowDn ? 0.85 : 1.00;
         double score = dist * fator;
         if(score < melhorScore) {
            melhorScore = score;
            melhorPreco = preco;
            melhorTipo = LINE_BOTTOM;
            achou = true;
         }
      }
   }

   if(!achou) return false;
   precoAncora = melhorPreco;
   tipoAncora = melhorTipo;
   return true;
}

#endif
