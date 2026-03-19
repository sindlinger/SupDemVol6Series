#ifndef SUPDEMVOL_MODULE_BOOK_V1_MQH
#define SUPDEMVOL_MODULE_BOOK_V1_MQH

struct SDV4_BookLevelState {
   bool used;
   int side;            // +1 sell, -1 buy
   long priceTicks;
   double currentVol;
   double accumVol;
   datetime lastSeen;
   datetime lastExec;
};

SDV4_BookLevelState g_bookLevels[];
int g_bookCapacity = 0;
bool g_bookSubscribed = false;
bool g_bookReady = false;
bool g_bookDirty = false;
ulong g_bookLastPollMs = 0;
ulong g_bookLastDrawMs = 0;

long g_bookPrevTicks[];
int g_bookPrevSides[];
double g_bookPrevVols[];
int g_bookPrevCount = 0;

int SDV4_BookMaxMemoria() {
   int v = InpBookMaxNiveisMemoria;
   if(v < 100) v = 100;
   if(v > 5000) v = 5000;
   return v;
}

int SDV4_BookMaxNiveisDesenho() {
   int v = InpBookMaxNiveisDesenho;
   if(v < 1) v = 1;
   if(v > 500) v = 500;
   return v;
}

int SDV4_BookOffsetBarras() {
   int v = InpBookOffsetDireitaBarras;
   if(v < 0) v = 0;
   if(v > 500) v = 500;
   return v;
}

int SDV4_BookLarguraBarras() {
   int v = InpBookLarguraBarras;
   if(v < 1) v = 1;
   if(v > 200) v = 200;
   return v;
}

int SDV4_BookAlturaPontos() {
   int v = InpBookAlturaPontos;
   if(v < 1) v = 1;
   if(v > 500) v = 500;
   return v;
}

int SDV4_BookFonte() {
   int v = InpBookFonte;
   if(v < 6) v = 6;
   if(v > 24) v = 24;
   return v;
}

int SDV4_BookPollMs() {
   int v = InpBookPollMs;
   if(v < 50) v = 50;
   if(v > 5000) v = 5000;
   return v;
}

int SDV4_BookRefreshVisualMs() {
   int v = InpBookRefreshVisualMs;
   if(v < 50) v = 50;
   if(v > 5000) v = 5000;
   return v;
}

double SDV4_BookVolumeMinimo() {
   double v = InpBookVolumeMinimoExibicao;
   if(!MathIsValidNumber(v) || v < 0.0) v = 0.0;
   return v;
}

bool SDV4_BookAtivo() {
   if(SDV4_RegrasLowCostTotalAtivo()) return false;
   if(!InpBookAtivo) return false;
   return true;
}

int SDV4_BookTipoParaSide(const ENUM_BOOK_TYPE tipo) {
   if(tipo == BOOK_TYPE_SELL || tipo == BOOK_TYPE_SELL_MARKET) return +1;
   if(tipo == BOOK_TYPE_BUY || tipo == BOOK_TYPE_BUY_MARKET) return -1;
   return 0;
}

double SDV4_BookVolumeEntrada(const MqlBookInfo &entry) {
   double v = (double)entry.volume;
   if(!MathIsValidNumber(v) || v < 0.0) v = 0.0;
   return v;
}

int SDV4_BookFindLevel(const int side, const long ticks) {
   if(g_bookCapacity <= 0) return -1;
   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) continue;
      if(g_bookLevels[i].side == side && g_bookLevels[i].priceTicks == ticks) return i;
   }
   return -1;
}

int SDV4_BookEscolherSlotEviccao() {
   if(g_bookCapacity <= 0) return -1;

   int livre = -1;
   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) {
         livre = i;
         break;
      }
   }
   if(livre >= 0) return livre;

   int idxZero = -1;
   datetime tZero = 0;
   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) continue;
      bool semMassa = (g_bookLevels[i].currentVol <= 1e-9 && g_bookLevels[i].accumVol <= 1e-9);
      if(!semMassa) continue;
      if(idxZero < 0 || g_bookLevels[i].lastSeen < tZero) {
         idxZero = i;
         tZero = g_bookLevels[i].lastSeen;
      }
   }
   if(idxZero >= 0) return idxZero;

   int idxOld = 0;
   datetime tOld = g_bookLevels[0].lastSeen;
   for(int i = 1; i < g_bookCapacity; i++) {
      if(g_bookLevels[i].lastSeen < tOld) {
         idxOld = i;
         tOld = g_bookLevels[i].lastSeen;
      }
   }
   return idxOld;
}

