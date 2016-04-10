library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity scsi_block_transfer_unit is
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
begin
end;

-- TODO:
-- + read and respond to scsi_data_err
-- + provide a method for the controller to cancel a transfer
architecture behavioral of scsi_block_transfer_unit is
	signal state : std_logic_vector(3 downto 0);
	signal in_progress : std_logic;
	signal direction_reg : std_logic;
	signal address_reg : std_logic_vector(9 downto 0);
	signal count_reg : std_logic_vector(9 downto 0);

	signal read_enable : std_logic;
	signal read_busy : std_logic;
	signal write_enable : std_logic;
	signal write_busy : std_logic;

	signal transfer_requested : std_logic;
	signal transfer_finished : std_logic;
	signal read_complete : std_logic;
	signal write_complete : std_logic;

	signal reg_load : std_logic;
	signal reg_count : std_logic;

	signal direction_load : std_logic;
	signal direction_d : std_logic;

	signal state_load : std_logic;
	signal state_d : std_logic_vector(3 downto 0);

	signal count_reg_is_zero : std_logic;
begin
	in_progress <= not state(0);
	busy <= in_progress;

	err <= '0';

	mem_chip_enable <= 'Z' when in_progress = '0' else '1';
	mem_write_enable <= 'Z' when in_progress = '0' else write_enable and not direction_reg;
	mem_address <= (others => 'Z') when in_progress = '0' else address_reg;
	mem_data_out <= (others => 'Z') when in_progress = '0' else scsi_data_in;

	scsi_data_write_enable <= 'Z' when in_progress = '0' else
	                          write_enable when direction_reg = '1' else
	                          read_enable;
	scsi_data_direction <= 'Z' when in_progress = '0' else direction_reg;
	scsi_data_out <= (others => 'Z') when in_progress = '0' else mem_data_in;

	read_enable <= state(1) and not count_reg_is_zero;
	write_enable <= state(2);
	read_busy <= mem_busy when direction_reg = '1' else scsi_data_busy;
	write_busy <= scsi_data_busy when direction_reg = '1' else mem_busy;

	-- Control
	count_reg_is_zero <= '1' when count_reg = "0000000000" else '0';

	transfer_requested <= state(0) and start;
	transfer_finished <= state(1) and count_reg_is_zero;
	read_complete <= state(2) and not read_busy;
	write_complete <= state(3) and not write_busy;

	reg_load <= transfer_requested;
	reg_count <= write_complete;

	direction_load <= transfer_requested or transfer_finished;
	direction_d <= direction when transfer_requested = '1' else '1';

	state_load <= read_complete or state(1) or transfer_requested or write_complete or transfer_finished;
	state_d <= read_complete & (state(1) and not transfer_finished) & (transfer_requested or write_complete) & transfer_finished;

	-- Counters
	process(clk)
	begin
		if rising_edge(clk) then
			if reg_load = '1' then
				address_reg <= start_address;
				count_reg <= transfer_size;
			elsif reg_count = '1' then
				address_reg <= address_reg + "0000000001";
				count_reg <= count_reg + "1111111111";
			end if;
		end if;
	end process;

	-- Direction, read enable, write enable, and state
	process(clk, rst)
	begin
		if rst = '1' then
			direction_reg <= '0';
			state <= "0001";
		elsif rising_edge(clk) then
			if direction_load = '1' then
				direction_reg <= direction_d;
			end if;

			if state_load = '1' then
				state <= state_d;
			end if;
		end if;
	end process;
end architecture;
		
