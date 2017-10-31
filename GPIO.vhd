library IEEE;
use IEEE.std_logic_1164.all;
ENTITY GPIO IS
	PORT(
		Clk : IN std_logic;
		nReset : IN std_logic;
		
		Address : IN std_logic_vector (2 DOWNTO 0);
		ChipSelect : IN std_logic;
		
		Read : IN std_logic;
		Write : IN std_logic;
		
		ReadData : OUT std_logic_vector (31 DOWNTO 0);
		WriteData : IN std_logic_vector (31 DOWNTO 0);
		
		ParPort : INOUT std_logic_vector (31 DOWNTO 0)
	);
END GPIO;


ARCHITECTURE comp of GPIO IS
	SIGNAL iRegDir : std_logic_vector (31 DOWNTO 0);
	SIGNAL iRegPort : std_logic_vector (31 DOWNTO 0);
	SIGNAL iRegPin : std_logic_vector (31 DOWNTO 0);
BEGIN
	
	pRegWr : PROCESS(Clk)
	BEGIN
		IF nReset = '0' THEN
			iRegDir <= (others => '0');
		ELSIF rising_edge(Clk) THEN
			IF ChipSelect = '1' AND Write = '1' THEN
				CASE Address (2 DOWNTO 0) IS
					WHEN "000" => iRegDir <= WriteData;
					WHEN "001" => iRegPort <= WriteData;
					WHEN "011" => iRegPort <= iRegPort OR WriteData;
					WHEN "100" => iRegPort <= iRegPort AND NOT WriteData;
					WHEN others => NULL;
				END CASE;
			END IF;
		END IF;
	END PROCESS pRegWr;
	

	pRegRd : PROCESS(Clk)
	BEGIN
		IF rising_edge(Clk) THEN
			IF ChipSelect = '1' and Read = '1' THEN
				CASE Address (2 DOWNTO 0) IS
					WHEN "000" => ReadData <= iRegDir;
					WHEN "001" => ReadData <= iRegPin;
					WHEN "010" => ReadData <= iRegPort;
					WHEN others => null;
				END CASE;
			END IF;
		END IF;
	END PROCESS pRegRd;
	
	pPort : PROCESS(iRegDir, iRegPort)
	BEGIN
		FOR i IN 0 to 31 LOOP
			IF iRegDir(i) = '1' THEN
				ParPort(i) <= iRegPort(i);
			ELSE
				ParPort(i) <= 'Z';
			END IF;
		END LOOP;
	END PROCESS pPort;
	
	iRegPin <= ParPort;
	
END comp;