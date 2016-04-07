library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity scsi_block_transfer_unit is
	port(
		-- Control bus signals
		rst  : in std_logic;
		clk  : in std_logic;
		sel  : in std_logic;
		rw   : in std_logic;
		start_address : in std_logic_vector(9 downto 0);
		transfer_size : in std_logic_vector(9 downto 0);
		busy : out std_logic;
		err : out std_logic;

		-- Memory bus signals
		mem_sel : out std_logic;
		mem_rw : out std_logic;
		mem_address : out std_logic_vector(9 downto 0);
		mem_busy : in std_logic;
		mem_data : inout std_logic_vector(7 downto 0);

		-- SCSI data bus signals
		scsi_data_sel : out std_logic;
		scsi_data_rw : out std_logic;
		scsi_data_busy : in std_logic;
		scsi_data_err : in std_logic;
		scsi_data : inout std_logic_vector(7 downto 0)
	);
begin
end;

-- TODO:
-- + read and respond to scsi_data_err
-- + provide a method for the controller to cancel a transfer
architecture behavioral of scsi_block_transfer_unit is
	signal state : std_logic_vector(3 downto 0);
	signal in_progress : std_logic;
	signal direction : std_logic;
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

	signal read_enable_load : std_logic;
	signal read_enable_d : std_logic;

	signal write_enable_load : std_logic;
	signal write_enable_d : std_logic;

	signal state_load : std_logic;
	signal state_d : std_logic_vector(3 downto 0);

	signal count_reg_is_zero : std_logic;
begin
	in_progress <= not state(0);
	busy <= in_progress;

	err <= '0';

	mem_rw <= 'Z' when in_progress = '0' else not direction;
	mem_address <= "ZZZZZZZZZZ" when in_progress = '0' else address_reg;
	mem_data <= "ZZZZZZZZ" when in_progress = '0' or direction = '0' else scsi_data;

	scsi_data_rw <= 'Z' when in_progress = '0' else direction;
	scsi_data <= "ZZZZZZZZ" when in_progress = '0' or direction = '1' else mem_data;

	mem_sel <= 'Z' when in_progress = '0' else
	           read_enable when direction = '0' else
	           write_enable;

	scsi_data_sel <= 'Z' when in_progress = '0' else
	                 write_enable when direction = '0' else
	                 read_enable;

	read_busy <= mem_busy when direction = '0' else scsi_data_busy;
	write_busy <= scsi_data_busy when direction = '0' else mem_busy;

	-- Control
	count_reg_is_zero <= '1' when count_reg = "0000000000" else '0';

	transfer_requested <= state(0) and sel;
	transfer_finished <= state(1) and count_reg_is_zero;
	read_complete <= state(2) and not read_busy;
	write_complete <= state(3) and not write_busy;

	reg_load <= transfer_requested;
	reg_count <= write_complete;

	direction_load <= transfer_requested or transfer_finished;
	direction_d <= rw when transfer_requested = '1' else '1';

	read_enable_load <= state(1) or write_complete or transfer_finished;
	read_enable_d <= state(1) and not count_reg_is_zero;

	write_enable_load <= read_complete or write_complete or transfer_finished;
	write_enable_d <= state(2);

	state_load <= read_complete or state(1) or transfer_requested or write_complete or transfer_finished;
	state_d <= read_complete & state(1) & (transfer_requested or write_complete) & transfer_finished;

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
			direction <= '1';
			read_enable <= '0';
			write_enable <= '0';
			state <= "0001";
		elsif rising_edge(clk) then
			if direction_load = '1' then
				direction <= direction_d;
			end if;

			if read_enable_load = '1' then
				read_enable <= read_enable_d;
			end if;

			if write_enable_load = '1' then
				write_enable <= write_enable_d;
			end if;

			if state_load = '1' then
				state <= state_d;
			end if;
		end if;
	end process;
end architecture;
		
