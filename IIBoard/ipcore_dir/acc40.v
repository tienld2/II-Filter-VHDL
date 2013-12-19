////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 1995-2012 Xilinx, Inc.  All rights reserved.
////////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /    Vendor: Xilinx
// \   \   \/     Version: P.58f
//  \   \         Application: netgen
//  /   /         Filename: acc40.v
// /___/   /\     Timestamp: Mon Oct 28 13:08:55 2013
// \   \  /  \ 
//  \___\/\___\
//             
// Command	: -w -sim -ofmt verilog /home/nick/IIBoard/ipcore_dir/tmp/_cg/acc40.ngc /home/nick/IIBoard/ipcore_dir/tmp/_cg/acc40.v 
// Device	: 6vsx315tff1156-1
// Input file	: /home/nick/IIBoard/ipcore_dir/tmp/_cg/acc40.ngc
// Output file	: /home/nick/IIBoard/ipcore_dir/tmp/_cg/acc40.v
// # of Modules	: 1
// Design Name	: acc40
// Xilinx        : /opt/Xilinx/14.5/ISE_DS/ISE/
//             
// Purpose:    
//     This verilog netlist is a verification model and uses simulation 
//     primitives which may not represent the true implementation of the 
//     device, however the netlist is functionally correct and should not 
//     be modified. This file cannot be synthesized and should only be used 
//     with supported simulation tools.
//             
// Reference:  
//     Command Line Tools User Guide, Chapter 23 and Synthesis and Simulation Design Guide, Chapter 6
//             
////////////////////////////////////////////////////////////////////////////////

