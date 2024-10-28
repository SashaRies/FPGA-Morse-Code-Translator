--Sasha Ries, Teddy Wavle
--ES31/CS56
--Morse code translator Queue testbench code.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;	
--=============================================================
--Entitity Declarations
--=============================================================
ENTITY Queue_tb IS
END Queue_tb;

ARCHITECTURE behavior OF Queue_tb IS 

Component queue is
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

--put signals here
   --Inputs
   signal clk : std_logic := '0';
   signal in_pop : std_logic := '0';
   signal in_push : std_logic := '0';
   signal parallel_in : std_logic_vector(7 downto 0) := "00000000";
   
   --Outputs
   signal data_valid : std_logic;
   signal parallel_out : std_logic_vector(7 downto 0);
   
   --Clock Period Definition
   constant clk_period : time := 10ns; --100 MHz clock
   
   --Sample Data Inputs for Datapath
   constant input1 : std_logic_vector(7 downto 0) := "11101001";
   constant input2 : std_logic_vector(7 downto 0) := "00101011";
   constant input3 : std_logic_vector(7 downto 0) := "01100110";
   constant input4 : std_logic_vector(7 downto 0) := "10010001";
  
	
BEGIN
	uut: queue generic map(
		N_bytes => 6)
		PORT MAP (
			clk_port => clk,
			in_pop_port => in_pop,
			in_push_port => in_push,
			parallel_in_port => parallel_in,
			data_valid_port => data_valid,
			parallel_out_port => parallel_out);
		
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
	begin --spread out tming
	--make inputs only 1 clock cycle long
		wait for 2.7*clk_period;--input 1 thing
		in_push <= '1';
		parallel_in <= input1;
		wait for clk_period;
		in_push <= '0';
		
		wait for 5*clk_period;--input 1 thing
		in_push <= '1';
		parallel_in <= input2;	
		wait for clk_period;
		in_push <= '0';
		
		wait for 5*clk_period;--output 1 thing
        in_pop <= '1';
		wait for clk_period;
		in_pop <= '0';--should see input1
		
		wait for 5*clk_period;--output 1 thing
		in_pop <= '1';
		wait for clk_period;
		in_pop <= '0';--should see input2
		
		-- fill queue entirely
		wait for 5*clk_period;
		for fillup in 0 to 6 loop
			in_push  <= '1';
			parallel_in <= input3;
			wait for clk_period;
			in_push <= '0';
			wait for 5*clk_period;
		end loop;
		
		-- try to add something else to queue
		in_push <= '1';
		parallel_in <= input4;
        wait for clk_period;		
		in_push <= '0';
		
		--pop once
		wait for 5*clk_period;
		in_pop <= '1';
		wait for 1*clk_period;
		in_pop <= '0';
		
		-- try again to add something else to queue
		wait for 5*clk_period;
		in_push <= '1';
		parallel_in <= input4;
        wait for clk_period;		
		in_push <= '0';
		
		--clear queue
		wait for 5*clk_period;
		for clear in 0 to 7 loop
			in_pop  <= '1';
			wait for clk_period;
			in_pop <= '0';
			wait for 5*clk_period;
		end loop;
		--should see only input3 coming out
		
		--try to pop from empty queue
		in_pop <= '1';
		wait for 1*clk_period;
		in_pop <= '0';
		--nothing should be outputed
		
		wait for 5*clk_period;
		in_push <= '1';
		parallel_in <= input1;
        wait for clk_period;		
		in_push <= '0';
		
		wait;
	end process;
END;
	