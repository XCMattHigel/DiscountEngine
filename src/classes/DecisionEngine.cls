public class DecisionEngine {

    class Decision {

        public String operator { get; set; }
        public Object iValue { get; set; }
        public Object eValue { get; set; }
        public Object hValue { get; set; }
        public Object lValue { get; set; }

        Decision(Decision__c d, Map<String, Object> objMap) {
            Decision__c decision = d;
            operator = decision.Operator__c;
            if(operator.startsWith('Contains')) {
                String iValueString = String.valueOf(objMap.get(d.Element__c));
                iValue = (Object) new Set<String>(iValueString.split(';'));
                String eValueString = String.valueOf(objMap.get(d.Element__c));
                if(eValueString.contains(';')) {
                    eValue = (Object) new Set<String>(eValueString.split(';'));
                } else {
                    eValue = decision.Value__c;
                }
            } else {
                iValue = objMap.get(d.Element__c);
                eValue = decision.Value__c;
            }
            hValue = decision.High_Value__c;
            lValue = decision.Low_Value__c;
        }
    }

    public static Boolean eval(Decision__c decision, Map<String, Object> objMap) {
        Decision d = new Decision(decision, objMap);

        Boolean isMatched = false;

        if (d.operator == 'Equal to') {
            isMatched = isEqualTo(d.iValue, d.eValue);
        } else if (d.operator == 'Not equal to') {
            isMatched = !isEqualTo(d.iValue, d.eValue);
        } else if (d.operator == 'Greater than') {
            isMatched = isGreaterThan(d.iValue, d.eValue);
        } else if (d.operator == 'Greater than or Equal to') {
            isMatched = isGreaterThanOrEqualTo(d.iValue, d.eValue);
        } else if (d.operator == 'Less than') {
            isMatched = isLessThan(d.iValue, d.eValue);
        } else if (d.operator == 'Less than or Equal to') {
            isMatched = isLessThanOrEqualTo(d.iValue, d.eValue);
        } else if (d.operator == 'Between') {
            isMatched = isBetween(d.iValue, d.hValue, d.lValue);
        } else if (d.operator == 'Contains') {
            isMatched = contains((Set<Object>)d.iValue, d.eValue);
        } else if (d.operator == 'Contains any') {
            isMatched = containsAny((Set<Object>)d.iValue, (List<Object>)d.eValue);
        } else if(d.operator == 'Contains all') {
            isMatched = containsAll((Set<Object>)d.iValue, (List<Object>)d.eValue);
        } else if(d.operator == 'Contains none') {
            isMatched = containsNone((Set<Object>)d.iValue, (List<Object>)d.eValue);
        } else {
            throw new EvaluationException();
        }

        if(isMatched && !decision.Child_Decisions__r.isEmpty()) {
            for(Decision__c cd : decision.Child_Decisions__r) {
                isMatched = DecisionEngine.eval(cd, objMap);
            }
        }

        return isMatched;
    }

    static Boolean isEqualTo(Object a, Object b) {
        return String.valueOf(a).equalsIgnoreCase(String.valueOf(b));
    }

    static Boolean isGreaterThan(Object a, Object b) {
        if (a instanceof Date) {
            return Date.valueOf(a) > Date.valueOf(b);
        } else if (a instanceof Datetime) {
            return Datetime.valueOf(a) > Datetime.valueOf(b);
        }
        return Double.valueOf(a) > Double.valueOf(b);
    }

    static Boolean isGreaterThanOrEqualTo(Object a, Object b) {
        if (a instanceof Date) {
            return Date.valueOf(a) > Date.valueOf(b);
        } else if (a instanceof Datetime) {
            return Datetime.valueOf(a) >= Datetime.valueOf(b);
        }
        return Double.valueOf(a) >= Double.valueOf(b);
    }

    static Boolean isLessThan(Object a, Object b) {
        if (a instanceof Date) {
            return Date.valueOf(a) > Date.valueOf(b);
        } else if (a instanceof Datetime) {
            return Datetime.valueOf(a) < Datetime.valueOf(b);
        }
        return Double.valueOf(a) < Double.valueOf(b);
    }

    static Boolean isLessThanOrEqualTo(Object a, Object b) {
        if (a instanceof Date) {
            return Date.valueOf(a) > Date.valueOf(b);
        } else if (a instanceof Datetime) {
            return Datetime.valueOf(a) <= Datetime.valueOf(b);
        }
        return Double.valueOf(a) <= Double.valueOf(b);
    }

    static Boolean isBetween(Object a, Object high, Object low) {
        if (a instanceof Date) {
            return Date.valueOf(a) <= Date.valueOf(high) && Date.valueOf(a) >= Date.valueOf(low);
        } else if (a instanceof Datetime) {
            return Datetime.valueOf(a) <= Datetime.valueOf(high) && Datetime.valueOf(a) >= Datetime.valueOf(low);
        }
        return Double.valueOf(a) <= Double.valueOf(high) && Double.valueOf(a) >= Double.valueOf(low);
    }

    static Boolean contains(Set<Object> a, Object b) {
        return a.contains(b);
    }

    static Boolean containsAny(Set<Object> a, List<Object> b) {
        return a.removeAll(b);
    }

    static Boolean containsAll(Set<Object> a, List<Object> b) {
        return a.containsAll(b);
    }


    static Boolean containsNone(Set<Object> a, List<Object> b) {
        return !containsAll(a, b);
    }


    class EvaluationException extends Exception {}
}