-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- Ce code fonctionne (sauf les animations de LEDs)
-- ============================================================================
-- ============================================================================
-- ============================================================================
-- ============================================================================


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
-- EventDetector entity+archi
--
--*****************************************************************************
    library ieee;
    use ieee.std_logic_1164.all;

    entity EventDetector is
        generic(
            DURATION : positive := 1
        );
        port(
            clk_i     : in  std_logic;
            src_i     : in  std_logic;
            on_evt_o  : out std_logic;
            off_evt_o : out std_logic;
            status_o  : out std_logic
        );
    end EventDetector;

    architecture Simple of EventDetector is
        -- Declarations
        signal src_reg : std_logic_vector(0 to 1) := "00";
    begin

    -- processus de fonctionnement par binaire pur
    fonctionnement : process(clk_i)
    begin
    if rising_edge(clk_i) then
        src_reg(0) <= src_i;
        src_reg(1) <= src_reg(0);
    end if;
    end process fonctionnement;
        -- Concurrent statements
        on_evt_o <= src_reg(0) and not src_reg(1);
        off_evt_o <= src_reg(1) and not src_reg(0);
        status_o <= src_reg(0);
    end Simple;

--*****************************************************************************
--
-- Micro_ondes entity+archi
--
--*****************************************************************************
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity micro_ondes is
    port(
        -- Définition de nos ports :
        clk_i                               : in  std_logic;
        switches_i                          : in  std_logic_vector(15 downto 0);
        btn_left_i                          : in  std_logic;
        btn_right_i                         : in  std_logic;
        btn_center_i                        : in  std_logic;
        btn_up_i                            : in  std_logic;
        btn_down_i                          : in  std_logic;

        leds_o                              : out std_logic_vector(15 downto 0);

        disp_segments_n_o                   : out std_logic_vector(0 to 6);
        disp_select_n_o                     : out std_logic_vector(3 downto 0)
    );
end micro_ondes;

architecture Structural of micro_ondes is

    -- Clock progressivement ralentie :
    signal clk_slow_5ms, clk_slow_20ms, clk_slow_100ms, clk_slow_1s : std_logic;

    -- Signaux internes :
    signal porte_fermee                                             : std_logic := '0';
    signal fonctionnement                                           : std_logic := '0';
    signal pause                                                    : std_logic := '0';
    signal magnetron                                                : std_logic := '0';
    signal buzzer_actif                                             : std_logic := '0';
    signal compteur_buzzer                                          : integer range 0 to 3 := 0;

    signal secondes                                                 : integer range 0 to 5999 := 0;
    signal minute                                                   : integer range 0 to 99;
    signal seconde                                                  : integer range 0 to 59;

    signal dizaine_minute                                           : integer range 0 to 9;
    signal unite_minute                                             : integer range 0 to 9;
    signal dizaine_seconde                                          : integer range 0 to 5;
    signal unite_seconde                                            : integer range 0 to 9;

    signal digit_index                                              : integer range 0 to 3;
    signal valeur_afficheur                                         : integer range 0 to 9;
    signal segments                                                 : std_logic_vector(0 to 6); -- Segments pour l'affichage
    
    signal btn_left_s                                               : std_logic;
    signal btn_right_s                                              : std_logic;
    signal btn_center_s                                             : std_logic;
--    signal btn_up_s                                                 : std_logic;
--    signal btn_down_s                                               : std_logic;
    
    constant DURATION                                               : integer := 2;


    -- Signaux ajoutés par Kenneth :

begin
-------------------------------------------------------------------
-- Décalaration des instructions concurentes :
-------------------------------------------------------------------
    -------------------------------------------------------------------
    --                       AFFECTATION LEDs                        --
    -------------------------------------------------------------------
        leds_o(14 downto 11)    <= (others => magnetron);
        leds_o(4 downto 0)      <= (others => magnetron);
        leds_o(10 downto 5)     <= (others => buzzer_actif);
        leds_o(15)              <= switches_i(15);

    -------------------------------------------------------------------
    --                    NÉGATION DES SEGMENTS                      --
    -------------------------------------------------------------------
        disp_segments_n_o       <= not segments;

-------------------------------------------------------------------
-- Implémentation des diviseurs de clock :
-------------------------------------------------------------------
    divider_5ms_inst : entity work.CounterModN(Behavioral)
       generic map(
            N => 500000
        )
        port map(
            clk_i       => clk_i,
            reset_i     => '0',
            inc_i       => '1',
            value_o     => open,
            cycle_o     => clk_slow_5ms
        );
    divider_20ms_inst : entity work.CounterModN(Behavioral)
       generic map(
            N => 4
        )
        port map(
            clk_i       => clk_i,
            reset_i     => '0',
            inc_i       => clk_slow_5ms,
            value_o     => open,
            cycle_o     => clk_slow_20ms
        );
    divider_100ms_inst : entity work.CounterModN(Behavioral)
       generic map(
            N => 5
        )
        port map(
            clk_i       => clk_i,
            reset_i     => '0',
            inc_i       => clk_slow_20ms,
            value_o     => open,
            cycle_o     => clk_slow_100ms
        );
     divider_1s_inst : entity work.CounterModN(Behavioral)
       generic map(
            N => 10
        )
        port map(
            clk_i       => clk_i,
            reset_i     => btn_center_i,
            inc_i       => clk_slow_100ms,
            value_o     => open,
            cycle_o     => clk_slow_1s
        );

