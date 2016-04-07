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
	type state_t is (IDLE, START, READ_WAIT, WRITE_WAIT);

	signal state : state_t;
	signal state_in : state_t;
	signal in_progress : std_logic;
	signal direction : std_logic;
	signal direction_in : std_logic;
	signal address_reg : std_logic_vector(9 downto 0);
	signal address_reg_in : std_logic_vector(9 downto 0);
	signal count_reg : std_logic_vector(9 downto 0);
	signal count_reg_in : std_logic_vector(9 downto 0);

	signal read_enable : std_logic;
	signal read_enable_in : std_logic;
	signal read_busy : std_logic;
	signal write_enable : std_logic;
	signal write_enable_in : std_logic;
	signal write_busy : std_logic;
begin
	in_progress <= '0' when state = IDLE else '1';
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
	process(state, sel, rw, start_address, transfer_size, count_reg, read_busy, write_busy, address_reg)
	begin
		case state is
			when IDLE =>
				if sel = '1' then
					direction_in <= rw;
					address_reg_in <= start_address;
					count_reg_in <= transfer_size;
					state_in <= START;
				end if;

			when START =>
				if count_reg = "0000000000" then
					read_enable_in <= '0';
					write_enable_in <= '0';
					state_in <= IDLE;
				else
					read_enable_in <= '1';
					write_enable_in <= '0';
					state_in <= READ_WAIT;
				end if;

			when READ_WAIT =>
				if read_busy = '0' then
					write_enable_in <= '1';
					state_in <= WRITE_WAIT;
				end if;

			when WRITE_WAIT =>
				if write_busy = '0' then
					read_enable_in <= '0';
					write_enable_in <= '0';
					address_reg_in <= address_reg + "0000000001";
					count_reg_in <= count_reg + "1111111111";
					state_in <= START;
				end if;
		end case;
	end process;

	process(clk, rst)
	begin
		if rst = '1' then
			read_enable <= '0';
			write_enable <= '0';

			direction <= '1';
			address_reg <= "0000000000";
			count_reg <= "0000000000";
			state <= IDLE;
		elsif rising_edge(clk) then
			read_enable <= read_enable_in;
			write_enable <= write_enable_in;

			direction <= direction_in;
			address_reg <= address_reg_in;
			count_reg <= count_reg_in;
			state <= state_in;
		end if;
	end process;
end architecture;
		
