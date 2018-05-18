trigger AccountTrigger on Account (after update) {

    if(Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.onAfterUpdate(Trigger.newMap, Trigger.oldMap);
    }
}