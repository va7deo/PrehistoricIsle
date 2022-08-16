//============================================================================
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//
//============================================================================

`default_nettype none

module emu
(
    //Master input clock
    input         CLK_50M,

    //Async reset from top-level module.
    //Can be used as initial reset.
    input         RESET,

    //Must be passed to hps_io module
    inout  [48:0] HPS_BUS,

    //Base video clock. Usually equals to CLK_SYS.
    output        CLK_VIDEO,

    //Multiple resolutions are supported using different CE_PIXEL rates.
    //Must be based on CLK_VIDEO
    output        CE_PIXEL,

    //Video aspect ratio for HDMI. Most retro systems have ratio 4:3.
    //if VIDEO_ARX[12] or VIDEO_ARY[12] is set then [11:0] contains scaled size instead of aspect ratio.
    output [12:0] VIDEO_ARX,
    output [12:0] VIDEO_ARY,

    output  [7:0] VGA_R,
    output  [7:0] VGA_G,
    output  [7:0] VGA_B,
    output        VGA_HS,
    output        VGA_VS,
    output        VGA_DE,    // = ~(VBlank | HBlank)
    output        VGA_F1,
    output [2:0]  VGA_SL,
    output        VGA_SCALER, // Force VGA scaler

    input  [11:0] HDMI_WIDTH,
    input  [11:0] HDMI_HEIGHT,
    output        HDMI_FREEZE,

`ifdef MISTER_FB
    // Use framebuffer in DDRAM (USE_FB=1 in qsf)
    // FB_FORMAT:
    //    [2:0] : 011=8bpp(palette) 100=16bpp 101=24bpp 110=32bpp
    //    [3]   : 0=16bits 565 1=16bits 1555
    //    [4]   : 0=RGB  1=BGR (for 16/24/32 modes)
    //
    // FB_STRIDE either 0 (rounded to 256 bytes) or multiple of pixel size (in bytes)
    output        FB_EN,
    output  [4:0] FB_FORMAT,
    output [11:0] FB_WIDTH,
    output [11:0] FB_HEIGHT,
    output [31:0] FB_BASE,
    output [13:0] FB_STRIDE,
    input         FB_VBL,
    input         FB_LL,
    output        FB_FORCE_BLANK,

`ifdef MISTER_FB_PALETTE
    // Palette control for 8bit modes.
    // Ignored for other video modes.
    output        FB_PAL_CLK,
    output  [7:0] FB_PAL_ADDR,
    output [23:0] FB_PAL_DOUT,
    input  [23:0] FB_PAL_DIN,
    output        FB_PAL_WR,
`endif
`endif

    output        LED_USER,  // 1 - ON, 0 - OFF.

    // b[1]: 0 - LED status is system status OR'd with b[0]
    //       1 - LED status is controled solely by b[0]
    // hint: supply 2'b00 to let the system control the LED.
    output  [1:0] LED_POWER,
    output  [1:0] LED_DISK,

    // I/O board button press simulation (active high)
    // b[1]: user button
    // b[0]: osd button
    output  [1:0] BUTTONS,

    input         CLK_AUDIO, // 24.576 MHz
    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,
    output        AUDIO_S,   // 1 - signed audio samples, 0 - unsigned
    output  [1:0] AUDIO_MIX, // 0 - no mix, 1 - 25%, 2 - 50%, 3 - 100% (mono)

    //ADC
    inout   [3:0] ADC_BUS,

    //SD-SPI
    output        SD_SCK,
    output        SD_MOSI,
    input         SD_MISO,
    output        SD_CS,
    input         SD_CD,

    //High latency DDR3 RAM interface
    //Use for non-critical time purposes
    output        DDRAM_CLK,
    input         DDRAM_BUSY,
    output  [7:0] DDRAM_BURSTCNT,
    output [28:0] DDRAM_ADDR,
    input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
    output        DDRAM_RD,
    output [63:0] DDRAM_DIN,
    output  [7:0] DDRAM_BE,
    output        DDRAM_WE,

    //SDRAM interface with lower latency
    output        SDRAM_CLK,
    output        SDRAM_CKE,
    output [12:0] SDRAM_A,
    output  [1:0] SDRAM_BA,
    inout  [15:0] SDRAM_DQ,
    output        SDRAM_DQML,
    output        SDRAM_DQMH,
    output        SDRAM_nCS,
    output        SDRAM_nCAS,
    output        SDRAM_nRAS,
    output        SDRAM_nWE,

`ifdef MISTER_DUAL_SDRAM
    //Secondary SDRAM
    //Set all output SDRAM_* signals to Z ASAP if SDRAM2_EN is 0
    input         SDRAM2_EN,
    output        SDRAM2_CLK,
    output [12:0] SDRAM2_A,
    output  [1:0] SDRAM2_BA,
    inout  [15:0] SDRAM2_DQ,
    output        SDRAM2_nCS,
    output        SDRAM2_nCAS,
    output        SDRAM2_nRAS,
    output        SDRAM2_nWE,
`endif

    input         UART_CTS,
    output        UART_RTS,
    input         UART_RXD,
    output        UART_TXD,
    output        UART_DTR,
    input         UART_DSR,

`ifdef MISTER_ENABLE_YC
	output [39:0] CHROMA_PHASE_INC,
	output        YC_EN,
	output        PALFLAG,
