
module video_timing
(
    input       clk,
    input       clk_pix,
    input       reset,

    input  [2:0] pcb,
    
    input  signed [8:0] hs_offset,
    input  signed [8:0] vs_offset,

    output [8:0] hc,
    output [8:0] vc,

    output reg  hsync,
    output reg  vsync,
    
    output reg  hbl,
    output reg  vbl 
);

// 6MHz
wire [8:0] h_ofs = 0;
wire [8:0] HBL_START  = 256 ;
wire [8:0] HBL_END    = 0 ;
wire [8:0] HS_START   = HBL_START + 8 ;
wire [8:0] HS_END     = HBL_START + 40 ;
wire [8:0] HTOTAL     = 383;

wire [8:0] v_ofs = 0;
wire [8:0] VBL_START  = 240 ;
wire [8:0] VBL_END    = 16 ;
wire [8:0] VS_START   = VBL_START + 4 ;
wire [8:0] VS_END     = VBL_START + 8 ;
wire [8:0] VTOTAL     = 261 ;

reg [8:0] v;
reg [8:0] h;

assign vc = v - v_ofs;
assign hc = h - h_ofs;

always @ (posedge clk) begin
	if (reset) begin
		h <= 0;
		v <= 0;

		hbl <= 0;
		vbl <= 0;

        hsync <= 0;
        vsync <= 0;
	end else if ( clk_pix == 1 ) begin 
        // counter
        if (h == HTOTAL) begin
            h <= 0;
            v <= v + 1'd1;                

            if ( v == VTOTAL ) begin
                v <= 0;
            end
        end else begin
            h <= h + 1'd1;
        end

        // h signals
        if ( h == HBL_START ) begin
            hbl <= 1;
        end else if ( h == HBL_END ) begin
            hbl <= 0;
        end

        // v signals
        if ( v == VBL_START ) begin
            vbl <= 1;
        end else if ( v == VBL_END ) begin
            vbl <= 0;
        end
   
        if ( v == (VS_START + $signed(vs_offset) ) ) begin
            vsync <= 1;
        end else if ( v == (VS_END + $signed(vs_offset) ) ) begin
            vsync <= 0;
        end

        if ( h == (HS_START + $signed(hs_offset) ) ) begin
            hsync <= 1;
        end else if ( h == (HS_END + $signed(hs_offset) ) ) begin
            hsync <= 0;
        end
    end

end

endmodule


