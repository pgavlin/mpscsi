library ieee;
use ieee.std_logic_1164.all;
 
-- uncomment the following library declaration if using
-- arithmetic functions with signed or unsigned values
--use ieee.numeric_std.all;
 
entity scsi_controller_tld is
	port(
		clk => in std_logic;

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
end scsi_controller_tld;
 
architecture structure of scsi_controller_tld is 
	component scsi_controller
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
	end component;

	signal rst : std_logic;
	signal clk : std_logic;
	signal scsi_bsy : std_logic;
	signal scsi_sel : std_logic;
	signal scsi_cd : std_logic;
	signal scsi_io : std_logic;
	signal scsi_msg : std_logic;
	signal scsi_req : std_logic;
	signal scsi_ack : std_logic;
	signal scsi_atn : std_logic;
	signal scsi_db : std_logic_vector(7 downto 0);
	signal scsi_dbp : std_logic;

	signal no_reset : std_logic;
begin
	no_reset <= '0';

	ctl : scsi_controller
		port map(
			rst => no_reset,
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
end architecture;
