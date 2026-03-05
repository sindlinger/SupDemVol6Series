#ifndef SUPDEMVOL_MODULE_RUNTIME_OPS_V5_MQH
#define SUPDEMVOL_MODULE_RUNTIME_OPS_V5_MQH

void ObterLimiaresIntensidadeVolume(double &limiarMedio,
                                    double &limiarAlto,
                                    double &limiarExtremo) {
   limiarMedio = SDV4_RegrasVolumeRatioMedio();
   limiarAlto = SDV4_RegrasVolumeRatioAlto();
   limiarExtremo = SDV4_RegrasVolumeRatioExtremo();

   if(!MathIsValidNumber(limiarMedio) || limiarMedio <= 0.0) limiarMedio = 1.5;
   if(!MathIsValidNumber(limiarAlto) || limiarAlto <= 0.0) limiarAlto = 2.0;
   if(!MathIsValidNumber(limiarExtremo) || limiarExtremo <= 0.0) limiarExtremo = 3.0;

   if(limiarAlto < limiarMedio) limiarAlto = limiarMedio;
   if(limiarExtremo < limiarAlto) limiarExtremo = limiarAlto;
}

ENUM_VOLUME_INTENSIDADE DeterminarIntensidadeVolume(double volume, double volumeMedia) {
   if(!MathIsValidNumber(volumeMedia) || volumeMedia <= 0.0) volumeMedia = 1.0;
   double ratio = volume / volumeMedia;

   double limiarMedio = 1.5;
   double limiarAlto = 2.0;
   double limiarExtremo = 3.0;
   ObterLimiaresIntensidadeVolume(limiarMedio, limiarAlto, limiarExtremo);

   if(ratio >= limiarExtremo) return VOLUME_EXTREMO;
   else if(ratio >= limiarAlto) return VOLUME_ALTO;
   else if(ratio >= limiarMedio) return VOLUME_MEDIO;
   else return VOLUME_BAIXO;                    // Abaixo de 150%
}

//+------------------------------------------------------------------+
//| Verificar se a barra toca/vara a faixa de preço                 |
//+------------------------------------------------------------------+
bool BarraInterseccionaFaixa(double barraHigh, double barraLow, double faixaSuperior, double faixaInferior) {
   double sup = faixaSuperior;
   double inf = faixaInferior;
   if(sup < inf) {
      double t = sup;
      sup = inf;
      inf = t;
   }
   return !(barraHigh < inf || barraLow > sup);
}

bool DeveMostrarValoresZona() {
   // Chave mestre nova para evitar conflito com parâmetro legado.
   return SDV4_RegrasExibirValoresZona();
}

double ObterPosicaoVerticalTextoZona() {
   double p = SDV4_RegrasPosicaoVerticalTextoZona();
   if(!MathIsValidNumber(p)) p = 0.50;
   if(p < 0.0) p = 0.0;
   if(p > 1.0) p = 1.0;
   return p;
}

int ObterDeslocamentoTextoBarras() {
   int d = SDV4_RegrasDeslocamentoTextoBarras();
   if(d < -500) d = -500;
   if(d > 500) d = 500;
   return d;
}

ENUM_ANCHOR_POINT ObterAncoraTextoZona() {
   ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA pos = SDV4_RegrasPosicaoHorizontalTextoZona();
   if(pos == TEXTO_ZONA_ESQUERDA) return ANCHOR_LEFT;
   if(pos == TEXTO_ZONA_CENTRO) return ANCHOR_CENTER;
   return ANCHOR_RIGHT;
}

datetime ObterTempoTextoZona(const int idx, const datetime tempoFim, const int passo) {
   datetime tempoInicio = g_pivos[idx].tempoInicio;
   if(tempoInicio <= 0) tempoInicio = tempoFim;

   datetime tempoBase = tempoFim;
   ENUM_POSICAO_HORIZONTAL_TEXTO_ZONA pos = SDV4_RegrasPosicaoHorizontalTextoZona();
   if(pos == TEXTO_ZONA_ESQUERDA) {
      tempoBase = tempoInicio;
   } else if(pos == TEXTO_ZONA_CENTRO) {
      tempoBase = tempoInicio + (datetime)((tempoFim - tempoInicio) / 2);
   }

   int dBarras = ObterDeslocamentoTextoBarras();
   int passoSeguro = passo;
   if(passoSeguro <= 0) passoSeguro = 60;
   tempoBase += (datetime)(dBarras * passoSeguro);
   return tempoBase;
}

