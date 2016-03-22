/** Author : Ravi Dutt Sharma
*  Created Date : 3/18/2016
*  Description : Contains methods that can be resued.
**/
public class UtilityClass {
    
    /** Method name : getObjectNameFromId
     * Arguments : Id recordId - the id of the record whose name needs to be identified
     * Return type : String
     * Description : Pass the record id to this method and it will return you the name of associated object
    **/
    public static String getObjectNameFromId(Id recordId){
        Schema.DescribeSObjectResult dr = UtilityHelper.getDescribeSObjectResultFromId(recordId);
        return dr.getName(); 
    }
    
    /** Method name : getChildRelationshipsFromId
     * Arguments : Id recordId - the id of the record whose name child relationships needs to be identified
     * Return type : List<Schema.ChildRelationship>
     * Description : Pass the record id to this method and it will return you a list of all associated child relationships
    **/
    public static List<Schema.ChildRelationship> getChildRelationshipsFromId(Id recordId){
        Schema.DescribeSObjectResult dr = UtilityHelper.getDescribeSObjectResultFromId(recordId);
        return dr.getChildRelationships();
    }
    
    /** Method name : cloneObject
     * Arguments : String objName : Name of the object which needs to be cloned
     * Id orgRecordId : Id of the parent record on which clone button is created
     * Boolean isSelfId : Boolean flag to determine whether the agrument orgRecordId is self id or parent object id
     * String relationshipField : Used when the orgRecordId is parent id
     * String parentRecordId : Id of parent record
     * Return type : List<Sobject> - List of object which is cloned
     * Description : Clones the parent or related list record based on the parameters passed
    **/
    public static List<Sobject> cloneObject(String objName, Id orgRecordId, Boolean isSelfId,String relationshipField, String parentRecordId){
        SObjectType objToken = Schema.getGlobalDescribe().get(objName);
        DescribeSObjectResult objDef = objToken.getDescribe();
        Map<String, SObjectField> fields = objDef.fields.getMap();
        List<String> fieldslist = new List<String>();
        for(String fieldName : fields.keySet()) {
            if(fields.containsKey(fieldName) && fields.get(fieldName).getDescribe().isCreateable()){
                fieldslist.add(fieldName);
            }
        }
        
        /*Add exceptional condition for OpportunityLineItem object as we cannot specify Total price and Unit price together for an 
		OpportunityLineItem record */
        if(objName.equals('OpportunityLineItem')){
            // Convert List to Set as List does not have contains method
            Set<String> fieldsSet = new Set<String>(fieldslist);
            if(fieldsSet.contains('unitprice') && fieldsSet.contains('totalprice')){
                // remove either TotalPrice or UnitPrice
                fieldsSet.remove('totalprice');
                fieldslist.clear();
                fieldslist.addAll(fieldsSet);
            }
        }
        
        String query;
        if(isSelfId){
            query   = 'SELECT ' + String.join(fieldslist, ',') + ' FROM '+ objName +' WHERE Id =\''+ orgRecordId +'\' LIMIT 1';
        }else{
            query   = 'SELECT ' + String.join(fieldslist, ',') + ' FROM '+ objName +' WHERE '+ relationshipField +' =\''+ orgRecordId +'\'';
        }
        List<SObject> sObjList = new List<SObject>();
        if(fieldslist.size() > 0){
            sObjList = Database.query(query); 
        }
        List<SObject> clonedObjList = new List<SObject>();
        SObject clonedSobj;
        for(Sobject obj : sObjList){
            clonedSobj  = obj.clone(false, false, false, false);
            if(!isSelfId && clonedSobj!=null){
                // update relationshipField with parentRecordId
                if(String.isNotBlank(relationshipField) && String.isNotBlank(parentRecordId)){
                    clonedSobj.put(relationshipField,parentRecordId);
                }
            }
            clonedObjList.add(clonedSobj);
        }
        return clonedObjList;
    }
}