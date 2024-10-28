--------------------------------------------------------------------------------
-- Course:	 		Engs 31 16S
--
-- Create Date:   17:11:39 07/25/2009
-- Design Name:   
-- Module Name:   Sci_reciever_tb.vhd
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
 
ENTITY Sci_reciever_Tb IS
END Sci_reciever_Tb;
 
ARCHITECTURE behavior OF Sci_reciever_Tb IS 
 
COMPONENT sci_reciever
	generic(
		N_SHIFTS 				: integer;
		N_bits   				: integer;
		Tc 						: integer);
	port(
	    --1 MkHz serial clock
		clk_port				: in  std_logic;	
    	
    	--controller signals	
		push_port				: out std_logic;
        
        --datapath signals
		serial_data_port   		: in  std_logic;	
		parallel_data_port		: out std_logic_vector(N_bits - 1 downto 0));
	END COMPONENT;
   

   --Inputs
   signal clk : std_logic := '0';
   signal data : std_logic := '1';

 	--Outputs
   signal rx_shift : std_logic;
   signal data_out : std_logic_vector(7 downto 0);
   signal push : std_logic;

   -- Clock period definitions
   constant clk_period : time := 10ns;		-- 100 MHz clock
	
	-- Data definitions
	constant bit_time : time := 104us;		-- 9600 baud
--- constant bit_time : time := 8.68us;		-- 115,200 baud
	constant TxData : std_logic_vector(7 downto 0) := "11101001";
	
BEGIN 
	-- Instantiate the Unit Under Test (UUT)
   uut: sci_reciever generic map(
		N_SHIFTS => 10,
		N_bits  =>  8,
		Tc =>       10416)
		PORT MAP (
          clk_port => clk,
          serial_data_port => data,
          parallel_data_port => data_out,
          push_port => push);

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
		
		data <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			data <= TxData(bitcount);
			wait for bit_time;
		end loop;
		
		data <= '1';		-- Stop bit
		wait for 20 us;
		
		data <= '0';		-- Start bit
		wait for bit_time;
		
		for bitcount in 0 to 7 loop
			data <= not( TxData(bitcount) );
			wait for bit_time;
		end loop;
		
		data <= '1';		-- Stop bit
		
		wait;
   end process;
END;