int SDV4_BookUpsertLevel(const int side, const long ticks) {
   int idx = SDV4_BookFindLevel(side, ticks);
   if(idx >= 0) return idx;

   idx = SDV4_BookEscolherSlotEviccao();
   if(idx < 0 || idx >= g_bookCapacity) return -1;

   g_bookLevels[idx].used = true;
   g_bookLevels[idx].side = side;
   g_bookLevels[idx].priceTicks = ticks;
   g_bookLevels[idx].currentVol = 0.0;
   g_bookLevels[idx].accumVol = 0.0;
   g_bookLevels[idx].lastSeen = TimeCurrent();
   g_bookLevels[idx].lastExec = 0;
   return idx;
}

void SDV4_BookLimparObjetosDOM() {
   string pRect = g_prefixo + "BookRect_";
   string pText = g_prefixo + "BookText_";
   int total = ObjectsTotal(g_chartID);
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, pRect) == 0 || StringFind(nome, pText) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
}

void SDV4_BookResetState() {
   g_bookDirty = false;
   g_bookLastPollMs = 0;
   g_bookLastDrawMs = 0;
   g_bookPrevCount = 0;
   ArrayResize(g_bookPrevTicks, 0);
   ArrayResize(g_bookPrevSides, 0);
   ArrayResize(g_bookPrevVols, 0);

   g_bookCapacity = SDV4_BookMaxMemoria();
   ArrayResize(g_bookLevels, g_bookCapacity);
   for(int i = 0; i < g_bookCapacity; i++) {
      g_bookLevels[i].used = false;
      g_bookLevels[i].side = 0;
      g_bookLevels[i].priceTicks = 0;
      g_bookLevels[i].currentVol = 0.0;
      g_bookLevels[i].accumVol = 0.0;
      g_bookLevels[i].lastSeen = 0;
      g_bookLevels[i].lastExec = 0;
   }

   SDV4_BookLimparObjetosDOM();
}

bool SDV4_BookAtualizarSnapshotInterno(const string origem) {
   if(!g_bookSubscribed) return false;

   MqlBookInfo book[];
   if(!MarketBookGet(_Symbol, book)) {
      if(InpBookLog && SDV4_RegrasLogDetalhadoAtivo()) {
         Print("BOOK: MarketBookGet falhou em ", origem, " err=", GetLastError());
      }
      return false;
   }

   const double point = (_Point > 0.0 ? _Point : 0.00001);
   const int nBook = ArraySize(book);
   long curTicks[];
   int curSides[];
   double curVols[];
   ArrayResize(curTicks, nBook);
   ArrayResize(curSides, nBook);
   ArrayResize(curVols, nBook);
   int curCount = 0;

   for(int i = 0; i < nBook; i++) {
      int side = SDV4_BookTipoParaSide(book[i].type);
      if(side == 0) continue;
      double vol = SDV4_BookVolumeEntrada(book[i]);
      if(vol <= 1e-12) continue;
      long ticks = (long)MathRound(book[i].price / point);
      if(ticks <= 0) continue;

      int idxFound = -1;
      for(int j = 0; j < curCount; j++) {
         if(curSides[j] == side && curTicks[j] == ticks) {
            idxFound = j;
            break;
         }
      }

      if(idxFound < 0) {
         curSides[curCount] = side;
         curTicks[curCount] = ticks;
         curVols[curCount] = vol;
         curCount++;
      } else {
         curVols[idxFound] += vol;
      }
   }

   if(InpBookAcumularReducaoComoExecutado) {
      for(int i = 0; i < g_bookPrevCount; i++) {
         long ticks = g_bookPrevTicks[i];
         int side = g_bookPrevSides[i];
         double prevVol = g_bookPrevVols[i];
         if(prevVol <= 1e-12) continue;

         double curVol = 0.0;
         for(int j = 0; j < curCount; j++) {
            if(curSides[j] == side && curTicks[j] == ticks) {
               curVol = curVols[j];
               break;
            }
         }

         if(prevVol > curVol + 1e-9) {
            double delta = prevVol - curVol;
            int idx = SDV4_BookUpsertLevel(side, ticks);
            if(idx >= 0) {
               g_bookLevels[idx].accumVol += delta;
               g_bookLevels[idx].lastExec = TimeCurrent();
            }
         }
      }
   }

   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) continue;
      g_bookLevels[i].currentVol = 0.0;
   }

   datetime agora = TimeCurrent();
   for(int i = 0; i < curCount; i++) {
      int idx = SDV4_BookUpsertLevel(curSides[i], curTicks[i]);
      if(idx < 0) continue;
      g_bookLevels[idx].currentVol = curVols[i];
      g_bookLevels[idx].lastSeen = agora;
   }

   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) continue;
      if(g_bookLevels[i].currentVol <= 1e-9 && g_bookLevels[i].accumVol <= 1e-9) {
         g_bookLevels[i].used = false;
      }
   }

   ArrayResize(g_bookPrevTicks, curCount);
   ArrayResize(g_bookPrevSides, curCount);
   ArrayResize(g_bookPrevVols, curCount);
   for(int i = 0; i < curCount; i++) {
      g_bookPrevTicks[i] = curTicks[i];
      g_bookPrevSides[i] = curSides[i];
      g_bookPrevVols[i] = curVols[i];
   }
   g_bookPrevCount = curCount;

   g_bookDirty = true;
   return true;
}

