//+------------------------------------------------------------------+
//|                                    VolumeProfile_HighVolumeOnly.mq5 |
//|                       Volume Profile - 7 Zonas Dinâmicas        |
//+------------------------------------------------------------------+
#property copyright "Volume Profile - 7 Zonas Dinâmicas"
#property version   "14.05"
#property indicator_separate_window
#property indicator_buffers 4
#property indicator_plots   3

// Plot do histograma de volume
#property indicator_label1  "Volume"
#property indicator_type1   DRAW_COLOR_HISTOGRAM
#property indicator_color1  C'46,123,214', C'46,123,214', C'188,36,52'
#property indicator_style1  STYLE_SOLID
#property indicator_width1  3

// Plot da banda superior
#property indicator_label2  "Banda Superior"
#property indicator_type2   DRAW_LINE
#property indicator_color2  C'46,123,214'
#property indicator_style2  STYLE_DASH
#property indicator_width2  2

// Plot da linha zero
#property indicator_label3  "Zero"
#property indicator_type3   DRAW_LINE
#property indicator_color3  C'46,123,214'
#property indicator_style3  STYLE_DOT
#property indicator_width3  1


#include "modules_v6_light_v1/SupDemVol_MainBody_v6.mqh"
