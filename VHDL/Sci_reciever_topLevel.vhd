----------------------------------------------------------------------------------
-- Course:	 		 Engs 31 16S
-- Author:           Sasha Ries
-- Create Date:      15:44:25 08/15/2022 
-- Design Name: 
-- Module Name:      sci top level 
-- Project Name:	 morse code translator 
-- Target Devices:   Spartan 6 / Nexys 3
-- Tool versions:    ISE 14.4
-- Description:      Top level shell for sci reciever
--
-- Dependencies:     SerialRx.vhd (eventually, SerialTx.vhd)
--
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.all;

library UNISIM;					-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

entity transmitor_reciever is
    Port ( Clk 					: in  STD_LOGIC;-- 100 MHz board clock
           data 	   			: in  STD_LOGIC;-- Rx input
           tx_done              : out STD_LOGIC;-- tx done tick
           serial_out_data_port : out std_logic);-- serial data stream
end transmitor_reciever;

architecture Structural of transmitor_reciever is

-- Signals for the 100 MHz to convert to 9600 baud rate
constant Tc: integer 	:= 10416;
-- Other signals
signal parallel_data	: std_logic_vector(7 downto 0);
signal push 			: std_logic;
signal serial_out 		: std_logic;
signal clock            : std_logic;

-- Component declarations
COMPONENT SerialTx
	PORT(
			clk             : in  STD_LOGIC;
			tx_data 		: in  STD_LOGIC_VECTOR (7 downto 0);
			tx_start 		: in  STD_LOGIC;
			tx_done_tick	: out  STD_LOGIC;
			tx 				: out  STD_LOGIC);
	END COMPONENT;

-- Add declarations for SerialTx and Mux7seg here
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
-------------------------
	
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

Transmitor: SerialTx
PORT MAP(
		clk => Clk,
		tx_data => parallel_data,
		tx_start => push,
		tx_done_tick => tx_done,
		tx => serial_out_data_port);
end Structural;
