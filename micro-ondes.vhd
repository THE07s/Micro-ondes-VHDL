--*****************************************************************************
--
-- CounterModN entity+archi
--
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;

entity CounterModN is
    generic(
        N : positive
    );
    port(
        clk_i, reset_i, inc_i : in  std_logic;
        value_o               : out integer range 0 to N - 1;
        cycle_o               : out std_logic
    );
end CounterModN;

architecture Behavioral of CounterModN is
    signal value_reg, value_next : integer range 0 to N - 1;
begin
    p_value_reg : process(clk_i, reset_i)
    begin
        if reset_i = '1' then
            value_reg <= 0;
        elsif rising_edge(clk_i) then
            if inc_i = '1' then
                value_reg <= value_next;
            end if;
        end if;
    end process p_value_reg;

    value_next <= 0 when value_reg = N - 1 else value_reg + 1;

    value_o <= value_reg;
    cycle_o <= '1' when inc_i = '1' and value_reg = N - 1 else '0';
end Behavioral;


--*****************************************************************************
--
-- SegmentDecoder entity+archi
--
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;

entity SegmentDecoder is
    port(
        digit_i    : in  natural range 0 to 15;
        segments_o : out std_logic_vector(0 to 6)
    );
end SegmentDecoder;

architecture TruthTable of SegmentDecoder is
begin
    with digit_i select
        segments_o <= "1111110" when 0,
                      "0110000" when 1,
                      "1101101" when 2,
                      "1111001" when 3,
                      "0110011" when 4,
                      "1011011" when 5,
                      "1011111" when 6,
                      "1110000" when 7,
                      "1111111" when 8,
                      "1111011" when 9,
                      "1110111" when 10,
                      "0011111" when 11,
                      "1001110" when 12,
                      "0111101" when 13,
                      "1001111" when 14,
                      "1000111" when 15;
end TruthTable;


--*****************************************************************************
--
-- micro-ondes entity+archi
--
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;

entity micro-ondes is
    port(
        clk_i             : in  std_logic;
        switches_i        : in  std_logic_vector(15 downto 0);
        btn_gauche_i      : in  std_logic;
        btn_center_i      : in  std_logic;
        btn_droite_i      : in  std_logic;
        btn_haut_i        : in  std_logic;
        btn_bad_i         : in  std_logic;
        led_magnetron_o   : out std_logic;
        led_buzzer_o      : out std_logic
    );
end micro-ondes;

architecture Structural of micro-ondes is
    -- Declarations
    signal start_stop : std_logic;
    signal bnt_G : std_logic;
    signal btn_D : std_logic;
    signal btn_C : std_logic;
    signal btn_H : std_logic;
    signal btn_B : std_logic;
    signal porte_fermee : std_logic;
    signal debut : std_logic;
    signal fonctionnement : std_logic;
    signal fin : std_logic;
    signal une_seconde : std_logic;
    signal vingt_milliseconde : std_logic;
    
    signal seconde : integer range 0 to 5999;
    signal dizaine_minute : integer range 0 to 9;
    signal unite_minute : integer range 0 to 9;
    signal dizaine_seconde : integer range 0 to 5;
    signal unite_seconde : integer range 0 to 9;
    signal port_afficheur : integer range 0 to 3;
    signal valeur_afficheur : integer range 0 to 9;

    -- signal clk_slow                : std_logic;
    -- signal start_stop              : integer range 0 to 15;
    -- signal configuration_chrono    : integer range 0 to 15;
    -- signal fonctionnement          : std_logic;
    -- signal convertisseur           : std_logic;
    -- signal et                      : std_logic;
    -- signal score_hit               : integer range 0 to 9;
    -- signal score_miss              : integer range 0 to 9;
    
    
begin
---------------------------------------------------------------    
-- Divider 1s
---------------------------------------------------------------
    divider_1s_inst : entity work.CounterModN(Behavioral)
       generic map(
            N => 100e6
        )
        port map(
            clk_i   => clk_i,
            reset_i => '0',
            inc_i   => '1',
            value_o => open,
            cycle_o => une_seconde
        );    
---------------------------------------------------------------
-- Vérification fermeture porte
---------------------------------------------------------------

    p_porte : process(switches_i(15))
        begin
            if switches_i(15) then
                porte_fermee <= 1;
            else 
                porte_fermee <= 0;
            end if;
        end process p_porte;
---------------------------------------------------------------
-- Bouton de démarrage
---------------------------------------------------------------
    p_start_stop : process(btn_C)
        begin
            if btn_C then
                 start_stop <= 1;
            else
                start_stop <=0;
            end if;
        end process p_start_stop;
---------------------------------------------------------------
-- autorisation fonctionnement
---------------------------------------------------------------
    p_autorisation : process(start_stop, porte_fermee)
        begin
            if start_stop and porte_fermee then
                debut <= 1;
            else
                debut <= 0;
            end if;
        end process p_autorisation;
---------------------------------------------------------------
-- Configuration du chronomètre
---------------------------------------------------------------
    p_config_chrono : process(btn_G, btn_D)
            begin
                if btn_G and seconde > 0 then
                    seconde <= seconde - 1;
                elsif btn_D and seconde < 5999 then
                    seconde <= seconde + 1;
                end if;
            end process p_config_chrono;
                















        
---------------------------------------------------------------
-- Compteur de score
---------------------------------------------------------------
    p_counter : process(clk_slow)
        begin
            if rising_edge(clk_slow) then
                if led_index = 15 then
                    led_index <= 0;
                else
                    led_index <= led_index + 1;
                end if;
            end if;
         end process p_counter;   

         
    p_decoder : process(clk_slow, led_index)
        begin
            led_o(led_index) <= '1';
            if rising_edge(clk_slow) then
                led_o(led_index) <= '0';
            end if;
        end process p_decoder;
        
    p_marteau : process(switches_i)
        begin
            btn_index <= 0;
            for i in 0 to 15 loop
                if switches_i(i) = '1' then
                    btn_index <= i;
                end if;
            end loop;
        end process;
        
    p_comparator : process(led_index, btn_index)
        begin
            if led_index = btn_index then
                hit <= '1';
            else
                miss <= '1';
            end if;
        end process p_comparator;
    
    p_score : process(btn_center_i, hit, miss, reset, score_hit, score_miss)
        begin
            if reset = '1' or btn_center_i = '1' then
                score_hit <= 0;
                score_miss <= 0;
            elsif score_hit + score_miss = 9 then
                reset <= '1';
            elsif hit = '1' then
                score_hit <= score_hit + 1;

            elsif miss = '1' then
                score_miss <= score_hit + 1;
            end if;
        end process p_score;
    
    decoder_hit_inst : entity work.SegmentDecoder(TruthTable)
        port map(
            digit_i => score_hit,
            segments_o => hit_o
        );

    decoder_miss_inst : entity work.SegmentDecoder(TruthTable)
        port map(
            digit_i => score_miss,
            segments_o => miss_o
        );
end Structural;