ENUM_LINE_TYPE ObterTipoVisualZona(const int idx) {
   if(idx < 0 || idx >= g_numeroZonas) return LINE_TOP;
   return g_pivos[idx].tipo;
}

void RemoverProgressBarsResiduais() {
   int total = ObjectsTotal(g_chartID);
   string token = g_prefixo + "Progress_";
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, token) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
}

void RemoverObjetosOrfaosV4() {
   int total = ObjectsTotal(g_chartID);
   string tokenPivo = g_prefixo + "Pivo_";
   string nomeLinhaMax = g_prefixo + "LinhaMaiorMaxima";
   string nomeLinhaMin = g_prefixo + "LinhaMenorMinima";
   string nomePainelLog = g_prefixo + "PainelLogEnriq";
   string nomeBalHdr = g_prefixo + "PainelBalCVHdr";
   string nomeBalBuy = g_prefixo + "PainelBalCVBuy";
   string nomeBalSell = g_prefixo + "PainelBalCVSell";
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixo) != 0) continue;

      if(nome == nomeLinhaMax || nome == nomeLinhaMin || nome == nomePainelLog ||
         nome == nomeBalHdr || nome == nomeBalBuy || nome == nomeBalSell) continue;

      if(StringFind(nome, tokenPivo) == 0) {
         string resto = StringSubstr(nome, StringLen(tokenPivo));
         int posUnd = StringFind(resto, "_");
         string numero = (posUnd >= 0) ? StringSubstr(resto, 0, posUnd) : resto;
         if(StringLen(numero) <= 0) {
            ObjectDelete(g_chartID, nome);
            continue;
         }

         int idx = (int)StringToInteger(numero);
         bool invalido = (idx < 0 || idx >= g_numeroZonas);
         if(!invalido && g_pivos[idx].estado == PIVO_REMOVIDO) invalido = true;

         if(posUnd >= 0) {
            string sufixo = StringSubstr(resto, posUnd);
            if(sufixo != "_Text") invalido = true;
         }

         if(invalido) {
            ObjectDelete(g_chartID, nome);
         }
         continue;
      }

      // Remove qualquer objeto legado deste prefixo (ex.: barras antigas).
      ObjectDelete(g_chartID, nome);
   }
}

//+------------------------------------------------------------------+
//| Cor elegante por tipo de zona                                   |
//+------------------------------------------------------------------+
color ObterCorZona(ENUM_LINE_TYPE tipo) {
   if(tipo == LINE_TOP) return g_palCorResistencia;
   return g_palCorSuporte;
}

//+------------------------------------------------------------------+
//| Atualizar coordenadas dos pivôs                                 |
//+------------------------------------------------------------------+
void AtualizarCoordenadasPivos(int rates_total, const datetime &time[]) {
   if(!g_pivosInicializados || rates_total < 1) return;
   
   // Verificação de segurança para o array time
   if(rates_total > ArraySize(time)) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("⚠️ rates_total maior que array time: ", rates_total, " > ", ArraySize(time));
      }
      return;
   }
   
   datetime tempoAtual = time[rates_total - 1];
   int passo = PeriodSeconds();
   if(passo <= 0) passo = 60;
   datetime tempoFim = tempoAtual;
   if(DeveDesenharZonaAteRecuo()) {
      tempoFim = tempoAtual + (datetime)(passo * ObterExtensaoTemporalCoordenada());
   }
   
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      
      string nomeObj = g_prefixo + "Pivo_" + IntegerToString(i);
      
      if(ObjectFind(g_chartID, nomeObj) >= 0) {
         // ATUALIZAR apenas a coordenada temporal final para manter pivô visível
         ObjectSetInteger(g_chartID, nomeObj, OBJPROP_TIME, 1, tempoFim);
      }
   }
}