void SDV4_BookInit() {
   g_bookReady = false;
   g_bookSubscribed = false;
   SDV4_BookResetState();

   if(!SDV4_BookAtivo()) return;

   if(!MarketBookAdd(_Symbol)) {
      if(InpBookLog || SDV4_RegrasLogDetalhadoAtivo()) {
         Print("BOOK: MarketBookAdd falhou para ", _Symbol, " err=", GetLastError());
      }
      return;
   }

   g_bookSubscribed = true;
   g_bookReady = true;
   SDV4_BookAtualizarSnapshotInterno("init");

   if(InpBookLog && SDV4_RegrasLogDetalhadoAtivo()) {
      Print("BOOK: assinatura ativa para ", _Symbol);
   }
}

void SDV4_BookDeinit() {
   SDV4_BookLimparObjetosDOM();
   if(g_bookSubscribed) {
      MarketBookRelease(_Symbol);
   }
   g_bookSubscribed = false;
   g_bookReady = false;
}

void SDV4_BookProcessarEvento(const string &symbol) {
   if(!g_bookReady || !SDV4_BookAtivo()) return;
   if(symbol != _Symbol) return;
   SDV4_BookAtualizarSnapshotInterno("book_event");
}

void SDV4_BookPolling() {
   if(!g_bookReady || !SDV4_BookAtivo()) return;
   ulong agora = GetTickCount();
   int pollMs = SDV4_BookPollMs();
   if(g_bookLastPollMs > 0 && (agora - g_bookLastPollMs) < (ulong)pollMs) return;
   g_bookLastPollMs = agora;
   SDV4_BookAtualizarSnapshotInterno("poll");
}

bool SDV4_BookSortCandidatosPorVolumeDesc(const int &indicesIn[],
                                          const double &volumesIn[],
                                          const int n,
                                          int &indicesOut[]) {
   ArrayResize(indicesOut, n);
   if(n <= 0) return false;

   for(int i = 0; i < n; i++) indicesOut[i] = indicesIn[i];

   for(int i = 0; i < n - 1; i++) {
      for(int j = i + 1; j < n; j++) {
         int idxI = indicesOut[i];
         int idxJ = indicesOut[j];
         if(volumesIn[idxJ] > volumesIn[idxI]) {
            int t = indicesOut[i];
            indicesOut[i] = indicesOut[j];
            indicesOut[j] = t;
         }
      }
   }
   return true;
}

