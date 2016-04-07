library ieee;
use ieee.std_logic_1164.all;

entity scsi_select_detect is
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
end entity;

architecture behavioral of scsi_select_detect is
	signal is_select_phase : std_logic;

	signal has_matching_id_internal : std_logic_vector(15 downto 0);
	signal has_matching_id : std_logic;

	signal has_two_bits_internal : std_logic_vector(11 downto 0);
	signal has_two_bits : std_logic;

	signal is_parity_correct : std_logic;
begin
	-- SELECT phase: BSY and IO negated, SEL asserted.
	is_select_phase <= scsi_bsy and scsi_io and not scsi_sel;

	-- Has matching ID: (id_mask & scsi_db) == id_mask
	has_matching_id_internal(15 downto 8) <= id_mask and scsi_db;
	has_matching_id_internal(7 downto 0) <= has_matching_id_internal(15 downto 8) xnor id_mask;
	has_matching_id <= (((has_matching_id_internal(7) xnor has_matching_id_internal(6)) xnor (has_matching_id_internal(5) xnor has_matching_id_internal(4))) xnor ((has_matching_id_internal(3) xnor has_matching_id_internal(2)) xnor (has_matching_id_internal(1) xnor has_matching_id_internal(0))));

	-- Has two bits: self-explanatory.
	has_two_bits_internal(11 downto 10) <= (scsi_db(7) xor scsi_db(6)) & (scsi_db(7) and scsi_db(6));
	has_two_bits_internal(9 downto 8) <= (scsi_db(5) xor scsi_db(4)) & (scsi_db(5) and scsi_db(4));
	has_two_bits_internal(7 downto 6) <= (scsi_db(3) xor scsi_db(2)) & (scsi_db(3) and scsi_db(2));
	has_two_bits_internal(5 downto 4) <= (scsi_db(1) xor scsi_db(0)) & (scsi_db(1) and scsi_db(0));
	has_two_bits_internal(3 downto 2) <= (has_two_bits_internal(11) xor has_two_bits_internal(9)) & ((has_two_bits_internal(11) and has_two_bits_internal(9)) or has_two_bits_internal(10) or has_two_bits_internal(8));
	has_two_bits_internal(1 downto 0) <= (has_two_bits_internal(7) xor has_two_bits_internal(5)) & ((has_two_bits_internal(7) and has_two_bits_internal(5)) or has_two_bits_internal(6) or has_two_bits_internal(4));
	has_two_bits <= (not has_two_bits_internal(3) and not has_two_bits_internal(2) and not has_two_bits_internal(1) and has_two_bits_internal(0)) or (has_two_bits_internal(3) and not has_two_bits_internal(2) and has_two_bits_internal(1) and not has_two_bits_internal(0)) or (not has_two_bits_internal(3) and has_two_bits_internal(2) and not has_two_bits_internal(1) and not has_two_bits_internal(0));

	-- Odd parity for a byte with two bits set is one.
	is_parity_correct <= scsi_dbp;

	-- If the detector is enabled and all of the above conditions are true,
	-- then it is the SELECT phase and this device has been selected.
	selected <= sel and is_select_phase and has_matching_id and has_two_bits and is_parity_correct;
end architecture;