`endif
    
    // Open-drain User port.
    // 0 - D+/RX
    // 1 - D-/TX
    // 2..6 - USR2..USR6
    // Set USER_OUT to 1 to read from USER_IN.
    input   [6:0] USER_IN,
    output  [6:0] USER_OUT,

    input         OSD_STATUS
);

///////// Default values for ports not used in this core /////////

assign ADC_BUS  = 'Z;
assign USER_OUT = 0;
assign {UART_RTS, UART_TXD, UART_DTR} = 0;
assign {SD_SCK, SD_MOSI, SD_CS} = 'Z;
//assign {SDRAM_DQ, SDRAM_A, SDRAM_BA, SDRAM_CLK, SDRAM_CKE, SDRAM_DQML, SDRAM_DQMH, SDRAM_nWE, SDRAM_nCAS, SDRAM_nRAS, SDRAM_nCS} = 'Z;
//assign {DDRAM_CLK, DDRAM_BURSTCNT, DDRAM_ADDR, DDRAM_DIN, DDRAM_BE, DDRAM_RD, DDRAM_WE} = '0;  

assign VGA_F1 = 0;
assign VGA_SCALER = 0;
assign HDMI_FREEZE = 0;

assign AUDIO_MIX = 0;
assign LED_USER =  | sprite_ram_dout ;
assign LED_DISK = 0;
assign LED_POWER = 0;
assign BUTTONS = 0;

assign m68k_a[0] = 0;

// Status Bit Map:
//              Upper Case                     Lower Case           
// 0         1         2         3          4         5         6   
// 01234567890123456789012345678901 23456789012345678901234567890123
// 0123456789ABCDEFGHIJKLMNOPQRSTUV 0123456789ABCDEFGHIJKLMNOPQRSTUV
// X  XXXXXXX X        XXX XXXXXXXX    XXXXXX                       

wire [1:0]  aspect_ratio = status[9:8];
wire        orientation = ~status[3];
wire [2:0]  scan_lines = status[6:4];
wire [3:0]  hs_offset = status[27:24];
wire [3:0]  vs_offset = status[31:28];

wire gfx1_en = ~(status[37] | key_txt_enable);
wire gfx2_en = ~(status[38] | key_fg_enable );
wire gfx3_en = ~(status[39] | key_bg_enable);
wire gfx4_en = ~(status[40] | key_spr_enable);

assign VIDEO_ARX = (!aspect_ratio) ? (orientation  ? 8'd4 : 8'd3) : (aspect_ratio - 1'd1);
assign VIDEO_ARY = (!aspect_ratio) ? (orientation  ? 8'd3 : 8'd4) : 12'd0;

`include "build_id.v" 
localparam CONF_STR = {
    "Prehistoric Isle;;",
    "-;",
    "P1,Video Settings;",
    "P1-;",
    "P1O89,Aspect ratio,Original,Full Screen,[ARC1],[ARC2];",
    "P1O3,Orientation,Horz,Vert;",
    "P1-;",    
    "P1O46,Scandoubler Fx,None,HQ2x,CRT 25%,CRT 50%,CRT 75%,CRT 100%;",
    "P1OA,Force Scandoubler,Off,On;",
    "P1-;",
    "P1O7,Video Mode,NTSC,PAL;",
    "P1OM,Video Signal,RGBS/YPbPr,Y/C;",
    "P1-;",
    "P1OOR,H-sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1OSV,V-sync Adjust,0,1,2,3,4,5,6,7,-8,-7,-6,-5,-4,-3,-2,-1;",
    "P1-;",
    "P2,Pause Options;",
    "P2-;",
    "P2OK,Pause when OSD is open,Off,On;",
    "P2OL,Dim video after 10s,Off,On;",
    "-;",
    "P3,PCB & Debug Settings;",
    "P3-;",
    "P3OB,Turbo (Legion Sets),Off,On;",    
    "P3o3,Service Menu,Off,On;",
    "P3o4,Debug Menu,Off,On;",
    "P3-;",
    "P3o5,Text Layer,On,Off;",
    "P3o6,Foreground Layer,On,Off;",
    "P3o7,Background Layer,On,Off;",
    "P3o8,Sprite Layer,On,Off;",
    "P3-;",
    "DIP;",
    "-;",
    "R0,Reset;",
    "J1,Button 1,Button 2,Button 3,Start,Coin,Pause;",
    "jn,A,B,X,R,L,Start;",           // name mapping
    "V,v",`BUILD_DATE
};


wire hps_forced_scandoubler;
wire forced_scandoubler = hps_forced_scandoubler | status[10];

wire  [1:0] buttons;
wire [63:0] status;
wire [10:0] ps2_key;
wire [15:0] joy0, joy1;

hps_io #(.CONF_STR(CONF_STR)) hps_io
(
    .clk_sys(clk_sys),
    .HPS_BUS(HPS_BUS),

    .buttons(buttons),
    .ps2_key(ps2_key),
    .status(status),
    .status_menumask(direct_video),
    .forced_scandoubler(hps_forced_scandoubler),
    .gamma_bus(gamma_bus),
    .direct_video(direct_video),
    .video_rotated(video_rotated),
    
    .ioctl_download(ioctl_download),
    .ioctl_upload(ioctl_upload),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr),
    .ioctl_dout(ioctl_dout),
    .ioctl_din(ioctl_din),
    .ioctl_index(ioctl_index),
    .ioctl_wait(ioctl_wait),

    .joystick_0(joy0),
    .joystick_1(joy1)
);

// INPUT

// 8 dip switches of 8 bits
reg [7:0] sw[8];
always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==254) && !ioctl_addr[24:3]) begin
        sw[ioctl_addr[2:0]] <= ioctl_dout;
    end
end

wire        direct_video;

wire        ioctl_download;
wire        ioctl_upload;
wire        ioctl_upload_req;
wire        ioctl_wait;
wire        ioctl_wr;
wire  [7:0] ioctl_index;
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout;
wire  [7:0] ioctl_din;

reg   [3:0] pcb;

always @(posedge clk_sys) begin
    if (ioctl_wr && (ioctl_index==1)) begin
        pcb <= ioctl_dout;
    end
end

wire [21:0] gamma_bus;

//<buttons names="Fire,Jump,Start,Coin,Pause" default="A,B,R,L,Start" />
reg [15:0] p1 ;
reg [15:0] p2 ;
reg [15:0] dsw1 ;
reg [15:0] dsw2 ;
reg [15:0] coin ;
reg [15:0] sys ;

always @ (posedge clk_sys ) begin 
    p1 <= 16'hffff;
    p1[7:0] <= ~{ start1, p1_buttons[2:0], p1_right, p1_left ,p1_down, p1_up};
     
    p2 <= 16'hffff;
    p2[7:0] <= ~{ start2, p2_buttons[2:0], p2_right, p2_left ,p2_down, p2_up};
    
    dsw1 <=  { 8'hff, sw[0] };
    dsw2 <=  { 8'hff, ~vbl, sw[1][6:0] };
    coin <=  { 14'hffff, coin_b, coin_a };
end

wire        p1_right   = joy0[0] | key_p1_right;
wire        p1_left    = joy0[1] | key_p1_left;
wire        p1_down    = joy0[2] | key_p1_down;
wire        p1_up      = joy0[3] | key_p1_up;
wire [3:0]  p1_buttons = joy0[7:4] | {key_p1_d, key_p1_c, key_p1_b, key_p1_a};

wire        p2_right   = joy1[0] | key_p2_right;
wire        p2_left    = joy1[1] | key_p2_left;
wire        p2_down    = joy1[2] | key_p2_down;
wire        p2_up      = joy1[3] | key_p2_up | status[36];
wire [3:0]  p2_buttons = joy1[7:4] | {key_p2_d, key_p2_c, key_p2_b | status[36], key_p2_a | status[36]};

wire        start1  = joy0[8]  | joy1[8]  | key_start_1p;
wire        start2  = joy0[9]  | joy1[9]  | key_start_2p | status[11];
wire        coin_a  = joy0[10] | joy1[10] | key_coin_a;
wire        coin_b  = joy0[11] | joy1[11] | key_coin_b;
wire        b_pause = joy0[12] | key_pause ;

// Keyboard handler

wire key_start_1p, key_start_2p, key_coin_a, key_coin_b;
wire key_test, key_reset, key_service, key_pause;
wire key_txt_enable, key_fg_enable, key_bg_enable, key_spr_enable;

wire key_p1_up, key_p1_left, key_p1_down, key_p1_right, key_p1_a, key_p1_b, key_p1_c, key_p1_d;
wire key_p2_up, key_p2_left, key_p2_down, key_p2_right, key_p2_a, key_p2_b, key_p2_c, key_p2_d;

wire pressed = ps2_key[9];

always @(posedge clk_sys) begin 
    reg old_state;

    old_state <= ps2_key[10];
    if(old_state ^ ps2_key[10]) begin
        casex(ps2_key[8:0])
            'h016: key_start_1p   <= pressed; // 1
            'h01e: key_start_2p   <= pressed; // 2
            'h02E: key_coin_a     <= pressed; // 5
            'h036: key_coin_b     <= pressed; // 6
            'h006: key_test       <= key_test ^ pressed; // f2
            'h004: key_reset      <= pressed; // f3
            'h046: key_service    <= pressed; // 9
            'h04D: key_pause      <= pressed; // p

            'hX75: key_p1_up      <= pressed; // up
            'hX72: key_p1_down    <= pressed; // down
            'hX6b: key_p1_left    <= pressed; // left
            'hX74: key_p1_right   <= pressed; // right
            'h014: key_p1_a       <= pressed; // lctrl
            'h011: key_p1_b       <= pressed; // lalt
            'h029: key_p1_c       <= pressed; // spacebar
            'h012: key_p1_d       <= pressed; // lshift

            'h02d: key_p2_up      <= pressed; // r
            'h02b: key_p2_down    <= pressed; // f
            'h023: key_p2_left    <= pressed; // d
            'h034: key_p2_right   <= pressed; // g
            'h01c: key_p2_a       <= pressed; // a
            'h01b: key_p2_b       <= pressed; // s
            'h015: key_p2_c       <= pressed; // q
            'h01d: key_p2_d       <= pressed; // w

            'h083: key_txt_enable <= key_txt_enable ^ pressed; // f7
            'h00A: key_bg_enable  <= key_bg_enable  ^ pressed; // f8
            'h001: key_fg_enable  <= key_fg_enable  ^ pressed; // f9
            'h009: key_spr_enable <= key_spr_enable ^ pressed; // f10
        endcase
    end
end



reg user_flip;

wire pll_locked;

wire clk_sys;
reg  clk_6M,clk_9M,clk_18M;

wire clk_72M;

pll pll
(
    .refclk(CLK_50M),
    .rst(0),
    .outclk_0(clk_sys),    
    .outclk_1(clk_72M),
    .locked(pll_locked)
);

assign    SDRAM_CLK = clk_72M;

localparam  CLKSYS=72;

reg [5:0] clk18_count;
reg [5:0] clk9_count;
reg [5:0] clk6_count;
reg [15:0] clk_ym_count;


always @ (posedge clk_sys) begin

    clk_6M <= ( clk6_count == 0 );

    if ( clk6_count == 11 ) begin
        clk6_count <= 0;
    end else begin
        clk6_count <= clk6_count + 1;
    end
    
    clk_18M <= ( clk18_count == 0 );

    if ( clk18_count == 3 ) begin
        clk18_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk18_count <= clk18_count + 1;
    end

    clk_9M <= ( clk9_count == 0 );

    if ( clk9_count == 7 ) begin
        clk9_count <= 0;
    end else if ( pause_cpu == 0 ) begin
        clk9_count <= clk9_count + 1;
    end
    
end

wire    reset;
assign  reset = RESET | ioctl_download | key_reset | status[0] ; 

//////////////////////////////////////////////////////////////////
wire rotate_ccw = 1;
wire no_rotate = orientation | direct_video;
wire video_rotated ;
wire flip = 0;

reg [23:0]     rgb;

wire hbl;
wire vbl;

wire [8:0] hc;
wire [8:0] vc;

wire hsync;
wire vsync;

wire hbl_delay, vbl_delay;

assign hbl_delay = hbl ;
assign vbl_delay = vbl ;

video_timing video_timing (
    .clk(clk_6M),
    .clk_pix(1'b1),
    .pcb(pcb),
    .hc(hc),
    .vc(vc),
    .hs_offset(hs_offset),
    .vs_offset(vs_offset),
    .hbl(hbl),
    .vbl(vbl),
    .hsync(hsync),
    .vsync(vsync)
);

// PAUSE SYSTEM
wire    pause_cpu;
wire    hs_pause;

// 8 bits per colour, 72MHz sys clk
pause #(8,8,8,72) pause 
(
    .clk_sys(clk_sys),
    .reset(reset),
    .user_button(b_pause),
    .pause_request(hs_pause),
    .options(status[21:20]),
    .pause_cpu(pause_cpu),
    .dim_video(dim_video),
    .OSD_STATUS(OSD_STATUS),
    .r(rgb[23:16]),
    .g(rgb[15:8]),
    .b(rgb[7:0]),
    .rgb_out(rgb_pause_out)
);

wire [23:0] rgb_pause_out;
wire dim_video;

arcade_video #(256,24) arcade_video
(
        .*,

        .clk_video(clk_sys),
        .ce_pix(clk_6M),

        .RGB_in(rgb_pause_out),

        .HBlank(hbl_delay),
        .VBlank(vbl_delay),
        .HSync(hsync),
        .VSync(vsync),

        .fx(scan_lines)
);

/*     Phase Accumulator Increments (Fractional Size 32, look up size 8 bit, total 40 bits)
    Increment Calculation - (Output Clock * 2 ^ Word Size) / Reference Clock
    Example
    NTSC = 3.579545
    PAL =  4.43361875
    W = 40 ( 32 bit fraction, 8 bit look up reference)
    Ref CLK = 42.954544 (This could us any clock)
    NTSC_Inc = 3.579545333 * 2 ^ 40 / 96 = 40997413706
    
*/


// SET PAL and NTSC TIMING
`ifdef MISTER_ENABLE_YC
    assign CHROMA_PHASE_INC = PALFLAG ? 40'd67705769163: 40'd54663218274 ;
    assign YC_EN =  status[22];
    assign PALFLAG = status[7];
`endif

screen_rotate screen_rotate (.*);



//    .address_a ( bg_tilemap_addr[15:0] ),
//    .q_a ( bg_tilemap_dout[7:0] )


reg [3:0] txt_pix ;
reg [3:0] bg_pix ;

reg [7:0] hc_del;

wire [11:0] pal  [0:15] = '{12'h000,12'hbbb,12'hc00,12'h0c0,12'h00c,12'hc30,12'hcc0,12'h08c,12'hc60,12'hc80,12'hcc0,12'hc30,12'h0c6,12'h07c,12'hc57,12'h666};
wire [11:0] pal2 [0:15] = '{12'ha00,12'hc11,12'he42,12'hf74,12'h121,12'h242,12'h362,12'h583,12'h694,12'h9b5,12'h100,12'hcd7,12'hee9,12'h400,12'hfff,12'h000};
wire [11:0] pal3 [0:15] = '{12'h541,12'h975,12'h482,12'h251,12'h121,12'h6ed,12'h0cb,12'h0a9,12'h087,12'h065,12'h9cf,12'h6ae,12'h38d,12'h06c,12'h04b,12'h000};
// 0xffaa0000,0xffcc1111,0xffee4422,0xffff7744,0xff112211,0xff224422,0xff336622,0xff558833,0xff669944,0xff99bb55,0xff110000,0xffccdd77,0xffeeee99,0xff440000,0xffffffff,0xff000000

reg [4:0] tile_state;
reg [4:0] sprite_state;
reg [8:0] sprite_num;

reg  [8:0] x;
wire [8:0] tx_x = x ;
wire [8:0] tx_y = vc ;

reg   [2:0] pri_buf[0:255];
 
reg  [31:0] pix_data;
reg  [31:0] spr_pix_data;

wire [13:0] fg_x = x  + fg_scroll_x ;
wire  [8:0] fg_y = vc + fg_scroll_y ;

wire [13:0] bg_x = x  + bg_scroll_x ;
wire  [8:0] bg_y = vc + bg_scroll_y ;

wire  [9:0] txt_tile = { vc[7:3], hc[7:3] };
wire [14:0] fg_tile  = { fg_x[11:4], fg_y[8:4] } ; 
wire [14:0] bg_tile  = { bg_x[13:4], bg_y[8:4] } ; 

reg [3:0] sprite_colour;

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
        tile_state <= 0;
    end else begin
    
        // tiles
        
        if ( tile_state == 0 && hc == 0 ) begin
            tile_state <= 1;
            x <= 0;
        end else if ( tile_state == 1) begin
            line_buf_tx_w <= 0;
            txt_ram_addr <= { tx_y[7:3], tx_x[7:3] }; 
            tile_state <= 2;
        end else if ( tile_state == 2) begin  
            // address is valid - need more more cycle to read 
            tile_state <= 3;
        end else if ( tile_state == 3) begin  
            txt_rom_addr <= { txt_ram_dout[11:0], vc[2:0] } ;
            txt_rom_cs <= 1;
            tile_state <= 4;
        end else if ( tile_state == 4) begin             
            // address is valid - need more more cycle to read 
            tile_state <= 5;
        end else if ( tile_state == 5) begin              
            if ( txt_rom_valid == 1 ) begin
                txt_rom_cs <= 0;
                pix_data <= txt_rom_data;
                tile_state <= 6 ;
            end
        end else if ( tile_state == 6) begin 
            pri_buf[x] <= 1;
            line_buf_addr_w <= { vc[0], x[8:0] };
            line_buf_tx_w <= 1;
            case ( x[2:0] )
                0: line_buf_din <= { txt_ram_dout[15:12], pix_data[31:28] }; 
                1: line_buf_din <= { txt_ram_dout[15:12], pix_data[27:24] }; 
                2: line_buf_din <= { txt_ram_dout[15:12], pix_data[23:20] }; 
                3: line_buf_din <= { txt_ram_dout[15:12], pix_data[19:16] }; 
                4: line_buf_din <= { txt_ram_dout[15:12], pix_data[15:12] }; 
                5: line_buf_din <= { txt_ram_dout[15:12], pix_data[11:8] }; 
                6: line_buf_din <= { txt_ram_dout[15:12], pix_data[7:4] }; 
                7: line_buf_din <= { txt_ram_dout[15:12], pix_data[3:0] }; 
            endcase
            if ( x < 255 ) begin
                if ( x[2:0] == 3'b111 ) begin
                    tile_state <= 1;
                end
                x <= x + 1;
            end else begin
                tile_state <= 7;
            end
        end else if ( tile_state == 7) begin             
            line_buf_tx_w <= 0;
            x <= 0;
            tile_state <= 11;

        // fg
        end else if ( tile_state == 11) begin             
            line_buf_fg_w <= 0;
            fg_ram_addr <= fg_tile ; 
            tile_state <= 12;
        end else if ( tile_state == 12) begin  
            // address is valid - need more more cycle to read 
            tile_state <= 13;
        end else if ( tile_state == 13) begin  
            fg_rom_addr <= { fg_ram_dout[10:0], fg_x[3], { 4 { fg_ram_dout[11] } } ^ fg_y[3:0] } ;
            fg_rom_cs <= 1;
            tile_state <= 14;
        end else if ( tile_state == 14) begin  
            // address is valid - need more more cycle to read 
            tile_state <= 15;
        end else if ( tile_state == 15) begin              
            if ( fg_rom_valid == 1 ) begin
                fg_rom_cs <= 0;
                pix_data <= fg_rom_data;
                tile_state <= 16 ;
            end
        end else if ( tile_state == 16) begin 
            line_buf_addr_w <= { vc[0], x[8:0] }; 
            line_buf_fg_w <= 1;
            case ( fg_x[2:0] ) // case ( x[2:0] )
                0: line_buf_din <= { fg_ram_dout[15:12], pix_data[31:28] }; 
                1: line_buf_din <= { fg_ram_dout[15:12], pix_data[27:24] }; 
                2: line_buf_din <= { fg_ram_dout[15:12], pix_data[23:20] }; 
                3: line_buf_din <= { fg_ram_dout[15:12], pix_data[19:16] }; 
                4: line_buf_din <= { fg_ram_dout[15:12], pix_data[15:12] }; 
                5: line_buf_din <= { fg_ram_dout[15:12], pix_data[11:8] }; 
                6: line_buf_din <= { fg_ram_dout[15:12], pix_data[7:4] }; 
                7: line_buf_din <= { fg_ram_dout[15:12], pix_data[3:0] }; 
            endcase
            if ( x < 255 ) begin
                if ( fg_x[2:0] == 3'b111 ) begin // if ( x[2:0] == 3'b111 ) begin
                    tile_state <= 11;
                end
                x <= x + 1;
            end else begin
                tile_state <= 17;
            end
        end else if ( tile_state == 17) begin   
            line_buf_fg_w <= 0;
            tile_state <= 21;    
            x <= 0;  
        // bg

        end else if ( tile_state == 21) begin             
            line_buf_bg_w <= 0;
            tilemap_rom_addr <= bg_tile ; 
            tile_state <= 22;
        end else if ( tile_state == 22) begin  
            // address is valid - need more more cycle to read 
            tile_state <= 23;
        end else if ( tile_state == 23) begin  
            bg_rom_addr <= { tilemap_rom_data[10:0], tilemap_rom_data[11] ^ bg_x[3], bg_y[3:0] } ;
            bg_rom_cs <= 1;
            tile_state <= 24;
        end else if ( tile_state == 24) begin  
            // address is valid - need more more cycle to read 
            tile_state <= 25;
        end else if ( tile_state == 25) begin              
            if ( bg_rom_valid == 1 ) begin
                bg_rom_cs <= 0;
                pix_data <= bg_rom_data;
                tile_state <= 26 ;
            end
        end else if ( tile_state == 26) begin 
            line_buf_addr_w <= { vc[0], x[8:0] };
            line_buf_bg_w <= 1;
            case ( { 3 { tilemap_rom_data[11] } } ^ bg_x[2:0] ) // case ( x[2:0] )
                0: line_buf_din <= { tilemap_rom_data[15:12], pix_data[31:28] }; 
                1: line_buf_din <= { tilemap_rom_data[15:12], pix_data[27:24] }; 
                2: line_buf_din <= { tilemap_rom_data[15:12], pix_data[23:20] }; 
                3: line_buf_din <= { tilemap_rom_data[15:12], pix_data[19:16] }; 
                4: line_buf_din <= { tilemap_rom_data[15:12], pix_data[15:12] }; 
                5: line_buf_din <= { tilemap_rom_data[15:12], pix_data[11:8] }; 
                6: line_buf_din <= { tilemap_rom_data[15:12], pix_data[7:4] }; 
                7: line_buf_din <= { tilemap_rom_data[15:12], pix_data[3:0] }; 
            endcase
            if ( x < 255 ) begin
                if ( bg_x[2:0] == 3'b111 ) begin // if ( x[2:0] == 3'b111 ) begin
                    tile_state <= 21;
                end
                x <= x + 1;
            end else begin
                tile_state <= 27;
            end
        end else if ( tile_state == 27) begin   
            line_buf_bg_w <= 0;
            tile_state <= 0;      
            
        end
        
        // sprites
        
        if ( sprite_state == 0 && hc == 0 ) begin
            sprite_state <= 21;
            sprite_num <= 0;
            // setup clearing line buffer
            spr_buf_din <= 15 ;
            spr_x_pos <= 0;
        end else if ( sprite_state == 21 )  begin  
            spr_buf_w <= 1 ;
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            if ( spr_x_pos == 255 ) begin
                spr_buf_w <= 0 ;
                sprite_state <= 22;
            end
            spr_x_pos <= spr_x_pos + 1;
        end else if ( sprite_state == 22 )  begin            
            sprite_state <= 1;
        end else if ( sprite_state == 1 )  begin
            spr_buf_w <= 0 ;
            sprite_ram_addr <= { sprite_num, 2'b0 } ; // y 
            sprite_state <= 2;
        end else if ( sprite_state == 2 )  begin
            // address valid read y
            sprite_state <= 3;
        end else if ( sprite_state == 3 )  begin
            // y valid
            if ( vc >= sprite_y && vc < ( sprite_y + 16 ) ) begin
                spr_y_ofs <= vc - sprite_y ;
                // setup to read x
                sprite_ram_addr <= sprite_ram_addr + 1 ;
                sprite_state <= 4;
            end else begin
                sprite_state <= 31;
            end
        end else if ( sprite_state == 4 ) begin
            // x address valid 
            sprite_state <= 5;
        end else if ( sprite_state == 5 ) begin
            // x value valid 
            if ( sprite_ram_dout[7:0] < 8'hff ) begin
                spr_x_ofs <= 0 ;
                spr_x_pos <= sprite_ram_dout[8:0] ;
                // read attribute / tile index
                sprite_ram_addr <= sprite_ram_addr + 1 ;
                
                sprite_state <= 6;
            end else begin
                sprite_state <= 31;
            end
        end else if ( sprite_state == 6 ) begin
            // attribute address valid
            sprite_state <= 7;
        end else if ( sprite_state == 7 ) begin
            // attribute data valid
            spr_tile_num <= sprite_ram_dout[12:0] ;
            spr_flip_x <= sprite_ram_dout[14];
            spr_flip_y <= sprite_ram_dout[15];
            
            sprite_ram_addr <= sprite_ram_addr + 1 ;
            
            sprite_state <= 8;
        end else if ( sprite_state == 8 ) begin    
            sprite_rom_addr <= { spr_tile_num, spr_flip_x ^ spr_x_ofs[3], { 4 {spr_flip_y} } ^ spr_y_ofs[3:0] } ;
            sprite_rom_cs <= 1;
            sprite_state <= 9;
        end else if ( sprite_state == 9 ) begin  
            sprite_colour <= sprite_ram_dout[15:12];
            // wait for sprite bitmap data
            if ( sprite_rom_valid == 1 ) begin
                sprite_rom_cs <= 0;
                spr_pix_data <= sprite_rom_data;
                sprite_state <= 10 ;
            end
        end else if ( sprite_state == 10 ) begin                    
            spr_buf_addr_w <= { vc[0], spr_x_pos };
            case ( { 3 { spr_flip_x } } ^ spr_x_ofs[2:0] ) // case ( x[2:0] )
            //case ( spr_x_ofs[2:0] ) // case ( x[2:0] )
                0: spr_buf_din <= { sprite_colour, spr_pix_data[31:28] }; 
                1: spr_buf_din <= { sprite_colour, spr_pix_data[27:24] }; 
                2: spr_buf_din <= { sprite_colour, spr_pix_data[23:20] }; 
                3: spr_buf_din <= { sprite_colour, spr_pix_data[19:16] }; 
                4: spr_buf_din <= { sprite_colour, spr_pix_data[15:12] }; 
                5: spr_buf_din <= { sprite_colour, spr_pix_data[11:8] }; 
                6: spr_buf_din <= { sprite_colour, spr_pix_data[7:4] }; 
                7: spr_buf_din <= { sprite_colour, spr_pix_data[3:0] }; 
            endcase 
            sprite_state <= 16;
        end else if ( sprite_state == 16 ) begin
              spr_buf_w <= ( spr_buf_din[3:0] < 15 );
//            spr_buf_addr_w <= { vc[0], spr_x_pos };
            if ( spr_x_ofs < 16 ) begin
//                spr_buf_din <= 1 ;
//                spr_buf_w <= 1 ;
                sprite_state <= 17;
            end else begin
                spr_buf_w <= 0;
                sprite_state <= 31;
            end
        end else if ( sprite_state == 17 ) begin
            spr_x_ofs <= spr_x_ofs + 1 ;
            spr_x_pos <= spr_x_pos + 1 ;
            sprite_state <= 8;
        end else if ( sprite_state == 31 ) begin
//            spr_buf_w <= 0;
            if ( sprite_num < 256 ) begin
                // next sprite
                sprite_num <= sprite_num + 1 ;
                sprite_state <= 1;
            end else begin
                // done.
                sprite_state <= 0;
            end
        end
   
    end
end

wire [8:0] sprite_y =  sprite_ram_dout[8:0]  ; // { 8 {sprite_ram_dout[8]} } ^
reg  [3:0] spr_y_ofs ;

reg  [8:0]  spr_x_ofs;
reg  [8:0]  spr_x_pos;
reg [12:0]  spr_tile_num;
reg         spr_flip_x;
reg         spr_flip_y;

//int16_t sy = spriteram16[offs] & 0x1ff;
//int16_t sx = spriteram16[offs + 1] & 0x1ff;
//uint16_t const attr = spriteram16[offs + 2];
//uint16_t const color = spriteram16[offs + 3] >> 12;
//uint16_t const code = attr & 0x1fff;
//uint32_t const priority = GFX_PMASK_4 | ((color < 0x4) ? 0 : GFX_PMASK_2); // correct?
//bool flipx = attr & 0x4000;
//bool flipy = attr & 0x8000;
        
// sprite addr 0 - 3ff
// sprite num 0 - ff
//reg  [10:0] sprite_ram_addr;
//wire [15:0] sprite_ram_dout;

//reg   [9:0]  spr_buf_addr_w;
//reg          spr_buf_w;
//reg   [7:0]  spr_buf_din;
//wire  [7:0]  spr_buf_dout;

reg [7:0] tx;
reg [7:0] fg;
reg [7:0] bg;
reg [7:0] sp;

reg [23:0] rgb_tx;
reg [23:0] rgb_fg;
reg [23:0] rgb_bg;
reg [23:0] rgb_sp;

//always @ (posedge clk_sys) begin
//    if ( reset == 1 ) begin
//    end else if ( clk_6M == 1 ) begin
//        if ( hc < 256 ) begin
//            line_buf_addr_r <= { ~vc[0], hc[8:0] };
//
//            tx <= line_buf_tx_out[3:0] ;
//            fg <= line_buf_fg_out[3:0] ;
//            bg <= line_buf_bg_out[3:0] ;
//            
//            rgb <= { pal3[bg][11:8],4'h0,pal3[bg][7:4],4'h0,pal3[bg][3:0],4'h0 };
//
//            if ( fg < 15 ) begin
//                rgb <= { pal2[fg][11:8],4'h0,pal2[fg][7:4],4'h0,pal2[fg][3:0],4'h0 };
//            end
//            
//            if ( tx < 15 ) begin
//                rgb <= { pal[tx][11:8],4'h0,pal[tx][7:4],4'h0,pal[tx][3:0],4'h0 };
//            end
//        end
//    end
//end

always @ (posedge clk_sys) begin
    if ( reset == 1 ) begin
    end else begin
        if ( hc < 256 ) begin
            if ( clk6_count == 1 ) begin
                line_buf_addr_r <= { ~vc[0], hc[8:0] };
            end else if ( clk6_count == 2 ) begin
                tx <= line_buf_tx_out[7:0] ;
                fg <= line_buf_fg_out[7:0] ;
                bg <= line_buf_bg_out[7:0] ;
                sp <= spr_buf_dout[7:0] ;
            end else if ( clk6_count == 3 ) begin                
                tile_pal_addr <= 12'd768 + bg ;
            end else if ( clk6_count == 5 ) begin                
                rgb_bg <= { tile_pal_dout[15:12],4'h0,tile_pal_dout[11:8],4'h0,tile_pal_dout[7:4],4'h0 };
                tile_pal_addr <= 12'd512 + fg ;
            end else if ( clk6_count == 7 ) begin                
                rgb_fg <= { tile_pal_dout[15:12],4'h0,tile_pal_dout[11:8],4'h0,tile_pal_dout[7:4],4'h0 };
                tile_pal_addr <= tx ;
            end else if ( clk6_count == 9 ) begin                
                rgb_tx <= { tile_pal_dout[15:12],4'h0,tile_pal_dout[11:8],4'h0,tile_pal_dout[7:4],4'h0 };
                tile_pal_addr <= 12'd256 + sp ;
            end else if ( clk6_count == 11 ) begin                
                rgb_sp <= { tile_pal_dout[15:12],4'h0,tile_pal_dout[11:8],4'h0,tile_pal_dout[7:4],4'h0 };
            end else if ( clk6_count == 0  ) begin                                
                rgb <= rgb_bg;
                if ( fg[3:0] < 15 ) begin
                    rgb <= rgb_fg;
                end
                if ( sp[3:0] < 15 ) begin
                    rgb <= rgb_sp;
                end
                if ( tx[3:0] < 15 ) begin
                    rgb <= rgb_tx;
                end
            end
            
        end
    end
end


/// 68k cpu

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        m68k_dtack_n <= 1;
        
//    end else if ( clk_8M == 1 ) begin
    end else if ( clk_18M == 1 ) begin
        // tell 68k to wait for valid data. 0=ready 1=wait
        // always ack when it's not program rom
        m68k_dtack_n <= m68k_rom_cs ? !m68k_rom_valid : 
                        0; 

        // select cpu data input based on what is active 
        m68k_din <=  m68k_rom_cs  ? m68k_rom_data :
                     m68k_ram_cs  ? m68k_ram_dout :
                     m68k_txt_ram_cs ? m68k_txt_ram_dout :
                     m68k_spr_cs  ? m68k_sprite_dout :
                     m68k_fg_ram_cs ? m68k_fg_ram_dout :
                     m68k_pal_cs ? m68k_pal_dout :
                     input_p1_cs ? p1 :
                     input_p2_cs ? p2 :
                     input_dsw1_cs ? dsw1 :
                     input_dsw2_cs ? dsw2 :
                     input_coin_cs ? coin :
                     16'd0;
                     
        // write asserted and rising cpu clock
        if ( m68k_rw == 0 ) begin        

            if ( fg_scroll_x_cs == 1 ) begin
                fg_scroll_x <= m68k_dout;
            end                     
            if ( fg_scroll_y_cs == 1 ) begin
                fg_scroll_y <= m68k_dout;
            end  
            
            if ( bg_scroll_x_cs == 1 ) begin
                bg_scroll_x <= m68k_dout;
            end                     
            if ( bg_scroll_y_cs == 1 ) begin
                bg_scroll_y <= m68k_dout;
            end                     
        end         
    end
end 



 
wire    m68k_rom_cs;
wire    m68k_ram_cs;
wire    m68k_pal_cs;
wire    m68k_txt_ram_cs;
wire    m68k_spr_cs;
wire    m68k_fg_ram_cs;
wire    m68k_bg_ram_cs;
wire    input_p1_cs;
wire    input_p2_cs;
wire    input_coin_cs;
wire    input_dsw1_cs;
wire    input_dsw2_cs;
wire    irq_z80_cs;
wire    bg_scroll_x_cs;
wire    bg_scroll_y_cs;
wire    fg_scroll_x_cs;
wire    fg_scroll_y_cs;
wire    sound_latch_cs;

wire    z80_rom_cs;
wire    z80_ram_cs;
wire    z80_latch_cs;
wire    z80_sound0_cs;
wire    z80_sound1_cs;
wire    z80_upd_cs;
wire    z80_upd_r_cs;
    
chip_select cs (
    .clk(clk_sys),
    .pcb(pcb),

    // 68k bus
    .m68k_a(m68k_a),
    .m68k_as_n(m68k_as_n),

    // 68k chip selects
    .m68k_rom_cs,
    .m68k_ram_cs,
    .m68k_txt_ram_cs,
    .m68k_spr_cs,
    .m68k_fg_ram_cs,
    .m68k_pal_cs,

    .input_p2_cs,
    .input_coin_cs,
    .input_p1_cs,
    .input_dsw1_cs,
    .input_dsw2_cs,

    .fg_scroll_y_cs,
    .fg_scroll_x_cs,
    .bg_scroll_y_cs,
    .bg_scroll_x_cs,

    .sound_latch_cs,
    
    // z80 

    .z80_rom_cs,
    .z80_ram_cs,
    .z80_latch_cs,
    .z80_sound0_cs,
    .z80_sound1_cs,
    .z80_upd_cs,
    .z80_upd_r_cs

);
 
reg [15:0] bg_scroll_x;
reg [15:0] bg_scroll_y;

reg [15:0] fg_scroll_x;
reg [15:0] fg_scroll_y;

reg [7:0]  sound_latch;

// CPU outputs
wire m68k_rw         ;    // Read = 1, Write = 0
wire m68k_as_n       ;    // Address strobe
wire m68k_lds_n      ;    // Lower byte strobe
wire m68k_uds_n      ;    // Upper byte strobe
wire m68k_E;         
wire [2:0] m68k_fc    ;   // Processor state
wire m68k_reset_n_o  ;    // Reset output signal
wire m68k_halted_n   ;    // Halt output

// CPU busses
wire [15:0] m68k_dout       ;
wire [23:0] m68k_a   /* synthesis keep */       ;
reg  [15:0] m68k_din        ;   
//assign m68k_a[0] = 1'b0;

// CPU inputs
reg  m68k_dtack_n ;         // Data transfer ack (always ready)
reg  m68k_ipl2_n ;

wire m68k_vpa_n = ~int_ack;//( m68k_lds_n == 0 && m68k_fc == 3'b111 ); // int ack

reg int_ack ;
reg [1:0] vbl_sr;

// vblank handling 
// process interrupt and sprite buffering
always @ (posedge clk_sys ) begin
    if ( reset == 1 ) begin
        m68k_ipl2_n <= 1 ;
        int_ack <= 0;
    end else begin
        vbl_sr <= { vbl_sr[0], vbl };

        if ( clk_18M == 1 ) begin
            int_ack <= ( m68k_as_n == 0 ) && ( m68k_fc == 3'b111 ); // cpu acknowledged the interrupt
        end

        if ( vbl_sr == 2'b01 ) begin // rising edge
            // trigger sprite buffer copy
            //  68k vbl interrupt
            m68k_ipl2_n <= 0;
        end else if ( int_ack == 1 || vbl_sr == 2'b10 ) begin
            // deassert interrupt since 68k ack'ed.
            m68k_ipl2_n <= 1 ;
        end
    end
end    

wire reset_n;

reg bg_enable;
reg fg_enable;
reg tx_enable;
reg sp_enable;

// fx68k clock generation
reg fx68_phi1;

always @(posedge clk_sys) begin
    if ( clk_18M == 1 ) begin
        fx68_phi1 <= ~fx68_phi1;
    end
end

fx68k fx68k (
    // input
    .clk( clk_18M ),
    .enPhi1(fx68_phi1),
    .enPhi2(~fx68_phi1),

    .extReset(reset),
    .pwrUp(reset),

    // output
    .eRWn(m68k_rw),
    .ASn(m68k_as_n),
    .LDSn(m68k_lds_n),
    .UDSn(m68k_uds_n),
    .E(),
    .VMAn(),
    .FC0(m68k_fc[0]),
    .FC1(m68k_fc[1]),
    .FC2(m68k_fc[2]),
    .BGn(),
    .oRESETn(m68k_reset_n_o),
    .oHALTEDn(m68k_halted_n),

    // input
    .VPAn( m68k_vpa_n ),  
    .DTACKn( m68k_dtack_n ),     
    .BERRn(1'b1), 
    .BRn(1'b1),  
    .BGACKn(1'b1),
    
    .IPL0n(1'b1),
    .IPL1n(1'b1),
    .IPL2n(m68k_ipl2_n),

    // busses
    .iEdb(m68k_din),
    .oEdb(m68k_dout),
    .eab(m68k_a[23:1])
);


// z80 audio 
wire    [7:0] z80_rom_data;
wire    [7:0] z80_ram_data;

wire   [15:0] z80_addr;
reg     [7:0] z80_din;
wire    [7:0] z80_dout;

wire z80_wr_n;
wire z80_rd_n;
reg  z80_wait_n;
reg  z80_irq_n;

wire IORQ_n;
wire MREQ_n;
wire M1_n;

T80pa z80 (
    .RESET_n    ( ~reset ),
    .CLK        ( clk_sys ),
    .CEN_p      ( clk_6M ),
    .CEN_n      ( ~clk_6M ),
    .WAIT_n     ( z80_wait_n ), 
    .INT_n      ( z80_irq_n ),  
    .NMI_n      ( 1'b1 ),
    .BUSRQ_n    ( 1'b1 ),
    .RD_n       ( z80_rd_n ),
    .WR_n       ( z80_wr_n ),
    .A          ( z80_addr ),
    .DI         ( z80_din  ),
    .DO         ( z80_dout ),
    // unused
    .DIRSET     ( 1'b0     ),
    .DIR        ( 212'b0   ),
    .OUT0       ( 1'b0     ),
    .RFSH_n     (),
    .IORQ_n     ( IORQ_n ),
    .M1_n       ( M1_n ), // for interrupt ack
    .BUSAK_n    (),
    .HALT_n     ( 1'b1 ),
    .MREQ_n     ( MREQ_n ),
    .Stop       (),
    .REG        ()
);

always @ (posedge clk_sys) begin

    if ( reset == 1 ) begin
        
    end else if ( clk_6M == 1 ) begin
        if ( z80_rom_cs == 1 ) begin
            z80_din <= z80_rom_data ;
        end                     
        if ( z80_ram_cs == 1 ) begin
            z80_din <= z80_ram_data ;
        end  

        if ( z80_latch_cs == 1 ) begin
            z80_din <= sound_latch ;
        end  
        
        sound_wr <= 0 ;
        if ( z80_wr_n == 0 ) begin 
            if ( z80_sound0_cs == 1 || z80_sound1_cs == 1) begin    
                sound_data  <= z80_dout;
                sound_addr <= z80_sound1_cs ; 
                sound_wr <= 1;
            end 
        end        
    end
end 

reg sound_addr ;
reg  [7:0] sound_data ;

// sound ic write enable
reg sound_wr;

wire [7:0] opl_dout;
wire opl_irq_n;

reg signed [15:0] sample;

assign AUDIO_S = 1'b1 ;

wire opl_sample_clk;

// 3.579 MHz

jtopl #(.OPL_TYPE(2)) opl
(
    .rst(reset),
    .clk(clk_6M),
    .cen(1'b1),
    .din(sound_data),
    .addr(sound_addr),
    .cs_n(~( z80_sound0_cs | z80_sound1_cs )),
    .wr_n(~sound_wr),
    .dout(opl_dout),
    .irq_n(opl_irq_n),
    .snd(sample),
    .sample(opl_sample_clk)
);

always @ * begin
    // mix audio
    AUDIO_L <= sample + ($signed({ ~dac1[7], dac1[6:0], 8'b0 }) >>> 1) + ($signed({ ~dac2[7], dac2[6:0], 8'b0 }) >>> 1) ;
    AUDIO_R <= sample + ($signed({ ~dac1[7], dac1[6:0], 8'b0 }) >>> 1) + ($signed({ ~dac2[7], dac2[6:0], 8'b0 }) >>> 1) ;
end

reg [7:0] dac1;
reg [7:0] dac2;

reg [16:0] gfx1_addr;
reg [17:0] gfx2_addr;
reg [16:0] gfx3_addr;
reg [16:0] gfx4_addr;

reg [7:0] gfx1_dout;
reg [7:0] gfx2_dout;
reg [7:0] gfx3_dout;
reg [7:0] gfx4_dout;

wire [15:0] m68k_ram_dout;
wire [15:0] m68k_sprite_dout;
wire [15:0] m68k_pal_dout;


// ioctl download addressing    
wire rom_download = ioctl_download && (ioctl_index==0);

wire m68k_ioctl_wr    = rom_download & ioctl_wr & (ioctl_addr >= 24'h000000) & (ioctl_addr < 24'h040000) ;
wire tilemap_ioctl_wr = rom_download & ioctl_wr & (ioctl_addr >= 24'h0f0000) & (ioctl_addr < 24'h100000) ;
wire txt_ioctl_wr     = rom_download & ioctl_wr & (ioctl_addr >= 24'h200000) & (ioctl_addr < 24'h208000) ;
wire z80_ioctl_wr     = rom_download & ioctl_wr & (ioctl_addr >= 24'h0c0000) & (ioctl_addr < 24'h0d0000) ;
wire upd_ioctl_wr     = rom_download & ioctl_wr & (ioctl_addr >= 24'h0d0000) & (ioctl_addr < 24'h0f0000) ;

// main 68k ram high    
dual_port_ram #(.LEN(8192)) ram8kx8_H (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_ram_dout[15:8] ) ,
    
//    .clock_b (  ),
//    .address_b (  ),
//    .wren_b (  ),
//    .data_b (  ),
//    .q_b ( )
    );

// main 68k ram low     
dual_port_ram #(.LEN(8192)) ram8kx8_L (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_ram_dout[7:0] ) ,
    
//    .clock_b (  ),
//    .address_b (  ),
//    .wren_b (  ),
//    .data_b (  ),
//    .q_b ( )
    );

reg  [10:0] sprite_ram_addr;
wire [15:0] sprite_ram_dout /* synthesis keep */;

    // main 68k sprite ram high  
// 2kx16
dual_port_ram #(.LEN(1024)) sprite_ram_H (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a (  m68k_sprite_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[15:8] )
    
    );

// main 68k sprite ram low     
dual_port_ram #(.LEN(1024)) sprite_ram_L (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_spr_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_sprite_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( sprite_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( sprite_ram_dout[7:0] )
    );

   
wire [12:0] fg_ram_addr;
wire [15:0] fg_ram_dout;

wire [15:0] m68k_fg_ram_dout;

// foreground high   
dual_port_ram #(.LEN(8192)) ram_fg_h (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_fg_ram_dout[15:8] ),

    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[15:8] )
    
    );

// foreground low
dual_port_ram #(.LEN(8192)) ram_fg_l (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[13:1] ),
    .wren_a ( !m68k_rw & m68k_fg_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_fg_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( fg_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( fg_ram_dout[7:0] )
    );
    
wire [15:0] m68k_txt_ram_dout ;
reg  [15:0] txt_ram_dout;
reg   [9:0] txt_ram_addr;
    
// text ram high   
dual_port_ram #(.LEN(1024)) txt_ram_h (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_txt_ram_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_txt_ram_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( txt_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( txt_ram_dout[15:8] )
    );

//  text ram low
dual_port_ram #(.LEN(1024)) txt_ram_l (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_txt_ram_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_txt_ram_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( txt_ram_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( txt_ram_dout[7:0] )
    );   
    
reg  [9:0] tile_pal_addr;
reg [15:0] tile_pal_dout;
    
// tile palette high   
dual_port_ram #(.LEN(1024)) tile_pal_h (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_uds_n ),
    .data_a ( m68k_dout[15:8]  ),
    .q_a ( m68k_pal_dout[15:8]  ),

    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[15:8] )
    );

//  tile palette low
dual_port_ram #(.LEN(1024)) tile_pal_l (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[10:1] ),
    .wren_a ( !m68k_rw & m68k_pal_cs & !m68k_lds_n ),
    .data_a ( m68k_dout[7:0]  ),
    .q_a ( m68k_pal_dout[7:0] ),
     
    .clock_b ( clk_sys ),
    .address_b ( tile_pal_addr ),  
    .wren_b ( 1'b0 ),
    .data_b ( ),
    .q_b( tile_pal_dout[7:0] )
    );    
    
//z80 program rom    
dual_port_ram #(.LEN(65536)) z80_rom (
    .clock_a ( clk_sys ),
    .address_a ( z80_addr[15:0] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( z80_rom_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[15:0] ),
    .wren_b ( z80_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
    
// z80 ram 
dual_port_ram #(.LEN(2048)) z80_ram (
    .clock_b ( clk_6M ), 
    .address_b ( z80_addr[10:0] ),
    .wren_b ( z80_ram_cs & ~z80_wr_n ),
    .data_b ( z80_dout ),
    .q_b ( z80_ram_data )
    );
    
reg [16:0] upd_addr ;
wire [7:0] upd_dout ;

//adpcm sample rom    
dual_port_ram #(.LEN(131072)) upd_rom (
    .clock_a ( clk_sys ),
    .address_a ( upd_addr[16:0] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( upd_dout[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[16:0] ),
    .wren_b ( upd_ioctl_wr ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );
    
reg  [15:0] bg_tilemap_addr ;
wire [15:0] bg_tilemap_dout ;
reg  [15:0] bg_download_data;
reg         bg_download_wr;

// The SDRAM controller has a 32-bit interface, so we need to buffer the
// bytes received from the IOCTL interface in order to write 32-bit words to
// the SDRAM. 
download_buffer #(.SIZE(2)) bg_download_buffer
(
    .clk(clk_sys),
    .din(ioctl_dout),
    .dout(bg_download_data),
    .we(upd_ioctl_wr),
    .valid(bg_download_wr)
);


wire [15:0] spr_pal_dout ;
wire [15:0] m68k_spr_pal_dout ;

reg  [8:0]  sprite_buffer_addr;  // 128 sprites
reg  [63:0] sprite_buffer_din;
wire [63:0] sprite_buffer_dout;
reg  sprite_buffer_w;

dual_port_ram #(.LEN(512), .DATA_WIDTH(64)) sprite_buffer (
    .clock_a ( clk_sys ),
    .address_a ( sprite_buffer_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( sprite_buffer_dout ),
    
    .clock_b ( clk_sys ),
    .address_b ( sprite_buffer_addr ),
    .wren_b ( sprite_buffer_w ),
    .data_b ( sprite_buffer_din  ),
    .q_b( )

    );
    
reg          line_buf_tx_w;
reg          line_buf_fg_w;
reg          line_buf_bg_w;
reg   [9:0]  line_buf_addr_w;
reg   [7:0]  line_buf_din;
//wire  [7:0]  line_buf_dout;

reg   [9:0]  line_buf_addr_r ; 
wire  [7:0]  line_buf_tx_out;
wire  [7:0]  line_buf_fg_out;
wire  [7:0]  line_buf_bg_out;

reg   [9:0]  spr_buf_addr_w;
reg          spr_buf_w;
reg   [7:0]  spr_buf_din;
wire  [7:0]  spr_buf_dout;
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) spr_buffer_ram (
    .clock_a ( clk_sys ),
    .address_a ( spr_buf_addr_w ),
    .wren_a ( spr_buf_w ),
    .data_a ( spr_buf_din ),
    .q_a (  ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),  // spr_buf_addr_r
    .wren_b ( 0 ),
    .q_b ( spr_buf_dout )
    ); 
    
// two line buffer for sprite rendering
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) line_buffer_ram_tx (
    .clock_a ( clk_sys ),
    .address_a ( line_buf_addr_w ),
    .wren_a ( line_buf_tx_w ),
    .data_a ( line_buf_din ),
//    .q_a ( line_buf_dout ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),  
    .wren_b ( 0 ),
    .q_b ( line_buf_tx_out )
    );    
    
dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) line_buffer_ram_fg (
    .clock_a ( clk_sys ),
    .address_a ( line_buf_addr_w ),
    .wren_a ( line_buf_fg_w ),
    .data_a ( line_buf_din ),
//    .q_a ( line_buf_dout ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),  
    .wren_b ( 0 ),
    .q_b ( line_buf_fg_out )
    );    

dual_port_ram #(.LEN(1024), .DATA_WIDTH(8)) line_buffer_ram_bg (
    .clock_a ( clk_sys ),
    .address_a ( line_buf_addr_w ),
    .wren_a ( line_buf_bg_w ),
    .data_a ( line_buf_din ),
//    .q_a ( line_buf_dout ),

    .clock_b ( clk_sys ),
    .address_b ( line_buf_addr_r ),  
    .wren_b ( 0 ),
    .q_b ( line_buf_bg_out )
    );   
    
  
    

reg  [11:0] gfx_txt_addr;
wire  [7:0] gfx_txt_dout;

reg  [11:0] gfx_txt_attr_addr;
wire  [7:0] gfx_txt_attr_dout;

wire [15:0] m68k_txt_attr_ram_dout;
   
wire [15:0] m68k_rom_data;
wire m68k_rom_valid;

wire z80_rom_valid;

reg  [17:0] sprite_rom_addr;
wire [31:0] sprite_rom_data;
reg sprite_rom_cs;
wire sprite_rom_valid;

reg  [15:0] fg_rom_addr;
wire [31:0] fg_rom_data;
reg fg_rom_cs;
wire fg_rom_valid;

reg  [15:0] bg_rom_addr;
wire [31:0] bg_rom_data;
reg bg_rom_cs;
wire bg_rom_valid;

reg  [12:0] txt_rom_addr;
wire [31:0] txt_rom_data;
reg txt_rom_cs;
wire txt_rom_valid;

assign m68k_rom_valid = 1;

dual_port_ram #(.LEN(131072)) m68k_rom_h (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[23:1] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( m68k_rom_data[15:8] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[17:1] ),
    .wren_b ( m68k_ioctl_wr & ~ioctl_addr[0]),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );   

dual_port_ram #(.LEN(131072)) m68k_rom_l (
    .clock_a ( clk_18M ),
    .address_a ( m68k_a[23:1] ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( m68k_rom_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[17:1] ),
    .wren_b ( m68k_ioctl_wr & ioctl_addr[0] ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );   

dual_port_ram #(.LEN(32768)) tilemap_rom_h (
    .clock_a ( clk_sys ),
    .address_a ( tilemap_rom_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( tilemap_rom_data[15:8] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[15:1] ),
    .wren_b ( tilemap_ioctl_wr & ~ioctl_addr[0]),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );   

reg [14:0] tilemap_rom_addr;
reg [15:0] tilemap_rom_data;

dual_port_ram #(.LEN(32768)) tilemap_rom_l (
    .clock_a ( clk_sys ),
    .address_a ( tilemap_rom_addr ),
    .wren_a ( 1'b0 ),
    .data_a ( ),
    .q_a ( tilemap_rom_data[7:0] ),
    
    .clock_b ( clk_sys ),
    .address_b ( ioctl_addr[15:1] ),
    .wren_b ( tilemap_ioctl_wr & ioctl_addr[0] ),
    .data_b ( ioctl_dout  ),
    .q_b( )
    );   
    
rom_controller rom_controller 
(
    .reset(reset),

    // clock
    .clk(clk_sys),

    // program ROM interface
//    .prog_rom_cs(m68k_rom_cs),
//    .prog_rom_oe(1),
//    .prog_rom_addr(m68k_a[23:1]),
//    .prog_rom_data(m68k_rom_data),
//    .prog_rom_data_valid(m68k_rom_valid),
    
    // sprite ROM interface
    .sprite_rom_cs(sprite_rom_cs),
    .sprite_rom_oe(1),
    .sprite_rom_addr(sprite_rom_addr),
    .sprite_rom_data(sprite_rom_data),
    .sprite_rom_data_valid(sprite_rom_valid),

    // fg ROM interface
    .fg_rom_cs(fg_rom_cs),
    .fg_rom_oe(1),
    .fg_rom_addr(fg_rom_addr),
    .fg_rom_data(fg_rom_data),
    .fg_rom_data_valid(fg_rom_valid),

    // bg ROM interface
    .bg_rom_cs(bg_rom_cs),
    .bg_rom_oe(1),
    .bg_rom_addr(bg_rom_addr),
    .bg_rom_data(bg_rom_data),
    .bg_rom_data_valid(bg_rom_valid),
    
    // text ROM interface
    .text_rom_cs(txt_rom_cs),
    .text_rom_oe(1),
    .text_rom_addr(txt_rom_addr),
    .text_rom_data(txt_rom_data),
    .text_rom_data_valid(txt_rom_valid),       
    
    // sound ROM #1 interface
//    .sound_rom_cs(z80_rom_cs),
//    .sound_rom_oe(1),
//    .sound_rom_addr(z80_addr),
//    .sound_rom_data(z80_rom_data),
//    .sound_rom_data_valid(z80_rom_valid),    

    // IOCTL interface
    .ioctl_addr(ioctl_addr),
    .ioctl_data(ioctl_dout),
    .ioctl_index(ioctl_index),
    .ioctl_wr(ioctl_wr),
    .ioctl_download(ioctl_download),

    // SDRAM interface
    .sdram_addr(sdram_addr),
    .sdram_data(sdram_data),
    .sdram_we(sdram_we),
    .sdram_req(sdram_req),
    .sdram_ack(sdram_ack),
    .sdram_valid(sdram_valid),
    .sdram_q(sdram_q)
  );

//    
reg  [22:0] sdram_addr;
reg  [31:0] sdram_data;
reg         sdram_we;
reg         sdram_req;

wire        sdram_ack;
wire        sdram_valid;
wire [31:0] sdram_q;

sdram #(.CLK_FREQ( (CLKSYS+0.0))) sdram
(
  .reset(~pll_locked),
  .clk(clk_sys),

  // controller interface
  .addr(sdram_addr),
  .data(sdram_data),
  .we(sdram_we),
  .req(sdram_req),
  
  .ack(sdram_ack),
  .valid(sdram_valid),
  .q(sdram_q),

  // SDRAM interface
  .sdram_a(SDRAM_A),
  .sdram_ba(SDRAM_BA),
  .sdram_dq(SDRAM_DQ),
  .sdram_cke(SDRAM_CKE),
  .sdram_cs_n(SDRAM_nCS),
  .sdram_ras_n(SDRAM_nRAS),
  .sdram_cas_n(SDRAM_nCAS),
  .sdram_we_n(SDRAM_nWE),
  .sdram_dqml(SDRAM_DQML),
  .sdram_dqmh(SDRAM_DQMH)
);    
    
endmodule

module delay
(
    input clk,  
    input i,
    output o
);

reg [5:0] r;

assign o = r[5]; 

always @(posedge clk) begin
    r <= { r[4:0], i };
end

endmodule

