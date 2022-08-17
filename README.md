

# SNK M68000 (Prehistoric Isle in 1930) FPGA Implementation

FPGA compatible core of SNK M68000 (Prehistoric Isle in 1930 based) arcade hardware for [**MiSTerFPGA**](https://github.com/MiSTer-devel/Main_MiSTer/wiki) written by [**Darren Olafson**](https://twitter.com/Darren__O). The intent is for this core to be a 1:1 playable implementation of the SNK (Prehistoric Isle in 1930 based) 68000 hardware. 

Currently in an alpha state, this core is in active development with assistance from [**atrac17**](https://github.com/atrac17).

<br>
<p align="center">
<img width="" height="" src="https://user-images.githubusercontent.com/32810066/184925944-f5d7b8f2-e589-41d0-adb8-959bc693aae5.png">
</p>
<br>

## External Modules

|Name| Purpose | Author |
|----|---------|--------|
| [**fx68k**](https://github.com/ijor/fx68k)      | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000) | Jorge Cwik     |
| [**t80**](https://opencores.org/projects/t80)   | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)           | Daniel Wallner |
| [**jtopl2**](https://github.com/jotego/jtopl)   | [**Yamaha OPL 2**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)      | Jose Tejada    |
| [**jt7759**](https://github.com/jotego/jt7759)  | **NEC uPD7759**                                                        | Jose Tejada    |

# Known Issues / Tasks

- Audio issues known, may be an issue with the jtopl2 core or the current usage<br>(No need to report further audio issues)  

# PCB Check List

- TBD

### Clock Information

H-Sync      | V-Sync      |
------------|-------------|
15.625kHz   | 59.637404Hz |

**Pixel clock:** 6.00 MHz

**Estimated geometry:**

    383 pixels/line
  
    261 pixels/line

### Main Components

Location | Chip | Use |
---------|------|-----|
F3  (Top Board) | [**Motorola 68000 CPU**](https://en.wikipedia.org/wiki/Motorola_68000)   | Main CPU      |
H12 (Top Board) | [**Zilog Z80 CPU**](https://en.wikipedia.org/wiki/Zilog_Z80)             | Sound CPU     |
C12 (Top Board) | [**Yamaha YM3812**](https://en.wikipedia.org/wiki/Yamaha_OPL#OPL2)       | OPL2          |
E14 (Top Board) | [**NEC uPD7759**](https://github.com/jotego/jt7759)                      | ADPCM Decoder |

# PCB Features

- TBD

# Controls

<br>

<table><tr><th>Game</th><th>Joystick</th><th>Service Menu</th><th>Control Type</th></tr><tr><td><p align="center">Prehistoric Isle in 1930</p></td><td><p align="center">8-Way</p></td><td><p align="center"><img src="https://user-images.githubusercontent.com/32810066/184927270-92710d25-e63e-4cd9-b4a7-a7713e4532a2.png"></td><td><p align="center">Co-Op</td> </table>

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

|Debug|
|--|
|<table> <tr><th>Functions</th><th>Keymap</th></tr><tr><td>Layer (TXT)</td><td>F7</td><tr><td>Layer (FG)</td><td>F8</td></tr><tr><td>Layer (BG)</td><td>F9</td><tr><td>Layer (SP)</td><td>F10</td></tr> </table>|

# Support

Please consider showing support for this and future projects via [**Ko-fi**](https://ko-fi.com/darreno). While it isn't necessary, it's greatly appreciated.

# Licensing

Contact the author for special licensing needs. Otherwise follow the GPLv2 license attached.