void SDV4_BookRender(const int rates_total,
                     const datetime &time[],
                     const double &close[]) {
   if(!SDV4_BookAtivo() || !InpBookDesenhar) {
      SDV4_BookLimparObjetosDOM();
      return;
   }
   if(!g_bookReady || rates_total < 1) return;

   ulong agora = GetTickCount();
   int refreshMs = SDV4_BookRefreshVisualMs();
   if(!g_bookDirty && g_bookLastDrawMs > 0 && (agora - g_bookLastDrawMs) < (ulong)refreshMs) return;
   g_bookLastDrawMs = agora;
   g_bookDirty = false;

   SDV4_BookLimparObjetosDOM();

   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;

   datetime baseTime = time[rates_total - 1] + (datetime)(passo * SDV4_BookOffsetBarras());
   datetime endTime = baseTime + (datetime)(passo * SDV4_BookLarguraBarras());
   datetime textTime = endTime + (datetime)passo;

   double chartMin = ChartGetDouble(g_chartID, CHART_PRICE_MIN, 0);
   double chartMax = ChartGetDouble(g_chartID, CHART_PRICE_MAX, 0);
   if(!MathIsValidNumber(chartMin) || !MathIsValidNumber(chartMax) || chartMax <= chartMin) {
      double px = close[rates_total - 1];
      chartMin = px - (200.0 * _Point);
      chartMax = px + (200.0 * _Point);
   }

   int maxLevels = SDV4_BookMaxNiveisDesenho();
   double volMin = SDV4_BookVolumeMinimo();

   int candIdx[];
   double candVol[];
   ArrayResize(candIdx, g_bookCapacity);
   ArrayResize(candVol, g_bookCapacity);
   int nCand = 0;

   for(int i = 0; i < g_bookCapacity; i++) {
      if(!g_bookLevels[i].used) continue;
      double total = g_bookLevels[i].currentVol;
      if(InpBookAcumularReducaoComoExecutado) total += g_bookLevels[i].accumVol;
      if(total <= volMin) continue;
      double price = (double)g_bookLevels[i].priceTicks * _Point;
      if(price < chartMin - (10.0 * _Point) || price > chartMax + (10.0 * _Point)) continue;
      candIdx[nCand] = i;
      candVol[i] = total;
      nCand++;
   }

   int sorted[];
   SDV4_BookSortCandidatosPorVolumeDesc(candIdx, candVol, nCand, sorted);

   int drawCount = 0;
   double halfHeight = (double)SDV4_BookAlturaPontos() * _Point * 0.5;
   int fontSize = SDV4_BookFonte();
   color corSell = C'120,24,35';
   color corBuy = C'18,80,150';

   for(int p = 0; p < nCand && drawCount < maxLevels; p++) {
      int i = sorted[p];
      if(i < 0 || i >= g_bookCapacity) continue;
      if(!g_bookLevels[i].used) continue;

      double price = (double)g_bookLevels[i].priceTicks * _Point;
      double cur = g_bookLevels[i].currentVol;
      double acc = g_bookLevels[i].accumVol;
      double total = cur + (InpBookAcumularReducaoComoExecutado ? acc : 0.0);
      if(total <= volMin) continue;

      string sideTag = (g_bookLevels[i].side > 0) ? "S" : "B";
      string tickTag = StringFormat("%I64d", g_bookLevels[i].priceTicks);
      string nameRect = g_prefixo + "BookRect_" + sideTag + "_" + tickTag;
      string nameText = g_prefixo + "BookText_" + sideTag + "_" + tickTag;
      color cor = (g_bookLevels[i].side > 0) ? corSell : corBuy;

      if(ObjectFind(g_chartID, nameRect) < 0) {
         ObjectCreate(g_chartID, nameRect, OBJ_RECTANGLE, 0, baseTime, price + halfHeight, endTime, price - halfHeight);
      }
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_TIME, 0, baseTime);
      ObjectSetDouble(g_chartID, nameRect, OBJPROP_PRICE, 0, price + halfHeight);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_TIME, 1, endTime);
      ObjectSetDouble(g_chartID, nameRect, OBJPROP_PRICE, 1, price - halfHeight);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_COLOR, cor);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_FILL, true);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_BACK, false);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_WIDTH, 1);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chartID, nameRect, OBJPROP_HIDDEN, true);

      if(ObjectFind(g_chartID, nameText) < 0) {
         ObjectCreate(g_chartID, nameText, OBJ_TEXT, 0, textTime, price);
      }
      ObjectSetInteger(g_chartID, nameText, OBJPROP_TIME, 0, textTime);
      ObjectSetDouble(g_chartID, nameText, OBJPROP_PRICE, 0, price);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_ANCHOR, ANCHOR_LEFT);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_COLOR, clrWhite);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_FONTSIZE, fontSize);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_SELECTABLE, false);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_HIDDEN, true);
      ObjectSetInteger(g_chartID, nameText, OBJPROP_BACK, false);
      ObjectSetString(g_chartID, nameText, OBJPROP_TEXT,
                      StringFormat("%s %.0f", sideTag, total));
      ObjectSetString(g_chartID, nameText, OBJPROP_TOOLTIP,
                      StringFormat("BOOK %s @ %.5f | atual=%.0f | acum=%.0f | total=%.0f",
                                   sideTag, price, cur, acc, total));

      drawCount++;
   }

   if(drawCount > 0) ChartRedraw(g_chartID);
}

void SDV4_BookOnCalculate(const int rates_total,
                          const datetime &time[],
                          const double &close[]) {
   if(!SDV4_BookAtivo()) {
      SDV4_BookLimparObjetosDOM();
      return;
   }
   SDV4_BookPolling();
   SDV4_BookRender(rates_total, time, close);
}

#endif
