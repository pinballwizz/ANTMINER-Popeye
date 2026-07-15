---------------------------------------------------------------------------------
--                         Popeye - Antminer S9
--                           Code from DarFPGA
--
--                         Modified for Antminer S9 
--                             by pinballwiz 
--                               25/06/2026
---------------------------------------------------------------------------------
-- Keyboard inputs :
--   5 : Add coin
--   2 : Start 2 players
--   1 : Start 1 player
--   LEFT Ctrl : Punch
--   RIGHT arrow : Move Right
--   LEFT arrow  : Move Left
--   UP arrow  : Move Up
--   DOWN arrow  : Move Down
---------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.ALL;
use ieee.numeric_std.all;
---------------------------------------------------------------------------------
entity popeye_antminer is
port(
	clock_50    : in std_logic;
   	I_RESET     : in std_logic;
	O_VIDEO_R	: out std_logic_vector(2 downto 0); 
	O_VIDEO_G	: out std_logic_vector(2 downto 0);
	O_VIDEO_B	: out std_logic_vector(1 downto 0);
	O_HSYNC		: out std_logic;
	O_VSYNC		: out std_logic;
	O_AUDIO_L 	: out std_logic;
	O_AUDIO_R 	: out std_logic;
   	ps2_clk     : in std_logic;
	ps2_dat     : inout std_logic;
	led         : out std_logic_vector(7 downto 0);
	aled        : out std_logic_vector(3 downto 0);
	joy         : in std_logic_vector(7 downto 0);
	dipsw       : in std_logic_vector(7 downto 0)
 );
end popeye_antminer;
------------------------------------------------------------------------------
architecture struct of popeye_antminer is

 signal clock_40 : std_logic;
 signal clock_36 : std_logic;
 signal clock_24 : std_logic;
 signal clock_18 : std_logic;
 signal clock_9  : std_logic;
 --
 signal video_r  : std_logic_vector(2 downto 0);
 signal video_g  : std_logic_vector(2 downto 0);
 signal video_b  : std_logic_vector(1 downto 0);
 --
 signal h_sync   : std_logic;
 signal v_sync	 : std_logic;
 signal blankn   : std_logic;
 --
 signal reset    : std_logic;
 --
 signal audio           : std_logic_vector(15 downto 0);
 signal audio_pwm       : std_logic;
 --
 signal kbd_intr        : std_logic;
 signal kbd_scancode    : std_logic_vector(7 downto 0);
 signal joy_BBBBFRLDU   : std_logic_vector(9 downto 0);
 --
 constant CLOCK_FREQ    : integer := 27E6;
 signal counter_clk     : std_logic_vector(25 downto 0);
 signal clock_4hz       : std_logic;
 signal AD              : std_logic_vector(15 downto 0);
---------------------------------------------------------------------------
component popeye_clocks
port(
  clk_out1          : out    std_logic;
  clk_out2          : out    std_logic;
  clk_out3          : out    std_logic;
  clk_in1           : in     std_logic
 );
end component;
---------------------------------------------------------------------------
begin

 reset <= not I_RESET;
 aled(3 downto 0) <= "1111"; -- turn unused onboard leds off

---------------------------------------------------------------------------
-- Clocks

Clocks: popeye_clocks
    port map (
        clk_in1   => clock_50,
        clk_out1  => clock_40,
        clk_out2  => clock_36,
        clk_out3  => clock_24       
    );
---------------------------------------------------------------------------
-- Clocks Divide

process(clock_36)
begin
	if rising_edge(clock_36) then
		clock_18 <= not clock_18;
	end if;
end process;    
--
process(clock_18)
begin
	if rising_edge(clock_18) then
		clock_9 <= not clock_9;
	end if;
end process;    
---------------------------------------------------------------------------
-- Main

popeye : entity work.popeye
  port map (
 clock_40   => clock_40,
 reset      => reset,
 video_r 	=> video_r,
 video_g 	=> video_g,
 video_b	=> video_b,
 video_hs   => h_sync,
 video_vs   => v_sync,
 video_blankn => blankn,
 audio_out  => audio,
 left1      => joy_BBBBFRLDU(2),
 right1     => joy_BBBBFRLDU(3),
 up1        => joy_BBBBFRLDU(0),
 down1      => joy_BBBBFRLDU(1),
 fire1      => joy_BBBBFRLDU(4),
 left2      => joy_BBBBFRLDU(2),
 right2     => joy_BBBBFRLDU(3),
 up2        => joy_BBBBFRLDU(0),
 down2      => joy_BBBBFRLDU(1),
 fire2      => joy_BBBBFRLDU(4),
 coin       => joy_BBBBFRLDU(7),
 start1     => joy_BBBBFRLDU(5),
 start2     => joy_BBBBFRLDU(6),
 sw1        => not("10"&'1'&"1111"),
 sw2        => not("00111101"),
 dbg_cpu_addr => AD
   );
-------------------------------------------------------------------------
-- vga output

	O_VIDEO_R 	<= video_r when blankn = '1' else "000";
	O_VIDEO_G 	<= video_g when blankn = '1' else "000";
	O_VIDEO_B 	<= video_b when blankn = '1' else "00";
	O_HSYNC     <= h_sync;
	O_VSYNC     <= v_sync;
--------------------------------------------------------------------------------------------
 -- Audio DAC
u_dac : entity work.dac
  generic map(
    msbi_g => 15
  )
port  map(
    clk_i   => clock_18,
    res_n_i => I_RESET,
    dac_i   => audio,
    dac_o   => audio_pwm
);

O_AUDIO_L <= audio_pwm; 
O_AUDIO_R <= audio_pwm;
------------------------------------------------------------------------------
-- get scancode from keyboard

keyboard : entity work.io_ps2_keyboard
port map (
  clk       => clock_9,
  kbd_clk   => ps2_clk,
  kbd_dat   => ps2_dat,
  interrupt => kbd_intr,
  scancode  => kbd_scancode
);
------------------------------------------------------------------------------
-- translate scancode to joystick

joystick : entity work.kbd_joystick
port map (
  clk         => clock_9,
  kbdint      => kbd_intr,
  kbdscancode => std_logic_vector(kbd_scancode), 
  joy_BBBBFRLDU  => joy_BBBBFRLDU 
);
------------------------------------------------------------------------------
-- debug

process(reset, clock_24)
begin
  if reset = '1' then
   clock_4hz <= '0';
   counter_clk <= (others => '0');
  else
    if rising_edge(clock_24) then
      if counter_clk = CLOCK_FREQ/8 then
        counter_clk <= (others => '0');
        clock_4hz <= not clock_4hz;
        led(7 downto 0) <= not AD(14 downto 7);
      else
        counter_clk <= counter_clk + 1;
      end if;
    end if;
  end if;
end process;
------------------------------------------------------------------------------
end struct;