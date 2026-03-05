#ifndef SUPDEMVOL_MODULE_CRIACAO_GATILHO_V5_MQH
#define SUPDEMVOL_MODULE_CRIACAO_GATILHO_V5_MQH

struct SDV4_CriacaoEventoContext {
   int idx0;
   double volumeAtualBarra;
   double volumeEventoCriacao;
   ENUM_LINE_TYPE tipoAtualBarra;
   bool modoMixSombra;
   double fracaoCompraSombra;
   double fracaoVendaSombra;
   bool gatilho;
};

bool SDV4_CriacaoPrepararEvento(const int rates_total,
                                const datetime &time[],
                                const long &tick_volume[],
                                const double &open[],
                                const double &high[],
                                const double &low[],
                                const double &close[],
                                SDV4_CriacaoEventoContext &evt) {
   if(rates_total < 1) return false;
   evt.idx0 = rates_total - 1;
   if(evt.idx0 < SDV4_RegrasPeriodoMedia()) return false;

   if(g_tempoBarraCriacaoRealtime != time[evt.idx0]) {
      g_tempoBarraCriacaoRealtime = time[evt.idx0];
      g_volumeCriacaoAplicadoBarra = 0.0;
      g_idxZonaDestinoCriacaoRealtime = -1;
   }

   evt.volumeAtualBarra = (double)tick_volume[evt.idx0];
   if(!MathIsValidNumber(evt.volumeAtualBarra) || evt.volumeAtualBarra < 0.0) evt.volumeAtualBarra = 0.0;
   if(evt.volumeAtualBarra + 1e-9 < g_volumeCriacaoAplicadoBarra) {
      g_volumeCriacaoAplicadoBarra = evt.volumeAtualBarra;
   }
   evt.volumeEventoCriacao = evt.volumeAtualBarra - g_volumeCriacaoAplicadoBarra;
   if(evt.volumeEventoCriacao <= 1e-9) return false;

   evt.tipoAtualBarra = DeterminarTipoLinhaPorSombra(evt.idx0, open, high, low, close);
   evt.modoMixSombra = SDV4_RegrasModoConflitoMixSombra();
   evt.fracaoCompraSombra = 0.5;
   evt.fracaoVendaSombra = 0.5;
   SDV4_CalcularFracaoSombraBarra(evt.idx0,
                                  open,
                                  high,
                                  low,
                                  close,
                                  evt.tipoAtualBarra,
                                  evt.fracaoCompraSombra,
                                  evt.fracaoVendaSombra);

   evt.gatilho = (BandaSuperiorBuffer[evt.idx0] > 0.0 &&
                  VolumeBuffer[evt.idx0] > BandaSuperiorBuffer[evt.idx0]);
   return true;
}

#endif
