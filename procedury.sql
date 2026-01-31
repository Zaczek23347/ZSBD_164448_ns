create or replace PROCEDURE AssignSuppliersDetails IS
BEGIN
  FOR r IN (SELECT * FROM get_masterdata) LOOP
    UPDATE invoices t
    SET t.supplier_name = r.suppliername,
        t.address1      = r.supplieraddress1,
        t.address2      = r.supplieraddress2,
        t.country_code      = r.countrycode,
        t.postal_code   = r.postalcode
    WHERE t.supplier_number = r.supplier_number 
      AND t.invoice_number = r.invoice_number;
  END LOOP;

  COMMIT;
END;






create or replace PROCEDURE write_faktury_xml IS
BEGIN
    
 -- załadowanie faktur
  FOR r IN (
    SELECT *
    FROM v_faktury_xml
    WHERE id_faktury_xml IN (
        SELECT id_faktury_xml
        FROM faktury_xml
        WHERE status_przetw = '0'
    )
  ) LOOP
    BEGIN
      INSERT INTO invoices (
        id_faktury_xml,
        nazwa_pliku,
        data_zaladunku,
        supplier_name,
        supplier_number,
        nip,
        address1,
        address2,
        postal_code,
        country_code,
        net_value_txt,
        vat_value_txt,
        invoice_number,
        branch,
        resp_center,
        vin,
        doc_path,
        invoice_date,
        gross_value
      )
      VALUES (
        r.id_faktury_xml,
        r.nazwa_pliku,
        r.data_zaladunku,
        r.supplier_name,
        substr(r.supplier_number,-4),
        r.nip,
        r.address1,
        r.address2,
        r.postal_code,
        r.country_code,
        TO_NUMBER(REPLACE(r.net_value_txt, ',', '.'), '99999999.99'),
        r.vat_value_txt,
        r.invoice_number,
        r.branch,
        r.resp_center,
        r.vin,
        r.doc_path,
        cast(r.invoice_date_txt as date),
        null
      );

      UPDATE faktury_xml
      SET status_przetw = '1'
      WHERE id_faktury_xml = r.id_faktury_xml;

    END;
  END LOOP;
  
 -- usuwanie duplikatów
 
    DELETE FROM invoices f
    where EXISTS (
      SELECT 1 
      FROM processed_invoices p 
      WHERE p.invoice_number = f.invoice_number 
        AND p.id_faktury_xml = f.id_faktury_xml 
    );
    
    DELETE FROM invoices f
    where EXISTS (
      SELECT 1 
      FROM error_invoices p 
      WHERE p.invoice_number = f.invoice_number 
        AND p.id_faktury_xml = f.id_faktury_xml 
    );
  
  
  -- usuwawnie błednie wygenerowanych faktur
  FOR r IN (
    SELECT *
    FROM invoices
    WHERE (net_value_txt is NULL OR net_value_txt = 0) OR (supplier_number is NULL OR TRIM(supplier_number) = '')
  ) LOOP
    BEGIN
    
    INSERT INTO error_invoices (
        id_faktury_xml,
        nazwa_pliku,
        data_zaladunku,
        supplier_name,
        supplier_number,
        nip,
        address1,
        address2,
        postal_code,
        country_code,
        net_value_txt,
        vat_value_txt,
        invoice_number,
        branch,
        resp_center,
        vin,
        doc_path,
        invoice_date
      )
      VALUES (
        r.id_faktury_xml,
        r.nazwa_pliku,
        r.data_zaladunku,
        r.supplier_name,
        r.supplier_number,
        r.nip,
        r.address1,
        r.address2,
        r.postal_code,
        r.country_code,
        r.net_value_txt,
        r.vat_value_txt,
        r.invoice_number,
        r.branch,
        r.resp_center,
        r.vin,
        r.doc_path,
        r.invoice_date
      );

    END;
  END LOOP;

-- wyliczanie kwoty brutto
    UPDATE invoices
    SET gross_value = calculate_gross(net_value_txt, vat_value_txt);
    
 -- wypelnienie pustych pol branch i rc
    UPDATE invoices
    SET branch = coalesce(branch,'999'),
    resp_center = coalesce(resp_center,'901');

-- wypelnienie danych dostawcow z bazy
    assignsuppliersdetails();


-- Archiwizacja przetworzonych faktur
    FOR r IN (
    SELECT *
    FROM invoices
  ) LOOP
    BEGIN
    
    INSERT INTO processed_invoices (
        id_faktury_xml,
        nazwa_pliku,
        data_zaladunku,
        supplier_name,
        supplier_number,
        nip,
        address1,
        address2,
        postal_code,
        country_code,
        net_value_txt,
        vat_value_txt,
        invoice_number,
        branch,
        resp_center,
        vin,
        doc_path,
        invoice_date,
        gross_value
      )
      VALUES (
        r.id_faktury_xml,
        r.nazwa_pliku,
        r.data_zaladunku,
        r.supplier_name,
        r.supplier_number,
        r.nip,
        r.address1,
        r.address2,
        r.postal_code,
        r.country_code,
        r.net_value_txt,
        r.vat_value_txt,
        r.invoice_number,
        r.branch,
        r.resp_center,
        r.vin,
        r.doc_path,
        r.invoice_date,
        r.gross_value
      );

    END;
  END LOOP;


  COMMIT;
END;