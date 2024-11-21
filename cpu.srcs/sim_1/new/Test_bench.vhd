LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY multicore_microprocessor_tb IS
END multicore_microprocessor_tb;

ARCHITECTURE behavior OF multicore_microprocessor_tb IS
    COMPONENT multicore_microprocessor
        PORT (
            clk         : IN  std_logic;
            reset       : IN  std_logic;
            in_data     : IN  std_logic_vector(7 DOWNTO 0);
            core_select : IN  std_logic_vector(2 DOWNTO 0);  -- Selects one of the 8 cores
            address     : IN  std_logic_vector(7 DOWNTO 0);
            mem_write   : IN  std_logic;
            out_data    : OUT std_logic_vector(7 DOWNTO 0)
        );
    END COMPONENT;

    SIGNAL clk_tb        : std_logic := '0';
    SIGNAL reset_tb      : std_logic := '0';
    SIGNAL in_data_tb    : std_logic_vector(7 DOWNTO 0);
    SIGNAL core_select_tb: std_logic_vector(2 DOWNTO 0) := "000";  -- Initially select core 0
    SIGNAL address_tb    : std_logic_vector(7 DOWNTO 0);
    SIGNAL mem_write_tb  : std_logic := '0';
    SIGNAL out_data_tb   : std_logic_vector(7 DOWNTO 0);

    CONSTANT clk_period  : time := 10 ns;

BEGIN
    -- Instantiate the Microprocessor
    uut: multicore_microprocessor PORT MAP (
        clk         => clk_tb,
        reset       => reset_tb,
        in_data     => in_data_tb,
        core_select => core_select_tb,
        address     => address_tb,
        mem_write   => mem_write_tb,
        out_data    => out_data_tb
    );

    -- Clock process
    clk_process : PROCESS
    BEGIN
        clk_tb <= '0';
        WAIT FOR clk_period / 2;
        clk_tb <= '1';
        WAIT FOR clk_period / 2;
    END PROCESS;

    -- Stimulus process
    stim_process : PROCESS
    BEGIN
        -- Initialize inputs
        reset_tb <= '1';
        WAIT FOR clk_period;
        reset_tb <= '0';

        -- Load immediate value into accumulator for Core 0
        core_select_tb <= "000";       -- Select core 0
        in_data_tb <= "00001111";      -- Load 15
        address_tb <= "00000000";      -- Load to accumulator
        WAIT FOR clk_period;

        -- Store a value in memory for Core 0
        mem_write_tb <= '1';
        in_data_tb <= "00000001";      -- Store 1
        address_tb <= "00000001";      -- At memory address 1
        WAIT FOR clk_period;
        mem_write_tb <= '0';

        -- Load from memory to R0 for Core 0
        address_tb <= "00000001";
        WAIT FOR clk_period;

        -- Add R0 to Accumulator for Core 0
        address_tb <= "00000000";      -- Accumulator + R0
        WAIT FOR clk_period;

        -- Subtract R1 from Accumulator for Core 0
        address_tb <= "00000010";      -- Assume R1 has some value
        WAIT FOR clk_period;

        -- Perform AND with R2 for Core 0
        address_tb <= "00000011";      -- Assume R2 has some value
        WAIT FOR clk_period;

        -- Perform OR with R2 for Core 0
        address_tb <= "00000011";      -- OR operation
        WAIT FOR clk_period;

        -- Jump if Zero for Core 0
        in_data_tb <= "00000010";      -- Jump to address 2 if Zero flag set
        WAIT FOR clk_period;

        -- Compare Accumulator with R0 for Core 0
        WAIT FOR clk_period;

        -- Test multiple cores by changing core_select
        FOR i IN 1 TO 7 LOOP
            core_select_tb <= std_logic_vector(to_unsigned(i, 3));  -- Select core i
            in_data_tb <= std_logic_vector(to_unsigned(i * 10, 8)); -- Load distinct data for each core
            address_tb <= "00000000";
            WAIT FOR clk_period;

            -- Additional load/store operations per core
            mem_write_tb <= '1';
            in_data_tb <= std_logic_vector(to_unsigned(i * 3, 8));  -- Store different values for each core
            address_tb <= std_logic_vector(to_unsigned(i, 8));
            WAIT FOR clk_period;
            mem_write_tb <= '0';
        END LOOP;

        -- End simulation
        WAIT;
    END PROCESS;

END behavior;
