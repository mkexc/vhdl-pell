library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity tb_pell is
end tb_pell;

architecture Behavioral of tb_pell is
component pell is
    port(
        clk,rst,start: in std_logic;
        n: in std_logic_vector(2 downto 0);
        ready: out std_logic;
        data: out std_logic_vector(7 downto 0)
    );
end component;
signal clk_s,rst_s,start_s,ready_s,ready_sFSMD: std_logic;
signal n_s: std_logic_vector(2 downto 0);
signal data_s,data_sFSMD : std_logic_vector(7 downto 0);
constant clkper: time:= 10 ns;

for HLSM: pell use entity work.pell(HLSM);
for FSMD: pell use entity work.pell(FSMD);

begin

    HLSM: pell port map (clk=>clk_s,rst=>rst_s,start=>start_s,n=>n_s,ready=>ready_s,data=>data_s);
    FSMD: pell port map (clk=>clk_s,rst=>rst_s,start=>start_s,n=>n_s,ready=>ready_sFSMD,data=>data_sFSMD);
    
    process
    begin
        clk_s<='0';
        wait for clkper/2;
        clk_s<='1';
        wait for clkper/2;
    end process;
    
    process
    begin
        rst_s<='1';
        wait for clkper; 
        rst_s<='0';
        for i in 0 to 7 loop
            start_s<='1'; n_s<=std_logic_vector(to_unsigned(i,n_s'length));
            wait until ready_sFSMD='1';
        end loop;
        wait;
    end process;

end Behavioral;
