--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:	13:49:39 04/05/2016
-- Design Name:	
-- Module Name:	Z:/Documents/scsi/scsi_select_detect_tb.vhdl
-- Project Name:  scsi
-- Target Device:  
-- Tool versions:  
-- Description:	
-- 
-- VHDL Test Bench Created by ISE for module: scsi_select_detect
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
 
ENTITY scsi_select_detect_tb IS
END scsi_select_detect_tb;
 
ARCHITECTURE behavior OF scsi_select_detect_tb IS 
 
	 -- Component Declaration for the Unit Under Test (UUT)
 
	 COMPONENT scsi_select_detect
	 PORT(
			sel : IN  std_logic;
			id_mask : IN  std_logic_vector(7 downto 0);
			selected : OUT  std_logic;
			scsi_bsy : IN  std_logic;
			scsi_sel : IN  std_logic;
			scsi_io : IN  std_logic;
			scsi_db : IN  std_logic_vector(7 downto 0);
			scsi_dbp : IN  std_logic
		  );
	 END COMPONENT;
	 

	--Inputs
	signal sel : std_logic := '0';
	signal id_mask : std_logic_vector(7 downto 0) := (others => '0');
	signal scsi_bsy : std_logic := '0';
	signal scsi_sel : std_logic := '0';
	signal scsi_io : std_logic := '0';
	signal scsi_db : std_logic_vector(7 downto 0) := (others => '0');
	signal scsi_dbp : std_logic := '0';

 	--Outputs
	signal selected : std_logic;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: scsi_select_detect PORT MAP (
			 sel => sel,
			 id_mask => id_mask,
			 selected => selected,
			 scsi_bsy => scsi_bsy,
			 scsi_sel => scsi_sel,
			 scsi_io => scsi_io,
			 scsi_db => scsi_db,
			 scsi_dbp => scsi_dbp
		  );

	-- Stimulus process
	stim_proc: process
	begin
		sel <= '0';
		id_mask <= "00000001";
		wait for 5 ns;

		sel <= '1';

		scsi_bsy <= '1';
		scsi_io <= '1';
		scsi_sel <= '0';
		scsi_db <= "10000001";
		scsi_dbp <= '1';
		wait for 5 ns;

		scsi_db <= "10000010";
		wait for 5 ns;

		scsi_db <= "10000100";
		wait for 5 ns;

		scsi_db <= "10001000";
		wait for 5 ns;

		scsi_db <= "10010000";
		wait for 5 ns;

		scsi_db <= "10100000";
		wait for 5 ns;

		scsi_db <= "11000000";
		wait for 5 ns;

		scsi_db <= "10000000";
		wait for 5 ns;

		scsi_db <= "10000001";
		wait for 5 ns;

		scsi_db <= "10000011";
		wait for 5 ns;

		scsi_db <= "10000001";
		scsi_dbp <= '0';
		wait for 5 ns;

		scsi_dbp <= '1';
		scsi_bsy <= '0';
		wait for 5 ns;

		scsi_bsy <= '1';
		scsi_io <= '0';
		wait for 5 ns;

		scsi_io <= '1';
		scsi_sel <= '1';
		wait for 5 ns;

		scsi_sel <= '0';
		sel <= '0';
		wait for 5 ns;

		sel <= '1';
		wait for 5 ns;

		wait;
	end process;

END;
