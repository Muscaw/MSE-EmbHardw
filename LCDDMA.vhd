library IEEE;
use IEEE.std_logic_1164.all;

ENTITY LCD IS
    PORT(
        -- Avalon slave interfaces
        Clk : IN std_logic;
        nReset : IN std_logic;
        
        AddressSlave : IN std_logic_vector(2 DOWNTO 0);
        ChipSelect : IN std_logic;

        Write : IN std_logic;

        WriteDataSlave : IN std_logic_vector (15 DOWNTO 0);

        WaitRequest : OUT std_logic;
		  
		  -- Avalon master interfaces
		  AddressMaster : OUT std_logic_vector(15 DOWNTO 0);
		  ReadMaster : OUT std_logic;
		  ReadDataMaster : OUT std_logic_vector (15 DOWNTO 0);
        -- LCD interface
        DCX : OUT std_logic;
        WRX : OUT std_logic;
		  Data : OUT std_logic_vector (15 DOWNTO 0);
		  RDX : OUT std_logic;
		  IM0 : OUT std_logic
		  
    );
END LCD;


ARCHITECTURE LCD_arch of LCD IS
    TYPE STATE_TYPE IS (Idle, s1, s2, s3, dS0, dS1, dS2, dS3, dS4);
    SIGNAL state : STATE_TYPE := Idle;
	 SIGNAL WRXSig : std_logic := '1';
	 SIGNAL DCXSig : std_logic := '0';
	 CONSTANT RDXSig : std_logic := '1';
	 SIGNAL FetchAddressSig : std_logic_vector (15 DOWNTO 0);
	 SIGNAL Size : UNSIGNED;
	 SIGNAL DataSig : std_logic_vector (15 DOWNTO 0) := "UUUUUUUUUUUUUUUU";
	 SIGNAL FetchedDataSig : std_logic_vector (15 DOWNTO 0) := "UUUUUUUUUUUUUUUU";
	 CONSTANT IM0Sig : std_logic := '0';
BEGIN
    pStateMachine : PROCESS (Clk, nReset)
    BEGIN
        IF nReset = '0' THEN
            state <= s0;
            -- Execute reset routine
        ELSIF rising_edge(Clk) THEN
            CASE state IS
                WHEN Idle => 
                    IF Write = '1' AND ChipSelect = '1' THEN
								CASE AddressSlave IS
									WHEN "000" => -- Write command to LCD
										DCXSig <= '0';
										state <= s1;
										DataSig <= WriteDataSlave;
										WRXSig <= '0';
									WHEN "001" => -- Write data to LCD
										DCXSig <= '1';
										state <= s1;
										DataSig <= WriteDataSlave;
										WRXSig <= '0';
									WHEN "010" => -- Setup source address
										FetchAddressSig <= WriteDataSlave;
										state <= Idle;
									WHEN "011" => -- Setup size of transfer
										Size <= unsigned(WriteDataSlave);
										state <= Idle;
									WHEN "100" => -- Start DMA transfer
										AddressMaster <= FetchAddressSig;
										ReadMaster <= '1';
										state <= dS0;
									WHEN others => NULL;
								END CASE;
                        
                    END IF;
                WHEN s1 =>
                    state <= s2;
						  WRXSig <= '0';
                WHEN s2 =>
                    state <= s3;
                    WRXSig <= '1';
                WHEN s3 =>
                    state <= Idle;
						  WRXSig <= '1';
					 WHEN dS0 =>
						state <= dS1;
					 WHEN dS1 =>
						FetchedDataSig <= ReadDataMaster;
						IF WaitRequestMaster = '0' THEN
							state <= dS2
						END IF;
					WHEN dS2 =>
						WRXSig <= '0';
						DCXSig <= '1';
						DataSig <= FetchedDataSig;
						state <= dS3;
					WHEN dS3 =>
						WRXSig <= '0';
						DCXSig <= '1';
						DataSig <= FetchedDataSig;
						state <= dS4;
					WHEN dS4 =>
						WRXSig <= '1';
						DCXSig <= '1';
						DataSig <= FetchedDataSig;
						IF Size = 0 THEN
							state <= s3;
						ELSE
							Size <= Size - 1;
							state <= dS0;
							AddressMaster <= std_logic_vector(unsigned(AddressMaster) + 2);
						END IF;
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
	 DCX <= DCXSig;
	 -- logique combinatoire pour le wait request (si dans le if rising edge, ajout de registre et coup de retard)
END LCD_arch;