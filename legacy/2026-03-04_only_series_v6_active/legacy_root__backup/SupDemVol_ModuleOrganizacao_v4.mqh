#ifndef SUPDEMVOL_MODULE_ORGANIZACAO_V3_MQH
#define SUPDEMVOL_MODULE_ORGANIZACAO_V3_MQH

void SDV4_ModuloOrganizacaoProcessar(const int rates_total,
                                     const bool barraNova,
                                     const datetime &time[],
                                     const double &close[],
                                     bool &deveRecalcular) {
   if(!g_pivosInicializados || rates_total < 2) return;
   if(!barraNova) return; // Somente em barra fechada.

   int idxFechada = rates_total - 2;
   datetime tempoFechada = time[idxFechada];
   datetime diaFechada = tempoFechada - (tempoFechada % 86400);

   // Novo padrão pedido: organizar em toda barra fechada.
   if(InpOrganizacaoEmBarraFechada) {
      if(OrganizarZonasNoInicioDoDia(close[idxFechada], tempoFechada)) {
         deveRecalcular = true;
         if(InpLogDetalhado) {
            Print("ORGANIZACAO_FECHADA: zonas condensadas na barra fechada.");
         }
      }
      return;
   }

   // Fallback legado: apenas uma vez no inicio do dia.
   if(InpOrganizacaoDiariaAtiva && g_ultimoDiaOrganizado != diaFechada) {
      if(OrganizarZonasNoInicioDoDia(close[idxFechada], tempoFechada)) {
         deveRecalcular = true;
         if(InpLogDetalhado) {
            Print("ORGANIZACAO_DIARIA: zonas condensadas no inicio do dia.");
         }
      } else if(InpLogDetalhado) {
         Print("ORGANIZACAO_DIARIA: sem pares sobrepostos para condensar.");
      }
      g_ultimoDiaOrganizado = diaFechada;
   }
}

#endif
