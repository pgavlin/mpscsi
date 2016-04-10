library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
 
entity scsi_block_transfer_unit_tb is
end scsi_block_transfer_unit_tb;
 
architecture behavior of scsi_block_transfer_unit_tb is 
 
	 -- component declaration for the unit under test (uut)
 
	component scsi_block_transfer_unit
		port(
			-- Control bus signals
			rst : in std_logic;
			clk : in std_logic;
			start : in std_logic;
			direction : in std_logic;
			start_address : in std_logic_vector(9 downto 0);
			transfer_size : in std_logic_vector(9 downto 0);
			busy : out std_logic;
			err : out std_logic;

			-- Memory bus signals
			mem_chip_enable : out std_logic;
			mem_write_enable : out std_logic;
			mem_address : out std_logic_vector(9 downto 0);
			mem_busy : in std_logic;
			mem_data_in : in std_logic_vector(7 downto 0);
			mem_data_out : out std_logic_vector(7 downto 0);

			-- SCSI data bus signals
			scsi_data_write_enable : out std_logic;
			scsi_data_direction : out std_logic;
			scsi_data_busy : in std_logic;
			scsi_data_err : in std_logic;
			scsi_data_in : in std_logic_vector(7 downto 0);
			scsi_data_out : out std_logic_vector(7 downto 0)
		);
	end component;

	component scsi_data_bus_io
		port(
			-- Internal bus signals
			rst : in std_logic;
			clk : in std_logic;
			write_enable : in std_logic;
			output_enable : in std_logic;
			direction : in std_logic;
			busy : out std_logic;
			err : out std_logic;
			data_in : in std_logic_vector(7 downto 0);
			data_out : out std_logic_vector(7 downto 0);

			-- SCSI bus signals
			scsi_req : out std_logic;
			scsi_ack : in std_logic;
			scsi_db : inout std_logic_vector(7 downto 0);
			scsi_dbp : inout std_logic
		);
	end component;

	-- Control bus signals
	signal rst : std_logic := '1';
	signal clk : std_logic := '0';
	signal start : std_logic := '0';
	signal direction : std_logic := '0';
	signal start_address : std_logic_vector(9 downto 0) := (others => '0');
	signal transfer_size : std_logic_vector(9 downto 0) := (others => '0');
	signal busy : std_logic;
	signal err : std_logic;

	-- Memory signals
	type mem is array(1023 downto 0) of std_logic_vector(7 downto 0);
	signal mem1k : mem := (others => "00000000");

	signal mem_chip_enable : std_logic;
	signal mem_write_enable : std_logic;
	signal mem_address : std_logic_vector(9 downto 0);
	signal mem_busy : std_logic := '0';
	signal mem_data_in : std_logic_vector(7 downto 0) := (others => '0');
	signal mem_data_out : std_logic_vector(7 downto 0);

	-- SCSI data bus signals
	signal scsi_data_write_enable : std_logic := 'L';
	signal scsi_data_direction : std_logic := 'H';
	signal scsi_data_busy : std_logic;
	signal scsi_data_err : std_logic;
	signal scsi_data_in : std_logic_vector(7 downto 0);
	signal scsi_data_out : std_logic_vector(7 downto 0);

	-- SCSI signals
	signal scsi_req : std_logic;
	signal scsi_ack : std_logic;
	signal scsi_db : std_logic_vector(7 downto 0);
	signal scsi_dbp : std_logic;

	-- clock period definitions
	constant clk_period : time := 100 ns;
begin
	scsi_data_write_enable <= 'L';
	scsi_data_direction <= 'H';
	scsi_db <= (others => 'H');
	scsi_dbp <= 'H';

	uut : scsi_block_transfer_unit
		port map(
			rst => rst,
			clk => clk,
			start => start,
			direction => direction,
			start_address => start_address,
			transfer_size => transfer_size,
			busy => busy,
			err => err,
			mem_chip_enable => mem_chip_enable,
			mem_write_enable => mem_write_enable,
			mem_address => mem_address,
			mem_busy => mem_busy,
			mem_data_in => mem_data_in,
			mem_data_out => mem_data_out,
			scsi_data_write_enable => scsi_data_write_enable,
			scsi_data_direction => scsi_data_direction,
			scsi_data_busy => scsi_data_busy,
			scsi_data_err => scsi_data_err,
			scsi_data_in => scsi_data_in,
			scsi_data_out => scsi_data_out
		);

	data_bus_io : scsi_data_bus_io
		port map(
			rst => rst,
			clk => clk,
			write_enable => scsi_data_write_enable,
			output_enable => '1',
			direction => scsi_data_direction,
			busy => scsi_data_busy,
			err => scsi_data_err,
			data_in => scsi_data_out,
			data_out => scsi_data_in,
			scsi_req => scsi_req,
			scsi_ack => scsi_ack,
			scsi_db => scsi_db,
			scsi_dbp => scsi_dbp
		);

	-- Clock process
	process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	-- Memory process
	process(clk, mem_chip_enable)
	begin
		if mem_chip_enable = '0' then
			mem_busy <= '0';
			mem_data_in <= (others => 'Z');
		elsif rising_edge(clk) then
			mem_data_in <= mem1k(to_integer(unsigned(mem_address)));

			if mem_write_enable = '1' then
				mem1k(to_integer(unsigned(mem_address))) <= mem_data_out;
			end if;
		end if;
	end process;

	-- SCSI process
	process(scsi_req, direction)
	begin
		if direction = '0' then
			scsi_db <= (others => 'Z');
			scsi_dbp <= 'Z';
		else
			scsi_db <= X"AA";
			scsi_dbp <= '1';
		end if;

		if scsi_req = '0' then
			scsi_ack <= '0';
		else
			scsi_ack <= '1';
		end if;
	end process;

	-- Stimulus process
	process
	begin		
		wait for clk_period * 10;
		rst <= '0';

		-- insert stimulus here 
		start_address <= "0000010000";
		transfer_size <= "0000001000";

		direction <= '1';
		start <= '1';
		wait for clk_period;

		start <= '0';
		wait until busy = '0';

		direction <= '0';
		start <= '1';
		wait for clk_period;

		start <= '0';
		wait until busy = '0';

		wait;
	end process;
end;
