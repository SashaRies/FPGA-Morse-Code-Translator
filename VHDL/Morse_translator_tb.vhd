--Sasha Ries
--ES31/CS56
--Morse code tranlsator Queue testbench code.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;	
--=============================================================
--Entitity Declarations
--=============================================================
ENTITY Morse_translator_tb IS
END Morse_translator_tb;

ARCHITECTURE behavior OF Morse_translator_tb IS 

Component Morse_translator is
--setup generics to hopefully reuse the shift register
	generic(
		N_flip_flops			: integer;
		buzz_freq				: integer);
	port(
	    --1 MHz serial clock
		clk_port				: in  std_logic;	
    	
    	--controller signals	
		done_port				: out std_logic;
        
        --datapath signals
		data_valid_port	   		: in  std_logic;
		data_queue_port			: in std_logic_vector(7 downto 0);
		morse_freq_port			: out std_logic); 
end component; 
--put signals here
--Inputs
   signal clk : std_logic := '0';
   signal parallel_in : std_logic_vector(7 downto 0) := "00000000";
   signal data_valid  : std_logic := '0';

 	--Outputs
   signal data_out     : std_logic := '0';
   signal done         : std_logic := '0';

   -- Clock period definitions
   constant clk_period : time := 1000ns;		-- 100 MHz clock
	
	-- Data definitions
	constant ascii_time: time := 1040 us;
	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: morse_translator generic map(
        buzz_freq => 4,
		N_flip_flops => 2)
		PORT MAP (
          clk_port => clk,
          done_port => done,
          data_queue_port => parallel_in,
          morse_freq_port => data_out,
          data_valid_port => data_valid);

   -- Clock process definitions
   clk_process : process
   begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
   end process;
   
   
   -- Stimulus process
   stim_proc: process
   begin		
		wait for 1 us;		
		
		data_valid <= '1';
		parallel_in <= "01100001";
		wait for 5*ascii_time;
		
		data_valid <= '1';
		parallel_in <= "10100001";
		wait for 400 ms;
		
		data_valid <= '1';
		parallel_in <= "00000001";
		wait for 1*clk_period;
		data_valid <= '0';
		wait for 2*ascii_time;
		
		data_valid <= '1';
		parallel_in <= "01010101";
		wait for 1*clk_period;
		data_valid <= '0';
		wait;
   end process;
END;