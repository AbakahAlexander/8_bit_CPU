LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY multicore_microprocessor IS
    PORT (
        clk       : IN  std_logic;
        reset     : IN  std_logic;
        in_data   : IN  std_logic_vector(7 DOWNTO 0);
        core_select : IN std_logic_vector(2 DOWNTO 0); -- Selects one of the 8 cores
        address    : INOUT  std_logic_vector(7 DOWNTO 0);
        mem_write  : IN  std_logic;  -- Memory write signal
        out_data   : OUT std_logic_vector(7 DOWNTO 0)
    );
END multicore_microprocessor;

ARCHITECTURE Behavioral OF multicore_microprocessor IS
    -- Define memory and registers
    TYPE memory_type IS ARRAY (0 TO 255) OF std_logic_vector(7 DOWNTO 0);
    TYPE reg_file_type IS ARRAY (0 TO 7) OF std_logic_vector(7 DOWNTO 0); -- 8 cores with 8-bit registers

    -- 8-core signals
    SIGNAL memory      : memory_type := (OTHERS => (OTHERS => '0'));
    SIGNAL acc         : reg_file_type := (OTHERS => (OTHERS => '0'));  -- Accumulators for each core
    SIGNAL pc          : reg_file_type := (OTHERS => (OTHERS => '0'));  -- Program Counter for each core
    SIGNAL ir          : reg_file_type := (OTHERS => (OTHERS => '0'));  -- Instruction Register for each core
    SIGNAL r0, r1, r2  : reg_file_type := (OTHERS => (OTHERS => '0'));  -- General-purpose registers per core
    SIGNAL alu_result  : std_logic_vector(7 DOWNTO 0);
    SIGNAL op_code     : std_logic_vector(3 DOWNTO 0);  -- Increased op_code size
    SIGNAL zero_flag   : std_logic_vector(7 DOWNTO 0);  -- Zero flag for each core
    SIGNAL carry_flag  : std_logic_vector(7 DOWNTO 0);  -- Carry flag for each core

    -- Process to select which core to activate based on core_select signal
    SIGNAL selected_core : integer range 0 to 7 := 0;
BEGIN
    selected_core <= to_integer(unsigned(core_select)); -- Convert core_select to integer for core indexing

    PROCESS(clk, reset)
    BEGIN
        IF reset = '1' THEN
            -- Initialize all cores
            FOR i IN 0 TO 7 LOOP
                acc(i) <= (OTHERS => '0');
                pc(i) <= (OTHERS => '0');
                ir(i) <= (OTHERS => '0');
                r0(i) <= (OTHERS => '0');
                r1(i) <= (OTHERS => '0');
                r2(i) <= (OTHERS => '0');
                zero_flag(i) <= '0';
                carry_flag(i) <= '0';
            END LOOP;
            alu_result <= (OTHERS => '0');

        ELSIF rising_edge(clk) THEN
            -- Fetch instruction for the selected core
            pc(selected_core) <= std_logic_vector(unsigned(pc(selected_core)) + 1);

            ir(selected_core) <= memory(to_integer(unsigned(pc(selected_core))));

            -- Decode the instruction from IR of the selected core
            op_code <= ir(selected_core)(7 DOWNTO 4);  -- Assume top 4 bits are opcode

            CASE op_code IS
                WHEN "0000" =>  -- Load immediate to accumulator
                    acc(selected_core) <= in_data;

                WHEN "0001" =>  -- Load from memory to R0
                    r0(selected_core) <= memory(to_integer(unsigned(address)));

                WHEN "0010" =>  -- Add R0 to Accumulator
                    alu_result <= std_logic_vector(unsigned(acc(selected_core)) + unsigned(r0(selected_core)));
                    IF unsigned(alu_result) = 0 THEN
                        zero_flag(selected_core) <= '1';
                    ELSE
                        zero_flag(selected_core) <= '0';
                    END IF;

                WHEN "0011" =>  -- Subtract R1 from Accumulator
                    alu_result <= std_logic_vector(unsigned(acc(selected_core)) - unsigned(r1(selected_core)));
                    IF unsigned(acc(selected_core)) < unsigned(r1(selected_core)) THEN
                        carry_flag(selected_core) <= '1';
                    ELSE
                        carry_flag(selected_core) <= '0';
                    END IF;

                WHEN "0100" =>  -- AND R2 with Accumulator
                    alu_result <= std_logic_vector(unsigned(acc(selected_core)) AND unsigned(r2(selected_core)));

                WHEN "0101" =>  -- OR R2 with Accumulator
                    alu_result <= std_logic_vector(unsigned(acc(selected_core)) OR unsigned(r2(selected_core)));

                WHEN "0110" =>  -- Store Accumulator to Memory
                    IF mem_write = '1' THEN
                        memory(to_integer(unsigned(address))) <= acc(selected_core);
                    END IF;

                WHEN "0111" =>  -- Jump if Zero
                    IF zero_flag(selected_core) = '1' THEN
                        pc(selected_core) <= in_data;  -- Jump to address specified in in_data
                    END IF;

                WHEN "1000" =>  -- Compare Accumulator with R0
                    IF acc(selected_core) = r0(selected_core) THEN
                        zero_flag(selected_core) <= '1';
                    ELSE
                        zero_flag(selected_core) <= '0';
                    END IF;

                WHEN OTHERS =>
                    NULL;  -- No operation
            END CASE;

            -- Update the accumulator after arithmetic operations
            IF op_code /= "0110" THEN
                acc(selected_core) <= alu_result;
            END IF;
        END IF;
    END PROCESS;

    out_data <= acc(selected_core);  -- Output accumulator value for selected core
END Behavioral;