`timescale 1 ns/1 ps

module acc40 (
  clk, sclr, b, q
)/* synthesis syn_black_box syn_noprune=1 */;
  input clk;
  input sclr;
  input [35 : 0] b;
  output [49 : 0] q;
  
  // synthesis translate_off
  
  wire \blk00000001/sig000000ee ;
  wire \blk00000001/sig000000ed ;
  wire \blk00000001/sig000000ec ;
  wire \blk00000001/sig000000eb ;
  wire \blk00000001/sig000000ea ;
  wire \blk00000001/sig000000e9 ;
  wire \blk00000001/sig000000e8 ;
  wire \blk00000001/sig000000e7 ;
  wire \blk00000001/sig000000e6 ;
  wire \blk00000001/sig000000e5 ;
  wire \blk00000001/sig000000e4 ;
  wire \blk00000001/sig000000e3 ;
  wire \blk00000001/sig000000e2 ;
  wire \blk00000001/sig000000e1 ;
  wire \blk00000001/sig000000e0 ;
  wire \blk00000001/sig000000df ;
  wire \blk00000001/sig000000de ;
  wire \blk00000001/sig000000dd ;
  wire \blk00000001/sig000000dc ;
  wire \blk00000001/sig000000db ;
  wire \blk00000001/sig000000da ;
  wire \blk00000001/sig000000d9 ;
  wire \blk00000001/sig000000d8 ;
  wire \blk00000001/sig000000d7 ;
  wire \blk00000001/sig000000d6 ;
  wire \blk00000001/sig000000d5 ;
  wire \blk00000001/sig000000d4 ;
  wire \blk00000001/sig000000d3 ;
  wire \blk00000001/sig000000d2 ;
  wire \blk00000001/sig000000d1 ;
  wire \blk00000001/sig000000d0 ;
  wire \blk00000001/sig000000cf ;
  wire \blk00000001/sig000000ce ;
  wire \blk00000001/sig000000cd ;
  wire \blk00000001/sig000000cc ;
  wire \blk00000001/sig000000cb ;
  wire \blk00000001/sig000000ca ;
  wire \blk00000001/sig000000c9 ;
  wire \blk00000001/sig000000c8 ;
  wire \blk00000001/sig000000c7 ;
  wire \blk00000001/sig000000c6 ;
  wire \blk00000001/sig000000c5 ;
  wire \blk00000001/sig000000c4 ;
  wire \blk00000001/sig000000c3 ;
  wire \blk00000001/sig000000c2 ;
  wire \blk00000001/sig000000c1 ;
  wire \blk00000001/sig000000c0 ;
  wire \blk00000001/sig000000bf ;
  wire \blk00000001/sig000000be ;
  wire \blk00000001/sig000000bd ;
  wire \blk00000001/sig000000bc ;
  wire \blk00000001/sig000000bb ;
  wire \blk00000001/sig000000ba ;
  wire \blk00000001/sig000000b9 ;
  wire \blk00000001/sig000000b8 ;
  wire \blk00000001/sig000000b7 ;
  wire \blk00000001/sig000000b6 ;
  wire \blk00000001/sig000000b5 ;
  wire \blk00000001/sig000000b4 ;
  wire \blk00000001/sig000000b3 ;
  wire \blk00000001/sig000000b2 ;
  wire \blk00000001/sig000000b1 ;
  wire \blk00000001/sig000000b0 ;
  wire \blk00000001/sig000000af ;
  wire \blk00000001/sig000000ae ;
  wire \blk00000001/sig000000ad ;
  wire \blk00000001/sig000000ac ;
  wire \blk00000001/sig000000ab ;
  wire \blk00000001/sig000000aa ;
  wire \blk00000001/sig000000a9 ;
  wire \blk00000001/sig000000a8 ;
  wire \blk00000001/sig000000a7 ;
  wire \blk00000001/sig000000a6 ;
  wire \blk00000001/sig000000a5 ;
  wire \blk00000001/sig000000a4 ;
  wire \blk00000001/sig000000a3 ;
  wire \blk00000001/sig000000a2 ;
  wire \blk00000001/sig000000a1 ;
  wire \blk00000001/sig000000a0 ;
  wire \blk00000001/sig0000009f ;
  wire \blk00000001/sig0000009e ;
  wire \blk00000001/sig0000009d ;
  wire \blk00000001/sig0000009c ;
  wire \blk00000001/sig0000009b ;
  wire \blk00000001/sig0000009a ;
  wire \blk00000001/sig00000099 ;
  wire \blk00000001/sig00000098 ;
  wire \blk00000001/sig00000097 ;
  wire \blk00000001/sig00000096 ;
  wire \blk00000001/sig00000095 ;
  wire \blk00000001/sig00000094 ;
  wire \blk00000001/sig00000093 ;
  wire \blk00000001/sig00000092 ;
  wire \blk00000001/sig00000091 ;
  wire \blk00000001/sig00000090 ;
  wire \blk00000001/sig0000008f ;
  wire \blk00000001/sig0000008e ;
  wire \blk00000001/sig0000008d ;
  wire \blk00000001/sig0000008c ;
  wire \blk00000001/sig0000008b ;
  wire \blk00000001/sig0000008a ;
  wire \blk00000001/sig00000089 ;
  wire \blk00000001/sig00000088 ;
  wire \blk00000001/sig00000087 ;
  wire \blk00000001/sig00000086 ;
  wire \blk00000001/sig00000085 ;
  wire \blk00000001/sig00000084 ;
  wire \blk00000001/sig00000083 ;
  wire \blk00000001/sig00000082 ;
  wire \blk00000001/sig00000081 ;
  wire \blk00000001/sig00000080 ;
  wire \blk00000001/sig0000007f ;
  wire \blk00000001/sig0000007e ;
  wire \blk00000001/sig0000007d ;
  wire \blk00000001/sig0000007c ;
  wire \blk00000001/sig0000007b ;
  wire \blk00000001/sig0000007a ;
  wire \blk00000001/sig00000079 ;
  wire \blk00000001/sig00000078 ;
  wire \blk00000001/sig00000077 ;
  wire \blk00000001/sig00000076 ;
  wire \blk00000001/sig00000075 ;
  wire \blk00000001/sig00000074 ;
  wire \blk00000001/sig00000073 ;
  wire \blk00000001/sig00000072 ;
  wire \blk00000001/sig00000071 ;
  wire \blk00000001/sig00000070 ;
  wire \blk00000001/sig0000006f ;
  wire \blk00000001/sig0000006e ;
  wire \blk00000001/sig0000006d ;
  wire \blk00000001/sig0000006c ;
  wire \blk00000001/sig0000006b ;
  wire \blk00000001/sig0000006a ;
  wire \blk00000001/sig00000069 ;
  wire \blk00000001/sig00000068 ;
  wire \blk00000001/sig00000067 ;
  wire \blk00000001/sig00000066 ;
  wire \blk00000001/sig00000065 ;
  wire \blk00000001/sig00000064 ;
  wire \blk00000001/sig00000063 ;
  wire \blk00000001/sig00000062 ;
  wire \blk00000001/sig00000061 ;
  wire \blk00000001/sig00000060 ;
  wire \blk00000001/sig0000005f ;
  wire \blk00000001/sig0000005e ;
  wire \blk00000001/sig0000005d ;
  wire \blk00000001/sig0000005c ;
  wire \blk00000001/sig0000005b ;
  wire \blk00000001/sig0000005a ;
  wire \blk00000001/sig00000059 ;
  wire [49 : 0] NlwRenamedSig_OI_q;
  assign
    q[49] = NlwRenamedSig_OI_q[49],
    q[48] = NlwRenamedSig_OI_q[48],
    q[47] = NlwRenamedSig_OI_q[47],
    q[46] = NlwRenamedSig_OI_q[46],
    q[45] = NlwRenamedSig_OI_q[45],
    q[44] = NlwRenamedSig_OI_q[44],
    q[43] = NlwRenamedSig_OI_q[43],
    q[42] = NlwRenamedSig_OI_q[42],
    q[41] = NlwRenamedSig_OI_q[41],
    q[40] = NlwRenamedSig_OI_q[40],
    q[39] = NlwRenamedSig_OI_q[39],
    q[38] = NlwRenamedSig_OI_q[38],
    q[37] = NlwRenamedSig_OI_q[37],
    q[36] = NlwRenamedSig_OI_q[36],
    q[35] = NlwRenamedSig_OI_q[35],
    q[34] = NlwRenamedSig_OI_q[34],
    q[33] = NlwRenamedSig_OI_q[33],
    q[32] = NlwRenamedSig_OI_q[32],
    q[31] = NlwRenamedSig_OI_q[31],
    q[30] = NlwRenamedSig_OI_q[30],
    q[29] = NlwRenamedSig_OI_q[29],
    q[28] = NlwRenamedSig_OI_q[28],
    q[27] = NlwRenamedSig_OI_q[27],
    q[26] = NlwRenamedSig_OI_q[26],
    q[25] = NlwRenamedSig_OI_q[25],
    q[24] = NlwRenamedSig_OI_q[24],
    q[23] = NlwRenamedSig_OI_q[23],
    q[22] = NlwRenamedSig_OI_q[22],
    q[21] = NlwRenamedSig_OI_q[21],
    q[20] = NlwRenamedSig_OI_q[20],
    q[19] = NlwRenamedSig_OI_q[19],
    q[18] = NlwRenamedSig_OI_q[18],
    q[17] = NlwRenamedSig_OI_q[17],
    q[16] = NlwRenamedSig_OI_q[16],
    q[15] = NlwRenamedSig_OI_q[15],
    q[14] = NlwRenamedSig_OI_q[14],
    q[13] = NlwRenamedSig_OI_q[13],
    q[12] = NlwRenamedSig_OI_q[12],
    q[11] = NlwRenamedSig_OI_q[11],
    q[10] = NlwRenamedSig_OI_q[10],
    q[9] = NlwRenamedSig_OI_q[9],
    q[8] = NlwRenamedSig_OI_q[8],
    q[7] = NlwRenamedSig_OI_q[7],
    q[6] = NlwRenamedSig_OI_q[6],
    q[5] = NlwRenamedSig_OI_q[5],
    q[4] = NlwRenamedSig_OI_q[4],
    q[3] = NlwRenamedSig_OI_q[3],
    q[2] = NlwRenamedSig_OI_q[2],
    q[1] = NlwRenamedSig_OI_q[1],
    q[0] = NlwRenamedSig_OI_q[0];
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c9  (
    .I0(NlwRenamedSig_OI_q[49]),
    .I1(b[35]),
    .O(\blk00000001/sig000000bc )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c8  (
    .I0(NlwRenamedSig_OI_q[48]),
    .I1(b[35]),
    .O(\blk00000001/sig0000008c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c7  (
    .I0(NlwRenamedSig_OI_q[47]),
    .I1(b[35]),
    .O(\blk00000001/sig0000008d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c6  (
    .I0(NlwRenamedSig_OI_q[46]),
    .I1(b[35]),
    .O(\blk00000001/sig0000008e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c5  (
    .I0(NlwRenamedSig_OI_q[45]),
    .I1(b[35]),
    .O(\blk00000001/sig0000008f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c4  (
    .I0(NlwRenamedSig_OI_q[44]),
    .I1(b[35]),
    .O(\blk00000001/sig00000090 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c3  (
    .I0(NlwRenamedSig_OI_q[43]),
    .I1(b[35]),
    .O(\blk00000001/sig00000091 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c2  (
    .I0(NlwRenamedSig_OI_q[42]),
    .I1(b[35]),
    .O(\blk00000001/sig00000092 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c1  (
    .I0(NlwRenamedSig_OI_q[41]),
    .I1(b[35]),
    .O(\blk00000001/sig00000093 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000c0  (
    .I0(NlwRenamedSig_OI_q[40]),
    .I1(b[35]),
    .O(\blk00000001/sig00000094 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bf  (
    .I0(NlwRenamedSig_OI_q[39]),
    .I1(b[35]),
    .O(\blk00000001/sig00000095 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000be  (
    .I0(NlwRenamedSig_OI_q[38]),
    .I1(b[35]),
    .O(\blk00000001/sig00000096 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bd  (
    .I0(NlwRenamedSig_OI_q[37]),
    .I1(b[35]),
    .O(\blk00000001/sig00000097 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bc  (
    .I0(NlwRenamedSig_OI_q[36]),
    .I1(b[35]),
    .O(\blk00000001/sig00000098 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000bb  (
    .I0(NlwRenamedSig_OI_q[35]),
    .I1(b[35]),
    .O(\blk00000001/sig00000099 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ba  (
    .I0(NlwRenamedSig_OI_q[34]),
    .I1(b[34]),
    .O(\blk00000001/sig0000009a )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b9  (
    .I0(NlwRenamedSig_OI_q[33]),
    .I1(b[33]),
    .O(\blk00000001/sig0000009b )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b8  (
    .I0(NlwRenamedSig_OI_q[32]),
    .I1(b[32]),
    .O(\blk00000001/sig0000009c )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b7  (
    .I0(NlwRenamedSig_OI_q[31]),
    .I1(b[31]),
    .O(\blk00000001/sig0000009d )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b6  (
    .I0(NlwRenamedSig_OI_q[30]),
    .I1(b[30]),
    .O(\blk00000001/sig0000009e )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b5  (
    .I0(NlwRenamedSig_OI_q[29]),
    .I1(b[29]),
    .O(\blk00000001/sig0000009f )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b4  (
    .I0(NlwRenamedSig_OI_q[28]),
    .I1(b[28]),
    .O(\blk00000001/sig000000a0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b3  (
    .I0(b[27]),
    .I1(NlwRenamedSig_OI_q[27]),
    .O(\blk00000001/sig000000a1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b2  (
    .I0(b[26]),
    .I1(NlwRenamedSig_OI_q[26]),
    .O(\blk00000001/sig000000a2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b1  (
    .I0(b[25]),
    .I1(NlwRenamedSig_OI_q[25]),
    .O(\blk00000001/sig000000a3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000b0  (
    .I0(b[24]),
    .I1(NlwRenamedSig_OI_q[24]),
    .O(\blk00000001/sig000000a4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000af  (
    .I0(b[23]),
    .I1(NlwRenamedSig_OI_q[23]),
    .O(\blk00000001/sig000000a5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ae  (
    .I0(b[22]),
    .I1(NlwRenamedSig_OI_q[22]),
    .O(\blk00000001/sig000000a6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ad  (
    .I0(b[21]),
    .I1(NlwRenamedSig_OI_q[21]),
    .O(\blk00000001/sig000000a7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ac  (
    .I0(b[20]),
    .I1(NlwRenamedSig_OI_q[20]),
    .O(\blk00000001/sig000000a8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000ab  (
    .I0(b[19]),
    .I1(NlwRenamedSig_OI_q[19]),
    .O(\blk00000001/sig000000a9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000aa  (
    .I0(b[18]),
    .I1(NlwRenamedSig_OI_q[18]),
    .O(\blk00000001/sig000000aa )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a9  (
    .I0(b[17]),
    .I1(NlwRenamedSig_OI_q[17]),
    .O(\blk00000001/sig000000ab )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a8  (
    .I0(b[16]),
    .I1(NlwRenamedSig_OI_q[16]),
    .O(\blk00000001/sig000000ac )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a7  (
    .I0(b[15]),
    .I1(NlwRenamedSig_OI_q[15]),
    .O(\blk00000001/sig000000ad )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a6  (
    .I0(b[14]),
    .I1(NlwRenamedSig_OI_q[14]),
    .O(\blk00000001/sig000000ae )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a5  (
    .I0(b[13]),
    .I1(NlwRenamedSig_OI_q[13]),
    .O(\blk00000001/sig000000af )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a4  (
    .I0(b[12]),
    .I1(NlwRenamedSig_OI_q[12]),
    .O(\blk00000001/sig000000b0 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a3  (
    .I0(b[11]),
    .I1(NlwRenamedSig_OI_q[11]),
    .O(\blk00000001/sig000000b1 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a2  (
    .I0(b[10]),
    .I1(NlwRenamedSig_OI_q[10]),
    .O(\blk00000001/sig000000b2 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a1  (
    .I0(b[9]),
    .I1(NlwRenamedSig_OI_q[9]),
    .O(\blk00000001/sig000000b3 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk000000a0  (
    .I0(b[8]),
    .I1(NlwRenamedSig_OI_q[8]),
    .O(\blk00000001/sig000000b4 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009f  (
    .I0(b[7]),
    .I1(NlwRenamedSig_OI_q[7]),
    .O(\blk00000001/sig000000b5 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009e  (
    .I0(b[6]),
    .I1(NlwRenamedSig_OI_q[6]),
    .O(\blk00000001/sig000000b6 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009d  (
    .I0(b[5]),
    .I1(NlwRenamedSig_OI_q[5]),
    .O(\blk00000001/sig000000b7 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009c  (
    .I0(b[4]),
    .I1(NlwRenamedSig_OI_q[4]),
    .O(\blk00000001/sig000000b8 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009b  (
    .I0(b[3]),
    .I1(NlwRenamedSig_OI_q[3]),
    .O(\blk00000001/sig000000b9 )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk0000009a  (
    .I0(b[2]),
    .I1(NlwRenamedSig_OI_q[2]),
    .O(\blk00000001/sig000000ba )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000099  (
    .I0(b[1]),
    .I1(NlwRenamedSig_OI_q[1]),
    .O(\blk00000001/sig000000bb )
  );
  LUT2 #(
    .INIT ( 4'h6 ))
  \blk00000001/blk00000098  (
    .I0(b[0]),
    .I1(NlwRenamedSig_OI_q[0]),
    .O(\blk00000001/sig000000bd )
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000097  (
    .C(clk),
    .D(\blk00000001/sig0000005a ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[0])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000096  (
    .C(clk),
    .D(\blk00000001/sig0000005b ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[1])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000095  (
    .C(clk),
    .D(\blk00000001/sig0000005c ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[2])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000094  (
    .C(clk),
    .D(\blk00000001/sig0000005d ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[3])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000093  (
    .C(clk),
    .D(\blk00000001/sig0000005e ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[4])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000092  (
    .C(clk),
    .D(\blk00000001/sig0000005f ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[5])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000091  (
    .C(clk),
    .D(\blk00000001/sig00000060 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[6])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000090  (
    .C(clk),
    .D(\blk00000001/sig00000061 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[7])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008f  (
    .C(clk),
    .D(\blk00000001/sig00000062 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[8])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008e  (
    .C(clk),
    .D(\blk00000001/sig00000063 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[9])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008d  (
    .C(clk),
    .D(\blk00000001/sig00000064 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[10])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008c  (
    .C(clk),
    .D(\blk00000001/sig00000065 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[11])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008b  (
    .C(clk),
    .D(\blk00000001/sig00000066 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[12])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000008a  (
    .C(clk),
    .D(\blk00000001/sig00000067 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[13])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000089  (
    .C(clk),
    .D(\blk00000001/sig00000068 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[14])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000088  (
    .C(clk),
    .D(\blk00000001/sig00000069 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[15])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000087  (
    .C(clk),
    .D(\blk00000001/sig0000006a ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[16])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000086  (
    .C(clk),
    .D(\blk00000001/sig0000006b ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[17])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000085  (
    .C(clk),
    .D(\blk00000001/sig0000006c ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[18])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000084  (
    .C(clk),
    .D(\blk00000001/sig0000006d ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[19])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000083  (
    .C(clk),
    .D(\blk00000001/sig0000006e ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[20])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000082  (
    .C(clk),
    .D(\blk00000001/sig0000006f ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[21])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000081  (
    .C(clk),
    .D(\blk00000001/sig00000070 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[22])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000080  (
    .C(clk),
    .D(\blk00000001/sig00000071 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[23])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007f  (
    .C(clk),
    .D(\blk00000001/sig00000072 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[24])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007e  (
    .C(clk),
    .D(\blk00000001/sig00000073 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[25])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007d  (
    .C(clk),
    .D(\blk00000001/sig00000074 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[26])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007c  (
    .C(clk),
    .D(\blk00000001/sig00000075 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[27])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007b  (
    .C(clk),
    .D(\blk00000001/sig00000076 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[28])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000007a  (
    .C(clk),
    .D(\blk00000001/sig00000077 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[29])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000079  (
    .C(clk),
    .D(\blk00000001/sig00000078 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[30])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000078  (
    .C(clk),
    .D(\blk00000001/sig00000079 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[31])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000077  (
    .C(clk),
    .D(\blk00000001/sig0000007a ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[32])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000076  (
    .C(clk),
    .D(\blk00000001/sig0000007b ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[33])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000075  (
    .C(clk),
    .D(\blk00000001/sig0000007c ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[34])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000074  (
    .C(clk),
    .D(\blk00000001/sig0000007d ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[35])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000073  (
    .C(clk),
    .D(\blk00000001/sig0000007e ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[36])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000072  (
    .C(clk),
    .D(\blk00000001/sig0000007f ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[37])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000071  (
    .C(clk),
    .D(\blk00000001/sig00000080 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[38])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000070  (
    .C(clk),
    .D(\blk00000001/sig00000081 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[39])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006f  (
    .C(clk),
    .D(\blk00000001/sig00000082 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[40])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006e  (
    .C(clk),
    .D(\blk00000001/sig00000083 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[41])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006d  (
    .C(clk),
    .D(\blk00000001/sig00000084 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[42])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006c  (
    .C(clk),
    .D(\blk00000001/sig00000085 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[43])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006b  (
    .C(clk),
    .D(\blk00000001/sig00000086 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[44])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk0000006a  (
    .C(clk),
    .D(\blk00000001/sig00000087 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[45])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000069  (
    .C(clk),
    .D(\blk00000001/sig00000088 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[46])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000068  (
    .C(clk),
    .D(\blk00000001/sig00000089 ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[47])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000067  (
    .C(clk),
    .D(\blk00000001/sig0000008a ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[48])
  );
  FDR #(
    .INIT ( 1'b0 ))
  \blk00000001/blk00000066  (
    .C(clk),
    .D(\blk00000001/sig0000008b ),
    .R(sclr),
    .Q(NlwRenamedSig_OI_q[49])
  );
  MUXCY   \blk00000001/blk00000065  (
    .CI(\blk00000001/sig00000059 ),
    .DI(NlwRenamedSig_OI_q[0]),
    .S(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig000000ee )
  );
  MUXCY   \blk00000001/blk00000064  (
    .CI(\blk00000001/sig000000ee ),
    .DI(NlwRenamedSig_OI_q[1]),
    .S(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig000000ed )
  );
  MUXCY   \blk00000001/blk00000063  (
    .CI(\blk00000001/sig000000ed ),
    .DI(NlwRenamedSig_OI_q[2]),
    .S(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig000000ec )
  );
  MUXCY   \blk00000001/blk00000062  (
    .CI(\blk00000001/sig000000ec ),
    .DI(NlwRenamedSig_OI_q[3]),
    .S(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig000000eb )
  );
  MUXCY   \blk00000001/blk00000061  (
    .CI(\blk00000001/sig000000eb ),
    .DI(NlwRenamedSig_OI_q[4]),
    .S(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig000000ea )
  );
  MUXCY   \blk00000001/blk00000060  (
    .CI(\blk00000001/sig000000ea ),
    .DI(NlwRenamedSig_OI_q[5]),
    .S(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig000000e9 )
  );
  MUXCY   \blk00000001/blk0000005f  (
    .CI(\blk00000001/sig000000e9 ),
    .DI(NlwRenamedSig_OI_q[6]),
    .S(\blk00000001/sig000000b6 ),
    .O(\blk00000001/sig000000e8 )
  );
  MUXCY   \blk00000001/blk0000005e  (
    .CI(\blk00000001/sig000000e8 ),
    .DI(NlwRenamedSig_OI_q[7]),
    .S(\blk00000001/sig000000b5 ),
    .O(\blk00000001/sig000000e7 )
  );
  MUXCY   \blk00000001/blk0000005d  (
    .CI(\blk00000001/sig000000e7 ),
    .DI(NlwRenamedSig_OI_q[8]),
    .S(\blk00000001/sig000000b4 ),
    .O(\blk00000001/sig000000e6 )
  );
  MUXCY   \blk00000001/blk0000005c  (
    .CI(\blk00000001/sig000000e6 ),
    .DI(NlwRenamedSig_OI_q[9]),
    .S(\blk00000001/sig000000b3 ),
    .O(\blk00000001/sig000000e5 )
  );
  MUXCY   \blk00000001/blk0000005b  (
    .CI(\blk00000001/sig000000e5 ),
    .DI(NlwRenamedSig_OI_q[10]),
    .S(\blk00000001/sig000000b2 ),
    .O(\blk00000001/sig000000e4 )
  );
  MUXCY   \blk00000001/blk0000005a  (
    .CI(\blk00000001/sig000000e4 ),
    .DI(NlwRenamedSig_OI_q[11]),
    .S(\blk00000001/sig000000b1 ),
    .O(\blk00000001/sig000000e3 )
  );
  MUXCY   \blk00000001/blk00000059  (
    .CI(\blk00000001/sig000000e3 ),
    .DI(NlwRenamedSig_OI_q[12]),
    .S(\blk00000001/sig000000b0 ),
    .O(\blk00000001/sig000000e2 )
  );
  MUXCY   \blk00000001/blk00000058  (
    .CI(\blk00000001/sig000000e2 ),
    .DI(NlwRenamedSig_OI_q[13]),
    .S(\blk00000001/sig000000af ),
    .O(\blk00000001/sig000000e1 )
  );
  MUXCY   \blk00000001/blk00000057  (
    .CI(\blk00000001/sig000000e1 ),
    .DI(NlwRenamedSig_OI_q[14]),
    .S(\blk00000001/sig000000ae ),
    .O(\blk00000001/sig000000e0 )
  );
  MUXCY   \blk00000001/blk00000056  (
    .CI(\blk00000001/sig000000e0 ),
    .DI(NlwRenamedSig_OI_q[15]),
    .S(\blk00000001/sig000000ad ),
    .O(\blk00000001/sig000000df )
  );
  MUXCY   \blk00000001/blk00000055  (
    .CI(\blk00000001/sig000000df ),
    .DI(NlwRenamedSig_OI_q[16]),
    .S(\blk00000001/sig000000ac ),
    .O(\blk00000001/sig000000de )
  );
  MUXCY   \blk00000001/blk00000054  (
    .CI(\blk00000001/sig000000de ),
    .DI(NlwRenamedSig_OI_q[17]),
    .S(\blk00000001/sig000000ab ),
    .O(\blk00000001/sig000000dd )
  );
  MUXCY   \blk00000001/blk00000053  (
    .CI(\blk00000001/sig000000dd ),
    .DI(NlwRenamedSig_OI_q[18]),
    .S(\blk00000001/sig000000aa ),
    .O(\blk00000001/sig000000dc )
  );
  MUXCY   \blk00000001/blk00000052  (
    .CI(\blk00000001/sig000000dc ),
    .DI(NlwRenamedSig_OI_q[19]),
    .S(\blk00000001/sig000000a9 ),
    .O(\blk00000001/sig000000db )
  );
  MUXCY   \blk00000001/blk00000051  (
    .CI(\blk00000001/sig000000db ),
    .DI(NlwRenamedSig_OI_q[20]),
    .S(\blk00000001/sig000000a8 ),
    .O(\blk00000001/sig000000da )
  );
  MUXCY   \blk00000001/blk00000050  (
    .CI(\blk00000001/sig000000da ),
    .DI(NlwRenamedSig_OI_q[21]),
    .S(\blk00000001/sig000000a7 ),
    .O(\blk00000001/sig000000d9 )
  );
  MUXCY   \blk00000001/blk0000004f  (
    .CI(\blk00000001/sig000000d9 ),
    .DI(NlwRenamedSig_OI_q[22]),
    .S(\blk00000001/sig000000a6 ),
    .O(\blk00000001/sig000000d8 )
  );
  MUXCY   \blk00000001/blk0000004e  (
    .CI(\blk00000001/sig000000d8 ),
    .DI(NlwRenamedSig_OI_q[23]),
    .S(\blk00000001/sig000000a5 ),
    .O(\blk00000001/sig000000d7 )
  );
  MUXCY   \blk00000001/blk0000004d  (
    .CI(\blk00000001/sig000000d7 ),
    .DI(NlwRenamedSig_OI_q[24]),
    .S(\blk00000001/sig000000a4 ),
    .O(\blk00000001/sig000000d6 )
  );
  MUXCY   \blk00000001/blk0000004c  (
    .CI(\blk00000001/sig000000d6 ),
    .DI(NlwRenamedSig_OI_q[25]),
    .S(\blk00000001/sig000000a3 ),
    .O(\blk00000001/sig000000d5 )
  );
  MUXCY   \blk00000001/blk0000004b  (
    .CI(\blk00000001/sig000000d5 ),
    .DI(NlwRenamedSig_OI_q[26]),
    .S(\blk00000001/sig000000a2 ),
    .O(\blk00000001/sig000000d4 )
  );
  MUXCY   \blk00000001/blk0000004a  (
    .CI(\blk00000001/sig000000d4 ),
    .DI(NlwRenamedSig_OI_q[27]),
    .S(\blk00000001/sig000000a1 ),
    .O(\blk00000001/sig000000d3 )
  );
  MUXCY   \blk00000001/blk00000049  (
    .CI(\blk00000001/sig000000d3 ),
    .DI(NlwRenamedSig_OI_q[28]),
    .S(\blk00000001/sig000000a0 ),
    .O(\blk00000001/sig000000d2 )
  );
  MUXCY   \blk00000001/blk00000048  (
    .CI(\blk00000001/sig000000d2 ),
    .DI(NlwRenamedSig_OI_q[29]),
    .S(\blk00000001/sig0000009f ),
    .O(\blk00000001/sig000000d1 )
  );
  MUXCY   \blk00000001/blk00000047  (
    .CI(\blk00000001/sig000000d1 ),
    .DI(NlwRenamedSig_OI_q[30]),
    .S(\blk00000001/sig0000009e ),
    .O(\blk00000001/sig000000d0 )
  );
  MUXCY   \blk00000001/blk00000046  (
    .CI(\blk00000001/sig000000d0 ),
    .DI(NlwRenamedSig_OI_q[31]),
    .S(\blk00000001/sig0000009d ),
    .O(\blk00000001/sig000000cf )
  );
  MUXCY   \blk00000001/blk00000045  (
    .CI(\blk00000001/sig000000cf ),
    .DI(NlwRenamedSig_OI_q[32]),
    .S(\blk00000001/sig0000009c ),
    .O(\blk00000001/sig000000ce )
  );
  MUXCY   \blk00000001/blk00000044  (
    .CI(\blk00000001/sig000000ce ),
    .DI(NlwRenamedSig_OI_q[33]),
    .S(\blk00000001/sig0000009b ),
    .O(\blk00000001/sig000000cd )
  );
  MUXCY   \blk00000001/blk00000043  (
    .CI(\blk00000001/sig000000cd ),
    .DI(NlwRenamedSig_OI_q[34]),
    .S(\blk00000001/sig0000009a ),
    .O(\blk00000001/sig000000cc )
  );
  MUXCY   \blk00000001/blk00000042  (
    .CI(\blk00000001/sig000000cc ),
    .DI(NlwRenamedSig_OI_q[35]),
    .S(\blk00000001/sig00000099 ),
    .O(\blk00000001/sig000000cb )
  );
  MUXCY   \blk00000001/blk00000041  (
    .CI(\blk00000001/sig000000cb ),
    .DI(NlwRenamedSig_OI_q[36]),
    .S(\blk00000001/sig00000098 ),
    .O(\blk00000001/sig000000ca )
  );
  MUXCY   \blk00000001/blk00000040  (
    .CI(\blk00000001/sig000000ca ),
    .DI(NlwRenamedSig_OI_q[37]),
    .S(\blk00000001/sig00000097 ),
    .O(\blk00000001/sig000000c9 )
  );
  MUXCY   \blk00000001/blk0000003f  (
    .CI(\blk00000001/sig000000c9 ),
    .DI(NlwRenamedSig_OI_q[38]),
    .S(\blk00000001/sig00000096 ),
    .O(\blk00000001/sig000000c8 )
  );
  MUXCY   \blk00000001/blk0000003e  (
    .CI(\blk00000001/sig000000c8 ),
    .DI(NlwRenamedSig_OI_q[39]),
    .S(\blk00000001/sig00000095 ),
    .O(\blk00000001/sig000000c7 )
  );
  MUXCY   \blk00000001/blk0000003d  (
    .CI(\blk00000001/sig000000c7 ),
    .DI(NlwRenamedSig_OI_q[40]),
    .S(\blk00000001/sig00000094 ),
    .O(\blk00000001/sig000000c6 )
  );
  MUXCY   \blk00000001/blk0000003c  (
    .CI(\blk00000001/sig000000c6 ),
    .DI(NlwRenamedSig_OI_q[41]),
    .S(\blk00000001/sig00000093 ),
    .O(\blk00000001/sig000000c5 )
  );
  MUXCY   \blk00000001/blk0000003b  (
    .CI(\blk00000001/sig000000c5 ),
    .DI(NlwRenamedSig_OI_q[42]),
    .S(\blk00000001/sig00000092 ),
    .O(\blk00000001/sig000000c4 )
  );
  MUXCY   \blk00000001/blk0000003a  (
    .CI(\blk00000001/sig000000c4 ),
    .DI(NlwRenamedSig_OI_q[43]),
    .S(\blk00000001/sig00000091 ),
    .O(\blk00000001/sig000000c3 )
  );
  MUXCY   \blk00000001/blk00000039  (
    .CI(\blk00000001/sig000000c3 ),
    .DI(NlwRenamedSig_OI_q[44]),
    .S(\blk00000001/sig00000090 ),
    .O(\blk00000001/sig000000c2 )
  );
  MUXCY   \blk00000001/blk00000038  (
    .CI(\blk00000001/sig000000c2 ),
    .DI(NlwRenamedSig_OI_q[45]),
    .S(\blk00000001/sig0000008f ),
    .O(\blk00000001/sig000000c1 )
  );
  MUXCY   \blk00000001/blk00000037  (
    .CI(\blk00000001/sig000000c1 ),
    .DI(NlwRenamedSig_OI_q[46]),
    .S(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig000000c0 )
  );
  MUXCY   \blk00000001/blk00000036  (
    .CI(\blk00000001/sig000000c0 ),
    .DI(NlwRenamedSig_OI_q[47]),
    .S(\blk00000001/sig0000008d ),
    .O(\blk00000001/sig000000bf )
  );
  MUXCY   \blk00000001/blk00000035  (
    .CI(\blk00000001/sig000000bf ),
    .DI(NlwRenamedSig_OI_q[48]),
    .S(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig000000be )
  );
  XORCY   \blk00000001/blk00000034  (
    .CI(\blk00000001/sig000000ee ),
    .LI(\blk00000001/sig000000bb ),
    .O(\blk00000001/sig0000005b )
  );
  XORCY   \blk00000001/blk00000033  (
    .CI(\blk00000001/sig000000ed ),
    .LI(\blk00000001/sig000000ba ),
    .O(\blk00000001/sig0000005c )
  );
  XORCY   \blk00000001/blk00000032  (
    .CI(\blk00000001/sig000000ec ),
    .LI(\blk00000001/sig000000b9 ),
    .O(\blk00000001/sig0000005d )
  );
  XORCY   \blk00000001/blk00000031  (
    .CI(\blk00000001/sig000000eb ),
    .LI(\blk00000001/sig000000b8 ),
    .O(\blk00000001/sig0000005e )
  );
  XORCY   \blk00000001/blk00000030  (
    .CI(\blk00000001/sig000000ea ),
    .LI(\blk00000001/sig000000b7 ),
    .O(\blk00000001/sig0000005f )
  );
  XORCY   \blk00000001/blk0000002f  (
    .CI(\blk00000001/sig000000e9 ),
    .LI(\blk00000001/sig000000b6 ),
    .O(\blk00000001/sig00000060 )
  );
  XORCY   \blk00000001/blk0000002e  (
    .CI(\blk00000001/sig000000e8 ),
    .LI(\blk00000001/sig000000b5 ),
    .O(\blk00000001/sig00000061 )
  );
  XORCY   \blk00000001/blk0000002d  (
    .CI(\blk00000001/sig000000e7 ),
    .LI(\blk00000001/sig000000b4 ),
    .O(\blk00000001/sig00000062 )
  );
  XORCY   \blk00000001/blk0000002c  (
    .CI(\blk00000001/sig000000e6 ),
    .LI(\blk00000001/sig000000b3 ),
    .O(\blk00000001/sig00000063 )
  );
  XORCY   \blk00000001/blk0000002b  (
    .CI(\blk00000001/sig000000e5 ),
    .LI(\blk00000001/sig000000b2 ),
    .O(\blk00000001/sig00000064 )
  );
  XORCY   \blk00000001/blk0000002a  (
    .CI(\blk00000001/sig000000e4 ),
    .LI(\blk00000001/sig000000b1 ),
    .O(\blk00000001/sig00000065 )
  );
  XORCY   \blk00000001/blk00000029  (
    .CI(\blk00000001/sig000000e3 ),
    .LI(\blk00000001/sig000000b0 ),
    .O(\blk00000001/sig00000066 )
  );
  XORCY   \blk00000001/blk00000028  (
    .CI(\blk00000001/sig000000e2 ),
    .LI(\blk00000001/sig000000af ),
    .O(\blk00000001/sig00000067 )
  );
  XORCY   \blk00000001/blk00000027  (
    .CI(\blk00000001/sig000000e1 ),
    .LI(\blk00000001/sig000000ae ),
    .O(\blk00000001/sig00000068 )
  );
  XORCY   \blk00000001/blk00000026  (
    .CI(\blk00000001/sig000000e0 ),
    .LI(\blk00000001/sig000000ad ),
    .O(\blk00000001/sig00000069 )
  );
  XORCY   \blk00000001/blk00000025  (
    .CI(\blk00000001/sig000000df ),
    .LI(\blk00000001/sig000000ac ),
    .O(\blk00000001/sig0000006a )
  );
  XORCY   \blk00000001/blk00000024  (
    .CI(\blk00000001/sig000000de ),
    .LI(\blk00000001/sig000000ab ),
    .O(\blk00000001/sig0000006b )
  );
  XORCY   \blk00000001/blk00000023  (
    .CI(\blk00000001/sig000000dd ),
    .LI(\blk00000001/sig000000aa ),
    .O(\blk00000001/sig0000006c )
  );
  XORCY   \blk00000001/blk00000022  (
    .CI(\blk00000001/sig000000dc ),
    .LI(\blk00000001/sig000000a9 ),
    .O(\blk00000001/sig0000006d )
  );
  XORCY   \blk00000001/blk00000021  (
    .CI(\blk00000001/sig000000db ),
    .LI(\blk00000001/sig000000a8 ),
    .O(\blk00000001/sig0000006e )
  );
  XORCY   \blk00000001/blk00000020  (
    .CI(\blk00000001/sig000000da ),
    .LI(\blk00000001/sig000000a7 ),
    .O(\blk00000001/sig0000006f )
  );
  XORCY   \blk00000001/blk0000001f  (
    .CI(\blk00000001/sig000000d9 ),
    .LI(\blk00000001/sig000000a6 ),
    .O(\blk00000001/sig00000070 )
  );
  XORCY   \blk00000001/blk0000001e  (
    .CI(\blk00000001/sig000000d8 ),
    .LI(\blk00000001/sig000000a5 ),
    .O(\blk00000001/sig00000071 )
  );
  XORCY   \blk00000001/blk0000001d  (
    .CI(\blk00000001/sig000000d7 ),
    .LI(\blk00000001/sig000000a4 ),
    .O(\blk00000001/sig00000072 )
  );
  XORCY   \blk00000001/blk0000001c  (
    .CI(\blk00000001/sig000000d6 ),
    .LI(\blk00000001/sig000000a3 ),
    .O(\blk00000001/sig00000073 )
  );
  XORCY   \blk00000001/blk0000001b  (
    .CI(\blk00000001/sig000000d5 ),
    .LI(\blk00000001/sig000000a2 ),
    .O(\blk00000001/sig00000074 )
  );
  XORCY   \blk00000001/blk0000001a  (
    .CI(\blk00000001/sig000000d4 ),
    .LI(\blk00000001/sig000000a1 ),
    .O(\blk00000001/sig00000075 )
  );
  XORCY   \blk00000001/blk00000019  (
    .CI(\blk00000001/sig000000d3 ),
    .LI(\blk00000001/sig000000a0 ),
    .O(\blk00000001/sig00000076 )
  );
  XORCY   \blk00000001/blk00000018  (
    .CI(\blk00000001/sig000000d2 ),
    .LI(\blk00000001/sig0000009f ),
    .O(\blk00000001/sig00000077 )
  );
  XORCY   \blk00000001/blk00000017  (
    .CI(\blk00000001/sig000000d1 ),
    .LI(\blk00000001/sig0000009e ),
    .O(\blk00000001/sig00000078 )
  );
  XORCY   \blk00000001/blk00000016  (
    .CI(\blk00000001/sig000000d0 ),
    .LI(\blk00000001/sig0000009d ),
    .O(\blk00000001/sig00000079 )
  );
  XORCY   \blk00000001/blk00000015  (
    .CI(\blk00000001/sig000000cf ),
    .LI(\blk00000001/sig0000009c ),
    .O(\blk00000001/sig0000007a )
  );
  XORCY   \blk00000001/blk00000014  (
    .CI(\blk00000001/sig000000ce ),
    .LI(\blk00000001/sig0000009b ),
    .O(\blk00000001/sig0000007b )
  );
  XORCY   \blk00000001/blk00000013  (
    .CI(\blk00000001/sig000000cd ),
    .LI(\blk00000001/sig0000009a ),
    .O(\blk00000001/sig0000007c )
  );
  XORCY   \blk00000001/blk00000012  (
    .CI(\blk00000001/sig000000cc ),
    .LI(\blk00000001/sig00000099 ),
    .O(\blk00000001/sig0000007d )
  );
  XORCY   \blk00000001/blk00000011  (
    .CI(\blk00000001/sig000000cb ),
    .LI(\blk00000001/sig00000098 ),
    .O(\blk00000001/sig0000007e )
  );
  XORCY   \blk00000001/blk00000010  (
    .CI(\blk00000001/sig000000ca ),
    .LI(\blk00000001/sig00000097 ),
    .O(\blk00000001/sig0000007f )
  );
  XORCY   \blk00000001/blk0000000f  (
    .CI(\blk00000001/sig000000c9 ),
    .LI(\blk00000001/sig00000096 ),
    .O(\blk00000001/sig00000080 )
  );
  XORCY   \blk00000001/blk0000000e  (
    .CI(\blk00000001/sig000000c8 ),
    .LI(\blk00000001/sig00000095 ),
    .O(\blk00000001/sig00000081 )
  );
  XORCY   \blk00000001/blk0000000d  (
    .CI(\blk00000001/sig000000c7 ),
    .LI(\blk00000001/sig00000094 ),
    .O(\blk00000001/sig00000082 )
  );
  XORCY   \blk00000001/blk0000000c  (
    .CI(\blk00000001/sig000000c6 ),
    .LI(\blk00000001/sig00000093 ),
    .O(\blk00000001/sig00000083 )
  );
  XORCY   \blk00000001/blk0000000b  (
    .CI(\blk00000001/sig000000c5 ),
    .LI(\blk00000001/sig00000092 ),
    .O(\blk00000001/sig00000084 )
  );
  XORCY   \blk00000001/blk0000000a  (
    .CI(\blk00000001/sig000000c4 ),
    .LI(\blk00000001/sig00000091 ),
    .O(\blk00000001/sig00000085 )
  );
  XORCY   \blk00000001/blk00000009  (
    .CI(\blk00000001/sig000000c3 ),
    .LI(\blk00000001/sig00000090 ),
    .O(\blk00000001/sig00000086 )
  );
  XORCY   \blk00000001/blk00000008  (
    .CI(\blk00000001/sig000000c2 ),
    .LI(\blk00000001/sig0000008f ),
    .O(\blk00000001/sig00000087 )
  );
  XORCY   \blk00000001/blk00000007  (
    .CI(\blk00000001/sig000000c1 ),
    .LI(\blk00000001/sig0000008e ),
    .O(\blk00000001/sig00000088 )
  );
  XORCY   \blk00000001/blk00000006  (
    .CI(\blk00000001/sig000000c0 ),
    .LI(\blk00000001/sig0000008d ),
    .O(\blk00000001/sig00000089 )
  );
  XORCY   \blk00000001/blk00000005  (
    .CI(\blk00000001/sig000000bf ),
    .LI(\blk00000001/sig0000008c ),
    .O(\blk00000001/sig0000008a )
  );
  XORCY   \blk00000001/blk00000004  (
    .CI(\blk00000001/sig000000be ),
    .LI(\blk00000001/sig000000bc ),
    .O(\blk00000001/sig0000008b )
  );
  XORCY   \blk00000001/blk00000003  (
    .CI(\blk00000001/sig00000059 ),
    .LI(\blk00000001/sig000000bd ),
    .O(\blk00000001/sig0000005a )
  );
  GND   \blk00000001/blk00000002  (
    .G(\blk00000001/sig00000059 )
  );

// synthesis translate_on

endmodule

// synthesis translate_off

`ifndef GLBL
`define GLBL

`timescale  1 ps / 1 ps

