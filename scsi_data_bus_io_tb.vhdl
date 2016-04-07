--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:40:53 04/02/2016
-- Design Name:   
-- Module Name:   C:/Data/dev/scsi/scsi_data_bus_io_tb.vhdl
-- Project Name:  scsi
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: scsi_data_bus_io
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
 
ENTITY scsi_data_bus_io_tb IS
END scsi_data_bus_io_tb;
 
ARCHITECTURE behavior OF scsi_data_bus_io_tb IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT scsi_data_bus_io
    PORT(
         rst : IN  std_logic;
         sel : IN  std_logic;
         rw : IN  std_logic;
         busy : OUT  std_logic;
         err : OUT  std_logic;
         data : INOUT  std_logic_vector(7 downto 0);
         scsi_req : OUT  std_logic;
         scsi_io : OUT  std_logic;
         scsi_ack : IN  std_logic;
         scsi_db : INOUT  std_logic_vector(7 downto 0);
         scsi_dbp : INOUT  std_logic
        );
    END COMPONENT;
    

   --Inputs
   signal rst : std_logic := '1';
   signal sel : std_logic := '0';
   signal rw : std_logic := '0';
   signal scsi_ack : std_logic := '1';

	--BiDirs
   signal data : std_logic_vector(7 downto 0);
   signal scsi_db : std_logic_vector(7 downto 0);
   signal scsi_dbp : std_logic;

 	--Outputs
   signal busy : std_logic;
   signal err : std_logic;
   signal scsi_req : std_logic;
   signal scsi_io : std_logic;
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
   uut: scsi_data_bus_io PORT MAP (
          rst => rst,
          sel => sel,
          rw => rw,
          busy => busy,
          err => err,
          data => data,
          scsi_req => scsi_req,
          scsi_io => scsi_io,
          scsi_ack => scsi_ack,
          scsi_db => scsi_db,
          scsi_dbp => scsi_dbp
        );

   -- Stimulus process
   stim_proc: process
   begin		
      wait for 10 ns;	

		data <= "ZZZZZZZZ";
		scsi_db <= "ZZZZZZZZ";
		scsi_dbp <= 'Z';
		rst <= '0';
		rw <= '0';
		wait for 10 ns;

		data <= "10100101";
		wait for 2 ns;
		sel <= '1';
		wait for 1 ns;
		--wait until busy = '1';
		sel <= '0';
		wait for 1 ns;
		
		--wait until scsi_req = '0';
		scsi_ack <= '0';
		wait for 1 ns;
		--wait until scsi_req = '1';
		scsi_ack <= '1';
		wait for 1 ns;
		--wait until busy = '0';
		
		data <= "ZZZZZZZZ";
		rw <= '1';
		sel <= '1';
		wait for 1 ns;
		--wait until busy = '1';
		sel <= '0';
		wait for 1 ns;
		
		--wait until scsi_req = '0';
		scsi_db <= "01011010";
		scsi_dbp <= '1';
		wait for 2 ns;
		scsi_ack <= '0';
		wait for 1 ns;
		--wait until scsi_req = '1';
		scsi_ack <= '1';
		wait for 1 ns;
		--wait until busy = '0';
		
		sel <= '1';
		wait for 1 ns;
		sel <= '0';
		wait for 1 ns;
		
		--wait until scsi_req = '0';
		scsi_db <= "01011010";
		scsi_dbp <= '0';
		wait for 2 ns;
		scsi_ack <= '0';
		wait for 1 ns;
		--wait until scsi_req = '1';
		scsi_ack <= '1';
		wait for 1 ns;
		--wait until busy = '0';		

		scsi_db <= "ZZZZZZZZ";
		scsi_dbp <= 'Z';

		data <= "11111111";
		rw <= '0';
		wait for 2 ns;

		sel <= '1';
		wait for 1 ns;
		sel <= '0';
		wait for 1 ns;
		
		scsi_ack <= '0';
		wait for 1 ns;
		scsi_ack <= '1';
		wait for 1 ns;

      wait;
   end process;

END;
