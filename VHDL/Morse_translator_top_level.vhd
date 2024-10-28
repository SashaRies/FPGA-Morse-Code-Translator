-- Course:	 		 Engs 31 16S
-- Author:           Sasha Ries
-- Create Date:      15:44:25 08/22/2022 
-- Design Name: 
-- Module Name:      morse translator top level 
-- Project Name:	 morse code translator 
-- Target Devices:   Spartan 6 / Nexys 3
-- Tool versions:    ISE 14.4
-- Description:      Top level shell for morse translator
--
-- Additional Comments:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity morse_translator_complete is
    Port ( Clk 					: in  STD_LOGIC;-- 100 MHz board clock
           data 	   			: in  STD_LOGIC;-- reciever input
           morse_out_port       : out std_logic;--morse blinker
           morse_freq_out       : out STD_LOGIC);-- morse buzz code
end morse_translator_complete;

architecture Structural of morse_translator_complete is

-- Signal for the 100 MHz to convert to 9600 baud rate
constant Tc: integer 	:= 10416;
-- Signal for buzzer to have a 240ms period
constant buzz_freq: integer := 4;
--signal for queue length
constant N_bytes: integer := 10;
-- Other signals
signal parallel_data		: std_logic_vector(7 downto 0);
signal push 				: std_logic;
signal pop	 				: std_logic;
signal data_valid			: std_logic;
signal queue_out_parallel 	: std_logic_vector(7 downto 0);
signal clock           		: std_logic; 

-- Component declarations
COMPONENT queue
	--setup generics to hopefully resuse the shift register
	generic(
		N_bytes 				: integer);
	port(
	    --1 MkHz serial clock
		clk_port				: in  std_logic;	
    	
    	--controller signals	
		in_pop_port				: in std_logic;
		in_push_port			: in std_logic;
		
        
        --datapath signals
		parallel_in_port   		: in  std_logic_vector(7 downto 0);	
		data_valid_port			: out std_logic;
		parallel_out_port		: out std_logic_vector(7 downto 0));
end component; 

--add declarations for the sci reciever and morse translator
COMPONENT sci_reciever
    generic(
		N_SHIFTS 				: integer;
		N_bits   				: integer;
		Tc 						: integer);
	PORT(
		--1 MHz serial clock
		clk_port        		: in  std_logic;	
    	--controller ports	
		push_port				: out std_logic;
        --datapath ports
		serial_data_port   		: in  std_logic;	
		parallel_data_port		: out std_logic_vector(7 downto 0));
	END COMPONENT;
	
component morse_translator
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
		morse_out               : out std_logic;
		morse_freq_port			: out std_logic);
end component; 

begin
------------------------------

-- Map testing signals to toplevel ports
Receiver: sci_reciever 
generic map(
	Tc => Tc,
	N_SHIFTS => 10,
	N_bits => 8)               --You don't need a semicolon here
PORT MAP(
		clk_port => Clk,
		push_port => push,--push tells transmitor data is ready
		parallel_data_port => parallel_data,--output data of reciever
		serial_data_port => data);--1 bit input data

Intermediate: queue
generic map(
	N_bytes => N_bytes)
PORT MAP(
		clk_port => Clk,
		in_pop_port => pop,--pop input from morse translator
		in_push_port => push,--push input from sci reciever
		parallel_in_port => parallel_data,--parallel byte input from sci reciever
		parallel_out_port => queue_out_parallel,--poped byte output from queue
		data_valid_port => data_valid);--data valid output from queue

Final: morse_translator
generic map(
    N_flip_flops => 2,
	buzz_freq => buzz_freq) 
port map(
		clk_port => Clk,
		done_port => pop,--pop output to queue
		data_valid_port => data_valid,--data valid input from queue
		data_queue_port => queue_out_parallel,--popped byte input from queue
		morse_out       => morse_out_port,--led blinking morse
		morse_freq_port => morse_freq_out);-- frequency output to buzzer

end Structural;