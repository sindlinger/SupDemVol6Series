#ifndef SUPDEMVOL_MODULE_ORGANIZACAO_V5_MQH
#define SUPDEMVOL_MODULE_ORGANIZACAO_V5_MQH

void SDV4_ModuloOrganizacaoProcessar(const int rates_total,
                                     const bool barraNova,
                                     const datetime &time[],
                                     const double &close[],
                                     bool &deveRecalcular,
                                     const bool fasePosPipeline = false,
                                     const bool forcarExecucao = false) {
   if(rates_total < 2) return;
   bool execEmBarraFechada = barraNova;
   bool podeExecutar = (execEmBarraFechada || forcarExecucao);
   if(!podeExecutar) return;
   if(!SDV4_RegrasOrganizacaoEmBarraFechada() && !forcarExecucao) return;

   int idxEvento = execEmBarraFechada ? (rates_total - 2) : (rates_total - 1);
   if(idxEvento < 0 || idxEvento >= rates_total) return;
   datetime tempoEvento = time[idxEvento];
   string origemGate = fasePosPipeline ? "MOD-ORG-POS" : "MOD-ORG-PRE";
   if(forcarExecucao && !execEmBarraFechada) origemGate = "MOD-ORG-DEMANDA-RT";
   if(!SDV4_RegrasPermitirEntradaModulo(SDV4_EXEC_MOD_ORGANIZACAO, tempoEvento, origemGate)) return;
   if(!g_pivosInicializados) return;

   if(OrganizarZonasNoInicioDoDia(close[idxEvento], tempoEvento)) {
      deveRecalcular = true;
      if(SDV4_RegrasLogDetalhadoAtivo()) {
         if(forcarExecucao && !execEmBarraFechada) {
            Print("ORGANIZACAO_DEMANDA_RT: ajuste sob demanda executado na barra aberta.");
         } else if(fasePosPipeline) {
            Print("ORGANIZACAO_POS: ajuste pós-pipeline executado.");
         } else {
            Print("ORGANIZACAO_PRE: ajuste pré-pipeline executado.");
         }
      }
   }
}

#endif
