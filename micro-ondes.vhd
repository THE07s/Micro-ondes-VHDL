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
        segments_o : out std_logic_vector(6 downto 0)
    );
end SegmentDecoder;

architecture TruthTable of SegmentDecoder is
begin
    with digit_i select
        segments_o <= "1111110" when  0,
                      "0110000" when  1,
                      "1101101" when  2,
                      "1111001" when  3,
                      "0110011" when  4,
                      "1011011" when  5,
                      "1011111" when  6,
                      "1110000" when  7,
                      "1111111" when  8,
                      "1111011" when  9,
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
use ieee.numeric_std.all;

entity micro_ondes is
    port(
        clk_i                           : in  std_logic;
        switches_i                      : in  std_logic_vector(15 downto 0);
        btn_left_i                      : in  std_logic;
        btn_center_i                    : in  std_logic;
        btn_right_i                     : in  std_logic;
        btn_up_i                        : in  std_logic;
        btn_down_i                      : in  std_logic;
        leds_o                           : out std_logic_vector(15 downto 0);
        disp_segments_n_o               : out std_logic_vector(6 downto 0);
        disp_point_n_o                  : out std_logic;
        disp_select_n_o                 : out std_logic_vector(3 downto 0)
    );
end micro_ondes;

architecture Structural of micro_ondes is
    signal porte_fermee                 : std_logic;
    signal debut                        : std_logic;
    signal fonctionnement               : std_logic := '0';
    signal pause                        : std_logic := '0';
    signal fin                          : std_logic;
    signal magnetron                    : std_logic;
    signal buzzer_actif                 : std_logic := '0';
    signal compteur_buzzer              : integer range 0 to 3 := 0;
    signal seconde                      : integer;
    signal minute                       : integer;
    signal secondes                     : integer range 0 to 5999;
    signal secondes_decalees            : integer range 0 to 5999 := 0;
    signal dizaine_minute               : integer range 0 to 9;
    signal unite_minute                 : integer range 0 to 9;
    signal dizaine_seconde              : integer range 0 to 5;
    signal unite_seconde                : integer range 0 to 9;
    signal clk_slow_1s                  : std_logic;
    signal clk_slow_20ms                : std_logic;
    signal afficheur_selection          : std_logic_vector(1 downto 0) := "00";
    signal valeur_afficheur             : integer range 0 to 9;

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
            cycle_o => clk_slow_1s
        );
---------------------------------------------------------------    
-- Divider 20ms
---------------------------------------------------------------
    divider_20ms_inst : entity work.CounterModN(Behavioral)
        generic map(
            N => 2e6
        )
        port map(
            clk_i   => clk_i,
            reset_i => '0',
            inc_i   => '1',
            value_o => open,
            cycle_o => clk_slow_20ms
        );
---------------------------------------------------------------
-- Vérification fermeture porte
---------------------------------------------------------------
    p_porte : process(switches_i(15), pause)
    begin
        if switches_i(15) = '0' then
            porte_fermee <= '0';
            pause <= '1';
        else
            porte_fermee <= '1';
        end if;
    end process p_porte;
---------------------------------------------------------------
-- Bouton de démarrage et pause
---------------------------------------------------------------
    p_start_stop : process(btn_center_i, fonctionnement)
    begin
        if btn_center_i = '1' then
            if fonctionnement = '1' then
                fonctionnement <= '0';
                pause <= '1';
            else
                fonctionnement <= '1';
                pause <= '0';
            end if;
        end if;
    end process p_start_stop;
---------------------------------------------------------------
-- Autorisation fonctionnement
---------------------------------------------------------------
    p_autorisation : process(fonctionnement, pause, porte_fermee)
    begin
        if fonctionnement = '1' and pause = '0' and porte_fermee = '1' then
            debut <= '1';
        else
            debut <= '0';
        end if;
    end process p_autorisation;
