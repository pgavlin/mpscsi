library ieee;
use ieee.std_logic_1164.all;

entity scsi_data_bus_io is
	port(
		-- Internal bus signals
		rst   : in std_logic;
		sel   : in std_logic;
		rw    : in std_logic;
		busy  : out std_logic;
		err   : out std_logic;
		data  : inout std_logic_vector(7 downto 0);

		-- SCSI bus signals
		scsi_req : out std_logic;
		scsi_io  : out std_logic;
		scsi_ack : in std_logic;
		scsi_db  : inout std_logic_vector(7 downto 0);
		scsi_dbp : inout std_logic
	);
begin
end;

architecture behavioral of scsi_data_bus_io is
	signal sel_rising_edge : std_logic;
	signal sel_rising_edge_en : std_logic;
	signal sel_rising_edge_rst : std_logic;

	signal scsi_ack_rising_edge : std_logic;
	signal scsi_ack_rising_edge_en : std_logic;
	signal scsi_ack_rising_edge_rst : std_logic;

	signal scsi_ack_falling_edge : std_logic;
	signal scsi_ack_falling_edge_en : std_logic;
	signal scsi_ack_falling_edge_rst : std_logic;

	signal in_progress : std_logic;
	signal in_progress_rst : std_logic;

	signal req : std_logic;
	signal req_rst : std_logic;

	signal direction : std_logic;

	signal parity_sel : std_logic;
	signal parity_data : std_logic_vector(7 downto 0);
	signal parity : std_logic;

	signal data_out : std_logic_vector(7 downto 0);
	signal err_out : std_logic;
begin
	busy <= in_progress;
	scsi_req <= req;
	scsi_io <= direction;

	-- Parity generation is multiplexed based on whether or not a transfer
	-- is in progress and if so, the direction of the transfer. If no transfer
	-- is in progress, the `data` lines feed the parity generator, allowing
	-- its output to be latched with the rising edge of `sel`. Otherwise,
	-- the parity generator is fed by the SCSI data bus.
	parity_sel <= in_progress and direction;

	parity_data <= data when parity_sel = '0' else
	               scsi_db when parity_sel = '1' else
	               "XXXXXXXX";

	parity <= not (((parity_data(7) xor parity_data(6)) xor (parity_data(5) xor parity_data(4))) xor ((parity_data(3) xor parity_data(2)) xor (parity_data(1) xor parity_data(0))));

	-- Edge detectors
	sel_rising_edge_en <= not in_progress;
	sel_rising_edge_rst <= rst or (in_progress and scsi_ack_rising_edge);
	process(sel, sel_rising_edge_rst)
	begin
		if sel_rising_edge_rst = '1' then
			sel_rising_edge <= '0';
		elsif rising_edge(sel) and sel_rising_edge_en = '1' then
			sel_rising_edge <= '1';
		end if;
	end process;

	scsi_ack_rising_edge_en <= in_progress;
	scsi_ack_rising_edge_rst <= rst or (in_progress and scsi_ack_rising_edge);
	process(scsi_ack, scsi_ack_rising_edge_rst)
	begin
		if scsi_ack_rising_edge_rst = '1' then
			scsi_ack_rising_edge <= '0';
		elsif rising_edge(scsi_ack) and scsi_ack_rising_edge_en = '1' then
			scsi_ack_rising_edge <= '1';
		end if;
	end process;

	scsi_ack_falling_edge_en <= in_progress;
	scsi_ack_falling_edge_rst <= rst or (in_progress and scsi_ack_rising_edge);
	process (scsi_ack, scsi_ack_falling_edge_rst)
	begin
		if scsi_ack_falling_edge_rst = '1' then
			scsi_ack_falling_edge <= '0';
		elsif falling_edge(scsi_ack) and scsi_ack_falling_edge_en = '1' then
			scsi_ack_falling_edge <= '1';
		end if;
	end process;

	in_progress_rst <= rst or (in_progress and scsi_ack_rising_edge);
	process(sel_rising_edge, in_progress_rst)
	begin
		if in_progress_rst = '1' then
			in_progress <= '0';
			direction <= 'Z';

			scsi_db <= "ZZZZZZZZ";
			scsi_dbp <= 'Z';
		elsif rising_edge(sel_rising_edge) then
			in_progress <= '1';
			direction <= rw;

			if rw = '0' then
				scsi_db <= data;
				scsi_dbp <= parity;
			else
				scsi_db <= "ZZZZZZZZ";
				scsi_dbp <= 'Z';
			end if;
		end if;
	end process;

	req_rst <= rst or (in_progress and scsi_ack_falling_edge);
	process(sel_rising_edge, req_rst)
	begin
		if req_rst = '1' then
			req <= '1';
		elsif rising_edge(sel_rising_edge) then
			req <= '0';
		end if;
	end process;

	-- Output data and the `err` signal are latched on the falling edge
	-- of `scsi_ack` if a read is in progress. Output data remains valid
	-- until the next `rst` pulse, the next transfer, or the assertion
	-- of `rw`.
	data <= data_out when rw = '1' else "ZZZZZZZZ";
	err <= err_out when rw = '1' else '0';

	process(scsi_ack, rst)
	begin
		if rst = '1' then
			data_out <= "ZZZZZZZZ";
			err_out <= '0';
		elsif falling_edge(scsi_ack) then
			if in_progress = '1' and direction = '1' then
				data_out <= scsi_db;
				err_out <= parity xor scsi_dbp;
			end if;
		end if;
	end process;
end architecture;

