@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Retail POS Header'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true
define root view entity Z_I_Retail_HD
  as select from zretail_hd
  composition [0..*] of Z_I_Retail_IT as _Items
{
  key transaction_uuid      as TransactionUUID,
      receipt_id            as ReceiptID,
      store_id              as StoreID,
      trans_date            as TransDate,
      trans_time            as TransTime,
      @Semantics.amount.currencyCode: 'Currency'
      gross_amount          as GrossAmount,
      currency              as Currency,
      local_last_changed_at as LocalLastChangedAt,
      
      _Items 
}
