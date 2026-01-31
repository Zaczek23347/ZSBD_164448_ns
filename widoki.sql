
  CREATE OR REPLACE FORCE EDITIONABLE VIEW "INF2NS_ZACZEKK"."GET_MASTERDATA" ("SUPPLIER_NUMBER", "INVOICE_NUMBER", "SUPPLIERNAME", "SUPPLIERADDRESS1", "SUPPLIERADDRESS2", "COUNTRYCODE", "POSTALCODE") AS 
  Select 
t.supplier_number
,t.invoice_number
,md.suppliername
,md.supplieraddress1
,md.supplieraddress2
,md.countrycode
,md.postalcode
from invoices t
left join Master_data md on t.supplier_number = md.suppliernumber;



  CREATE OR REPLACE FORCE EDITIONABLE VIEW "INF2NS_ZACZEKK"."V_FAKTURY_XML" ("ID_FAKTURY_XML", "NAZWA_PLIKU", "DATA_ZALADUNKU", "SUPPLIER_NAME", "SUPPLIER_NUMBER", "NIP", "ADDRESS1", "ADDRESS2", "POSTAL_CODE", "COUNTRY_CODE", "NET_VALUE_TXT", "VAT_VALUE_TXT", "INVOICE_NUMBER", "INVOICE_DATE_TXT", "BRANCH", "RESP_CENTER", "VIN", "DOC_PATH") AS 
  SELECT
    f.id_faktury_xml,
    f.nazwa_pliku,
    f.data_zaladunku,

    x.supplier_name,
    x.supplier_number,
    x.nip,
    x.address1,
    x.address2,
    x.postal_code,
    x.country_code,

    x.net_value_txt,
    x.vat_value_txt,
    x.invoice_number,
    x.invoice_date_txt,
    x.branch,
    x.resp_center,
    x.vin,
    x.doc_path

FROM faktury_xml f,
     XMLTABLE(
       '/root'
       PASSING f.xml_dokument
       COLUMNS
         supplier_name     VARCHAR2(200) PATH 'Supplier/@SupplierName',
         supplier_number   VARCHAR2(50)  PATH 'Supplier/@SupplierNumber',
         nip               VARCHAR2(50)  PATH 'Supplier/@NIP',
         address1          VARCHAR2(200) PATH 'Supplier/@Addres1',
         address2          VARCHAR2(200) PATH 'Supplier/@Addres2',
         postal_code       VARCHAR2(20)  PATH 'Supplier/@PostalCode',
         country_code      VARCHAR2(10)  PATH 'Supplier/@CountryCode',

         net_value_txt     VARCHAR2(50)  PATH 'NetValue',
         vat_value_txt     VARCHAR2(50)  PATH 'VatValue',
         invoice_number    VARCHAR2(50)  PATH 'InvoiceNumber',
         invoice_date_txt  VARCHAR2(20)  PATH 'InvoiceDate',
         branch            VARCHAR2(20)  PATH 'Branch',
         resp_center       VARCHAR2(20)  PATH 'RespCenter',
         vin               VARCHAR2(50)  PATH 'VIN',
         doc_path          VARCHAR2(400) PATH 'DocPath'
     ) x where f.STATUS_PRZETW = 0;

