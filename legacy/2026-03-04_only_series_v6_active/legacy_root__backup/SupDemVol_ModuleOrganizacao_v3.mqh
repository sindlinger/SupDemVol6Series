#ifndef SUPDEMVOL_MODULE_ORGANIZACAO_V3_MQH
#define SUPDEMVOL_MODULE_ORGANIZACAO_V3_MQH

void SDV3_ModuloOrganizacaoProcessar(const int rates_total,
                                     const datetime agora,
                                     const datetime hojeMidnight,
                                     const double &close[],
                                     bool &deveRecalcular) {
   // Organizacao diaria (1x por dia): condensa zonas sobrepostas usando principio de existencia S/R.
   if(g_pivosInicializados && g_ultimoDiaOrganizado != hojeMidnight) {
      if(OrganizarZonasNoInicioDoDia(close[rates_total - 1], agora)) {
         deveRecalcular = true;
         if(InpLogDetalhado) {
            Print("ORGANIZACAO_DIARIA: zonas condensadas no inicio do dia.");
         }
      } else if(InpLogDetalhado && InpOrganizacaoDiariaAtiva) {
         Print("ORGANIZACAO_DIARIA: sem pares sobrepostos para condensar.");
      }
      g_ultimoDiaOrganizado = hojeMidnight;
   }
}

#endif
