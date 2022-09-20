// ---------------------------------------------------------------------
// File name         : syn_gen.v
// Module name       : syn_gen
// Module Description: 
// Created by        : Caojie
// ---------------------------------------------------------------------
// Release history
// VERSION |   Date      | AUTHOR  |    DESCRIPTION
// --------------------------------------------------------------------
//   1.0   | 16-Jul-2019 | Caojie  |    initial
// --------------------------------------------------------------------

module syn_gen
(
    input              I_pxl_clk   ,//pixel clock
    input              I_rst_n     ,//low active 
    input      [15:0]  I_h_total   ,//hor total time 
    input      [15:0]  I_h_sync    ,//hor sync time
    input      [15:0]  I_h_bporch  ,//hor back porch
    input      [15:0]  I_h_res     ,//hor resolution
    input      [15:0]  I_v_total   ,//ver total time 
    input      [15:0]  I_v_sync    ,//ver sync time  
    input      [15:0]  I_v_bporch  ,//ver back porch  
    input      [15:0]  I_v_res     ,//ver resolution 
    input      [15:0]  I_rd_hres   ,
    input      [15:0]  I_rd_vres   ,
    input              I_hs_pol    ,//HS polarity , 0:负极性，1：正极性
    input              I_vs_pol    ,//VS polarity , 0:负极性，1：正极性
    output reg         O_rden      ,
    output reg         O_de        ,   
    output reg         O_hs        ,
    output reg         O_vs         
);
  
//====================================================
reg  [15:0]   V_cnt     ;
reg  [15:0]   H_cnt     ;

//-----------------------------------------              
wire          Pout_de_w    ;                          
wire          Pout_hs_w    ;
wire          Pout_vs_w    ;

reg           Pout_de_dn   ;                          
reg           Pout_hs_dn   ;
reg           Pout_vs_dn   ;

//-----------------------------------------
wire          Rden_w    ;

reg           Rden_dn   ; 

//==============================================================================
//Generate HS, VS, DE signals
always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		V_cnt <= 16'd0;
	else     
		begin
			if((V_cnt >= (I_v_total-1'b1)) && (H_cnt >= (I_h_total-1'b1)))
				V_cnt <= 16'd0;
			else if(H_cnt >= (I_h_total-1'b1))
				V_cnt <=  V_cnt + 1'b1;
			else
				V_cnt <= V_cnt;
		end
end

//-------------------------------------------------------------    
always @(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		H_cnt <=  16'd0; 
	else if(H_cnt >= (I_h_total-1'b1))
		H_cnt <=  16'd0 ; 
	else 
		H_cnt <=  H_cnt + 1'b1 ;           
end

//-------------------------------------------------------------
assign  Pout_de_w = ((H_cnt>=(I_h_sync+I_h_bporch))&(H_cnt<=(I_h_sync+I_h_bporch+I_h_res-1'b1)))&
                    ((V_cnt>=(I_v_sync+I_v_bporch))&(V_cnt<=(I_v_sync+I_v_bporch+I_v_res-1'b1))) ;
assign  Pout_hs_w =  ~((H_cnt>=16'd0) & (H_cnt<=(I_h_sync-1'b1))) ;
assign  Pout_vs_w =  ~((V_cnt>=16'd0) & (V_cnt<=(I_v_sync-1'b1))) ;  

//==============================================================================
assign  Rden_w    = ((H_cnt>=(I_h_sync+I_h_bporch))&(H_cnt<=(I_h_sync+I_h_bporch+I_rd_hres-1'b1)))&
                    ((V_cnt>=(I_v_sync+I_v_bporch))&(V_cnt<=(I_v_sync+I_v_bporch+I_rd_vres-1'b1))); 

//-------------------------------------------------------------
always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		begin
			Pout_de_dn  <= 1'b0;                          
			Pout_hs_dn  <= 1'b1;
			Pout_vs_dn  <= 1'b1; 
			Rden_dn     <= 1'b0; 
		end
	else 
		begin
			Pout_de_dn  <= Pout_de_w;                          
			Pout_hs_dn  <= Pout_hs_w;
			Pout_vs_dn  <= Pout_vs_w;
			Rden_dn     <= Rden_w   ; 
		end
end

always@(posedge I_pxl_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
		begin 
			O_de  <= 1'b0;                       
			O_hs  <= 1'b1;
			O_vs  <= 1'b1;
			O_rden<= 1'b0; 
		end
	else 
		begin   
			O_de  <= Pout_de_dn;                      
			O_hs  <= I_hs_pol ? ~Pout_hs_dn : Pout_hs_dn ;
			O_vs  <= I_vs_pol ? ~Pout_vs_dn : Pout_vs_dn ;
			O_rden<= Rden_dn;
		end
end

endmodule       
              