//+------------------------------------------------------------------+
//| Verificar rompimentos com ANTI PISCA-PISCA                     |
//+------------------------------------------------------------------+
bool VerificarRompimentosEAssentamento(int rates_total, const double &close[]) {
   if(rates_total < 2 || !g_pivosInicializados) return false;
   
   // Verificação de segurança para o array close
   if(rates_total > ArraySize(close)) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("⚠️ rates_total maior que array close: ", rates_total, " > ", ArraySize(close));
      }
      return false;
   }
   
   double precoAtual = close[rates_total - 1];
   bool houveMudanca = false;
   
   for(int i = 0; i < g_numeroZonas; i++) {
      if(g_pivos[i].estado == PIVO_REMOVIDO) continue;
      
      // Verificar se foi rompido
      bool foiRompido = false;
      if(g_pivos[i].tipo == LINE_TOP && precoAtual > g_pivos[i].preco) {
         foiRompido = true;
      } else if(g_pivos[i].tipo == LINE_BOTTOM && precoAtual < g_pivos[i].preco) {
         foiRompido = true;
      }
      
      if(foiRompido && g_pivos[i].estado == PIVO_ATIVO) {
         g_pivos[i].estado = PIVO_ROMPIDO;
         g_pivos[i].barraRompimento = rates_total - 1;
         g_pivos[i].barrasAposRompimento = 0;
         g_pivos[i].precoAssentado = false;
         // Mantém cor estável por tipo da zona (evita troca visual sem critério).
         g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
         houveMudanca = true;
         if(SDV4_RegrasLogDetalhadoAtivo()) {
            Print("🔸 Pivô ", i+1, " rompido: ", g_pivos[i].preco, " - Aguardando assentamento");
         }
      }
      
      // ANTI PISCA-PISCA: Contar barras após rompimento
      if(g_pivos[i].estado == PIVO_ROMPIDO) {
         g_pivos[i].barrasAposRompimento++;
         
         // Verificar se preço está realmente "assentado" na nova região
         bool precoEstabilizado = false;
         if(g_pivos[i].tipo == LINE_TOP) {
            // Para resistência rompida: preço deve permanecer ACIMA
            precoEstabilizado = (precoAtual > g_pivos[i].precoSuperior);
         } else {
            // Para suporte rompido: preço deve permanecer ABAIXO
            precoEstabilizado = (precoAtual < g_pivos[i].precoInferior);
         }
         
         // SÓ MUDA COR após tempo de assentamento E preço estabilizado
         if(g_pivos[i].barrasAposRompimento >= SDV4_RegrasTempoAssentamento() && precoEstabilizado) {
            g_pivos[i].estado = PIVO_CONFIRMADO;
            g_pivos[i].precoAssentado = true;
            
            // Volta para a cor elegante por tipo (suporte/resistência).
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            if(SDV4_RegrasLogDetalhadoAtivo()) {
               Print("✅ Pivô ", i+1, " confirmado após assentamento: ", g_pivos[i].preco);
            }
         } else if(g_pivos[i].barrasAposRompimento >= SDV4_RegrasTempoAssentamento() && !precoEstabilizado) {
            // Falso rompimento, voltar ao normal
            g_pivos[i].estado = PIVO_ATIVO;
            g_pivos[i].barrasAposRompimento = 0;
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            if(SDV4_RegrasLogDetalhadoAtivo()) {
               Print("🔄 Pivô ", i+1, " - falso rompimento, voltando ao normal: ", g_pivos[i].preco);
            }
         }
      }
   }
   return houveMudanca;
}

