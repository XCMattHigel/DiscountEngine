
public class DiscountEngine {

    ccrz__E_Cart__c cart { get; set; }
    Map<Id, ccrz__E_CartItem__c> cartItemMap { get; set; }
    Map<String, ccrz__E_Coupon__c> couponByCodeMap { get; set; }
    Integer lineItemCount { get; set; }
    List<Cart_Item_Discount__c> discountList { get; set; }
    public Set<String> existingDiscountSet { get; set; }
    Map<Id, ccrz__E_Coupon__c> couponMap { get; set; }
//    Map<String, >

    public DiscountEngine(List<ccrz__E_CartItem__c> cartItemList) {
        Id cartId = cartItemList[0].ccrz__Cart__c;
        this.cart = [SELECT Id FROM ccrz__E_Cart__c WHERE Id = :cartId];

        cartItemMap = new Map<Id, ccrz__E_CartItem__c>(cartItemList);

        init();

        lineItemCount = cartItemMap.size();
    }

    public DiscountEngine(ccrz__E_Cart__c cart) {
        this.cart = cart;

        cartItemMap = new Map<Id, ccrz__E_CartItem__c>([
                SELECT Id, ccrz__Quantity__c, ccrz__Product__c, ccrz__Product__r.ccrz__SKU__c,
                        ccrz__Price__c, ccrz__PricingType__c, ccrz__AdjustmentAmount__c
                FROM ccrz__E_CartItem__c
                WHERE ccrz__Cart__c = :cart.Id
        ]);

        init();

        lineItemCount = cartItemMap.size();
    }

    void init() {
        couponByCodeMap = new Map<String, ccrz__E_Coupon__c>();

        existingDiscountSet = getExistingDiscounts();

        couponMap = new Map<Id, ccrz__E_Coupon__c>([
                SELECT Id, ccrz__RuleType__c, ccrz__DiscountType__c, ccrz__DiscountAmount__c,
                        ccrz__CartTotalAmount__c, ccrz__CouponCode__c
                FROM ccrz__E_Coupon__c
        ]);

        for (ccrz__E_Coupon__c c : couponMap.values()) {
            couponByCodeMap.put(c.ccrz__CouponCode__c, c);
        }
    }

    public Set<String> getExistingDiscounts() {
        Set<String> existingDiscountSet = new Set<String>();
        for (Cart_Item_Discount__c cid : [
                SELECT Id, CC_Coupon__r.ccrz__CouponCode__c, CC_Cart_Item__c
                FROM Cart_Item_Discount__c
                WHERE CC_Cart_Item__c IN :cartItemMap.keySet()
        ]) {
            existingDiscountSet.add(cid.CC_Coupon__r.ccrz__CouponCode__c + '-' + cid.CC_Cart_Item__c);
        }

        return existingDiscountSet;
    }

    public List<Cart_Item_Discount__c> getApplicableDiscounts() {
        System.debug('get applicable discounts');
        discountList = new List<Cart_Item_Discount__c>();
        Map<String, ccrz__E_CartItem__c> skuItemMap = getSkuValueMap();
        List<Decision__c> decisionList = [
                SELECT Id, Element__c, Operator__c, Value__c, High_Value__c, Low_Value__c, Consequent__c, (
                        SELECT Id, Element__c, Operator__c, Value__c, High_Value__c, Low_Value__c, Consequent__c
                        FROM Child_Decisions__r
                )
                FROM Decision__c
                WHERE RecordType.Name = 'Discount Rule'
        ];

        System.debug('decisionList size = ' + String.valueOf(decisionList.size()));

        Map<Id, Set<Id>> couponsByItemIdMap = new Map<Id, Set<Id>>();
        for (String sku : skuItemMap.keySet()) {
            System.debug('sku = ' + sku);
            ccrz__E_CartItem__c item = skuItemMap.get(sku);
            Map<String, Object> objMap = new Map<String, Object>();
            couponsByItemIdMap.put(item.Id, new Set<Id>());
            for (Decision__c d : decisionList) {
                System.debug('d.Consequent__c = ' + d.Consequent__c);

                if (String.isNotBlank(d.Consequent__c) && !existingDiscountSet.contains(d.Consequent__c + '-' + item.Id)) {
                    objMap.put('ccrz__Quantity__c', item.ccrz__Quantity__c);
                    objMap.put('ccrz__Product__c', item.ccrz__Product__c);
                    objMap.put('ccrz__Product__r.ccrz__SKU__c', item.ccrz__Product__r.ccrz__SKU__c);
                    objMap.put('ccrz__Price__c', item.ccrz__Price__c);
                    Boolean matched = DecisionEngine.eval(d, objMap);

                    Set<Id> couponSet = couponsByItemIdMap.get(item.Id);
                    ccrz__E_Coupon__c coupon = couponByCodeMap.get(d.Consequent__c);
                    if (matched && !couponSet.contains(coupon.Id)) {
                        couponSet.add(coupon.Id);
                        couponsByItemIdMap.put(item.Id, couponSet);
                    }
                }
            }
        }

        discountList = new List<Cart_Item_Discount__c>();
        for (Id itemId : couponsByItemIdMap.keySet()) {
            System.debug('itemId = ' + itemId);
            for (Id couponId : couponsByItemIdMap.get(itemId)) {
                System.debug('couponId = ' + couponId);
                Cart_Item_Discount__c cid = new Cart_Item_Discount__c(
                        CC_Cart_Item__c = itemId,
                        CC_Coupon__c = couponId
                );
                discountList.add(cid);
            }
        }

        return discountList;
    }

