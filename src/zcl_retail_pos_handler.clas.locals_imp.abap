CLASS lcl_buffer DEFINITION.
  PUBLIC SECTION.
    CLASS-DATA: mt_header TYPE STANDARD TABLE OF zretail_hd WITH EMPTY KEY,
                mt_item   TYPE STANDARD TABLE OF zretail_it WITH EMPTY KEY.
ENDCLASS.

CLASS lhc_POSHeader DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR POSHeader RESULT result.
    METHODS create FOR MODIFY
      IMPORTING entities FOR CREATE POSHeader.
    METHODS update FOR MODIFY
      IMPORTING entities FOR UPDATE POSHeader.
    METHODS delete FOR MODIFY
      IMPORTING keys FOR DELETE POSHeader.
    METHODS read FOR READ
      IMPORTING keys FOR READ POSHeader RESULT result.
    METHODS lock FOR LOCK
      IMPORTING keys FOR LOCK POSHeader.
    METHODS rba_Items FOR READ
      IMPORTING keys_rba FOR READ POSHeader\_Items FULL result_requested RESULT result LINK association_links.
    METHODS cba_Items FOR MODIFY
      IMPORTING entities_cba FOR CREATE POSHeader\_Items.
ENDCLASS.

CLASS lhc_POSHeader IMPLEMENTATION.

  METHOD get_instance_authorizations.
    " Implementation not required for basic setup
  ENDMETHOD.

  METHOD create.
    LOOP AT entities ASSIGNING FIELD-SYMBOL(<ls_entity>).
      DATA(lv_uuid) = cl_system_uuid=>create_uuid_x16_static( ).

      APPEND VALUE #(
        transaction_uuid = lv_uuid
        receipt_id       = <ls_entity>-ReceiptID
        store_id         = <ls_entity>-StoreID
        trans_date       = cl_abap_context_info=>get_system_date( )
        trans_time       = cl_abap_context_info=>get_system_time( )
        currency         = <ls_entity>-Currency
        gross_amount     = <ls_entity>-GrossAmount
      ) TO lcl_buffer=>mt_header.

      INSERT VALUE #( %cid = <ls_entity>-%cid TransactionUUID = lv_uuid ) INTO TABLE mapped-posheader.
    ENDLOOP.
  ENDMETHOD.

  METHOD update.
    " For unmanaged, you would update lcl_buffer=>mt_header here
  ENDMETHOD.

  METHOD delete.
    " For unmanaged, you would mark records for deletion here
  ENDMETHOD.

  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM zretail_hd FOR ALL ENTRIES IN @keys
        WHERE transaction_uuid = @keys-TransactionUUID
        INTO CORRESPONDING FIELDS OF TABLE @result.
    ENDIF.
  ENDMETHOD.

  METHOD lock.
    " Locking logic (Enqueue) goes here
  ENDMETHOD.

  METHOD rba_Items.
    IF keys_rba IS NOT INITIAL.
      " Select data to fill association_links
      SELECT parent_uuid AS TransactionUUID,
             parent_uuid AS ParentUUID,
             line_item_id AS LineItemID
        FROM zretail_it
        FOR ALL ENTRIES IN @keys_rba
        WHERE parent_uuid = @keys_rba-TransactionUUID
        INTO TABLE @DATA(lt_links).

      LOOP AT lt_links ASSIGNING FIELD-SYMBOL(<ls_link>).
        APPEND VALUE #(
            source-TransactionUUID = <ls_link>-TransactionUUID
            target-ParentUUID      = <ls_link>-ParentUUID
            target-LineItemID      = <ls_link>-LineItemID
        ) TO association_links.
      ENDLOOP.

      IF result_requested = abap_true.
        SELECT * FROM zretail_it
          FOR ALL ENTRIES IN @keys_rba
          WHERE parent_uuid = @keys_rba-TransactionUUID
          INTO CORRESPONDING FIELDS OF TABLE @result.
      ENDIF.
    ENDIF.
  ENDMETHOD.

  METHOD cba_Items.
    LOOP AT entities_cba ASSIGNING FIELD-SYMBOL(<ls_cba>).
      LOOP AT <ls_cba>-%target ASSIGNING FIELD-SYMBOL(<ls_item_in>).
        APPEND VALUE #(
          parent_uuid   = <ls_cba>-TransactionUUID
          line_item_id  = <ls_item_in>-LineItemID
          material_id   = <ls_item_in>-MaterialID
          sale_quantity = <ls_item_in>-SaleQuantity
          unit          = <ls_item_in>-Unit
          net_price     = <ls_item_in>-NetPrice
        ) TO lcl_buffer=>mt_item.

        INSERT VALUE #( %cid = <ls_item_in>-%cid
                        ParentUUID = <ls_cba>-TransactionUUID
                        LineItemID = <ls_item_in>-LineItemID ) INTO TABLE mapped-positem.
      ENDLOOP.
    ENDLOOP.
  ENDMETHOD.
ENDCLASS.

CLASS lhc_POSItem DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS update FOR MODIFY IMPORTING entities FOR UPDATE POSItem.
    METHODS delete FOR MODIFY IMPORTING keys FOR DELETE POSItem.
    METHODS read FOR READ IMPORTING keys FOR READ POSItem RESULT result.
ENDCLASS.

CLASS lhc_POSItem IMPLEMENTATION.
  METHOD update. ENDMETHOD.
  METHOD delete. ENDMETHOD.
  METHOD read.
    IF keys IS NOT INITIAL.
      SELECT * FROM zretail_it FOR ALL ENTRIES IN @keys
        WHERE parent_uuid = @keys-ParentUUID AND line_item_id = @keys-LineItemID
        INTO CORRESPONDING FIELDS OF TABLE @result.
    ENDIF.
  ENDMETHOD.
ENDCLASS.

CLASS lsc_saver DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.
    METHODS save REDEFINITION.
    METHODS cleanup REDEFINITION.
ENDCLASS.

CLASS lsc_saver IMPLEMENTATION.
  METHOD save.
    IF lcl_buffer=>mt_header IS NOT INITIAL.
      INSERT zretail_hd FROM TABLE @lcl_buffer=>mt_header.
    ENDIF.
    IF lcl_buffer=>mt_item IS NOT INITIAL.
      INSERT zretail_it FROM TABLE @lcl_buffer=>mt_item.
    ENDIF.
  ENDMETHOD.

  METHOD cleanup.
    FREE: lcl_buffer=>mt_header, lcl_buffer=>mt_item.
  ENDMETHOD.
ENDCLASS.
