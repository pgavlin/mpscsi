--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:	10:01:57 04/03/2016
-- Design Name:	
-- Module Name:	Z:/Documents/scsi/scsi_block_transfer_unit_tb.vhdl
-- Project Name:  scsi
-- Target Device:  
-- Tool versions:  
-- Description:	
-- 
-- VHDL Test Bench Created by ISE for module: scsi_block_transfer_unit
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
USE ieee.numeric_std.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY scsi_block_transfer_unit_tb IS
END scsi_block_transfer_unit_tb;
 
ARCHITECTURE behavior OF scsi_block_transfer_unit_tb IS 
 
	 -- Component Declaration for the Unit Under Test (UUT)
 
	 COMPONENT scsi_block_transfer_unit
	 PORT(
			rst : IN  std_logic;
			clk : IN  std_logic;
			sel : IN  std_logic;
			rw : IN  std_logic;
			start_address : IN  std_logic_vector(9 downto 0);
			transfer_size : IN  std_logic_vector(9 downto 0);
			busy : OUT  std_logic;
			err : OUT  std_logic;
			mem_sel : OUT  std_logic;
			mem_rw : OUT  std_logic;
			mem_address : OUT  std_logic_vector(9 downto 0);
			mem_busy : IN  std_logic;
			mem_data : INOUT  std_logic_vector(7 downto 0);
			scsi_data_sel : OUT  std_logic;
			scsi_data_rw : OUT  std_logic;
			scsi_data_busy : IN  std_logic;
			scsi_data_err : IN  std_logic;
			scsi_data : INOUT  std_logic_vector(7 downto 0)
		  );
	 END COMPONENT;
	 

	--Inputs
	signal rst : std_logic := '1';
	signal clk : std_logic := '0';
	signal sel : std_logic := '0';
	signal rw : std_logic := '0';
	signal start_address : std_logic_vector(9 downto 0) := (others => '0');
	signal transfer_size : std_logic_vector(9 downto 0) := (others => '0');
	signal mem_busy : std_logic := '0';
	signal scsi_data_busy : std_logic := '0';
	signal scsi_data_err : std_logic := '0';

	--BiDirs
	signal mem_data : std_logic_vector(7 downto 0) := (others => 'Z');
	signal scsi_data : std_logic_vector(7 downto 0) := (others => 'Z');

 	--Outputs
	signal busy : std_logic;
	signal err : std_logic;
	signal mem_sel : std_logic;
	signal mem_rw : std_logic;
	signal mem_address : std_logic_vector(9 downto 0);
	signal scsi_data_sel : std_logic;
	signal scsi_data_rw : std_logic;

	-- Clock period definitions
	constant clk_period : time := 10 ns;
 
BEGIN
 
	-- Instantiate the Unit Under Test (UUT)
	uut: scsi_block_transfer_unit PORT MAP (
			 rst => rst,
			 clk => clk,
			 sel => sel,
			 rw => rw,
			 start_address => start_address,
			 transfer_size => transfer_size,
			 busy => busy,
			 err => err,
			 mem_sel => mem_sel,
			 mem_rw => mem_rw,
			 mem_address => mem_address,
			 mem_busy => mem_busy,
			 mem_data => mem_data,
			 scsi_data_sel => scsi_data_sel,
			 scsi_data_rw => scsi_data_rw,
			 scsi_data_busy => scsi_data_busy,
			 scsi_data_err => scsi_data_err,
			 scsi_data => scsi_data
		  );

	-- Clock process definitions
	clk_process :process
	begin
		clk <= '0';
		wait for clk_period/2;
		clk <= '1';
		wait for clk_period/2;
	end process;

	-- Memory process
	mem_proc : process(mem_sel)
		type mem is array(1023 downto 0) of std_logic_vector(7 downto 0);
		variable mem1k : mem := (others => "00000000");
	begin
		if mem_sel = '0' then
			mem_data <= "ZZZZZZZZ" after 1 ns;
			mem_busy <= '0' after 1 ns;
		elsif mem_sel = '1' then
			mem_busy <= '1' after 1 ns, '0' after 10 ns;

			if mem_rw = '0' then
				mem1k(to_integer(unsigned(mem_address))) := mem_data;
			else
				mem_data <= mem1k(to_integer(unsigned(mem_address))) after 5 ns;
			end if;
		end if;
	end process;

	-- SCSI process
	scsi_data_proc : process(scsi_data_sel)
	begin
		if scsi_data_sel = '0' then
			scsi_data <= "ZZZZZZZZ" after 1 ns;
			scsi_data_busy <= '0' after 1 ns;
		elsif scsi_data_sel = '1' then
			scsi_data_busy <= '1' after 1 ns, '0' after 10 ns;

			if scsi_data_rw = '0' then
				scsi_data <= "ZZZZZZZZ" after 5 ns;
			else
				scsi_data <= "10100101" after 5 ns;
			end if;
		end if;
	end process;

	-- Stimulus process
	stim_proc: process
	begin		
		-- hold reset state for 100 ns.
		wait for 100 ns;
		rst <= '0';

		wait for clk_period;

		-- insert stimulus here 
		start_address <= "0000010000";
		transfer_size <= "0000001000";

		rw <= '1';
		sel <= '1';
		wait for clk_period;

		sel <= '0';
		wait until busy = '0';

		rw <= '0';
		sel <= '1';
		wait for clk_period * 2;

		sel <= '0';
		wait until busy = '0';

		wait;
	end process;

END;
