#ifndef SUPDEMVOL_MODULE_ORGANIZACAO_V5_MQH
#define SUPDEMVOL_MODULE_ORGANIZACAO_V5_MQH

void SDV4_ModuloOrganizacaoProcessar(const int rates_total,
                                     const bool barraNova,
                                     const datetime &time[],
                                     const double &close[],
                                     bool &deveRecalcular,
                                     const bool fasePosPipeline = false) {
   if(!g_pivosInicializados || rates_total < 2) return;
   if(!barraNova) return; // Somente em barra fechada.
   if(!InpOrganizacaoEmBarraFechada) return;

   int idxFechada = rates_total - 2;
   datetime tempoFechada = time[idxFechada];

   if(OrganizarZonasNoInicioDoDia(close[idxFechada], tempoFechada)) {
      deveRecalcular = true;
      if(InpLogDetalhado) {
         if(fasePosPipeline) Print("ORGANIZACAO_POS: ajuste pós-pipeline executado.");
         else Print("ORGANIZACAO_PRE: ajuste pré-pipeline executado.");
      }
   }
}

#endif
