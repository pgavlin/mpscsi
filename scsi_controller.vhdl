library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity scsi_controller is
	port(
		rst : in std_logic;
		clk : in std_logic;

		scsi_bsy : inout std_logic;
		scsi_sel : in std_logic;

		scsi_cd : out std_logic;
		scsi_io : inout std_logic;
		scsi_msg : out std_logic;
		scsi_req : out std_logic;
		scsi_ack : in std_logic;
		scsi_atn : in std_logic;

		scsi_db : inout std_logic_vector(7 downto 0);
		scsi_dbp : inout std_logic
	);
end entity;

architecture behavioral of scsi_controller is
	component scsi_data_bus_io
		port(
			rst : in std_logic;
			clk : in std_logic;
			write_enable : in std_logic;
			output_enable : in std_logic;
			direction : in std_logic;
			busy : out std_logic;
			err : out std_logic;
			data_in : in std_logic_vector(7 downto 0);
			data_out : out std_logic_vector(7 downto 0);

			scsi_req : out std_logic;
			scsi_ack : in std_logic;
			scsi_db : inout std_logic_vector(7 downto 0);
			scsi_dbp : inout std_logic
		);
	end component;

	component scsi_block_transfer_unit
		port(
			rst : in std_logic;
			clk : in std_logic;
			start : in std_logic;
			direction : in std_logic;
			start_address : in std_logic_vector(9 downto 0);
			transfer_size : in std_logic_vector(9 downto 0);
			busy : out std_logic;
			err : out std_logic;

			mem_chip_enable : out std_logic;
			mem_write_enable : out std_logic;
			mem_address : out std_logic_vector(9 downto 0);
			mem_busy : in std_logic;
			mem_data_in : in std_logic_vector(7 downto 0);
			mem_data_out : out std_logic_vector(7 downto 0);

			scsi_data_write_enable : out std_logic;
			scsi_data_direction : out std_logic;
			scsi_data_busy : in std_logic;
			scsi_data_err : in std_logic;
			scsi_data_in : in std_logic_vector(7 downto 0);
			scsi_data_out : out std_logic_vector(7 downto 0)
		);
	end component;

	component scsi_select_detect
		port(
			sel : in std_logic;
			id_mask : in std_logic_vector(7 downto 0);
			selected : out std_logic;
			scsi_bsy : in std_logic;
			scsi_sel : in std_logic;
			scsi_io : in std_logic;
			scsi_db : in std_logic_vector(7 downto 0);
			scsi_dbp : in std_logic
		);
	end component;

	component kcpsm6
		generic(
			hwbuild : std_logic_vector(7 downto 0) := X"00";
			interrupt_vector : std_logic_vector(11 downto 0) := X"3ff";
			scratch_pad_memory_size : integer := 64
		);

		port(
			address : out std_logic_vector(11 downto 0);
			instruction : in std_logic_vector(17 downto 0);
			bram_enable : out std_logic;
			in_port : in std_logic_vector(7 downto 0);
			out_port : out std_logic_vector(7 downto 0);
			port_id : out std_logic_vector(7 downto 0);
			write_strobe : out std_logic;
			k_write_strobe : out std_logic;
			read_strobe : out std_logic;
			interrupt : in std_logic;
			interrupt_ack : out std_logic;
			sleep : in std_logic;
			reset : in std_logic;
			clk : in std_logic
		);
	end component;

	component kcpsm6_rom
		port(
			address : in std_logic_vector(11 downto 0);
			instruction : out std_logic_vector(17 downto 0);
			enable : in std_logic;
			clk : in std_logic
		);
	end component;

	-- Muxed data bus IO unit lines
	signal data_bus_io_write_enable : std_logic;
	signal data_bus_io_direction : std_logic;
	signal data_bus_io_busy : std_logic;
	signal data_bus_io_err : std_logic;
	signal data_bus_io_data_in : std_logic_vector(7 downto 0);
	signal data_bus_io_data_out : std_logic_vector(7 downto 0);

	-- Muxed block transfer unit lines
	signal block_transfer_start : std_logic;
	signal block_transfer_direction : std_logic;
	signal block_transfer_busy : std_logic;
	signal block_transfer_err : std_logic;

	-- Command buffer
	type command_buf_mem is array (31 downto 0) of std_logic_vector(7 downto 0);
	signal command_buf : command_buf_mem;
	signal command_buf_selector : std_logic;
	signal command_buf_we : std_logic;
	signal command_buf_address : std_logic_vector(4 downto 0);
	signal command_buf_data_in : std_logic_vector(7 downto 0);
	signal command_buf_data_out : std_logic_vector(7 downto 0);

	-- Block transfer buffers
	signal block_transfer_scsi_write_enable : std_logic;
	signal block_transfer_scsi_direction : std_logic;
	signal block_transfer_scsi_data_out : std_logic_vector(7 downto 0);
	signal block_transfer_mem_chip_enable : std_logic;
	signal block_transfer_mem_write_enable : std_logic;
	signal block_transfer_mem_address : std_logic_vector(9 downto 0);
	signal block_transfer_mem_data_out : std_logic_vector(7 downto 0);

	-- Select detect lines
	signal select_detect_sel : std_logic;
	signal select_detect_id_mask : std_logic_vector(7 downto 0);
	signal select_detect_selected : std_logic;

	-- Control registers
	signal port_selector : std_logic_vector(8 downto 0);

	-- Port 0
	-- 8                                                                                          0
	-- | OUTPUT_ENABLE | SCSI_BSY | SCSI_MSG | SCSI_CD | SCSI_IO | SCSI_ATN | SCSI_SEL | SELECTED |
	signal scsi_control_reg : std_logic_vector(7 downto 0);

	-- Port 1: transfer control register
	-- 8                                        0
	-- | X | X | X | X | X | ERR | BUSY | START |
	signal transfer_control_reg : std_logic_vector(7 downto 0);
	signal transfer_strobe_rst : std_logic;
	signal transfer_strobe_write : std_logic;

	-- Port 2: transfer data register

	-- Ports 3 and 4: block transfer start address register
	signal transfer_address_reg : std_logic_vector(9 downto 0);

	-- Ports 5 and 6: block transfer size register
	signal transfer_size_reg : std_logic_vector(9 downto 0);

	-- KCPSM6 signals
	signal proc_address : std_logic_vector(11 downto 0);
	signal proc_instruction : std_logic_vector(17 downto 0);
	signal proc_rom_enable : std_logic;
	signal proc_in_port : std_logic_vector(7 downto 0);
	signal proc_out_port : std_logic_vector(7 downto 0);
	signal proc_port_id : std_logic_vector(7 downto 0);
	signal proc_write_strobe : std_logic;
	signal proc_k_write_strobe : std_logic;
	signal proc_read_strobe : std_logic;
	signal proc_interrupt : std_logic;
	signal proc_interrupt_ack : std_logic;
	signal proc_sleep : std_logic;
