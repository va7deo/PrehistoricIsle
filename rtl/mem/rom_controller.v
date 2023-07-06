
`default_nettype none

module rom_controller 
(
    // reset
    input reset,

    // clock
    input clk,

    // program ROM interface
    input  prog_rom_cs,
    input  prog_rom_oe,
    input  [23:1] prog_rom_addr,
    output [15:0] prog_rom_data,
    output prog_rom_data_valid,

    // background ROM interface
    input bg_rom_cs,
    input bg_rom_oe,
    input  [15:0] bg_rom_addr,
    output [31:0] bg_rom_data,
    output bg_rom_data_valid,    

    // foreground ROM interface
    input fg_rom_cs,
    input fg_rom_oe,
    input  [15:0] fg_rom_addr,
    output [31:0] fg_rom_data,
    output fg_rom_data_valid,    
    
    // text ROM interface
    input text_rom_cs,
    input text_rom_oe,
    input  [12:0] text_rom_addr,
    output [31:0] text_rom_data,
    output text_rom_data_valid,      

    // sprite ROM #1 interface
    input sprite_rom_cs,
    input sprite_rom_oe,
    input  [17:0] sprite_rom_addr,
    output [31:0] sprite_rom_data,
    output sprite_rom_data_valid,    
    
    // sound ROM #1 interface
    input sound_rom_cs,
    input sound_rom_oe,
    input  [16:0] sound_rom_addr,
    output [7:0] sound_rom_data,
    output sound_rom_data_valid,        

    // IOCTL interface
    input [24:0] ioctl_addr,
    input [7:0] ioctl_data,
    input [15:0] ioctl_index,
    input ioctl_wr,
    input ioctl_download,

    // SDRAM interface
    output reg [22:0] sdram_addr,
    output reg [31:0] sdram_data,
    output reg sdram_we,
    output reg sdram_req,
    input  sdram_ack,
    input  sdram_valid,
    input  [31:0] sdram_q
  );

localparam NONE         = 0; 
localparam PROG_ROM     = 1;
localparam SPRITE_ROM   = 2;
localparam BG_ROM       = 3;
localparam FG_ROM       = 4;
localparam TEXT_ROM     = 5;
localparam SOUND_ROM    = 6;
  
// ROM wires
reg [2:0] rom;
reg [2:0] next_rom;
reg [2:0] pending_rom;

// ROM request wires
reg prog_rom_ctrl_req;
reg sprite_rom_ctrl_req;
reg bg_rom_ctrl_req;
reg fg_rom_ctrl_req;
reg text_rom_ctrl_req;
reg sound_rom_ctrl_req;

// ROM acknowledge wires
reg prog_rom_ctrl_ack;
reg sprite_rom_ctrl_ack;
reg fg_rom_ctrl_ack;
reg bg_rom_ctrl_ack;
reg text_rom_ctrl_ack;
reg sound_rom_ctrl_ack;

reg prog_rom_ctrl_hit;
reg sprite_rom_ctrl_hit;
reg fg_rom_ctrl_hit;
reg bg_rom_ctrl_hit;
reg text_rom_ctrl_hit;
reg sound_rom_ctrl_hit;

// ROM valid wires
reg prog_rom_ctrl_valid;
reg sprite_rom_ctrl_valid;
reg fg_rom_ctrl_valid;
reg bg_rom_ctrl_valid;
reg text_rom_ctrl_valid;
reg sound_rom_ctrl_valid;

// address mux wires
reg [22:0] prog_rom_ctrl_addr;
reg [22:0] sprite_rom_ctrl_addr;
reg [22:0] fg_rom_ctrl_addr;
reg [22:0] bg_rom_ctrl_addr;
reg [22:0] text_rom_ctrl_addr;
reg [22:0] sound_rom_ctrl_addr;

// download wires
reg [22:0] download_addr;
reg [32:0] download_data;
reg download_req;

// control wires
reg ctrl_req;

// The SDRAM controller has a 32-bit interface, so we need to buffer the
// bytes received from the IOCTL interface in order to write 32-bit words to
// the SDRAM. 
download_buffer #(.SIZE(4) ) download_buffer
(
    .clk(clk),
    .din(ioctl_data),
    .dout(download_data),
    .we(ioctl_download & ioctl_wr),
    .valid(download_req)
);

segment 
#(
    .ROM_ADDR_WIDTH(17), // 0x20000 x 16 words = 256k
    .ROM_DATA_WIDTH(16),
    .ROM_OFFSET(24'h000000)
) prog_rom_segment 
(
    .reset(reset),
    .clk(clk),
    .cs(prog_rom_cs & !ioctl_download),
    .oe(prog_rom_oe),
    .ctrl_addr(prog_rom_ctrl_addr),
    .ctrl_req(prog_rom_ctrl_req),
    .ctrl_ack(prog_rom_ctrl_ack),
    .ctrl_valid(prog_rom_ctrl_valid),
    .ctrl_hit(prog_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(prog_rom_addr),
    .rom_data(prog_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(16), // 0x10000 x 32 words = 256k
    .ROM_DATA_WIDTH(32),
    .ROM_OFFSET(24'h040000)
) fg_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(fg_rom_cs & !ioctl_download),
    .oe(fg_rom_oe),
    .ctrl_addr(fg_rom_ctrl_addr),
    .ctrl_req(fg_rom_ctrl_req),
    .ctrl_ack(fg_rom_ctrl_ack),
    .ctrl_valid(fg_rom_ctrl_valid),
    .ctrl_hit(fg_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(fg_rom_addr),
    .rom_data(fg_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(16), // 0x10000 x 32 words = 256k
    .ROM_DATA_WIDTH(32),
    .ROM_OFFSET(24'h080000)
) bg_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(bg_rom_cs & !ioctl_download),
    .oe(bg_rom_oe),
    .ctrl_addr(bg_rom_ctrl_addr),
    .ctrl_req(bg_rom_ctrl_req),
    .ctrl_ack(bg_rom_ctrl_ack),
    .ctrl_valid(bg_rom_ctrl_valid),
    .ctrl_hit(bg_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(bg_rom_addr),
    .rom_data(bg_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(13), // 0x10000 x 32 words = 32k
    .ROM_DATA_WIDTH(32),
    .ROM_OFFSET(24'h200000)
) text_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(text_rom_cs & !ioctl_download),
    .oe(text_rom_oe),
    .ctrl_addr(text_rom_ctrl_addr),
    .ctrl_req(text_rom_ctrl_req),
    .ctrl_ack(text_rom_ctrl_ack),
    .ctrl_valid(text_rom_ctrl_valid),
    .ctrl_hit(text_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(text_rom_addr),
    .rom_data(text_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(17),    // 0x20000 x 8 words = 128k // upd7759 samples
    .ROM_DATA_WIDTH(8),
    .ROM_OFFSET(24'h0d0000)
) sound_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(sound_rom_cs & !ioctl_download),
    .oe(sound_rom_oe),
    .ctrl_addr(sound_rom_ctrl_addr),
    .ctrl_req(sound_rom_ctrl_req),
    .ctrl_ack(sound_rom_ctrl_ack),
    .ctrl_valid(sound_rom_ctrl_valid),
    .ctrl_hit(sound_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(sound_rom_addr),
    .rom_data(sound_rom_data)
);

segment 
#(
    .ROM_ADDR_WIDTH(18), // 0x40000 x 32 words - 1MB
    .ROM_DATA_WIDTH(32),
    .ROM_OFFSET(24'h100000)
) sprite_rom_segment
(
    .reset(reset),
    .clk(clk),
    .cs(sprite_rom_cs & !ioctl_download),
    .oe(sprite_rom_oe),
    .ctrl_addr(sprite_rom_ctrl_addr),
    .ctrl_req(sprite_rom_ctrl_req),
    .ctrl_ack(sprite_rom_ctrl_ack),
    .ctrl_valid(sprite_rom_ctrl_valid),
    .ctrl_hit(sprite_rom_ctrl_hit),
    .ctrl_data(sdram_q),
    .rom_addr(sprite_rom_addr),
    .rom_data(sprite_rom_data)
);

// latch the next ROM
always @ (posedge clk, posedge reset) begin
    if ( reset == 1 ) begin
        rom <= NONE;
        pending_rom <= NONE;
    end else begin
        // default to not having any ROM selected
        rom <= NONE;

        // set the current ROM register when ROM data is not being downloaded
        if ( ioctl_download == 0 ) begin
            rom <= next_rom;
        end;

        // set the pending ROM register when a request is acknowledged (i.e.
        // a new request has been started)
        if ( sdram_ack == 1 ) begin
            pending_rom <= rom;
        end

        sdram_valid_reg <= sdram_valid;
    end
end

reg sdram_valid_reg;

   
// select cpu data input based on what is active
assign prog_rom_data_valid    = prog_rom_cs   & ( prog_rom_ctrl_hit   | (pending_rom == PROG_ROM   ? sdram_valid : 0) ) & ~reset;
assign text_rom_data_valid    = text_rom_cs   & ( text_rom_ctrl_hit   | (pending_rom == TEXT_ROM   ? sdram_valid : 0) ) & ~reset;
assign fg_rom_data_valid      = fg_rom_cs     & ( fg_rom_ctrl_hit     | (pending_rom == FG_ROM     ? sdram_valid : 0) ) & ~reset;
assign bg_rom_data_valid      = bg_rom_cs     & ( bg_rom_ctrl_hit     | (pending_rom == BG_ROM     ? sdram_valid : 0) ) & ~reset;
assign sprite_rom_data_valid  = sprite_rom_cs & ( sprite_rom_ctrl_hit | (pending_rom == SPRITE_ROM ? sdram_valid : 0) ) & ~reset;
assign sound_rom_data_valid   = sound_rom_cs  & ( sound_rom_ctrl_hit  | (pending_rom == SOUND_ROM  ? sdram_valid : 0) ) & ~reset;

always @ (*) begin

    // mux the next ROM in priority order

    next_rom <= NONE;  // default
    case (1)
        prog_rom_ctrl_req:      next_rom <= PROG_ROM;
        text_rom_ctrl_req:      next_rom <= TEXT_ROM;
        fg_rom_ctrl_req:        next_rom <= FG_ROM;
        bg_rom_ctrl_req:        next_rom <= BG_ROM;        
        sprite_rom_ctrl_req:    next_rom <= SPRITE_ROM;
        sound_rom_ctrl_req:     next_rom <= SOUND_ROM;
    endcase

    // route SDRAM acknowledge wire to the current ROM
    prog_rom_ctrl_ack <= 0;
    text_rom_ctrl_ack <= 0;
    fg_rom_ctrl_ack <= 0;
    bg_rom_ctrl_ack <= 0;
    sprite_rom_ctrl_ack <= 0;
    sound_rom_ctrl_ack <= 0;

    case (rom)
        PROG_ROM:       prog_rom_ctrl_ack <= sdram_ack;
        TEXT_ROM:       text_rom_ctrl_ack <= sdram_ack;
        FG_ROM:         fg_rom_ctrl_ack <= sdram_ack;
        BG_ROM:         bg_rom_ctrl_ack <= sdram_ack;
        SPRITE_ROM:     sprite_rom_ctrl_ack <= sdram_ack;
        SOUND_ROM:      sound_rom_ctrl_ack <= sdram_ack;
    endcase

    
    // route SDRAM valid wire to the pending ROM
    prog_rom_ctrl_valid  <= 0;
    text_rom_ctrl_valid  <= 0;
    fg_rom_ctrl_valid    <= 0;
    bg_rom_ctrl_valid    <= 0;
    sprite_rom_ctrl_valid  <= 0;
    sound_rom_ctrl_valid  <= 0;

    case (pending_rom)
        PROG_ROM:       prog_rom_ctrl_valid  <= sdram_valid;
        TEXT_ROM:       text_rom_ctrl_valid  <= sdram_valid;
        FG_ROM:         fg_rom_ctrl_valid    <= sdram_valid;
        BG_ROM:         bg_rom_ctrl_valid    <= sdram_valid;        
        SPRITE_ROM:     sprite_rom_ctrl_valid  <= sdram_valid;
        SOUND_ROM:      sound_rom_ctrl_valid  <= sdram_valid;
    endcase


    // mux ROM request
    ctrl_req <= prog_rom_ctrl_req |
                text_rom_ctrl_req |
                fg_rom_ctrl_req |
                bg_rom_ctrl_req |
                sound_rom_ctrl_req |
                sprite_rom_ctrl_req ;

     // mux SDRAM address in priority order
     sdram_addr <= 0;
     case (1)
        ioctl_download:         sdram_addr <= download_addr;
        prog_rom_ctrl_req:      sdram_addr <= prog_rom_ctrl_addr;
        text_rom_ctrl_req:      sdram_addr <= text_rom_ctrl_addr;
        fg_rom_ctrl_req:        sdram_addr <= fg_rom_ctrl_addr;
        bg_rom_ctrl_req:        sdram_addr <= bg_rom_ctrl_addr;
        sprite_rom_ctrl_req:    sdram_addr <= sprite_rom_ctrl_addr;
        sound_rom_ctrl_req:     sdram_addr <= sound_rom_ctrl_addr;
     endcase 
     
    // set SDRAM data input
    sdram_data <= download_data;
    // sdram_data <= download_addr;  poor man's testbench

    // set SDRAM request
    sdram_req <= (ioctl_download & download_req) | (!ioctl_download & ctrl_req);

    // enable writing to the SDRAM when downloading ROM data
    sdram_we <= ioctl_download & ( ioctl_index == 0 );

    // we need to divide the address by four, because we're converting from
    // a 8-bit IOCTL address to a 32-bit SDRAM address
    download_addr <= ioctl_addr[24:2];
end

endmodule 