    public List<ccrz__E_CartItem__c> applyDiscounts() {
        System.debug('applyDiscounts');

        if (discountList == null) {
            System.debug('disounctList is null; getApplicableDiscounts');
            discountList = getApplicableDiscounts();
        }

        List<ccrz__E_CartItem__c> cartItemList = new List<ccrz__E_CartItem__c>();

        try {
            System.debug('insert discountList');
            insert discountList;

            for (Cart_Item_Discount__c cid : discountList) {
                System.debug('iterating discountList');
                ccrz__E_Coupon__c coupon = couponMap.get(cid.CC_Coupon__c);
                ccrz__E_CartItem__c item = cartItemMap.get(cid.CC_Cart_Item__c);

                Double discountAmount = coupon.ccrz__DiscountAmount__c < 0 ?
                        coupon.ccrz__DiscountAmount__c * -1 : coupon.ccrz__DiscountAmount__c;
                String discountType = coupon.ccrz__DiscountType__c;

                System.debug('coupon.ccrz__DiscountType__c = ' + coupon.ccrz__DiscountType__c);

                if (coupon.ccrz__RuleType__c.equalsIgnoreCase('General')) {
                    Double price = Double.valueOf(item.ccrz__Price__c);
                    item.ccrz__AdjustmentAmount__c = getPriceAdjustment(discountType, discountAmount, price);
                } else if (coupon.ccrz__RuleType__c.equalsIgnoreCase('Shipping')) {
                    Double price = Double.valueOf(cart.ccrz__ShipAmount__c);
                    cart.ccrz__AdjustmentAmount__c = getPriceAdjustment(discountType, discountAmount, price);
                } else if (coupon.ccrz__RuleType__c.equalsIgnoreCase('CartTotal')) {
                    Double cartTotal = Double.valueOf(cart.ccrz__TotalAmount__c);
                    discountAmount = Double.valueOf(coupon.ccrz__CartTotalAmount__c);
                    cart.ccrz__AdjustmentAmount__c = getPriceAdjustment(discountType, discountAmount, cartTotal);
                }
                item.ccrz__PricingType__c = 'external';
            }

            for(Id cId : cartItemMap.keySet()) {
                System.debug('cId = ' + cId);
                ccrz__E_CartItem__c item = cartItemMap.get(cid);
                cartItemList.add(item);
            }

            update cart;
            update cartItemList;
        } catch (Exception e) {
            System.debug('Exception caught while applying discounts to Cart Items: ' + e.getMessage());
        }

        System.debug('return cartItemList');
        return cartItemList;
    }

    public Map<String, ccrz__E_CartItem__c> getSkuValueMap() {
        Map<String, ccrz__E_CartItem__c> skuItemMap = new Map<String, ccrz__E_CartItem__c>();

        for (ccrz__E_CartItem__c item : cartItemMap.values()) {
            skuItemMap.put(item.ccrz__Product__r.ccrz__SKU__c, item);
        }

        return skuItemMap;
    }

    private Double getPriceAdjustment(String discountType, Double discountAmount, Double price) {
        Double adjustment = 0.0;
        if (discountType == 'Percentage') {
            adjustment = -1 * price * (1 - (discountAmount / 100));
        } else if (discountType == 'Absolute') {
            adjustment = -1 * discountAmount;
        } else {
            adjustment = discountAmount - price;
        }

        return adjustment;
    }
}