begin
	-- Component instantiations
	data_bus_io : scsi_data_bus_io
		port map(
			rst => rst,
			clk => clk,

			write_enable => data_bus_io_write_enable,
			output_enable => scsi_control_reg(7),
			direction => data_bus_io_direction,
			busy => data_bus_io_busy,
			err => data_bus_io_err,
			data_in => data_bus_io_data_in,
			data_out => data_bus_io_data_out,

			scsi_req => scsi_req,
			scsi_ack => scsi_ack,
			scsi_db => scsi_db,
			scsi_dbp => scsi_dbp
		);

	block_transfer : scsi_block_transfer_unit
		port map(
			rst => rst,
			clk => clk,

			start => transfer_control_reg(0),
			direction => scsi_control_reg(3),
			start_address => transfer_address_reg,
			transfer_size => transfer_size_reg,
			busy => block_transfer_busy,
			err => block_transfer_err,

			mem_chip_enable => block_transfer_mem_chip_enable,
			mem_write_enable => block_transfer_mem_write_enable,
			mem_address => block_transfer_mem_address,
			mem_busy => '0',
			mem_data_in => command_buf_data_out,
			mem_data_out => block_transfer_mem_data_out,

			scsi_data_write_enable => block_transfer_scsi_write_enable,
			scsi_data_direction => block_transfer_scsi_direction,
			scsi_data_busy => data_bus_io_busy,
			scsi_data_err => data_bus_io_err,
			scsi_data_in => data_bus_io_data_out,
			scsi_data_out => block_transfer_scsi_data_out
		);

	select_detect : scsi_select_detect
		port map(
			sel => select_detect_sel,

			id_mask => select_detect_id_mask,
			selected => select_detect_selected,

			scsi_bsy => scsi_bsy,
			scsi_sel => scsi_sel,
			scsi_io => scsi_io,
			scsi_db => scsi_db,
			scsi_dbp => scsi_dbp
		);

	proc : kcpsm6
		generic map(
			hwbuild => X"00",
			interrupt_vector => X"3ff",
			scratch_pad_memory_size => 64
		)

		port map(
			address => proc_address,
			instruction => proc_instruction,
			bram_enable => proc_rom_enable,

			in_port => proc_in_port,
			out_port => proc_out_port,
			port_id => proc_port_id,
			write_strobe => proc_write_strobe,
			k_write_strobe => proc_k_write_strobe,
			read_strobe => proc_read_strobe,

			interrupt => proc_interrupt,
			interrupt_ack => proc_interrupt_ack,

			sleep => proc_sleep,
			reset => rst,
			clk => clk
		);

	rom : kcpsm6_rom
		port map(
			address => proc_address,
			instruction => proc_instruction,
			enable => proc_rom_enable,

			clk => clk
		);

	-- Data transfer unit signals
	data_bus_io_write_enable <= (proc_write_strobe and port_selector(2)) when block_transfer_busy = '0' else block_transfer_scsi_write_enable;
	data_bus_io_direction <= scsi_control_reg(3) when block_transfer_busy = '0' else block_transfer_scsi_direction;
	data_bus_io_data_in <= proc_out_port when block_transfer_busy = '0' else block_transfer_scsi_data_out;

	transfer_control_reg(1) <= data_bus_io_busy or block_transfer_busy;
	transfer_control_reg(2) <= data_bus_io_err or block_transfer_err;

	-- SCSI ID
	select_detect_sel <= '1';
	select_detect_id_mask <= X"02";

	-- SCSI control bus buffers
	scsi_bsy <= 'Z' when scsi_control_reg(7) = '0' else not scsi_control_reg(6);
	scsi_msg <= 'Z' when scsi_control_reg(7) = '0' else not scsi_control_reg(5);
	scsi_cd <= 'Z' when scsi_control_reg(7) = '0' else not scsi_control_reg(4);
	scsi_io <= 'Z' when scsi_control_reg(7) = '0' else not scsi_control_reg(3);

	scsi_control_reg(2 downto 0) <= (not scsi_atn) & (not scsi_sel) & select_detect_selected;

	-- Command buffer
	command_buf_selector <= proc_write_strobe and port_selector(8);
	command_buf_we <= proc_write_strobe when command_buf_selector = '1' else block_transfer_mem_write_enable and block_transfer_mem_chip_enable;
	command_buf_address <= proc_port_id(4 downto 0) when command_buf_selector = '1' else block_transfer_mem_address(4 downto 0);
	command_buf_data_in <= proc_out_port when command_buf_selector = '1' else block_transfer_mem_data_out;

	command_buffer : process(clk)
	begin
		if rising_edge(clk) then
			command_buf_data_out <= command_buf(to_integer(unsigned(command_buf_address)));

			if command_buf_we = '1' then
				command_buf(to_integer(unsigned(command_buf_address))) <= command_buf_data_in;
			end if;
		end if;
	end process;

	-- Control registers
	port_id : process(proc_port_id)
	begin
		if proc_port_id(5) = '0' then
			case proc_port_id(2 downto 0) is
				when "000" => port_selector <= "000000001";
				when "001" => port_selector <= "000000010";
				when "010" => port_selector <= "000000100";
				when "011" => port_selector <= "000001000";
				when "100" => port_selector <= "000010000";
				when "101" => port_selector <= "000100000";
				when "110" => port_selector <= "001000000";
				when "111" => port_selector <= "010000000";
				when others => port_selector <= (others => 'X');
			end case;
		else
			port_selector <= "100000000";
		end if;
	end process;

	transfer_strobe_rst <= rst or transfer_control_reg(1);
	transfer_strobe_write <= proc_write_strobe and port_selector(1);
	transfer_strobe : process(transfer_strobe_rst, clk)
	begin
		if transfer_strobe_rst = '1' then
			transfer_control_reg(0) <= '0';
		elsif rising_edge(clk) then
			if transfer_strobe_write = '1' then
				transfer_control_reg(0) <= proc_out_port(0);
			end if;
		end if;
	end process;

	control_registers : process(rst, clk)
	begin
		if rst = '1' then
			scsi_control_reg(7 downto 3) <= "00000";

			transfer_address_reg <= "0000000000";
			transfer_size_reg <= "0000000000";
		elsif rising_edge(clk) then
			if proc_write_strobe = '1' then
				if port_selector(0) = '1' then
					scsi_control_reg(7 downto 3) <= proc_out_port(7 downto 3);
				end if;

				if port_selector(3) = '1' then
					transfer_address_reg(7 downto 0) <= proc_out_port;
				end if;
				if port_selector(4) = '1' then
					transfer_address_reg(9 downto 8) <= proc_out_port(1 downto 0);
				end if;
				if port_selector(5) = '1' then
					transfer_size_reg(7 downto 0) <= proc_out_port;
				end if;
				if port_selector(6) = '1' then
					transfer_size_reg(9 downto 8) <= proc_out_port(1 downto 0);
				end if;
			end if;
		end if;
	end process;

	-- KCPSM6 input register
	input_reg : process(rst, clk)
	begin
		if rst = '1' then
			proc_in_port <= X"00";
		elsif rising_edge(clk) then
			if proc_port_id(5) = '0' then
				case proc_port_id(2 downto 0) is
					when "000" => proc_in_port <= scsi_control_reg;
					when "001" => proc_in_port <= transfer_control_reg;
					when "010" => proc_in_port <= data_bus_io_data_out;
					when others => proc_in_port <= X"00";
				end case;
			else
				proc_in_port <= command_buf_data_out;
			end if;
		end if;
	end process;

	-- KCPSM6 misc. signals
	proc_interrupt <= '0';
	proc_sleep <= '0';
end architecture;
