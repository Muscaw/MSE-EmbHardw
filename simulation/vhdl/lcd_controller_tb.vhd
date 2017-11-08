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
-- File Name   : lcd_controller_tb.vhd
-- Description : Testbench for the LCD Controller
--
-- Features:     - 
--
--------------------------------------------------------------------
-- Change History
-- Date     |Name      |Modification
------------|----------|--------------------------------------------
-- 28.02.13 | mati     | file created
--------------------------------------------------------------------

--------------------------------------------------------------------------
-- NOTE:
-- this testbench allows you to do a simple _functional_
-- verification of the LCD_ctrl design unit
-- for advanced verification in vhdl check the following topics
--  * asserts
--  * signal attributes (timing analysis)
--  * randomization (additional packages, not in the language)
--  * functions from std.textio (file io, stimulus patterns in file)
--------------------------------------------------------------------------

--------------------------------------------------------------------------
-- TODO:
--  * improve debug console out (put it into read / write procedures)
--------------------------------------------------------------------------


library ieee;
  use IEEE.std_logic_1164.all;
  use IEEE.numeric_std.all;
  use IEEE.std_logic_textio.all;
  use STD.textio.all;
  
  use work.avalon_pkg.all;


entity lcd_controller_tb is
end;


architecture rtl of lcd_controller_tb is

  ---------------------------------------------------------------------------------------
  -- testbench constants
  ---------------------------------------------------------------------------------------
  constant CLK_PERIOD           : time                          := 20 ns;           --50 mhz
  constant CLK_HALF_PERIOD      : time                          := 10 ns;
  constant CLK_FOURTH_PERIOD    : time                          := 5 ns;
  
  constant RESET_DURATION       : time                          := 42 ns;
  
  -- for DMA test only
  constant AV_DUMMY_SLAVE_ADDR  : std_logic_vector(31 downto 0) := x"00_00_da_7a";
  constant DMA_TEST_IMG_SIZE    : std_logic_vector(31 downto 0) := x"00_00_00_0A";

  ---------------------------------------------------------------------------------------
  -- test selection, only _one_ test selection allowed!
  ---------------------------------------------------------------------------------------
  constant LCD_WRITE_TEST       : boolean                       := false;
  constant LCD_DMA_TEST         : boolean                       := true;

  ---------------------------------------------------------------------------------------
  -- signals to and from design under test (dut)
  ---------------------------------------------------------------------------------------
  -- general
  signal clk_s                : std_logic                     := '0';
  signal reset_s              : std_logic                     := '1';        
  
  -- Avalon Slave
  signal avs_address_s        : std_logic_vector(2 downto 0)  := (others=>'0');
  signal avs_cs_s             : std_logic                     := '0';
  signal avs_read_s           : std_logic                     := '0';
  signal avs_readdata_s       : std_logic_vector(31 downto 0);
  signal avs_write_s          : std_logic                     := '0';
  signal avs_writedata_s      : std_logic_vector(31 downto 0) := (others=>'0');
  
  -- Avalon Master
  signal avm_address_s        : std_logic_vector(31 downto 0)  := (others=>'0');
  signal avm_read_s           : std_logic                     := '0'; 
  signal avm_readdata_s       : std_logic_vector(15 downto 0);
  signal avm_waitrequest_s    : std_logic                     := '0';
 
  -- IRQ
  signal end_of_transaction_irq_s	: std_logic;
  
  -- LCD Parallel Bus
  signal lcd_data_s	     : std_logic_vector(15 downto 0) := (others=>'0');
  signal lcd_cs_n_s	     : std_logic;
  signal lcd_wr_n_s	     : std_logic; 
  signal lcd_d_c_n_s	     : std_logic;

  --register definition (from vhdl implementation)
  constant  LCD_WRITE_CMD_ADDR  : std_logic_vector              := "000";
  constant  LCD_WRITE_DATA_ADDR : std_logic_vector              := "001";
  constant  IMG_PTR_REG_ADDR    : std_logic_vector              := "010";
  constant  IMG_SIZE_REG_ADDR   : std_logic_vector              := "011";
  constant  CTRL_REG_ADDR       : std_logic_vector              := "100";

  ---------------------------------------------------------------------------------------
  -- shared signals of the test processes
  ---------------------------------------------------------------------------------------
  
  signal dma_access_cnt         : std_logic_vector(31 downto 0)  := x"00_00_00_00";
  
  signal read_data              : std_logic_vector(31 downto 0);
    
