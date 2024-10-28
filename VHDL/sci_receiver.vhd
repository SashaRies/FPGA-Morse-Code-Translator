--=============================================================
--Sasha Ries
--ES31/CS56
--SCI reciever for Morse code translator
--Your name goes here: 
--=============================================================

--=============================================================
--Library Declarations
--=============================================================
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;			-- needed for arithmetic
use ieee.math_real.all;				-- needed for automatic register sizing
library UNISIM;						-- needed for the BUFG component
use UNISIM.Vcomponents.ALL;

--=============================================================
--Entitity Declarations
--=============================================================
entity sci_reciever is
--setup generics to hopefully resuse the shift register
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
end sci_reciever; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of sci_reciever is
--=============================================================
--Local Signal Declaration
--=============================================================
signal shift_enable		: std_logic := '0';
signal baud_enable		: std_logic := '0';
signal shift_reg	    : std_logic_vector(N_bits + 1 downto 0) := (others => '0');
signal baud_tc          : std_logic := '0';
signal tc_bit			: std_logic := '0';
signal load_en			: std_logic := '0';
--count for baud counter
signal baud_y			: unsigned(14 downto 0) := (others => '0');
--count for bit counter
signal bit_y            : unsigned(3 downto 0) := "0000";

--the 5 states of the controller
type state_type is (idle, wait_for_baud_tc, shift, data_ready, load);
signal curr_state : state_type := idle;
signal next_state : state_type;

begin
--=============================================================
--Controller:
--=============================================================
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--State Update:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++		
StateUpdate: process(clk_port)
begin         
if rising_edge(clk_port) then
	curr_state <= next_state;
end if;
end process StateUpdate;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Next State Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
NextStateLogic: process(curr_state, serial_data_port, tc_bit, baud_tc)
begin
next_state <= curr_state;
	case curr_state is
	   when idle =>
	       if serial_data_port = '1' then
	           next_state <= idle;
	       elsif serial_data_port = '0' then
	           next_state <= wait_for_baud_tc;
	       end if;
	   when wait_for_baud_tc =>
	   --wait untill baud_tc goes high, 
	   --then enable bit counter and shift register
	       if baud_tc = '1' then
	           next_state <= shift;
		   else next_state <= wait_for_baud_tc;
	       end if;
	   when shift =>
	   --check if more shifts need to be done
	   --otherwise all data has been shifted in
		   if tc_bit = '0' then
			   next_state <= wait_for_baud_tc;
		   elsif tc_bit = '1' then
			   next_state <= load;
	       end if;
		when load =>
			next_state <= data_ready;
	   when data_ready =>
		   next_state <= idle;
	end case;
end process NextStateLogic;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Output Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
output: process(curr_state)
begin
push_port    <= '0';
shift_enable <= '0';
baud_enable  <= '0';
load_en 	 <= '0';
case curr_state is
--when idle baud counter is paused and set to tc/2 count
    when idle => 
    when wait_for_baud_tc => baud_enable <= '1'; shift_enable <= '0';
    when shift => shift_enable <= '1'; baud_enable <= '1';    
	when load => load_en <= '1';
	when data_ready => push_port <= '1'; shift_enable <= '0'; baud_enable <= '0';
end case;
end process output;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--set up baud counter and baud_tc:
baud_counter: process(clk_port)
begin
if rising_edge(clk_port) then
    if baud_enable = '0' then
        baud_y <= to_unsigned(Tc/2,15);--say width of 7 value and cast integer to unsigned
    elsif baud_tc = '1' then
        baud_y <= (others => '0');
	else baud_y <= baud_y + 1;
    end if;   
end if;
end process baud_counter;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
baud_count_cap: process(baud_y)
begin
if baud_y = Tc - 1 then
    baud_tc <= '1';
    else baud_tc <= '0';
end if;
end process baud_count_cap;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--set up bit counter and bit tc
bit_counter: process(clk_port)
begin
if rising_edge(clk_port) then
	if tc_bit = '1' then
		bit_y <= "0000";
	elsif baud_tc = '1'then
	   bit_y <= bit_y + 1;
	end if;
end if;
end process bit_counter;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
bit_count_cap: process(bit_y)
begin
if bit_y = N_shifts then 
	tc_bit <= '1';
else tc_bit <= '0';
end if;
end process bit_count_cap;
--=============================================================
--Datapath:
--=============================================================
shift_register: process(clk_port) 
begin
	if rising_edge(clk_port) then
        if shift_enable = '1' then shift_reg <= serial_data_port & shift_reg(9 downto 1);
		end if;
		if load_en = '1' then
			parallel_data_port <= shift_reg(8 downto 1);
		end if;
	end if;
end process;
end Behavioral; 