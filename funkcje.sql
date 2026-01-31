create or replace FUNCTION calculate_gross(
    p_net_value IN float,
    p_vat_code  IN VARCHAR2
) RETURN float IS
    v_vat_rate float;
BEGIN

    v_vat_rate := CASE p_vat_code
        WHEN '23' THEN 0.23
        WHEN '8'  THEN 0.08
        WHEN '0'  THEN 0.00
        ELSE 0.00 
    END;


    RETURN ROUND(p_net_value * (1 + v_vat_rate), 2);
END;