begin

  ---------------------------------------------------------------------------------------
  -- component (dut) instantiation
  ---------------------------------------------------------------------------------------
  lcd_controller_component : entity work.DMA_LCD_ctrl
  port map(

    -- global signals
    clk                         => clk_s,
    reset                       => reset_s,
    
    -- Avalon Master
    master_address              => avm_address_s,
    master_read                 => avm_read_s,
    master_readdata             => avm_readdata_s,
    master_waitrequest          => avm_waitrequest_s,
    
    -- IRQ
    end_of_transaction_irq      => end_of_transaction_irq_s, 
    
    -- Avalon Slave
    avalon_address              => avs_address_s,
    avalon_cs                   => avs_cs_s,
    avalon_rd                   => avs_read_s,
    avalon_read_data            => avs_readdata_s,
    avalon_wr                   => avs_write_s,
    avalon_write_data           => avs_writedata_s,

    -- LCD Parallel Bus
    LCD_data                    => lcd_data_s,
    LCD_CS_n                    => lcd_cs_n_s,
    LCD_WR_n                    => lcd_wr_n_s,
    LCD_D_C_n                   => lcd_d_c_n_s

  );


  ---------------------------------------------------------------------------------------
  -- reset process
  ---------------------------------------------------------------------------------------
  reset : process
  begin

    -- do reset
    reset_s <= '1';
    wait for RESET_DURATION;
    reset_s <= '0';

    -- do not restart this process
    wait;

  end process reset;


  ---------------------------------------------------------------------------------------
  -- clk process
  ---------------------------------------------------------------------------------------
  clk : process
  begin

    clk_s <= '0';
    wait for CLK_HALF_PERIOD;
    clk_s <= '1';
    wait for CLK_HALF_PERIOD;

    -- restart porcess, do not wait

  end process clk;



  ---------------------------------------------------------------------------------------
  -- TEST PROCESS (STIMULUS) DEFINED BELOW
  --  * select test by define (test selection)
  ---------------------------------------------------------------------------------------


  ---------------------------------------------------------------------------------------
  -- lcd direct write test - stimulus process
  ---------------------------------------------------------------------------------------
  lcd_write_test_gen : if LCD_WRITE_TEST = true generate
  stimulus : process

    ---------------------------------------------------------------------------------------
    -- writes data and command directly to the LCD
    ---------------------------------------------------------------------------------------
    --    1) write command 0x2A
    --    2) write data 0xCC
    
    variable my_line                : STD.textio.line;
    alias swrite is write [line, string, side, width] ;

  begin

    ---------------------------------------------------------------------------------------
    -- wait for reset
    ---------------------------------------------------------------------------------------
    wait for RESET_DURATION;

    ---------------------------------------------------------------------------------------
    -- write test message
    ---------------------------------------------------------------------------------------
    swrite(my_line, "[LCD_WRITE_TEST]");
    writeline(STD.textio.output, my_line);

    ---------------------------------------------------------------------------------------
    -- write command
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => LCD_WRITE_CMD_ADDR,
                          CONST_DATA => x"00_00_00_2A"
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - LCD_WRITE_CMD_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
   
    ---------------------------------------------------------------------------------------
    
    -- Wait until LCD data is written
    wait for 80 ns;
    
    ---------------------------------------------------------------------------------------
    -- write data
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => LCD_WRITE_DATA_ADDR,
                          CONST_DATA => x"00_00_00_CC"
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - LCD_WRITE_DATA_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
   
    ---------------------------------------------------------------------------------------

    -- do not restart this process
    wait;

  end process stimulus;
  end generate;

  ---------------------------------------------------------------------------------------
  -- lcd dma test - stimulus process
  ---------------------------------------------------------------------------------------
  lcd_dma_test_gen : if LCD_DMA_TEST = true generate
  stimulus : process
  
    ---------------------------------------------------------------------------------------
    -- initialiazes the dma controller and checks if the image data is read from the right
    -- place
    ---------------------------------------------------------------------------------------
    --    1) initialize dma controller (image pointer and image size)
    --    2) read back config registers (image pointer and image size)
    --    3) start dma controller 
    --    4) check if image data is read from the right memory address, the pointer is
    --       incremented correctly and the image size is correct (number of read accesses)
    --       -> happens in the av_dummy_slave process
    --    5) wait for the interrupt request when dma transfer finished
    --    6) clear IRQ flag
    
    variable my_line                : STD.textio.line;
    alias swrite is write [line, string, side, width] ;
    
  begin

    ---------------------------------------------------------------------------------------
    -- wait for reset
    ---------------------------------------------------------------------------------------
    wait for RESET_DURATION;

    ---------------------------------------------------------------------------------------
    -- write test message
    ---------------------------------------------------------------------------------------
    swrite(my_line, "[LCD_DMA_TEST]");
    writeline(STD.textio.output, my_line);

    ---------------------------------------------------------------------------------------
    -- write image pointer
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => IMG_PTR_REG_ADDR,
                          CONST_DATA => AV_DUMMY_SLAVE_ADDR
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - IMG_PTR_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
    
    ---------------------------------------------------------------------------------------
    
    ---------------------------------------------------------------------------------------
    -- write image size
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => IMG_SIZE_REG_ADDR,
                          CONST_DATA => DMA_TEST_IMG_SIZE
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - IMG_SIZE_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
      
    ---------------------------------------------------------------------------------------

    ---------------------------------------------------------------------------------------
    -- read back image pointer
    ---------------------------------------------------------------------------------------
    avalon_read_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          READ => avs_read_s,
                          DATA => avs_readdata_s,
                          READ_VALUE => read_data,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => IMG_PTR_REG_ADDR                          
    );

    -- debug out
    swrite(my_line, "[READ INSTRUCTION - IMG_PTR_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA READ="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
    
    assert read_data = AV_DUMMY_SLAVE_ADDR report "LCD DMA test: image pointer read back value is invalid " severity error;
    
     ---------------------------------------------------------------------------------------
    -- read back image size
    ---------------------------------------------------------------------------------------
    avalon_read_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          READ => avs_read_s,
                          DATA => avs_readdata_s,
                          READ_VALUE => read_data,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => IMG_SIZE_REG_ADDR                          
    );

    -- debug out
    swrite(my_line, "[READ INSTRUCTION - IMG_SIZE_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA READ="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
    
    assert read_data = DMA_TEST_IMG_SIZE report "LCD DMA test: image size read back value is invalid" severity error;
    
    ---------------------------------------------------------------------------------------
    -- start dma
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => CTRL_REG_ADDR,
                          CONST_DATA => x"00_00_00_01"
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - CTRL_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
      
    ---------------------------------------------------------------------------------------
    
    -- wait for IRQ signal
    wait until end_of_transaction_irq_s = '1';
    assert not(dma_access_cnt < DMA_TEST_IMG_SIZE) report "LCD DMA test: number of dma accesses is lower than image size" severity error;
    assert not(dma_access_cnt > DMA_TEST_IMG_SIZE) report "LCD DMA test: number of dma accesses is higher than image size" severity error;

  
    ---------------------------------------------------------------------------------------
    -- clear IRQ signal
    ---------------------------------------------------------------------------------------
    avalon_write_data(    ADDRESS => avs_address_s,
                          CS => avs_cs_s,
                          WRITE => avs_write_s,
                          DATA => avs_writedata_s,
                          CLK => clk_s,
                          CLK_PERIOD => CLK_PERIOD,
                          CONST_ADDRESS => CTRL_REG_ADDR,
                          CONST_DATA => x"00_00_00_04"
    );

    -- debug out
    swrite(my_line, "[WRITE INSTRUCTION - CTRL_REG_ADDR] time="); write(my_line, now);
    swrite(my_line, "  ADDRESS="); write(my_line, avs_address_s);
    swrite(my_line, "  DATA WRITE="); write(my_line, avs_writedata_s);
    writeline(STD.textio.output, my_line);
      
    ---------------------------------------------------------------------------------------
        
    assert end_of_transaction_irq_s = '0' report "LCD DMA test: IRQ flag couldn't be cleared" severity error;
        
    -- do not restart this process
    wait;

  end process stimulus;
  end generate;
    
  ---------------------------------------------------------------------------------------
  -- LCD bus monitor
  -- This monitor supervises the LCD parallel bus. Adjust the timing model if necessary.
  ---------------------------------------------------------------------------------------
    lcd_bus_monitor: process
  
    variable data       : std_logic_vector(15 downto 0);
    
    begin
    -- wait for bus activity
    wait until lcd_cs_n_s = '0';
    -- fetch data from avalon bus
    if LCD_WRITE_TEST = true then
        data := avs_writedata_s(15 downto 0);
    elsif LCD_DMA_TEST = true then
        data := avm_readdata_s;
    end if;
    
    assert lcd_wr_n_s = '1' report"LCD bus monitor: timing error, lcd_wr_n should be high" severity error;
    assert data = lcd_data_s report "LCD bus monitor: invalid data" severity error;
    
    -- lcd_wr_n_s low for two clock cycles
    wait for CLK_PERIOD + 1 ns;
    assert lcd_cs_n_s = '0' report"LCD bus monitor: timing error, lcd_cs_n_s should be low" severity error;
    assert lcd_wr_n_s = '0' report"LCD bus monitor: timing error, lcd_wr_n should be low" severity error;
    
    -- lcd_wr_n_s high for two clock cycles
    wait for 2*CLK_PERIOD;
    assert lcd_cs_n_s = '0' report"LCD bus monitor: timing error, lcd_cs_n_s should be low" severity error;
    assert lcd_wr_n_s = '1' report"LCD bus monitor: timing error, lcd_wr_n should be high" severity error;
    
    -- end of bus transaction   
    wait for 2*CLK_PERIOD;
    assert lcd_cs_n_s = '1' report"LCD bus monitor: timing error, lcd_cs_n_s should be high" severity error;
    assert lcd_wr_n_s = '1' report"LCD bus monitor: timing error, lcd_wr_n should be high" severity error;
    
    end process;
    
  ---------------------------------------------------------------------------------------
  -- Avalon dummy slave
  -- This process emulates the RAM, i.e. it provides test data for the DMA access and
  -- checks if the access happens correctly.
  ---------------------------------------------------------------------------------------
  av_dummy_slave_gen : if LCD_DMA_TEST = true generate
  av_dummy_slave: process
  
  begin
  
      -- wait for bus activity
      wait until avm_read_s = '1';
      
      assert avm_address_s = std_logic_vector(unsigned(AV_DUMMY_SLAVE_ADDR) + unsigned(dma_access_cnt)) report "AV dummy slave: wrong address" severity error;
      
      avm_readdata_s <= dma_access_cnt(15 downto 0);
      
      wait for CLK_PERIOD + 1 ns;
      
      assert avm_read_s = '0' report "AV dummy slave: avm_read_s is still high" severity error;
      
      dma_access_cnt <= std_logic_vector(unsigned(dma_access_cnt) + 2);
  
  end process;
  end generate;
  
  
end rtl;

