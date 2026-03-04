#ifndef SUPDEMVOL_MODULE_RUNTIME_OPS_V5_MQH
#define SUPDEMVOL_MODULE_RUNTIME_OPS_V5_MQH

void ObterLimiaresIntensidadeVolume(double &limiarMedio,
                                    double &limiarAlto,
                                    double &limiarExtremo) {
   limiarMedio = InpVolumeRatioMedio;
   limiarAlto = InpVolumeRatioAlto;
   limiarExtremo = InpVolumeRatioExtremo;

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
   return InpExibirValoresZona;
}

double ObterPosicaoVerticalTextoZona() {
   double p = InpPosicaoVerticalTextoZona;
   if(!MathIsValidNumber(p)) p = 0.50;
   if(p < 0.0) p = 0.0;
   if(p > 1.0) p = 1.0;
   return p;
}

int ObterDeslocamentoTextoBarras() {
   int d = InpDeslocamentoTextoBarras;
   if(d < -500) d = -500;
   if(d > 500) d = 500;
   return d;
}

ENUM_ANCHOR_POINT ObterAncoraTextoZona() {
   if(InpPosicaoHorizontalTextoZona == TEXTO_ZONA_ESQUERDA) return ANCHOR_LEFT;
   if(InpPosicaoHorizontalTextoZona == TEXTO_ZONA_CENTRO) return ANCHOR_CENTER;
   return ANCHOR_RIGHT;
}

datetime ObterTempoTextoZona(const int idx, const datetime tempoFim, const int passo) {
   datetime tempoInicio = g_pivos[idx].tempoInicio;
   if(tempoInicio <= 0) tempoInicio = tempoFim;

   datetime tempoBase = tempoFim;
   if(InpPosicaoHorizontalTextoZona == TEXTO_ZONA_ESQUERDA) {
      tempoBase = tempoInicio;
   } else if(InpPosicaoHorizontalTextoZona == TEXTO_ZONA_CENTRO) {
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

//+------------------------------------------------------------------+
//| Criar progress bar dentro da zona                               |
//+------------------------------------------------------------------+
void CriarProgressBar(int pivoIndex, datetime tempoInicio, datetime tempoFim, double precoSuperior, double precoInferior) {
   string nomeProgressBar = g_prefixo + "Progress_" + IntegerToString(pivoIndex);
   // Progress bar removida por pedido do usuário.
   if(ObjectFind(g_chartID, nomeProgressBar) >= 0) ObjectDelete(g_chartID, nomeProgressBar);
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

void AtualizarObjetosHibernadosAteRecuo(const int rates_total, const datetime &time[]) {
   // Hibernacao desativada: remove qualquer objeto legado desse fluxo.
   int total = ObjectsTotal(g_chartID);
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixoHibernacao) != 0) continue;
      ObjectDelete(g_chartID, nome);
   }
}

//+------------------------------------------------------------------+
//| Obter cor baseada na intensidade do volume                     |
//+------------------------------------------------------------------+
color ObterCorPorVolume(ENUM_VOLUME_INTENSIDADE intensidade) {
   switch(intensidade) {
      case VOLUME_EXTREMO: return g_palCorVolExtremo;  // Volume extremo
      case VOLUME_ALTO:    return g_palCorVolAlto;     // Volume alto
      case VOLUME_MEDIO:   return g_palCorVolMedio;    // Volume médio
      case VOLUME_BAIXO:   
      default:             return g_palCorVolBaixo;    // Volume baixo
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
      Print("⚠️ rates_total maior que array time: ", rates_total, " > ", ArraySize(time));
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
      Print("⚠️ rates_total maior que array close: ", rates_total, " > ", ArraySize(close));
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
         Print("🔸 Pivô ", i+1, " rompido: ", g_pivos[i].preco, " - Aguardando assentamento");
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
         if(g_pivos[i].barrasAposRompimento >= InpTempoAssentamento && precoEstabilizado) {
            g_pivos[i].estado = PIVO_CONFIRMADO;
            g_pivos[i].precoAssentado = true;
            
            // Volta para a cor elegante por tipo (suporte/resistência).
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            Print("✅ Pivô ", i+1, " confirmado após assentamento: ", g_pivos[i].preco);
         } else if(g_pivos[i].barrasAposRompimento >= InpTempoAssentamento && !precoEstabilizado) {
            // Falso rompimento, voltar ao normal
            g_pivos[i].estado = PIVO_ATIVO;
            g_pivos[i].barrasAposRompimento = 0;
            g_pivos[i].corAtual = ObterCorZona(g_pivos[i].tipo);
            houveMudanca = true;
            
            Print("🔄 Pivô ", i+1, " - falso rompimento, voltando ao normal: ", g_pivos[i].preco);
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
      Print("⚠️ Índice inválido em CalcularATR: ", barra, " / ", arraySize);
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

//+------------------------------------------------------------------+
//| Distância média usando pivôs do ZigZag importado                |
//+------------------------------------------------------------------+
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

      // Evita duplicidade quando o mesmo pivô reaparece no mesmo nível.
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
      Print("⚠️ Índice inválido em DeterminarTipoLinha: ", barra, " / ", arraySize);
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

//+------------------------------------------------------------------+
//| Limpar todos os objetos                                         |
//+------------------------------------------------------------------+
void LimparObjetos() {
   int total = ObjectsTotal(g_chartID);
   for(int i = total - 1; i >= 0; i--) {
      string nome = ObjectName(g_chartID, i);
      if(StringFind(nome, g_prefixo) == 0 || StringFind(nome, g_prefixoHibernacao) == 0) {
         ObjectDelete(g_chartID, nome);
      }
   }
   
   ChartRedraw(g_chartID);
}

#endif
