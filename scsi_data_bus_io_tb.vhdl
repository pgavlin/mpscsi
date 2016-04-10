library ieee;
use ieee.std_logic_1164.all;
 
entity scsi_data_bus_io_tb is
end scsi_data_bus_io_tb;
 
architecture behavior of scsi_data_bus_io_tb is 
	component scsi_data_bus_io
		port(
			-- internal bus signals
			rst : in std_logic;
			clk : in std_logic;
			write_enable : in std_logic;
			output_enable : in std_logic;
			direction : in std_logic;
			busy : out std_logic;
			err : out std_logic;
			data_in : in std_logic_vector(7 downto 0);
			data_out : out std_logic_vector(7 downto 0);

			-- scsi bus signals
			scsi_req : out std_logic;
			scsi_ack : in std_logic;
			scsi_db : inout std_logic_vector(7 downto 0);
			scsi_dbp : inout std_logic
		);
	end component;
	 
	signal rst : std_logic := '1';
	signal clk : std_logic := '0';
	signal write_enable : std_logic := '0';
	signal output_enable : std_logic := '0';
	signal direction : std_logic := '0';
	signal busy : std_logic;
	signal err : std_logic;
	signal data_in : std_logic_vector(7 downto 0);
	signal data_out : std_logic_vector(7 downto 0);

	signal scsi_req : std_logic;
	signal scsi_ack : std_logic;
	signal scsi_db : std_logic_vector(7 downto 0);
	signal scsi_dbp : std_logic;

	constant clk_period : time := 100 ns;
begin
	uut : scsi_data_bus_io
		port map(
			rst => rst,
			clk => clk,
			write_enable => write_enable,
			output_enable => output_enable,
			direction => direction,
			busy => busy,
			err => err,
			data_in => data_in,
			data_out => data_out,

			-- scsi bus signals
			scsi_req => scsi_req,
			scsi_ack => scsi_ack,
			scsi_db => scsi_db,
			scsi_dbp => scsi_dbp
		);

	-- Clock process
	process
	begin
		clk <= '0';
		wait for clk_period / 2;
		clk <= '1';
		wait for clk_period / 2;
	end process;

	-- Stimulus process
	stim_proc: process
	begin
		-- Set up SCSI bus
		scsi_ack <= '1';
		scsi_db <= (others => 'Z');
		scsi_dbp <= 'Z';

		-- Hold reset for 10 clocks
		wait for clk_period * 10;
		rst <= '0';

		-- Request a SCSI write
		write_enable <= '1';
		output_enable <= '1';
		direction <= '0';
		data_in <= X"AA";

		wait until scsi_req = '0';
		scsi_ack <= '0';
		wait until scsi_req = '1';
		scsi_ack <= '1';

		-- Request a SCSI read
		write_enable <= '1';
		output_enable <= '1';
		direction <= '1';
		scsi_db <= X"BB";
		scsi_dbp <= '1';

		wait until scsi_req = '0';
		scsi_ack <= '0';
		wait until scsi_req = '1';
		scsi_ack <= '1';

		-- Request a SCSI write before the bus is free
		write_enable <= '1';
		output_enable <= '1';
		direction <= '0';
		data_in <= X"55";
		scsi_ack <= '0';

		wait for clk_period;
		write_enable <= '0';

		wait for clk_period * 3;
		scsi_db <= (others => 'Z');
		scsi_dbp <= 'Z';
		scsi_ack <= '1';

		wait until scsi_req = '0';
		scsi_ack <= '0';
		wait until scsi_req = '1';

		-- Request a SCSI read before the bus is free
		write_enable <= '1';
		output_enable <= '1';
		direction <= '1';

		wait for clk_period;
		write_enable <= '0';

		wait for clk_period * 3;
		scsi_db <= X"CC";
		scsi_dbp <= '1';
		scsi_ack <= '1';

		wait until scsi_req = '0';
		scsi_ack <= '0';
		wait until scsi_req = '1';
		scsi_ack <= '1';

		wait;
	end process;
end;
