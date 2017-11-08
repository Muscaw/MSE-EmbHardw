--------------------------------------------------------------------
--  _____       ______  _____                                     --
-- |_   _|     |  ____|/ ____|                                    --
--   | |  _ __ | |__  | (___    Institute of Embedded Systems     --
--   | | | '_ \|  __|  \___ \   Zürcher Hochschule für Angewandte --
--  _| |_| | | | |____ ____) |  Wissenschaften                    --
-- |_____|_| |_|______|_____/   8401 Winterthur, Switzerland      --
--------------------------------------------------------------------
--
-- Project     : Design of Embedded Hardware & Firmware MSE Module
--
-- File Name   : avalon_pkg.vhd
-- Description : Package for avalon bus read and writes
--
-- Features:     - 
--
--------------------------------------------------------------------
-- Change History
-- Date     |Name      |Modification
------------|----------|--------------------------------------------
-- 05.03.13 | mati     | file created
--------------------------------------------------------------------


library ieee;
  use IEEE.std_logic_1164.all;
  use IEEE.std_logic_arith.all;
  use IEEE.std_logic_textio.all;
  use STD.textio.all;


package avalon_pkg is

    ---------------------------------------------------------------------------------------
    -- package constants
    --------------------------------------------------------------------------------------- 
    constant WRITE_WAIT_TIME      : integer                       :=  1;
    constant READ_WAIT_TIME       : integer                       :=  1;
    
    ---------------------------------------------------------------------------------------
    -- procedure to write data to the avalon bus
    ---------------------------------------------------------------------------------------
    procedure avalon_write_data(
                                  signal      ADDRESS         : out std_logic_vector;
                                  signal      CS              : out std_logic;
                                  signal      WRITE           : out std_logic;
                                  signal      DATA            : out std_logic_vector;

                                  signal      CLK             : in std_logic;
                                  
                                  constant    CLK_PERIOD      : in time;
                                  constant    CONST_ADDRESS   : in std_logic_vector;
                                  constant    CONST_DATA      : in std_logic_vector
    );
    
  ---------------------------------------------------------------------------------------
  -- procedure to read data from the avalon bus
  ---------------------------------------------------------------------------------------
  procedure avalon_read_data(
                                signal      ADDRESS         : out std_logic_vector;
                                signal      CS              : out std_logic;
                                signal      READ            : out std_logic;
                                signal      DATA            : in std_logic_vector;
                                signal      READ_VALUE      : out std_logic_vector;
                                
                                signal      CLK             : in std_logic;
                                
                                constant    CLK_PERIOD      : in time;
                                constant    CONST_ADDRESS   : in std_logic_vector
  
  );
    


end avalon_pkg;


package body avalon_pkg is

  ---------------------------------------------------------------------------------------
  -- procedure to write data to the avalon bus
  ---------------------------------------------------------------------------------------
  procedure avalon_write_data(
                                signal      ADDRESS         : out std_logic_vector;
                                signal      CS              : out std_logic;
                                signal      WRITE           : out std_logic;
                                signal      DATA            : out std_logic_vector;

                                signal      CLK             : in std_logic;

                                constant    CLK_PERIOD      : time;
                                constant    CONST_ADDRESS   : in std_logic_vector;
                                constant    CONST_DATA      : in std_logic_vector

  ) is
  begin

    --wait until clock is rising
    wait until rising_edge(CLK);
    wait for CLK_PERIOD/4;

    --assign address
    ADDRESS <= CONST_ADDRESS;

    --assign cs
    CS <= '1';

    --rise write signal
    WRITE <= '1';

    --assign data
    DATA <= CONST_DATA;

    --wait (write wait)
    wait for (WRITE_WAIT_TIME * CLK_PERIOD);

    wait until rising_edge(CLK);
    wait for CLK_PERIOD/4;

    --release write signal and cs
    WRITE <= '0';
    CS <= '0';

  end avalon_write_data;


  ---------------------------------------------------------------------------------------
  -- procedure to read data from the avalon bus
  ---------------------------------------------------------------------------------------
  procedure avalon_read_data(
                                signal      ADDRESS         : out std_logic_vector;
                                signal      CS              : out std_logic;
                                signal      READ            : out std_logic;
                                signal      DATA            : in std_logic_vector;
                                signal      READ_VALUE      : out std_logic_vector;
                                
                                signal      CLK             : in std_logic;
                                
                                constant    CLK_PERIOD      : time;
                                constant    CONST_ADDRESS   : in std_logic_vector
  ) is
           
  begin

    --wait until clock is rising
    wait until rising_edge(CLK);

    --assign address
    ADDRESS <= CONST_ADDRESS;

    --assign cs
    CS <= '1';

    --rise read signal
    READ <= '1';

    --wait (read wait)
    wait for (READ_WAIT_TIME * CLK_PERIOD);
    wait for CLK_PERIOD/4 ;

    --assign data
    READ_VALUE <= DATA;

    wait until rising_edge(CLK);
    wait for CLK_PERIOD/4 ;

    --release write signal and cs
    READ <= '0';
    CS <= '0';

  end avalon_read_data;

end package body avalon_pkg;