-------------------------------------------------------------------
-- Implémentation des anti-rebonds :
-------------------------------------------------------------------
    btn_left_detec : entity work.EventDetector(Simple)
    generic map(
        DURATION        => DURATION
    )
    port map(
        clk_i           => clk_i,
        src_i           => btn_left_i,
        on_evt_o        => btn_left_s,
        off_evt_o       => open,
        status_o        => open
    );
    
    btn_right_detec : entity work.EventDetector(Simple)
    generic map(
        DURATION        => DURATION
    )
    port map(
        clk_i           => clk_i,
        src_i           => btn_right_i,
        on_evt_o        => btn_right_s,
        off_evt_o       => open,
        status_o        => open
    );
    
    btn_center_detec : entity work.EventDetector(Simple)
    generic map(
        DURATION        => DURATION
    )
    port map(
        clk_i           => clk_i,
        src_i           => btn_center_i,
        on_evt_o        => btn_center_s,
        off_evt_o       => open,
        status_o        => open
    );

-------------------------------------------------------------------
-- Process principal :
-------------------------------------------------------------------
    p_fonctionnement_micro_ondes : process(clk_i)
    begin
        if rising_edge(clk_i) then

            ----------------------------------------------------------------
            --        GESTION PORTE FERMÉE / PAUSE (switches_i(15))       --
            ----------------------------------------------------------------
            if switches_i(15) = '0' then
                porte_fermee <= '0';
                pause <= '1';
            else
                porte_fermee <= '1';
            end if;

            ----------------------------------------------------------------
            --              BOUTON START/STOP (btn_center_i)              --
            ----------------------------------------------------------------
            if btn_center_s = '1' then
                if fonctionnement = '1' then
                    -- Charlie, on pause tout ça !
                    fonctionnement <= '0';
                    pause <= '1';
                else
                    -- Charlie, on remet tout en route !
                    fonctionnement <= '1';
                    pause <= '0';
                end if;
            end if;

            ----------------------------------------------------------------
            --       CONFIGURATION CHRONO (btn_left_i, btn_right_i)       --
            ----------------------------------------------------------------
            if btn_left_s = '1' then
                if secondes > 29 then
                    secondes <= secondes - 30; -- minimum atteignable de 0s
                end if;
            elsif btn_right_s = '1' then
                if secondes < 5970 then
                    secondes <= secondes + 30; -- maximum atteignable de 99m59s
                end if;
            end if;

            if clk_slow_1s = '1' then
                ----------------------------------------------------------------
                --                FONCTIONNEMENT MICRO-ONDES                  --
                ----------------------------------------------------------------
                    if fonctionnement = '1' and pause = '0' and porte_fermee = '1' then
                        if secondes > 0 then
                            magnetron <= '1';
                            secondes  <= secondes - 1;
                        else
                            magnetron <= '0';
                        end if;
                    else
                        magnetron <= '0';
                    end if;

                ----------------------------------------------------------------
                --                           BUZZER                           --
                ----------------------------------------------------------------
                    if fonctionnement = '1' and secondes = 0 then
                        buzzer_actif    <= '1';
                        fonctionnement  <='0';
                    elsif buzzer_actif = '1' and compteur_buzzer < 3 then
                        compteur_buzzer <= compteur_buzzer + 1;
                    else
                        buzzer_actif    <='0';
                        compteur_buzzer <= 0;
                    end if;
            end if;

            ----------------------------------------------------------------
            --      CONVERSION SECONDES -> 4 QUARTETS -> AFFICHEUR        --
            ----------------------------------------------------------------
            minute          <= secondes / 60;
            seconde         <= secondes - (minute * 60);
            
            dizaine_seconde <= seconde / 10; --* 204 / 2048;
            unite_seconde   <= seconde - (dizaine_seconde * 10);
            
            dizaine_minute  <= minute / 10;
            unite_minute    <= minute - (dizaine_minute * 10);

        end if;
    end process p_fonctionnement_micro_ondes;

-------------------------------------------------------------------
--                 CADENÇAGE CHOIX AFFICHEUR MUX                 --
-------------------------------------------------------------------
    process(clk_i)
    begin
        if rising_edge(clk_slow_20ms) then
            if digit_index = 3 then
                digit_index <= 0;
            else
                digit_index <= digit_index + 1;
            end if;
        end if;
    end process;

-------------------------------------------------------------------
--                      MUX POUR AFFICHEUR                       --
-------------------------------------------------------------------
    -- Sélection de la valeur à afficher :
    with digit_index select
        valeur_afficheur <= unite_seconde   when 0,
                            dizaine_seconde when 1,
                            unite_minute    when 2,
                            dizaine_minute  when 3;

    ---------------------------------------------------------------------------
    -- Activation des afficheurs (active bas)
    process(digit_index)
    begin
        case digit_index is
            when 0 => disp_select_n_o <= "1110"; 
            when 1 => disp_select_n_o <= "1101";
            when 2 => disp_select_n_o <= "1011";
            when 3 => disp_select_n_o <= "0111";

            when others => disp_select_n_o <= "1111"; -- Désactive tous les afficheurs
        end case;
    end process;


-------------------------------------------------------------------
-- Implémentation de l'afficheur 7 segments :
-------------------------------------------------------------------
    decoder_inst : entity work.SegmentDecoder(TruthTable)
        port map(
            digit_i    => valeur_afficheur,
            segments_o => segments
        );

    end Structural;
