--Sasha Ries/Teddy Wavle
--ES31/CS56
--Morse code tranlsator Queue code.

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;	
--=============================================================
--Entitity Declarations
--=============================================================
entity queue is
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
end queue; 

----------------------------------------------------------
architecture Behavioral of queue is
--create signals
	signal prev_push		: std_logic := '0';
	signal prev_pop			: std_logic := '0';
	signal eq				: std_logic := '0';
	signal push_count		: unsigned(4 downto 0) := "00000";
	signal pop_count		: unsigned(4 downto 0) := "00000";
	signal pop_inc			: std_logic := '0';
	signal push_inc			: std_logic := '0';
	signal pop_sig			: std_logic := '0';
	signal push_sig			: std_logic := '0';
	signal push_tc			: std_logic := '0';
	signal pop_tc           : std_logic := '0';


--create the register file
type regfile_type is 
	array(0 to N_bytes -1) of std_logic_vector(7 downto 0);
	signal regfile : regfile_type;

--the 3 states of the controller
type state_type is (idle, push, pop);
	signal curr_state : state_type := idle;
	signal next_state : state_type;
--------------------------------------------------------------
begin
--Controller:
--State Update:	
StateUpdate: process(clk_port)
begin         
	if rising_edge(clk_port) then
		curr_state <= next_state;
	end if;
end process StateUpdate;

--------------------------------------------------------
--Next State Logic:
NextStateLogic: process(curr_state, in_push_port, in_pop_port)
begin
    --next state gets current state by default
	next_state <= curr_state;
	case curr_state is 
		when idle =>
			if in_push_port = '1' then--push has priority over pop
			--check if push is high then check if queue is full
				if eq = '0' then
					next_state <= push;
				elsif  eq = '1' and prev_push = '0' then
					next_state <= push;
				end if;
			elsif in_pop_port = '1' then
			--check if pop is high then check if queue is full
				if eq = '0' then
					next_state <= pop;
				elsif eq = '1' and prev_pop = '0' then
					next_state <= pop;
				end if;
			end if;
		when push =>
			next_state <= idle;
		when pop =>
			next_state <= idle;
	end case;
end process NextStateLogic;

----------------------------------------------------------------
--check if it is full or empty
equivalent: process(push_count, pop_count)
begin
	if push_count = pop_count then
		eq <= '1';
	else eq <= '0';
	end if;
end process equivalent;

-----------------------------------------------------------------
--Output Logic:
output: process(curr_state)
begin
	pop_sig 		<= '0';
	push_sig		<= '0';
	pop_inc			<= '0';
	push_inc 		<= '0';
	case curr_state is
	--when idle baud counter is paused and set to tc/2 count
		when idle => 
		when push => push_sig <= '1'; push_inc <= '1';
		when pop => pop_sig <= '1'; pop_inc <= '1'; 
	end case;
end process output;
------------------------------------------------------------------
--set up push counter and push tc
push_counter: process(clk_port)
begin
if rising_edge(clk_port) then
    if push_inc = '1' then
        if push_count = N_bytes - 1 then
            push_count <= "00000";
        else
            push_count <= push_count + 1;
           end if;
	--if push_tc = '1' then
		--push_count <= "00000";
	--elsif push_inc = '1' then push_count <= push_count + 1;
	end if;
end if;
end process push_counter;

--push_count_cap: process(push_count)
--begin
	--if push_count = N_bytes - 1 then 
		--push_tc <= '1';
	--else push_tc <= '0';
	--end if;
--end process push_count_cap;
	
------------------------------------------------------------------	
--set up pop counter and pop tc
pop_counter: process(clk_port)
begin
if rising_edge(clk_port) then
    if pop_inc = '1' then
        if pop_count = N_bytes - 1 then
            pop_count <= "00000";
        else
            pop_count <= pop_count + 1;
        end if;
	--if pop_tc = '1' then
		--pop_count <= "00000";
	--elsif pop_inc = '1' then pop_count <= pop_count + 1;
	end if;
end if;
end process pop_counter;

--pop_count_cap: process(pop_count)
--begin
	--if pop_count = N_bytes - 1 then 
		--pop_tc <= '1';
	--else pop_tc <= '0';
	--end if;
--end process pop_count_cap;

-----------------------------------------------------------------
--datapath
register_file: process(clk_port)
begin
	if rising_edge(clk_port) then
		--parallel data is always available to read but data_valid is not always high
        parallel_out_port <= regfile(to_integer(pop_count));
        if eq = '0' then
		--queue is neither empty nor full
			data_valid_port <= '1';
		elsif eq = '1' and prev_pop = '0' and prev_push = '0' then
			--queue is empty but no inputs have been given yet (initial state)
            data_valid_port <= '0';
        elsif eq = '1' and prev_push = '1' then
            --queue is full
			data_valid_port <= '1';
		else data_valid_port <= '0';--queue is empty
	    end if;
	    if push_sig = '1' then
		--add new data to the push address
            regfile(to_integer(push_count)) <= parallel_in_port;
		end if;
	end if;
end process register_file;
-----------------------------------------------------------------
--save state of push and pop for prev_push and prev_pop
save_state: process(clk_port)
begin	
	if rising_edge(clk_port) then
		if in_pop_port = '1' or in_push_port = '1' then
			prev_pop <= in_pop_port;
			prev_push <= in_push_port;
		end if;
	end if;
end process;
end behavioral;
		
	
