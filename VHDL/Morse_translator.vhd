--=============================================================
--Sasha Ries
--ES31/CS56
--Morse Translator code
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
entity morse_translator is
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
end morse_translator; 

--=============================================================
--Architecture + Component Declarations
--=============================================================
architecture Behavioral of morse_translator is
--define constants
constant CLOCK_FREQUENCY  : integer := 100000000;	
constant buzz_divider : integer := CLOCK_FREQUENCY / buzz_freq;
constant buzz_freq_divide : integer := CLOCK_FREQUENCY / 1000;
--=============================================================
--Local Signal Declaration
--=============================================================
signal data_ready		: std_logic := '0';
signal shift_en			: std_logic := '0';
signal morse		    : std_logic_vector(23 downto 0) := (others => '0');
signal morse_reg		: std_logic_vector(23 downto 0) := (others => '0');
signal read_en          : std_logic := '0';
signal clear_delay		: std_logic := '0';
signal morse_translated : std_logic := '0';
signal garbage          : std_logic := '0';--determines if morse is applicable
--signal to check if shift register is empty or if morse character doesnt exist
signal done				: std_logic := '0';
--signals for pipeline flip flop delay
signal pipeline1		: std_logic := '0';
signal pipeline2		: std_logic := '0';
--signals for buzz counter
signal buzz_count		: unsigned(25 downto 0) := (others => '0');
signal buzz_tc			: std_logic := '0';
signal buzz_freq_tc     : std_logic := '0';
signal buzz_freq_count  : unsigned(10 downto 0) := (others => '0');
signal morse_freq       : std_logic := '0';
signal buzz_count_en    : std_logic := '0';
--the 5 states of the controller
type state_type is (idle, read_in, clear, clear1, clear2, shift, wait_for_buzzer);
signal curr_state : state_type := idle;
signal next_state : state_type;

--add LUT component declarations
COMPONENT blk_mem_gen_1
  PORT (
    clka : IN STD_LOGIC;
    addra : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
    douta : OUT STD_LOGIC_VECTOR(23 DOWNTO 0)
  );
END COMPONENT;

begin
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--LUT setup
ROM : blk_mem_gen_1
  PORT MAP (
    clka => clk_port,
    addra => data_queue_port,
    douta => morse
  );
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
NextStateLogic: process(curr_state, data_ready, buzz_tc, done)
begin
next_state <= curr_state;
	case curr_state is
		when idle =>
			if data_ready = '1' then 
			--wait untill LUT time lines up with data_ready
			--this allows the 24 bit morse to be synced with the controller and datapath
				next_state <= read_in;
			end if;
		when read_in =>
			if garbage = '1' then
			--check if morse is valid
			--else pop next character from queue
				next_state <= clear;
			elsif garbage = '0' then
				next_state <= shift;
			end if;
		when shift =>
			if done = '1' then
			--check if all data has been shifted out (variable # of shifts)
				next_state <= clear;
			elsif done = '0' then
				next_state <= wait_for_buzzer;
			end if;
		when wait_for_buzzer =>
			if buzz_tc = '1' then
				next_state <= shift;
			end if;
		when clear =>
			next_state <= clear1;
	    when clear1 => 
	        next_state <= clear2;
	    when clear2 =>
	       next_state <= idle;
	end case;
end process NextStateLogic;
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--Output Logic:
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
output: process(curr_state)
begin
read_en		 <= '0';
shift_en     <= '0';
clear_delay  <= '0';
done_port 	 <= '0';
buzz_count_en <= '0';
case curr_state is
--when idle always try to pop from queue
    when idle =>
    when read_in => read_en <= '1'; shift_en <= '0';
    when shift => shift_en <= '1'; read_en <= '0';    
	when wait_for_buzzer => shift_en <= '0'; read_en <= '0'; buzz_count_en <= '1';
	when clear => clear_delay <= '1'; done_port <= '1';
	--add 2 more clear states to ensure data valid lines up with translator
	when clear1 => clear_delay <= '1'; done_port <= '0';
	when clear2 => clear_delay <= '1'; done_port <= '0';
end case;
end process output;

-------------------------------------------------------------
--processes for datapath
--set up LUT time syncing
flip_flop_delay: process(clk_port)
begin
	if rising_edge(clk_port) then
	--pipelines allow the data_ready to equal data_valid 3 clock cycles later
        if clear_delay = '1' then 
		  pipeline1 <= '0';
		  pipeline2 <= '0';
		  data_ready <= '0';
		else
		  pipeline1 <= data_valid_port;
		  pipeline2 <= pipeline1;
		  data_ready <= pipeline2;
	   end if;
	end if;
end process flip_flop_delay;
--------------------------------------------------------------
--set up buzz timer and roll over
buzz_counter: process(clk_port)
begin
	if rising_edge(clk_port) then
	   if buzz_count_en = '1' then
		  if buzz_tc = '1' then
			 buzz_count <= (others => '0');
		  elsif buzz_tc = '0'then
			 buzz_count <= buzz_count + 1;
		  end if;
	   end if;
	end if;
end process buzz_counter;
--------------------------------------------------------------
buzz_count_cap: process(buzz_count)
begin
	if buzz_count = buzz_divider then 
		buzz_tc <= '1';
	else buzz_tc <= '0';
	end if;
end process buzz_count_cap;
--------------------------------------------------------------
--check if Morse is valid
--check if shift register is empty
Morse_valid: process(read_en, shift_en, clk_port)
begin
    if rising_edge(clk_port) then
        if morse_reg = x"000001" then
	       done <= '1';
	   else done <= '0';
	   end if;
	end if;
	if morse(23 downto 21) = "111" then
	   garbage <= '1';
	else garbage <= '0';
	end if;
end process Morse_valid;

-----------------------------------------------------------------
--shift register
shift_register: process(clk_port) 
begin
	if rising_edge(clk_port) then
        if read_en = '1' then
	       morse_reg <= morse;
	    end if;
        if shift_en = '1' then 
			morse_translated <= morse_reg(0);
			morse_out <= morse_reg(0);
			morse_reg <= '0' & morse_reg(23 downto 1);
	    else 
	       morse_translated <= '0';
		end if;
		if done = '1' then
		   morse_out <= '0';
		end if;
	end if;
end process shift_register;
-----------------------------------------------------------------
--buzzer frequency generator
buzzer: process(clk_port) 
begin
	if rising_edge(clk_port) then
	   morse_freq_port <= morse_freq;
	   if morse_translated = '1' then 
	       if buzz_freq_tc = '1' then
		      morse_freq <= not(morse_freq);
		   end if;
	   else morse_freq <= '0';
	   end if;
    end if;
end process buzzer;

-------------------------------------------------
--create a clock divider for buzzer swaure wave frequency of 500Hz
buzz_freq_counter: process(clk_port)
begin
	if rising_edge(clk_port) then
		if buzz_freq_tc = '1' then
			buzz_freq_count <= (others => '0');
		elsif buzz_freq_tc = '0' then
			buzz_freq_count <= buzz_freq_count + 1;
		end if;
	end if;
end process buzz_freq_counter;
--------------------------------------------------------------
--determine when each buzzer clock cycle is halfway
buzz_freq_count_cap: process(buzz_freq_count)
begin
	if buzz_freq_count = buzz_freq_divide then 
		buzz_freq_tc <= '1';
	else buzz_freq_tc <= '0';
	end if;
end process buzz_freq_count_cap;
end Behavioral; 
	

