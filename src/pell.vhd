library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity pell is
    port(
        clk,rst,start: in std_logic;
        n: in std_logic_vector(2 downto 0);
        ready: out std_logic;
        data: out std_logic_vector(7 downto 0)
    );
end pell;

architecture HLSM of pell is
    type stateType is (S_init,S_wait,S_comp,S_end);
    signal currState,nextState: stateType;
    signal currN,currCntN,nextCntN: std_logic_vector(2 downto 0);
    signal currOut,nextOut,prev1,nextPrev1: std_logic_vector(7 downto 0);
    
begin
    regs: process(clk,rst)
    begin
        if(rst='1') then
            currState<=S_init;
            currOut<=(others=>'0');
            currN<=(others=>'0');
            prev1<=(others=>'0');
            currCntN<=(others=>'0');
        elsif(rising_edge(clk)) then
            currState<=nextState;
            currOut<=nextOut;
            if(start='1') then
                currN<=n;
            end if;
            prev1<=nextPrev1;
            currCntN<=nextCntN;
        end if;
    end process;
    
    data<=currOut;
    
    comb: process(currState,n,start,currOut,currN,prev1,currCntN)
    begin
    ready<='0';
        case currState is
            when S_init => nextState<= S_wait; nextOut<=(others=>'0'); nextCntN<=(others =>'0');
                nextPrev1<=(nextPrev1'length-1 downto 0 =>'0');
            when S_wait=> nextOut<=(others=>'0'); nextCntN<=(others =>'0');
                          nextPrev1<=(nextPrev1'length-1 downto 0 =>'0');
                          if(start='1') then
                            if(n=(2 downto 0 =>'0')) then
                                nextState<=S_end;
                            elsif (n=(2 downto 1=>'0')&"1") then
                                nextState<=S_end; nextOut<=(nextOut'length-1 downto 1 =>'0')&"1";
                            else
                                nextState<=S_comp; nextCntN<=std_logic_vector(to_unsigned(1,nextCntN'length)); --branch +1
                                nextOut<=std_logic_vector(to_unsigned(1,nextOut'length)); nextPrev1<=std_logic_vector(to_unsigned(0,nextPrev1'length)); 
                            end if;
                          else
                            nextState<= S_wait;
                          end if;
           when S_comp=> if(unsigned(currN)>unsigned(currCntN) and unsigned(currCntN)/=0) then
                            nextCntN<=std_logic_vector(unsigned(currCntN)+1);
                            nextOut<=std_logic_vector(to_unsigned(to_integer(unsigned(currOut))*2,nextOut'length) + unsigned(prev1));
                            nextPrev1<=currOut;
                            nextState<=S_comp;
                         else
                            nextCntN<=(others=>'0'); 
                            nextOut<=currOut;
                            nextPrev1<=prev1;
                            
                            nextState<=S_end;
                         end if;
           when S_end=> ready<='1'; nextState<= S_wait; nextOut<=(others=>'0'); nextCntN<=(others =>'0');
                nextPrev1<=(nextPrev1'length-1 downto 0 =>'0'); --0
           when others=> nextState<= S_init; nextOut<=(others=>'0'); nextCntN<=(others =>'0');
                nextPrev1<=(nextPrev1'length-1 downto 0 =>'0'); -- 0
        end case;
    end process;

end HLSM;

architecture FSMD of pell is
    -- Shared signals
    signal cmp_sel,cmp_is_zero,n_is_one,n_cntn_gt,cntn_sel,out_en: std_logic;
    signal prev1_sel,out_sel: std_logic_vector(1 downto 0);
    
    -- DP signals
    signal currN,currCntN,nextCntN,cmp_in: std_logic_vector(2 downto 0);
    signal currOut,nextOut,prev1,nextPrev1: std_logic_vector(7 downto 0);
    
    -- FSM signals
    type stateType is (S_init,S_wait,S_comp,S_end);
    signal currState,nextState: stateType;
    
begin
    
    -- Datapath processes
    DPregs: process(clk,rst)
    begin
        if(rst='1') then
            currOut<=(others=>'0');
            currN<=(others=>'0');
            prev1<=(others=>'0');
            currCntN<=(others=>'0');
        elsif(rising_edge(clk)) then
            if(out_en='1') then
                currOut<=nextOut;
            end if;
            if(start='1') then
                currN<=n;
            end if;
            prev1<=nextPrev1;
            currCntN<=nextCntN;
        end if;
    end process DPregs;
    
    DPcomb: process(currOut,currN,prev1,currCntN,cmp_in,cmp_sel,n,cntn_sel,out_sel,prev1_sel)
    begin
        if( cmp_in = (2 downto 0 =>'0')) then
            cmp_is_zero <= '1';
        else
            cmp_is_zero <= '0';
        end if;
        
        if( cmp_sel = '1') then
            cmp_in<=currCntN;
        else
            cmp_in<=n;
        end if;
        
        if(cntn_sel ='1') then
            nextCntN<= std_logic_vector(unsigned(currCntN)+1);
        else
            nextCntN<=(others=>'0');
        end if;
        
        if(unsigned(currN)>unsigned(currCntN)) then
            n_cntn_gt<='1';
        else
            n_cntn_gt<='0';
        end if;
        
        if( to_integer(unsigned(n)) = 1) then
            n_is_one<='1';
        else
            n_is_one<='0';
        end if;
        
        if (out_sel ="00") then
            nextOut <= std_logic_vector(unsigned(currOut(currOut'length-2 downto 0)&"0") + unsigned(prev1));
        elsif (out_sel = "01") then
            nextOut <= currOut;
        elsif (out_sel ="10") then
            nextOut <= std_logic_vector(to_unsigned(1,nextOut'length));
        else    
            nextOut <= std_logic_vector(to_unsigned(0,nextOut'length));
        end if;
        
        if(prev1_sel = "00") then
            nextPrev1<=(others=>'0');
        elsif (prev1_sel ="01") then
            nextPrev1<=prev1;
        else 
            nextPrev1<=currOut;
        end if;
    end process DPcomb;
    
    DPout: process(currOut)
    begin
        data<=currOut;
    end process DPOut;
    
    -- FSM processes
    
    FSMregs: process(clk,rst)
    begin
        if(rst='1') then
            currState<=S_init;
        elsif(rising_edge(clk)) then
            currState<=nextState;
        end if;
    end process FSMregs;

    FSMcomb: process(currState,start,currOut,currN,prev1,currCntN,cmp_is_zero,n_is_one,n_cntn_gt)
    begin
    ready<='0'; out_en<='1';
        case currState is
            when S_init => nextState<= S_wait; out_sel<="11"; cntn_sel<='0';
                prev1_sel<="00"; cmp_sel<='1';
            when S_wait=> out_sel<="11"; cntn_sel<='0';
                          prev1_sel<="00"; cmp_sel<='0';
                          if(start='1') then
                            if(cmp_is_zero='1') then
                                nextState<=S_end;
                            elsif (n_is_one='1') then
                                nextState<=S_end; out_sel<="10";
                            else
                                nextState<=S_comp; cntn_sel<='1';
                                out_sel<="10"; prev1_sel<="00";
                            end if;
                          else
                            nextState<= S_wait;
                          end if;
           when S_comp=> cmp_sel<='1';
                         if(n_cntn_gt='1' and cmp_is_zero='0') then
                            cntn_sel<='1';
                            out_sel<="00";
                            prev1_sel<="10";
                            nextState<=S_comp;
                         else
                            cntn_sel<='0';
                            out_en<='0';
                            prev1_sel<="01";
                            nextState<=S_end;
                         end if;
           when S_end=> ready<='1'; nextState<= S_wait; out_sel<="11"; cntn_sel<='0';
                prev1_sel<="00"; cmp_sel<='1'; 
           when others=> nextState<= S_init; out_sel<="11"; cntn_sel<='0';
                prev1_sel<="00"; cmp_sel<='1';
        end case;
    end process FSMComb;

end FSMD;
