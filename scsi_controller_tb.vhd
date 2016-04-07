--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:	17:37:31 04/05/2016
-- Design Name:	
-- Module Name:	Z:/Documents/scsi/scsi_controller_tb.vhd
-- Project Name:  scsi
-- Target Device:  
-- Tool versions:  
-- Description:	
-- 
-- VHDL Test Bench Created by ISE for module: scsi_controller
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY scsi_controller_tb IS
END scsi_controller_tb;
 
ARCHITECTURE behavior OF scsi_controller_tb IS 
 
	 -- Component Declaration for the Unit Under Test (UUT)
 
	 COMPONENT scsi_controller
	 PORT(
			rst : IN  std_logic;
			clk : IN  std_logic;
			scsi_bsy : INOUT  std_logic;
			scsi_sel : IN  std_logic;
			scsi_cd : OUT  std_logic;
			scsi_io : INOUT  std_logic;
			scsi_msg : OUT  std_logic;
			scsi_req : OUT  std_logic;
			scsi_ack : IN  std_logic;
			scsi_atn : IN  std_logic;
			scsi_db : INOUT  std_logic_vector(7 downto 0);
			scsi_dbp : INOUT  std_logic
		  );
	 END COMPONENT;
	 
	for uut: scsi_controller use entity work.scsi_controller(Structure);

	--Inputs
	signal rst : std_logic := '1';
	signal clk : std_logic := '0';
	signal scsi_sel : std_logic := '1';
	signal scsi_ack : std_logic := '1';
	signal scsi_atn : std_logic := '1';

	--BiDirs
	signal scsi_bsy : std_logic := '1';
	signal scsi_io : std_logic := '1';
	signal scsi_db : std_logic_vector(7 downto 0);
	signal scsi_dbp : std_logic;

 	--Outputs
	signal scsi_cd : std_logic;
	signal scsi_msg : std_logic;
	signal scsi_req : std_logic;

	-- Clock period definitions
	constant clk_period : time := 83 ns;
 
	signal scsi_phase : std_logic_vector(2 downto 0);
BEGIN
	scsi_phase <= scsi_msg & scsi_cd & scsi_io;
 
	-- Instantiate the Unit Under Test (UUT)
	uut: scsi_controller PORT MAP (
			 rst => rst,
			 clk => clk,
			 scsi_bsy => scsi_bsy,
			 scsi_sel => scsi_sel,
			 scsi_cd => scsi_cd,
			 scsi_io => scsi_io,
			 scsi_msg => scsi_msg,
			 scsi_req => scsi_req,
			 scsi_ack => scsi_ack,
			 scsi_atn => scsi_atn,
			 scsi_db => scsi_db,
			 scsi_dbp => scsi_dbp
		  );

	-- Clock process definitions
	clk_process : process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	-- Stimulus process
	stim_proc : process
		type bus_phases is (idle, data_out, data_in, command, status, message_out, message_in);
		variable last_phase : bus_phases := idle;

		type command_mem is array (0 to 11) of std_logic_vector(7 downto 0);
		variable command_buf : command_mem;
		variable command_len : integer;
		variable command_idx : integer;

		variable data : std_logic_vector(7 downto 0);

		constant read6 : command_mem := (X"08", X"00", X"00", X"00", X"01", X"00", others => X"00");
		constant read6_len : integer := 6;
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;

		rst <= '0';
		wait for clk_period * 10;

		main_loop : loop
			-- Selection phase
			scsi_sel <= '0';
			scsi_db <= X"82";
			scsi_dbp <= '1';
			scsi_bsy <= 'H';
			scsi_io <= 'H';

			wait until scsi_bsy = '0';
			scsi_sel <= '1';
			scsi_db <= "HHHHHHHH";
			scsi_dbp <= 'H';

			transfer_loop: loop
				wait until scsi_req = '0' or scsi_bsy /= '0';
				if scsi_bsy /= '0' then
					exit transfer_loop;
				end if;

				wait for 1 ns;

				case scsi_phase is
					when "111" => last_phase := data_out;
					when "110" => last_phase := data_in;

					when "101" =>
						if last_phase /= command then
							command_buf := read6;
							command_len := read6_len;
							command_idx := 0;
						end if;

						data := command_buf(command_idx);
						command_idx := command_idx + 1;

						if command_idx = command_len then
							last_phase := idle;
						else
							last_phase := command;
						end if;

					when "100" => last_phase := status;
					when "001" => last_phase := message_out;
					when "000" => last_phase := message_in;

					when others => last_phase := idle;
				end case;

				if scsi_phase(0) = '1' then
					scsi_db <= data;
					scsi_dbp <= not (data(0) xor data(1) xor data(2) xor data(3) xor data(4) xor data(5) xor data(6) xor data(7));
				end if;

				wait for 5 ns;
				scsi_ack <= '0';
				wait until scsi_req = '1';
				wait for 5 ns;
				scsi_ack <= '1';

				scsi_db <= (others => 'H');
				scsi_dbp <= 'H';
			end loop;
		end loop;
	
		wait;
	end process;

END;
