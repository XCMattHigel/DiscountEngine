@isTest
public class DiscountEngineTest {

    @testSetup
    static void setup() {
        ccrz__E_Product__C product = new ccrz__E_Product__c(
                Name = 'DiscountEngineTest',
                ccrz__SKU__c = 'DiscountEngineTest'
        );
        insert product;

        ccrz__E_Cart__c cart = new ccrz__E_Cart__c(
                ccrz__ShipAmount__c = 20.00,
                ccrz__AdjustmentAmount__c = 0.00
        );
        insert cart;

        ccrz__E_CartItem__c cartItem = new ccrz__E_CartItem__c(
                ccrz__Cart__c = cart.Id,
                ccrz__Product__c = product.Id,
                ccrz__Quantity__c = 1,
                ccrz__Price__c = 10.00
        );
        insert cartItem;

        List<ccrz__E_Coupon__c> couponList = new List<ccrz__E_Coupon__c>();
        ccrz__E_Coupon__c shippingCoupon = new ccrz__E_Coupon__c(
                ccrz__CouponCode__c = 'SDiscountEngineTest',
                ccrz__CouponName__c = 'SDiscountEngineTest',
                ccrz__RuleType__c = 'Shipping',
                ccrz__DiscountType__c = 'Price',
                ccrz__CouponType__c = 'Price',
                ccrz__DiscountAmount__c = 2.00,
                ccrz__MaxUse__c = 99,
                ccrz__TotalUsed__c = 0,
                ccrz__TargetProduct__c = product.Id
        );
        insert shippingCoupon;
        couponList.add(shippingCoupon);

        ccrz__E_Coupon__c generalCoupon = new ccrz__E_Coupon__c(
                ccrz__RuleType__c = 'General',
                ccrz__CouponCode__c = 'GDiscountEngineTest',
                ccrz__CouponName__c = 'GDiscountEngineTest',
                ccrz__DiscountType__c = 'Percentage',
                ccrz__CouponType__c = 'Percentage',
                ccrz__DiscountAmount__c = 20.00,
                ccrz__MaxUse__c = 99,
                ccrz__TotalUsed__c = 0,
                ccrz__TargetProduct__c = product.Id
        );
        insert generalCoupon;

        couponList.add(generalCoupon);

        ccrz__E_Coupon__c cartTotalCoupon = new ccrz__E_Coupon__c(
                ccrz__RuleType__c = 'CartTotal',
                ccrz__CouponCode__c = 'CTDiscountEngineTest',
                ccrz__CouponName__c = 'CTDiscountEngineTest',
                ccrz__CartTotalAmount__c = 2.00,
                ccrz__DiscountType__c = 'Absolute',
                ccrz__CouponType__c = 'Absolute',
                ccrz__MaxUse__c = 99,
                ccrz__TotalUsed__c = 0,
                ccrz__TargetProduct__c = product.Id
        );
        insert cartTotalCoupon;

        couponList.add(cartTotalCoupon);

        for (ccrz__E_Coupon__c c : couponList) {
            c.ccrz__MaxUse__c = 99;
            c.ccrz__TotalUsed__c = 0;
            c.ccrz__TargetProduct__c = product.Id;
        }

//        insert couponList;

        RecordType discountRt = [SELECT Id FROM RecordType WHERE SobjectType = 'Decision__c' AND Name = 'Discount Rule' LIMIT 1];

        Decision__c parentDecision = new Decision__c(
                Element__c = 'ccrz__Product__r.ccrz__SKU__c',
                Operator__c = 'Equal to',
                Value__c = 'DiscountEngineTest',
                Consequent__c = shippingCoupon.ccrz__CouponCode__c,
                RecordTypeId = discountRt.Id
        );
        insert parentDecision;

        List<Decision__c> decisionList = new List<Decision__c>();
        decisionList.add(new Decision__c(
                Element__c = 'ccrz__Quantity__c',
                Operator__c = 'Equal to',
                Value__c = '1',
                Consequent__c = generalCoupon.ccrz__CouponCode__c,
                RecordTypeId = discountRt.Id,
                Parent_Decision__c = parentDecision.Id
        ));

        decisionList.add(new Decision__c(
                Element__c = 'ccrz__Quantity__c',
                Operator__c = 'Equal to',
                Value__c = '1',
                Consequent__c = cartTotalCoupon.ccrz__CouponCode__c,
                RecordTypeId = discountRt.Id,
                Parent_Decision__c = parentDecision.Id
        ));

        insert decisionList;
    }

    @isTest
    static void testGetExistingDiscounts() {
        Test.startTest();
        ccrz__E_Coupon__c coupon = [SELECT Id, ccrz__CouponCode__c FROM ccrz__E_Coupon__c LIMIT 1];
        ccrz__E_CartItem__c cartItem = [SELECT Id FROM ccrz__E_CartItem__c LIMIT 1];

        Cart_Item_Discount__c discount = new Cart_Item_Discount__c(
                CC_Coupon__c = coupon.Id,
                CC_Cart_Item__c = cartItem.Id
        );
        insert discount;

        ccrz__E_Cart__c cart = [
                SELECT Id, ccrz__ShipAmount__c, ccrz__AdjustmentAmount__c
                FROM ccrz__E_Cart__c
                LIMIT 1
        ];

        DiscountEngine de = new DiscountEngine(cart);

        System.assert(de.existingDiscountSet.contains(coupon.Id + '-' + cartItem.Id));

        Test.stopTest();
    }

    @isTest
    static void testGetApplicableDiscounts() {
        Test.startTest();

        ccrz__E_Cart__c cart = [
                SELECT Id, ccrz__ShipAmount__c, ccrz__AdjustmentAmount__c
                FROM ccrz__E_Cart__c
                LIMIT 1
        ];

        DiscountEngine de = new DiscountEngine(cart);

        List<Cart_Item_Discount__c> discountList = de.getApplicableDiscounts();
        System.assertEquals(3, discountList.size());

        Test.stopTest();
    }

    @isTest
    static void testApplyDiscounts() {
        Test.startTest();

        ccrz__E_Cart__c cart = [
                SELECT Id, ccrz__ShipAmount__c, ccrz__AdjustmentAmount__c
                FROM ccrz__E_Cart__c
                LIMIT 1
        ];

        DiscountEngine de = new DiscountEngine(cart);

        List<ccrz__E_CartItem__c> cartItemList = de.applyDiscounts();

        Test.stopTest();
    }
}