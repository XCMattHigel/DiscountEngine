
global class ccCart extends ccrz.cc_api_CartExtension {

    global virtual override Map<String, Object> preprocess(Map<String, Object> inputData) {
        inputData = super.preprocess(inputData);

        List<ccrz__E_CartItem__c> cartItemList =
                (List<ccrz__E_CartItem__c>) inputData.get(ccrz.cc_api_CartExtension.PARAM_CARTITEMS);
        DiscountEngine de = new DiscountEngine(cartItemList);
        cartItemList = de.applyDiscounts();

        return new Map<String, Object>{
                ccrz.cc_api_CartExtension.PARAM_CARTITEMS => cartItemList
        };
    }
}