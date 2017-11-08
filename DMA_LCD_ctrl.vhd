library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;

ENTITY DMA_LCD_CTRL IS
    PORT(
        -- Avalon slave interfaces
        Clk : IN std_logic;
        reset : IN std_logic;
        
        avalon_address : IN std_logic_vector(2 DOWNTO 0);
        avalon_cs : IN std_logic;

        avalon_wr : IN std_logic;
        avalon_write_data : IN std_logic_vector (31 DOWNTO 0);
		avalon_rd : IN std_logic;
		avalon_read_data : OUT std_logic_vector (31 DOWNTO 0);
        WaitRequestSlave : OUT std_logic;
		end_of_transaction_irq : OUT std_logic;
		  -- Avalon master interfaces
		master_address : OUT std_logic_vector(31 DOWNTO 0);
		master_read : OUT std_logic;
		master_readdata : IN std_logic_vector (15 DOWNTO 0);
		master_waitrequest : IN std_logic;
		--master_byteenable : OUT std_logic_vector (3 DOWNTO 0);
        -- LCD interface
		LCD_CS_n : OUT std_logic;
        LCD_D_C_n : OUT std_logic;
        LCD_WR_n : OUT std_logic;
		LCD_data : OUT std_logic_vector (15 DOWNTO 0);
		RDX : OUT std_logic;
		IM0 : OUT std_logic;
		LEDS : OUT std_logic_vector(31 DOWNTO 0)
		  
    );
END DMA_LCD_CTRL;


ARCHITECTURE LCD_arch of DMA_LCD_CTRL IS
    TYPE STATE_TYPE IS (Idle, IdleNW, s1, s2, s3, dS0, dS1, dS2, dS3, dS4);
    SIGNAL state : STATE_TYPE := Idle;
	 SIGNAL WRXSig : std_logic := '1';
	 SIGNAL DCXSig : std_logic := '0';
	 CONSTANT RDXSig : std_logic := '1';
	 SIGNAL FetchAddressSig : std_logic_vector (31 DOWNTO 0);
	 SIGNAL Size : std_logic_vector(31 DOWNTO 0);
	 SIGNAL DataSig : std_logic_vector (15 DOWNTO 0);
	 SIGNAL FetchedDataSig : std_logic_vector (15 DOWNTO 0);
	 SIGNAL MasterReadSignal : std_logic := '0';
	 CONSTANT IM0Sig : std_logic := '0';
	 CONSTANT CS_nSig : std_logic := '1';
	 SIGNAL DMAMode : std_logic := '0';
	 --CONSTANT MasterByteenable : std_logic_vector(3 DOWNTO 0) := "0011";
BEGIN
    pStateMachine : PROCESS (Clk, reset)
    BEGIN
        IF reset = '1' THEN
            state <= Idle;
			WRXSig <= '1';
			DCXSig <= '0';
			DMAMode <= '0';
			MasterReadSignal <= '0';
			Size <= "00000000000000000000000000000000";
            -- Execute reset routine
        ELSIF rising_edge(Clk) THEN
            CASE state IS
                WHEN Idle => 
					end_of_transaction_irq <= '0';
                    IF avalon_wr = '1' AND avalon_cs = '1' THEN
						CASE avalon_address IS
							WHEN "000" => -- Write command to LCD
								DCXSig <= '0';
								state <= s1;
								DataSig <= avalon_write_data(15 DOWNTO 0);
								WRXSig <= '0';
							WHEN "001" => -- Write data to LCD
								DCXSig <= '1';
								state <= s1;
								DataSig <= avalon_write_data(15 DOWNTO 0);
								WRXSig <= '0';
							WHEN "010" => -- Setup source address
								FetchAddressSig <= avalon_write_data;
								state <= IdleNW;
							WHEN "011" => -- Setup size of transfer
								Size <= avalon_write_data;
								state <= IdleNW;
							WHEN "100" => -- Start DMA transfer
								Size <= std_logic_vector(unsigned(Size) - 2);
								master_address <= FetchAddressSig;
								MasterReadSignal <= '1';
								state <= dS0;
							WHEN others => NULL;
						END CASE;
					ELSIF avalon_rd = '1' AND avalon_cs = '1' THEN
						CASE avalon_address IS
							WHEN "010" =>
								avalon_read_data <= FetchAddressSig;
							WHEN "011" =>
								avalon_read_data <= std_logic_vector(Size);
							WHEN others => NULL;
						END CASE;
                    END IF;
				WHEN IdleNW =>
					state <= Idle;
                WHEN s1 =>
                    state <= s2;
						  WRXSig <= '0';
                WHEN s2 =>
                    state <= s3;
                    WRXSig <= '1';
                WHEN s3 =>
                    state <= Idle;
					WRXSig <= '1';
					IF DMAMode = '1' THEN
						DMAMode <= '0';
						end_of_transaction_irq <= '1';
					END IF;
				WHEN dS0 =>
					state <= dS1;
					MasterReadSignal <= '1';
					DMAMode <= '1';
				WHEN dS1 =>
					DataSig <= master_readdata;
					MasterReadSignal <= '0';
					IF master_waitrequest = '0' THEN
						state <= dS2;
					END IF;
				WHEN dS2 =>
					WRXSig <= '0';
					DCXSig <= '1';
					--DataSig <= FetchedDataSig;
					state <= dS3;
				WHEN dS3 =>
					WRXSig <= '0';
					DCXSig <= '1';
					--DataSig <= FetchedDataSig;
					FetchAddressSig <= std_logic_vector(unsigned(FetchAddressSig) + 2);
					state <= dS4;
				WHEN dS4 =>
					WRXSig <= '1';
					DCXSig <= '1';
					--DataSig <= FetchedDataSig;
					IF unsigned(Size) = 0 THEN
						state <= s3;
					ELSE
						Size <= std_logic_vector(unsigned(Size) - 2);
						state <= dS0;
						master_address <= FetchAddressSig;
					END IF;
            END CASE;
        END IF;
    END PROCESS pStateMachine;

    WaitRequestSlave <= '0' WHEN state = s3 OR state = IdleNW
        ELSE '1';
	 
	 LEDS <= Size;
	 LCD_data <= DataSig;
	 LCD_WR_n <= WRXSig;
	 RDX <= RDXSig;
	 IM0 <= IM0Sig;
	 LCD_D_C_n <= DCXSig;
	 master_read <= MasterReadSignal;
	 --LCD_CS_n <= CS_nSig;
	 --master_byteenable <= MasterByteenable;
	 -- logique combinatoire pour le wait request (si dans le if rising edge, ajout de registre et coup de retard)
END LCD_arch;