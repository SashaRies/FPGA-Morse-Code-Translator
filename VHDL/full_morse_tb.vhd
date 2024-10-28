--------------------------------------------------------------------------------
-- Course:	 		Engs 31 16S
--
-- Create Date:   17:11:39 07/25/2009
-- Design Name:   
-- Module Name:   Morse code translator_tb.vhd
-- Project Name:  Lab5
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: SerialRx
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:

--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.all;
 
ENTITY full_morse_tb IS
END full_morse_tb;
 
ARCHITECTURE behavior OF full_morse_tb IS 
 
COMPONENT morse_translator_complete
    Port ( Clk 					: in  STD_LOGIC;-- 100 MHz board clock
           data 	   			: in  STD_LOGIC;-- reciever input
           morse_out_port       : out std_logic;--morse blinker
           morse_freq_out       : out STD_LOGIC);-- morse buzz code
	END COMPONENT;
   

   --Inputs
   signal clk 		: std_logic := '0';
   signal data_sig 	: std_logic := '1';

 	--Outputs
   signal data_out  	: std_logic;
   signal morse_freq    : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10ns;		-- 100 MHz clock
	
	-- Data definitions
	constant bit_time : time := 104 us;		-- 9600 baud
--- constant bit_time : time := 8.68us;		-- 115,200 baud
	constant TxData : std_logic_vector(7 downto 0) := "01100001";
	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: morse_translator_complete
		PORT MAP (
          Clk => clk,
          data => data_sig,
          morse_out_port => data_out,
          morse_freq_out => morse_freq);

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
		
		data_sig <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			data_sig <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		data_sig <= '1';		-- Stop bit
		wait for 20 us;
		
		data_sig <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			data_sig <= not( TxData(bitcount) );
			wait for bit_time;
		end loop;
		
		data_sig <= '1';		-- Stop bit
		
		wait;
   end process;
END;