---------------------------------------------------------------
-- Configuration du chronomètre
---------------------------------------------------------------
    p_config_chrono : process(btn_left_i, btn_right_i)
    begin
        if btn_left_i = '1' and secondes > 29 then
            secondes <= secondes - 30;
            secondes_decalees <= secondes + 1;
        elsif btn_right_i = '1' and secondes < 5970 then
            secondes <= secondes + 30;
            secondes_decalees <= secondes + 1;
        end if;
    end process p_config_chrono;
---------------------------------------------------------------
-- Configuration du fonctionnement du micro-ondes
---------------------------------------------------------------
    p_fonctionnement_micro_ondes : process(clk_i, debut, clk_slow_1s)
    begin
        if rising_edge(clk_i) then
            if debut = '1' then
                if clk_slow_1s = '1' then
                    if secondes > 0 and secondes_decalees > 1 then
                        magnetron <= '1';
                        secondes <= secondes - 1;
                        secondes_decalees <= secondes_decalees - 1;
                    elsif secondes_decalees = 1 and secondes = 0 then 
                        magnetron <= '0';
                    end if;
                end if;
            end if;
        end if;
    end process p_fonctionnement_micro_ondes;
---------------------------------------------------------------
-- Configuration du buzzer
---------------------------------------------------------------
    p_buzzer : process(clk_i, clk_slow_1s, secondes, secondes_decalees)
    begin
        if rising_edge(clk_i) then
            if clk_slow_1s = '1' and secondes_decalees = 1 and secondes = 0 then
                buzzer_actif <= '1';
                compteur_buzzer <= 0;
            elsif buzzer_actif = '1' then
                if clk_slow_1s = '1' and compteur_buzzer < 3 then
                    compteur_buzzer <= compteur_buzzer + 1;
                elsif compteur_buzzer = 3 then
                    buzzer_actif <= '0';
                end if;
            end if;
            secondes_decalees <= secondes;
        end if;
    end process p_buzzer;
---------------------------------------------------------------
-- Configuration du Convertisseur
---------------------------------------------------------------
    p_convertisseur : process (secondes)
    begin
        if secondes /= 0 then
            minute <= (secondes * 34 / 64);
            seconde <= secondes - (minute * 60);
            dizaine_minute <= minute * 204 / 2048;
            unite_minute <= minute - (dizaine_minute * 10);
            dizaine_seconde <= seconde * 204 / 2048;
            unite_seconde <= seconde - (dizaine_seconde * 10);
        end if;
    end process p_convertisseur;
---------------------------------------------------------------
-- MUX pour l'affichage
---------------------------------------------------------------
    p_affichage : process(clk_slow_20ms)
    begin
        case afficheur_selection is
            when "00" => 
                valeur_afficheur <= dizaine_minute;
                disp_select_n_o <= "1110";
            when "01" => 
                valeur_afficheur <= unite_minute;
                disp_select_n_o <= "1101";
            when "10" => 
                valeur_afficheur <= dizaine_seconde;
                disp_select_n_o <= "1011";
            when "11" => 
                valeur_afficheur <= unite_seconde;
                disp_select_n_o <= "0111";
            when others =>
                valeur_afficheur <= 0;
                disp_select_n_o <= "1111";
        end case;
    end process p_affichage;
---------------------------------------------------------------
-- Décodage des segments pour l'affichage
---------------------------------------------------------------
    decoder_inst : entity work.SegmentDecoder(TruthTable)
        port map(
            digit_i => valeur_afficheur,
            segments_o => disp_segments_n_o
        );
---------------------------------------------------------------
-- Sélection cyclique des afficheurs
---------------------------------------------------------------
    p_selection_afficheur : process(clk_slow_20ms)
    begin
        if rising_edge(clk_slow_20ms) then
            afficheur_selection <= std_logic_vector( unsigned(afficheur_selection) + 1 );
        end if;
    end process p_selection_afficheur;

leds_o <= (others => magnetron);
leds_o <= (others => buzzer_actif);

end Structural;
