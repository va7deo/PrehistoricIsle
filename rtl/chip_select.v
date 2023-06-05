//

module chip_select
(
    input        clk,

    input [23:0] m68k_a,
    input        m68k_as_n,

    input [15:0] z80_addr,
    input        MREQ_n,
    input        IORQ_n,
    input        M1_n,

    // M68K selects
    output reg m68k_rom_cs,
    output reg m68k_ram_cs,
    output reg m68k_txt_ram_cs,
    output reg m68k_spr_cs,
    output reg m68k_pal_cs,
    output reg m68k_fg_ram_cs,
    output reg input_p1_cs,
    output reg input_p2_cs,
    output reg input_dsw1_cs,
    output reg input_dsw2_cs,
    output reg input_coin_cs,
    output reg bg_scroll_x_cs,
    output reg bg_scroll_y_cs,
    output reg fg_scroll_x_cs,
    output reg fg_scroll_y_cs,
    output reg flip_cs,
    output reg m_invert_ctrl_cs,
    output reg sound_latch_cs,

    // Z80 selects
    output reg   z80_rom_cs,
    output reg   z80_ram_cs,
    output reg   z80_latch_cs,

    output reg   z80_sound0_cs,
    output reg   z80_sound1_cs,
    output reg   z80_upd_cs,
    output reg   z80_upd_r_cs
);


function m68k_cs;
        input [23:0] start_address;
        input [23:0] end_address;
begin
    m68k_cs = ( m68k_a[23:0] >= start_address && m68k_a[23:0] <= end_address) & !m68k_as_n;
end
endfunction

function z80_mem_cs;
        input [15:0] base_address;
        input  [7:0] width;
begin
    z80_mem_cs = ( z80_addr >> width == base_address >> width ) & !MREQ_n;
end
endfunction

function z80_io_cs;
        input [7:0] address_lo;
begin
    z80_io_cs = ( z80_addr[7:0] == address_lo ) && !IORQ_n;
end
endfunction

always @ (*) begin
    m68k_rom_cs      <= m68k_cs( 24'h000000, 24'h03ffff );
    m68k_ram_cs      <= m68k_cs( 24'h070000, 24'h073fff );
    m68k_txt_ram_cs  <= m68k_cs( 24'h090000, 24'h0907ff );
    m68k_spr_cs      <= m68k_cs( 24'h0a0000, 24'h0a07ff );
    m68k_fg_ram_cs   <= m68k_cs( 24'h0b0000, 24'h0b3fff );
    m68k_pal_cs      <= m68k_cs( 24'h0d0000, 24'h0d07ff );

    input_p2_cs      <= m68k_cs( 24'h0e0010, 24'h0e0011 );
    input_coin_cs    <= m68k_cs( 24'h0e0020, 24'h0e0021 );
    input_p1_cs      <= m68k_cs( 24'h0e0040, 24'h0e0041 );
    input_dsw1_cs    <= m68k_cs( 24'h0e0042, 24'h0e0043 );
    input_dsw2_cs    <= m68k_cs( 24'h0e0044, 24'h0e0045 );

    fg_scroll_y_cs   <= m68k_cs( 24'h0f0000, 24'h0f0001 );
    fg_scroll_x_cs   <= m68k_cs( 24'h0f0010, 24'h0f0011 );
    bg_scroll_y_cs   <= m68k_cs( 24'h0f0020, 24'h0f0021 );
    bg_scroll_x_cs   <= m68k_cs( 24'h0f0030, 24'h0f0031 );

    m_invert_ctrl_cs <= m68k_cs( 24'h0f0046, 24'h0f0047 );
    flip_cs          <= m68k_cs( 24'h0f0060, 24'h0f0061 );

    sound_latch_cs   <= m68k_cs( 24'h0f0070, 24'h0f0071 );

    z80_rom_cs       <= ( MREQ_n == 0 && z80_addr[15:0] < 16'hf000 );
    z80_ram_cs       <= ( MREQ_n == 0 && z80_addr[15:0] >= 16'hf000 && z80_addr[15:0] < 16'hf800 );
    z80_latch_cs     <= ( MREQ_n == 0 && z80_addr[15:0] == 16'hf800 );

    z80_sound0_cs    <= z80_io_cs(8'h00); // ym3812 address
    z80_sound1_cs    <= z80_io_cs(8'h20); // ym3812 data
    z80_upd_cs       <= z80_io_cs(8'h40); // 7759 write
    z80_upd_r_cs     <= z80_io_cs(8'h80); // 7759 reset
end

endmodule
