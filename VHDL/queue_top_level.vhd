-- Course:	 		 Engs 31 16S
-- Author:           Sasha Ries
-- Create Date:      15:44:25 08/22/2022 
-- Design Name: 
-- Module Name:      queue top level 
-- Project Name:	 morse code translator 
-- Target Devices:   Spartan 6 / Nexys 3
-- Tool versions:    ISE 14.4
-- Description:      Top level shell for queue
--
-- Additional Comments:

----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity queue_top_level is
    Port ( Clk 					: in  STD_LOGIC;-- 100 MHz board clock
           data 	   			: in  STD_LOGIC;-- reciever input
           parallel_out         : out STD_LOGIC);-- popped data from queue
end queue_top_level;

architecture Structural of queue_top_level is

-- Signal for the 100 MHz to convert to 9600 baud rate
constant Tc: integer 	:= 10416;
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

--add sci reciever component
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

queue_level: queue
generic map(
	N_bytes => 10)   
PORT MAP(
		clk_port => Clk,
		tx_data => parallel_data,
		tx_start => push,
		tx_done_tick => tx_done,
		tx => serial_out_data_port);
end Structural;