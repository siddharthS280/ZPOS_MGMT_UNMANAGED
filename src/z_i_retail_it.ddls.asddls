@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Retail POS Items'
@Metadata.ignorePropagatedAnnotations: true
@Metadata.allowExtensions: true  // This allows the MDE below to work
define view entity Z_I_Retail_IT
  as select from zretail_it
  association to parent Z_I_Retail_HD as _Header on $projection.ParentUUID = _Header.TransactionUUID
{
  key parent_uuid     as ParentUUID,
  key line_item_id    as LineItemID,
      material_id     as MaterialID,
      
      @Semantics.quantity.unitOfMeasure: 'Unit'
      sale_quantity   as SaleQuantity,
      unit            as Unit,
      
      @Semantics.amount.currencyCode: 'Currency'
      net_price       as NetPrice,
      
      /* Exposing Currency from Parent for UI consistency */
      _Header.Currency as Currency,
      
      _Header
}
