library ieee;
use ieee.std_logic_1164.all;

entity scsi_data_bus_io is
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
begin
end;

architecture behavioral of scsi_data_bus_io is
	-- Control signals
	signal input_write_enable : std_logic;
	signal output_write_enable : std_logic;
	signal scsi_output_enable : std_logic;
	signal pending_reg_next : std_logic;
	signal busy_reg_next : std_logic;
	signal req_reg_next : std_logic;

	-- Data registers
	signal input_data_reg : std_logic_vector(7 downto 0);
	signal output_data_reg : std_logic_vector(7 downto 0);
	signal err_reg : std_logic;

	-- Control registers
	signal direction_reg : std_logic; -- 0 = input, 1 = output
	signal pending_reg : std_logic;
	signal busy_reg : std_logic;
	signal req_reg : std_logic;

	-- Parity generation
	signal parity_data : std_logic_vector(7 downto 0);
	signal parity : std_logic;
	signal parity_err : std_logic;
begin
	-- Control signals
	input_write_enable <= not busy_reg and write_enable;
	output_write_enable <= busy_reg and not req_reg and not scsi_ack and not direction_reg;
	scsi_output_enable <= ((pending_reg and not pending_reg_next) or (not pending_reg and busy_reg)) and direction_reg and output_enable;
	pending_reg_next <= input_write_enable or (pending_reg and req_reg and not scsi_ack);
	busy_reg_next <= pending_reg or (busy_reg and not pending_reg and not req_reg_next);
	req_reg_next <= (not busy_reg and not pending_reg) or (not busy_reg and pending_reg and not scsi_ack) or (busy_reg and not pending_reg and not scsi_ack) or (busy_reg and pending_reg);

	-- Data registers
	process(clk)
	begin
		if rising_edge(clk) then
			if input_write_enable = '1' then
				input_data_reg <= data_in;
			end if;
		end if;
	end process;

	process(rst, clk)
	begin
		if rst = '1' then
			output_data_reg <= X"00";
			err_reg <= '0';
		elsif falling_edge(clk) then
			if output_write_enable = '1' then
				output_data_reg <= scsi_db;
				err_reg <= parity_err;
			end if;
		end if;
	end process;

	-- Control registers
	process(rst, clk)
	begin
		if rst = '1' then
			direction_reg <= '0';
		elsif rising_edge(clk) then
			if input_write_enable = '1' then
				direction_reg <= direction;
			end if;
		end if;
	end process;

	process(rst, clk)
	begin
		if rst = '1' then
			pending_reg <= '0';
		elsif rising_edge(clk) then
			pending_reg <= pending_reg_next;
		end if;
	end process;

	process(rst, clk)
	begin
		if rst = '1' then
			busy_reg <= '0';
			req_reg <= '1';
		elsif falling_edge(clk) then
			busy_reg <= busy_reg_next;
			req_reg <= req_reg_next;
		end if;
	end process;

	-- Parity generation
	parity_data <= input_data_reg when direction_reg = '1' else scsi_db;
	parity <= not (((parity_data(7) xor parity_data(6)) xor (parity_data(5) xor parity_data(4))) xor ((parity_data(3) xor parity_data(2)) xor (parity_data(1) xor parity_data(0))));
	parity_err <= parity xor scsi_dbp;

	-- Internal outputs
	busy <= busy_reg;
	err <= err_reg;
	data_out <= output_data_reg;

	-- SCSI outputs
	scsi_req <= req_reg;
	scsi_db <= (others => 'Z') when scsi_output_enable = '0' else input_data_reg;
	scsi_dbp <= 'Z' when scsi_output_enable = '0' else parity;
end architecture;
