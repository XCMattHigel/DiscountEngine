public class TriggerUtility {

    public static List<SObject> getDiffSObjectList(String newObjJson, String oldObjJson, String field) {
        Map<Id, Sobject> newMap = (Map<Id, Sobject>)JSON.deserialize(newObjJson, Map<Id, SObject>.class);
        Map<Id, Sobject> oldMap = (Map<Id, Sobject>)JSON.deserialize(oldObjJson, Map<Id, SObject>.class);
        List<SObject> diffSObjectList = new List<SObject>();
        for (Id sId : newMap.keySet()) {
            SObject newObj = newMap.get(sId);
            SObject oldObj = oldMap.get(sId);

            Object newVal = newObj.get(field);
            Object oldVal = oldObj.get(field);

            if(newVal != oldVal) {
                diffSObjectList.add(newObj);
            }
        }

        return diffSObjectList;
    }
}