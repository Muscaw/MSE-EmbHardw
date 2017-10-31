library IEEE;
use IEEE.std_logic_1164.all;

ENTITY LCD IS
    PORT(
        -- Avalon slave interfaces
        Clk : IN std_logic;
        nReset : IN std_logic;
        
        Address : IN std_logic;
        ChipSelect : IN std_logic;

        Write : IN std_logic;

        WriteData : IN std_logic_vector (15 DOWNTO 0);

        WaitRequest : OUT std_logic;

        -- LCD interface
        DCX : OUT std_logic;
        WRX : OUT std_logic;
		  Data : OUT std_logic_vector (15 DOWNTO 0);
		  RDX : OUT std_logic;
		  IM0 : OUT std_logic;
		  -- Debug leds
		  LEDS : OUT std_logic_vector(31 DOWNTO 0)
    );
END LCD;


ARCHITECTURE LCD_arch of LCD IS
    TYPE STATE_TYPE IS (s0, s1, s2, s3);
    SIGNAL state : STATE_TYPE := s0;
	 SIGNAL WRXSig : std_logic := '1';
	 CONSTANT RDXSig : std_logic := '1';
	 SIGNAL LEDSSig : std_logic_vector (31 DOWNTO 0) := "00000000000000000000000000000000";
	 SIGNAL DataSig : std_logic_vector (15 DOWNTO 0) := "UUUUUUUUUUUUUUUU";
	 CONSTANT IM0Sig : std_logic := '0';
BEGIN
    pStateMachine : PROCESS (Clk)
    BEGIN
        IF nReset = '0' THEN
            state <= s0;
				LEDSSig <= "00000000000000000000000000000000";
            -- Execute reset routine
        ELSIF rising_edge(Clk) THEN
            CASE state IS
                WHEN s0 => 
                    IF Write = '1' AND ChipSelect = '1' THEN
                        -- Command and data mode managed here with Address
                        DCX <= Address;
                        IF Address = '0' THEN
                            LEDSSig(0) <= '1';
									 LEDSSig(1) <= '0';
                        ELSE
                            LEDSSig(1) <= '1';
									 LEDSSig(0) <= '0';
                        END IF;
                        --LEDSSig(0) <= NOT Address;
                        DataSig <= WriteData;
                        state <= s1;
                        WRXSig <= '0';
                    END IF;
                WHEN s1 =>
                    state <= s2;
						  WRXSig <= '0';
                WHEN s2 =>
                    state <= s3;
                    WRXSig <= '1';
                WHEN s3 =>
                    state <= s0;
						  WRXSig <= '1';
            END CASE;
        END IF;
    END PROCESS pStateMachine;

    WaitRequest <= '0' WHEN state = s3
        ELSE '1';
	 
	 Data <= DataSig;
	 WRX <= WRXSig;
	 LEDS <= LEDSSig;
	 RDX <= RDXSig;
	 IM0 <= IM0Sig;
	 -- logique combinatoire pour le wait request (si dans le if rising edge, ajout de registre et coup de retard)
END LCD_arch;