//+------------------------------------------------------------------+
//| Calcular ATR                                                     |
//+------------------------------------------------------------------+
double CalcularATR(int barra, const double &high[], const double &low[], const double &close[]) {
   int periodo = ObterPeriodoATR();
   int arraySize = ArraySize(high);
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("⚠️ Índice inválido em CalcularATR: ", barra, " / ", arraySize);
      }
      return ObterAtrFallbackEmErro(); // Valor padrão para evitar divisão por zero
   }
   
   if(barra < periodo) {
      return (high[barra] - low[barra]); // ATR simples se não há histórico suficiente
   }
   
   double soma = 0;
   for(int i = 0; i < periodo; i++) {
      int index = barra - i;
      
      // Verificação de limite para cada acesso ao array
      if(index < 0 || index >= arraySize) continue;
      
      double tr1 = high[index] - low[index];
      double tr2 = (index > 0 && index-1 >= 0) ? MathAbs(high[index] - close[index - 1]) : 0;
      double tr3 = (index > 0 && index-1 >= 0) ? MathAbs(low[index] - close[index - 1]) : 0;
      double tr = MathMax(tr1, MathMax(tr2, tr3));
      soma += tr;
   }
   
   return soma / periodo;
}

ENUM_LINE_TYPE DeterminarTipoPorPosicaoNoDia(const int barra, const double &high[], const double &low[]) {
   int arraySize = ArraySize(high);
   if(barra < 0 || barra >= arraySize) return LINE_TOP;

   double topoDia = g_extremoMaxDiaAtual;
   double fundoDia = g_extremoMinDiaAtual;
   if(!(topoDia > fundoDia)) {
      topoDia = g_extremoMaxDiaAnterior;
      fundoDia = g_extremoMinDiaAnterior;
   }

   double meioBarra = (high[barra] + low[barra]) * 0.5;
   if(topoDia > fundoDia) {
      double pos = (meioBarra - fundoDia) / (topoDia - fundoDia);
      if(pos <= 0.45) return LINE_BOTTOM;
      if(pos >= 0.55) return LINE_TOP;
   }

   // Desempate no miolo da faixa diária.
   double sombraSup = high[barra] - meioBarra;
   double sombraInf = meioBarra - low[barra];
   if(sombraInf > sombraSup) return LINE_BOTTOM;
   return LINE_TOP;
}

//+------------------------------------------------------------------+
//| Determinar tipo de linha                                        |
//+------------------------------------------------------------------+
ENUM_LINE_TYPE DeterminarTipoLinha(int barra, const double &high[], const double &low[]) {
   int arraySize = ArraySize(high);
   int vizinhanca = ObterVizinhancaPivot();
   
   // Verificações de segurança
   if(barra < 0 || barra >= arraySize) {
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         Print("⚠️ Índice inválido em DeterminarTipoLinha: ", barra, " / ", arraySize);
      }
      return LINE_TOP; // Default seguro
   }
   
   if(barra < vizinhanca || barra >= arraySize - vizinhanca)
      return DeterminarTipoPorPosicaoNoDia(barra, high, low);
   
   // Verificar se é topo
   bool ehTopo = true;
   for(int j = 1; j <= vizinhanca; j++) {
      int indexAntes = barra - j;
      int indexDepois = barra + j;
      
      // Verificar limites antes de acessar
      if(indexAntes < 0 || indexAntes >= arraySize || 
         indexDepois < 0 || indexDepois >= arraySize) {
         ehTopo = false;
         break;
      }
      
      if(high[barra] <= high[indexAntes] || high[barra] <= high[indexDepois]) {
         ehTopo = false;
         break;
      }
   }
   
   if(ehTopo) return LINE_TOP;
   
   // Verificar se é fundo
   bool ehFundo = true;
   for(int j = 1; j <= vizinhanca; j++) {
      int indexAntes = barra - j;
      int indexDepois = barra + j;
      
      // Verificar limites antes de acessar
      if(indexAntes < 0 || indexAntes >= arraySize || 
         indexDepois < 0 || indexDepois >= arraySize) {
         ehFundo = false;
         break;
      }
      
      if(low[barra] >= low[indexAntes] || low[barra] >= low[indexDepois]) {
         ehFundo = false;
         break;
      }
   }
   
   if(ehFundo) return LINE_BOTTOM;
   
   // Se não é nem topo nem fundo claro, usar posição relativa no dia.
   return DeterminarTipoPorPosicaoNoDia(barra, high, low);
}

//+------------------------------------------------------------------+
//| Limpar todos os objetos                                         |
//+------------------------------------------------------------------+
void LimparObjetos() {
   int total = ObjectsTotal(g_chartID);
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixo) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
   
   ChartRedraw(g_chartID);
}

#endif
