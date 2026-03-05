#ifndef SUPDEMVOL_MODULE_VISUAL_V5_MQH
#define SUPDEMVOL_MODULE_VISUAL_V5_MQH

void DesenharPivos(int rates_total, const datetime &time[]) {
   if(!g_pivosInicializados || rates_total < 1) return;

   // Verificação de segurança para o array time
   if(rates_total > ArraySize(time)) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("⚠️ rates_total maior que array time em DesenharPivos: ", rates_total, " > ", ArraySize(time));
      }
      return;
   }

   datetime tempoBarraZero = time[rates_total - 1];
   datetime tempoFim = tempoBarraZero;
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   if(DeveDesenharZonaAteRecuo()) {
      tempoFim = tempoBarraZero + (datetime)(passo * ObterExtensaoTemporalZona());
   }
   int pivosDesenhados = 0;
   double totalCompraCV = 0.0;
   double totalVendaCV = 0.0;

   // Segurança: remove qualquer progress bar residual de versões anteriores.
   RemoverProgressBarsResiduais();
   // Segurança: remove retângulos/textos órfãos que geram "tiras flutuantes".
   RemoverObjetosOrfaosV4();

   for(int i = 0; i < g_numeroZonas; i++) {
      string nomeObj = g_prefixo + "Pivo_" + IntegerToString(i);
      string nomeTexto = nomeObj + "_Text";
      string nomeProgress = g_prefixo + "Progress_" + IntegerToString(i);

      if(g_pivos[i].estado == PIVO_REMOVIDO) {
         if(ObjectFind(g_chartID, nomeObj) >= 0) ObjectDelete(g_chartID, nomeObj);
         if(ObjectFind(g_chartID, nomeTexto) >= 0) ObjectDelete(g_chartID, nomeTexto);
         if(ObjectFind(g_chartID, nomeProgress) >= 0) ObjectDelete(g_chartID, nomeProgress);
         continue;
      }

      // Regra visual fixa por posição diária: acima = vermelho, abaixo = azul.
      ENUM_LINE_TYPE tipoVisual = ObterTipoVisualZona(i);
      g_pivos[i].corAtual = ObterCorZona(tipoVisual);

      // 1) Zona: criar uma vez, atualizar sempre (sem delete/create por tick)
      if(ObjectFind(g_chartID, nomeObj) < 0) {
         ObjectCreate(g_chartID, nomeObj, OBJ_RECTANGLE, 0,
                      g_pivos[i].tempoInicio, g_pivos[i].precoSuperior,
                      tempoFim, g_pivos[i].precoInferior);
      }
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 0, g_pivos[i].tempoInicio);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 1, tempoFim);
      ObjectSetDouble(g_chartID, nomeObj, OBJPROP_PRICE, 0, g_pivos[i].precoSuperior);
      ObjectSetDouble(g_chartID, nomeObj, OBJPROP_PRICE, 1, g_pivos[i].precoInferior);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_COLOR, g_pivos[i].corAtual);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_STYLE, STYLE_SOLID);
      bool origemVolAlto = (g_pivos[i].volumeDistribuicao > 0.0);
      int larguraZona = CalcularLarguraZonaPorVolume(i);
      g_pivos[i].espessuraZona = larguraZona;
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_WIDTH, larguraZona);
      bool preencherZona = true;
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_FILL, preencherZona);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BACK, true);
      ObjectSetInteger(g_chartID, nomeObj, OBJPROP_SELECTABLE, false);

      if(preencherZona) {
         uint alpha = SDV4_RegrasTransparenciaZonas();
         if(alpha > 255) alpha = 255;
         color corComTransparencia = (color)((g_pivos[i].corAtual & 0x00FFFFFF) | (alpha << 24));
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BGCOLOR, corComTransparencia);
      } else {
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_BGCOLOR, g_pivos[i].corAtual);
      }
      string tipoZona = (tipoVisual == LINE_TOP) ? "Venda" : "Compra";
      string estadoZona = (g_pivos[i].estado == PIVO_CONFIRMADO || g_pivos[i].precoAssentado) ? "Vencida" : "Ativa";
      double volNom = ObterVolumeNominalZona(i);
      double volBuyZona = g_pivos[i].volumeBuy;
      double volSellZona = g_pivos[i].volumeSell;
      if(volBuyZona < 0.0) volBuyZona = 0.0;
      if(volSellZona < 0.0) volSellZona = 0.0;
      double volLados = volBuyZona + volSellZona;
      if(volLados <= 1e-9 && volNom > 0.0) {
         if(tipoVisual == LINE_BOTTOM) volBuyZona = volNom;
         else volSellZona = volNom;
         volLados = volBuyZona + volSellZona;
      }
      double pctBuyZona = (volLados > 0.0) ? ((volBuyZona / volLados) * 100.0) : 0.0;
      double pctSellZona = (volLados > 0.0) ? ((volSellZona / volLados) * 100.0) : 0.0;
      totalCompraCV += volBuyZona;
      totalVendaCV += volSellZona;
      if(SDV4_RegrasLowCostTotalAtivo()) {
         ObjectSetString(g_chartID, nomeObj, OBJPROP_TOOLTIP, "");
      } else {
         ObjectSetString(g_chartID, nomeObj, OBJPROP_TOOLTIP,
                         StringFormat("%s | %s | VolNom: %.0f | Buy: %.0f (%.1f%%) | Sell: %.0f (%.1f%%) | PctZonas: %.1f%% | VolDist: %.0f | Origem: %s",
                                      tipoZona,
                                      estadoZona,
                                      volNom,
                                      volBuyZona,
                                      pctBuyZona,
                                      volSellZona,
                                      pctSellZona,
                                      g_pivos[i].percentualVolumeInterno,
                                      g_pivos[i].volumeDistribuicao,
                                      (origemVolAlto ? "VOL_ALTO" : "NORMAL")));
      }
      pivosDesenhados++;

      // 2) Progress bar removida.
      if(ObjectFind(g_chartID, nomeProgress) >= 0) ObjectDelete(g_chartID, nomeProgress);

      // Percentual simples (sem barra de progresso).
      if(DeveMostrarValoresZona()) {
         double supZona = MathMax(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
         double infZona = MathMin(g_pivos[i].precoSuperior, g_pivos[i].precoInferior);
         double fracaoVertical = ObterPosicaoVerticalTextoZona();
         double precoTexto = infZona + ((supZona - infZona) * fracaoVertical);
         datetime tempoTexto = ObterTempoTextoZona(i, tempoFim, passo);
         string textoPct = StringFormat("%.0f | B%.0f(%.0f%%) S%.0f(%.0f%%) | %.0f%%z",
                                        volNom,
                                        volBuyZona,
                                        pctBuyZona,
                                        volSellZona,
                                        pctSellZona,
                                        g_pivos[i].percentualVolumeInterno);
         if(ObjectFind(g_chartID, nomeTexto) < 0) {
            ObjectCreate(g_chartID, nomeTexto, OBJ_TEXT, 0, tempoTexto, precoTexto);
         }
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_TIME, 0, tempoTexto);
         ObjectSetDouble(g_chartID, nomeTexto, OBJPROP_PRICE, 0, precoTexto);
         ObjectSetString(g_chartID, nomeTexto, OBJPROP_TEXT, textoPct);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_COLOR, clrWhite);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_FONTSIZE, ObterTamanhoFonteTextoZona());
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_ANCHOR, ObterAncoraTextoZona());
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_BACK, false);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_SELECTABLE, false);
         ObjectSetInteger(g_chartID, nomeTexto, OBJPROP_HIDDEN, false);
      } else if(ObjectFind(g_chartID, nomeTexto) >= 0) {
         ObjectDelete(g_chartID, nomeTexto);
      }
   }

   if(SDV4_RegrasLowCostTotalAtivo()) {
      if(g_ultimoCommentInfo != "") {
         Comment("");
         g_ultimoCommentInfo = "";
      }
   } else {
      string info = StringFormat("📊 %d zonas ativas (alvo %d | faixa %d-%d) | Volume Máximo: %.0f",
                                 pivosDesenhados,
                                 g_numeroZonasAlvo,
                                 g_numeroZonasMin,
                                 g_numeroZonasMax,
                                 g_volumeMaximoGlobal);
      if(info != g_ultimoCommentInfo) {
         Comment(info);
         g_ultimoCommentInfo = info;
      }
   }

   string nomePainelLog = g_prefixo + "PainelLogEnriq";
   string logEnriq = ObterTextoLogEnriquecimentoNoGrafico();
   if(StringLen(logEnriq) > 0) {
      if(ObjectFind(g_chartID, nomePainelLog) < 0) {
         ObjectCreate(g_chartID, nomePainelLog, OBJ_LABEL, 0, 0, 0);
      }
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_CORNER, ObterCornerPainelLogEnriquecimento());
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_XDISTANCE, ObterPainelLogOffsetX());
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_YDISTANCE, ObterPainelLogOffsetY());
      ObjectSetString(g_chartID, nomePainelLog, OBJPROP_TEXT, logEnriq);
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_COLOR, ObterPainelLogCorTexto());
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_FONTSIZE, ObterPainelLogFonteTamanho());
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_HIDDEN, true);
      ObjectSetInteger(g_chartID, nomePainelLog, OBJPROP_BACK, false);
   } else if(ObjectFind(g_chartID, nomePainelLog) >= 0) {
      ObjectDelete(g_chartID, nomePainelLog);
   }

   string nomeBalBuy = g_prefixo + "PainelBalCVBuy";
   string nomeBalSell = g_prefixo + "PainelBalCVSell";
   if(DeveExibirPainelBalanceCVNoGrafico()) {
      double totalCV = totalCompraCV + totalVendaCV;
      double pctBuy = (totalCV > 0.0) ? (totalCompraCV / totalCV) * 100.0 : 0.0;
      double pctSell = (totalCV > 0.0) ? (totalVendaCV / totalCV) * 100.0 : 0.0;
      int cornerBal = CORNER_RIGHT_UPPER;
      int xBal = ObterPainelBalanceOffsetX();
      int yBal = ObterPainelBalanceOffsetY();
      int fBal = ObterPainelBalanceFonteTamanho();
      if(ObjectFind(g_chartID, nomeBalBuy) < 0) ObjectCreate(g_chartID, nomeBalBuy, OBJ_LABEL, 0, 0, 0);
      if(ObjectFind(g_chartID, nomeBalSell) < 0) ObjectCreate(g_chartID, nomeBalSell, OBJ_LABEL, 0, 0, 0);

      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_CORNER, cornerBal);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_XDISTANCE, xBal);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_YDISTANCE, yBal);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetString(g_chartID, nomeBalBuy, OBJPROP_TEXT,
                      StringFormat("BUY %.0f | %.0f%%", totalCompraCV, pctBuy));
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_COLOR, g_palCorSuporte);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_FONTSIZE, fBal);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_HIDDEN, true);
      ObjectSetInteger(g_chartID, nomeBalBuy, OBJPROP_BACK, false);

      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_CORNER, cornerBal);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_XDISTANCE, xBal);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_YDISTANCE, yBal + (fBal + 8));
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_ANCHOR, ANCHOR_RIGHT_UPPER);
      ObjectSetString(g_chartID, nomeBalSell, OBJPROP_TEXT,
                      StringFormat("SELL %.0f | %.0f%%", totalVendaCV, pctSell));
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_COLOR, g_palCorResistencia);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_FONTSIZE, fBal);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_HIDDEN, true);
      ObjectSetInteger(g_chartID, nomeBalSell, OBJPROP_BACK, false);
   } else {
      if(ObjectFind(g_chartID, nomeBalBuy) >= 0) ObjectDelete(g_chartID, nomeBalBuy);
      if(ObjectFind(g_chartID, nomeBalSell) >= 0) ObjectDelete(g_chartID, nomeBalSell);
   }
   ChartRedraw(g_chartID);
}

#endif