module glbl ();

    parameter ROC_WIDTH = 100000;
    parameter TOC_WIDTH = 0;

//--------   STARTUP Globals --------------
    wire GSR;
    wire GTS;
    wire GWE;
    wire PRLD;
    tri1 p_up_tmp;
    tri (weak1, strong0) PLL_LOCKG = p_up_tmp;

    wire PROGB_GLBL;
    wire CCLKO_GLBL;

    reg GSR_int;
    reg GTS_int;
    reg PRLD_int;

//--------   JTAG Globals --------------
    wire JTAG_TDO_GLBL;
    wire JTAG_TCK_GLBL;
    wire JTAG_TDI_GLBL;
    wire JTAG_TMS_GLBL;
    wire JTAG_TRST_GLBL;

    reg JTAG_CAPTURE_GLBL;
    reg JTAG_RESET_GLBL;
    reg JTAG_SHIFT_GLBL;
    reg JTAG_UPDATE_GLBL;
    reg JTAG_RUNTEST_GLBL;

    reg JTAG_SEL1_GLBL = 0;
    reg JTAG_SEL2_GLBL = 0 ;
    reg JTAG_SEL3_GLBL = 0;
    reg JTAG_SEL4_GLBL = 0;

    reg JTAG_USER_TDO1_GLBL = 1'bz;
    reg JTAG_USER_TDO2_GLBL = 1'bz;
    reg JTAG_USER_TDO3_GLBL = 1'bz;
    reg JTAG_USER_TDO4_GLBL = 1'bz;

    assign (weak1, weak0) GSR = GSR_int;
    assign (weak1, weak0) GTS = GTS_int;
    assign (weak1, weak0) PRLD = PRLD_int;

    initial begin
	GSR_int = 1'b1;
	PRLD_int = 1'b1;
	#(ROC_WIDTH)
	GSR_int = 1'b0;
	PRLD_int = 1'b0;
    end

    initial begin
	GTS_int = 1'b1;
	#(TOC_WIDTH)
	GTS_int = 1'b0;
    end

endmodule

`endif

// synthesis translate_on
