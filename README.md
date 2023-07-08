
# SNK M68000 (Prehistoric Isle) FPGA Implementation

FPGA compatible core of SNK M68000 (Prehistoric Isle in 1930 based) arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O) with assistance from [**atrac17**](https://github.com/atrac17).

The intent is for this core to be a 1:1 playable implementation of Prehistoric Isle in 1930 arcade hardware. Pending PCB verification, on loan from [**XtraSmiley**](https://twitter.com/Xtrasmiley).

<img width="" height="" src="https://github.com/va7deo/PrehistoricIsle/assets/32810066/f206a42f-416a-455d-8359-8d2549b0ed8a">

## External Modules

| Module                                                                             | Function                                                               | Author                                         |
|------------------------------------------------------------------------------------|------------------------------------------------------------------------|------------------------------------------------|
| [**fx68k**](https://github.com/ijor/fx68k)                                         | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik                                     |
| [**t80**](https://opencores.org/projects/t80)                                      | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner                                 |
| [**jtopl2**](https://github.com/jotego/jtopl)                                      | [**Yamaha OPL 2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)      | Jose Tejada                                    |
| [**jt7759**](https://github.com/jotego/jt7759)                                     | [**NEC µPD7759**](https://github.com/jotego/jt7759)                    | Jose Tejada                                    |
| [**yc_out**](https://github.com/MikeS11/MiSTerFPGA_YC_Encoder)                     | [**Y/C Video Module**](https://en.wikipedia.org/wiki/S-Video)          | Mike Simone                                    |
| [**mem**](https://github.com/MiSTer-devel/Arcade-Rygar_MiSTer/tree/master/src/mem) | SDRAM Controller / Rom Downloader                                      | Josh Bassett, modified by Darren Olafson       |
| [**core_template**](https://github.com/MiSTer-devel/Template_MiSTer)               | MiSTer Framework Template                                              | sorgelig, modified by Darren Olafson / atrac17 |

# Known Issues / Tasks

- [**OPL2 Audio**](https://github.com/jotego/jtopl/issues/11)  **[Issue]**  
- Timing issues with jtframe_mixer module; false paths added to sdc (may need refactor?)  **[Task]**  

# PCB Check List

FPGA implementation loosely based on [**mame source**](https://github.com/mamedev/mame/blob/master/src/mame/snk/prehisle.cpp) and will be verified against an authentic SNK Prehistoric Isle in 1930 PCB.

### Clock Information

| H-Sync      | V-Sync      | Source                                                                                                                                                                      |
|-------------|-------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| 15.625kHz   | 54.065743Hz | [**OSSC**](https://user-images.githubusercontent.com/32810066/187164273-01cf0a2e-6eb4-47ce-ba79-830a7e977212.jpg) <br> [**OSSC**](https://mametesters.org/view.php?id=5939) |

### Crystal Oscillators

| Freq (MHz) | Use                                                   |
|------------|-------------------------------------------------------|
| 4.000      | Z80 (4 MHz)<br>YM3812CLK (4 MHz)<br>µPD7759 (640 KHz) |
| 18.000     | M68000 (9 MHz)                                        |
| 12.000     | Pixel CLK (6 MHz)                                     |

**Pixel clock:** 6.00 MHz

**Estimated geometry:**

    384 pixels/line
  
    289 pixels/line

### Main Components

| Chip                                                                   | Use           |
|------------------------------------------------------------------------|---------------|
| [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Main CPU      |
| [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Sound CPU     |
| [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)     | OPL2          |
| [**NEC µPD7759**](https://github.com/jotego/jt7759)                    | ADPCM Decoder |

# Core Features

### Video Timings

- Video timings can be modified if you experience sync issues with CRT or modern displays; this will alter gameplay from it's original state.

| Refresh Rate      | Timing Parameter           | HTOTAL | VTOTAL |
|-------------------|----------------------------|--------|--------|
| 15.63kHz / 54.1Hz | PCB                        | 384    | 289    |
| 15.63kHz / 59.2Hz | NTSC (Closest Spec) / MAME | 384    | 264    |

### P1/P2 Input Swap Option

- There is a toggle to swap inputs from Player 1 to Player 2. This only swaps inputs for the joystick, it does not effect keyboard inputs.

### Audio Options

- There is a toggle to disable playback of OPL2 / µPD7759 audio. There are toggles to adjust the volume of OPL2 and the µPD7759 audio.

### Overclock Options

- There is a toggle to increase the M68000 frequency from 9MHz to 12MHz; this will alter gameplay from it's original state.

### Native Y/C Output

- Native Y/C ouput is possible with the [**analog I/O rev 6.1 pcb**](https://github.com/MiSTer-devel/Main_MiSTer/wiki/IO-Board). Using the following cables, [**HD-15 to BNC cable**](https://www.amazon.com/StarTech-com-Coax-RGBHV-Monitor-Cable/dp/B0033AF5Y0/) will transmit Y/C over the green and red lines. Choose an appropriate adapter to feed [**Y/C (S-Video)**](https://www.amazon.com/MEIRIYFA-Splitter-Extension-Monitors-Transmission/dp/B09N19XZJQ) to your display.

### H/V Adjustments

- There are two H/V toggles, H/V-sync positioning adjust and H/V-sync width adjust. Positioning will move the display for centering on CRT display. The sync width adjust can be used to for sync issues (rolling, flagging etc) without modifying the video timings.

### Scandoubler Options

- Additional toggle to enable the scandoubler without changing ini settings and new scanline option for 100% is available, this draws a black line every other frame. Below is an example.

<table><tr><th>Scandoubler Fx</th><th>Scanlines 25%</th><th>Scanlines 50%</th><th>Scanlines 75%</th><th>Scanlines 100%</th><tr><td><br> <p align="center"><img width="128" height="112" src="https://user-images.githubusercontent.com/32810066/191252689-acfb3610-89d9-4ec2-9f69-dc285d9cf6dd.png"></td><td><br> <p align="center"><img width="128" height="112" src="https://user-images.githubusercontent.com/32810066/191252701-2cd221dd-0e31-49c3-89ef-e0dcafdd4916.png"></td><td><br> <p align="center"><img width="128" height="112" src="https://user-images.githubusercontent.com/32810066/191252717-b4f7bd03-5e76-4e43-b055-1a418589a169.png"></td><td><br> <p align="center"><img width="128" height="112" src="https://user-images.githubusercontent.com/32810066/191252728-638d1a44-07ff-4060-918f-ebfb79a6f206.png"></td><td><br> <p align="center"><img width="128" height="112" src="https://user-images.githubusercontent.com/32810066/191252737-be45e006-c172-471a-80dd-ee1335cd8ede.png"></td></tr></table>

# PCB Information / Control Layout

| Title                                               | Joystick | Service Menu                                                                                                       | Dip Switches                                                                                                    | Shared Controls | Dip Default | PCB Information                                                                                                                                                                                                                                                                                                                                                                            |
|-----------------------------------------------------|----------|--------------------------------------------------------------------------------------------------------------------|-----------------------------------------------------------------------------------------------------------------|-----------------|-------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| **Prehistoric Isle in 1930<br><br>Genshitou 1930s** | 8-Way    | [**Service Menu**](https://github.com/va7deo/PrehistoricIsle/assets/32810066/26f692bc-f688-4574-83e1-d96bcaba4d16) | [**Dip Sheet**](https://github.com/va7deo/PrehistoricIsle/assets/32810066/4c8ba229-5b43-4003-8d5e-5df6dacb203a) | Co-Op           | **Upright** | There is a level select dipswitch not documented in the manual, when toggled you can select to start at any stage or view the end credits. <br><br> There are two hidden cheat functions when setting dipswitches in certain positions. These enable a "pause" function which halts the CPU and infinite lives. <br><br> These are labeled clearly in the dip switch menu for convenience. |

<br>

### Keyboard Handler

- Keyboard inputs mapped to mame defaults for all functions.

<br>

|Services|Coin/Start|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Test</td><td>F2</td></tr><tr><td>Reset</td><td>F3</td></tr><tr><td>Service</td><td>9</td></tr><tr><td>Pause</td><td>P</td></tr> </table> | <table><tr><th>Functions</th><th>Keymap</th><tr><tr><td>P1 Start</td><td>1</td></tr><tr><td>P2 Start</td><td>2</td></tr><tr><td>P1 Coin</td><td>5</td></tr><tr><td>P2 Coin</td><td>6</td></tr> </table>|

|Player 1|Player 2|
|--|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P1 Up</td><td>Up</td></tr><tr><td>P1 Down</td><td>Down</td></tr><tr><td>P1 Left</td><td>Left</td></tr><tr><td>P1 Right</td><td>Right</td></tr><tr><td>P1 Bttn 1</td><td>L-Ctrl</td></tr><tr><td>P1 Bttn 2</td><td>L-Alt</td></tr><tr><td>P1 Bttn 3</td><td>Space</td></tr> </table> | <table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>P2 Up</td><td>R</td></tr><tr><td>P2 Down</td><td>F</td></tr><tr><td>P2 Left</td><td>D</td></tr><tr><td>P2 Right</td><td>G</td></tr><tr><td>P2 Bttn 1</td><td>A</td></tr><tr><td>P2 Bttn 2</td><td>S</td></tr><tr><td>P2 Bttn 3</td><td>Q</td></tr> </table>|

# Support

Please consider showing support for this and future projects via [**Darren's Ko-fi**](https://ko-fi.com/darreno) and [**atrac17's Patreon**](https://www.patreon.com/atrac17). While it isn't necessary, it's greatly appreciated.<br>

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
