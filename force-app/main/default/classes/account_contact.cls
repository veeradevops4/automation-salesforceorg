/*******************************************************************************************
Name: account_contact
Developed by: Wipro Ltd
============================================================================================
Purpose:                                                            
Test Class -  account_contactTest
For removing AccountContact Relation
============================================================================================
History
-------
VERSION  AUTHOR                  DATE(MM/DD/YYYY)              DETAILS
1.0 -    Sarita                                                 B-1427321
2.0 -    Vishnu KM                01/20/2022                    B-1427321
3.0 -    Vishnu KM                01/23/2022                    B-1427321
4.0 -    Vishnu KM                01/25/2022                    B-1428821
5.0 -    Jayaprasath              06/14/2022
****************************************************************************************************************************/


public with sharing class account_contact {
    @AuraEnabled(cacheable=false)//JP
    public static List<AccountContactRelation> getcontactExpress(Id val,String userId) {
        
        Boolean showTab =false;
        
        if(FeatureManagement.checkPermission('EnableTabUI')) //Start-Role_changes
        {
            showTab = true;
        }
        
        User u = [SELECT Id, UserRole.Name,UserRole.DeveloperName FROM User where Id =: userId];
        String roleName =u.UserRole.DeveloperName;
        system.debug('roleee'+roleName);
        if(roleName.contains('Express_Freight')){  
            system.debug('uuuuuuuu');
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c), contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];         
        }
        else if(roleName.contains('Express') || showTab){
            system.debug('mmmmmmmmmm');
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c), contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND Express_OpCo_Text__c ='Express'];
        }
        else if(roleName.contains('Freight')){
            system.debug('qqqqqqqq');
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,ContactId,Id,Roles,Contact.AccountId,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c), contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND Freight_OpCo_Text__c='Freight'];
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static boolean fetchUserUIPermission() {
        Boolean showTab =false;
        
        if(FeatureManagement.checkPermission('EnableTabUI')) //Start-Role_changes
        {
            showTab = true;
        }
        return showTab;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Contact> getcontactFreight(Id val) {
        return [select  Id,Name,Email,Phone,Account.Name, Address__c, recordtype.Name from Contact where accountid=:val and Is_Freight_Opco__c=true];
    }
   
    @AuraEnabled
    public static List<Contact> deleteMultipleContactRecord(List<String>conObj,String currentRecordId,String opcoVal){       
        list<AccountContactRelation> acrToUpdate = [SELECT Id,Freight_OpCo_Text__c,Express_OpCo_Text__c,contact.AccountId, Accountid FROM AccountContactRelation where ContactId IN:conObj and AccountId =:currentRecordId];    
       // list<AccountContactRelation> checkshellAccount = [SELECT Id,Account.Customer_Type__c FROM AccountContactRelation where ContactId IN:conObj];    
         Map<String,AccountContactRelation> acrMap = new Map<String,AccountContactRelation>();
        for(AccountContactRelation accr :[SELECT Id,ContactId,AccountId,Account.Customer_Type__c FROM AccountContactRelation where ContactId IN:conObj]){
            if(accr.Account.Customer_Type__c == 'Individual'){
                acrMap.put(accr.ContactId,accr);
            }
            
        }
        System.debug('ACR MAP :::' +acrMap);
        System.debug('acrToUpdate'+acrToUpdate + ' '+ conObj);
        System.debug('CurrentRcordId::' +currentRecordId);
        System.debug('Opco Value::' +opcoVal);
        //list<Contact> selectedContactId=[SELECT Id,AccountId FROM Contact where ContactId IN:conObj].AccountId;
        List<Account> lstAcc= new List<Account>();
        system.debug('Currenet Contact==>'+conObj);
        system.debug('ACR Rec==>'+acrToUpdate);
        list<AccountContactRelation>acrdelete=new list<AccountContactRelation>();
        for(integer i=0;i<acrToUpdate.size();i++){           
            if(opcoVal == 'Express' && acrToUpdate[i].Freight_OpCo_Text__c!=null){
                acrToUpdate[i].Express_OpCo_Text__c='';
                update acrToUpdate[i];
                expressAndFreightContactUpdate(opcoVal,acrToUpdate[i].ContactId,currentRecordId); //ALM 617606
                System.debug('Inside 1');
            }
            if(opcoVal == 'Express' && acrToUpdate[i].Freight_OpCo_Text__c==null && acrToUpdate[i].contact.AccountId!=currentRecordId ){
                //acrdelete.add(acrToUpdate[i]) ;
                system.debug('reached');
                List<AccountContactRelation> emptyCheck =[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                if(emptyCheck.size()!=1){
                    delete acrToUpdate[i];

                }
                if(emptyCheck.size()==1){
                    system.debug('reached 88'+ acrToUpdate[i].ContactId);
                    String shellAccId ='';
                    if(!acrMap.isEmpty() && acrMap.containskey(acrToUpdate[i].ContactId)){
                        shellAccId= acrMap.get(acrToUpdate[i].ContactId).AccountId;
                    }
                    else{
                        Contact accountCreation = [Select Id, Name ,FirstName ,LastName,Secondary_External_Id__c from Contact where Id=:acrToUpdate[i].ContactId];
                        Account shell= new Account();
                        shell.Name = accountCreation.LastName+', '+accountCreation.FirstName;
                        shell.Customer_Type__c ='Individual';
                        shell.Account_External_Id__c ='IND-'+accountCreation.Secondary_External_Id__c;
                        insert shell;
                        
                       shellAccId=shell.Id;
                    }
                    System.debug('Inside 3' +shellAccId);
                    
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name,Contact_Role__c,Express_OpCO__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c, Contact_Role_Express_Text__c,  
                                                           Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                           Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                           Billing_Country__c,Billing_Postal_Code__c
                                                           from Contact where Id=:acrToUpdate[i].ContactId];
                    for(Contact con:updateContactAccount1){
                        if( con.Contact_Role_Express__c=='CSR_BI'){
                             con.AccountId=shellAccId;
                        con.Express_OpCO__c='';
                        con.Contact_Role__c='Shipper';
                        con.Express_OpCo_Text__c='';
                        con.Is_Express_Opco__c=false;
                        con.Contact_Role_Express__c='';
                        con.Contact_Role_Express_Text__c='';
                        con.Street_Address__c = con.Billing_Street_Address__c;
                        con.Street_Address1__c = con.Billing_Street_Address1__c;
                        con.Street_Address2__c = con.Billing_Street_Address2__c;
                        con.Street_Address3__c = con.Billing_Street_Address3__c;
                        con.City__c = con.Billing_City__c;
                        con.State__c = con.Billing_State__c;
                        con.Country__c = con.Billing_Country__c;
                        con.Postal_Code__c = con.Billing_Postal_Code__c;
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                        else{
                            con.AccountId=shellAccId;
                        con.Express_OpCO__c='';
                        con.Contact_Role__c='Shipper';
                        con.Express_OpCo_Text__c='';
                        con.Is_Express_Opco__c=false;
                        con.Contact_Role_Express__c='';
                        con.Contact_Role_Express_Text__c='';
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                    }
                    update updateContactAccount1;
                    delete acrToUpdate[i];  
                }
                
            }
            if(opcoVal == 'Express' && acrToUpdate[i].Freight_OpCo_Text__c==null && acrToUpdate[i].contact.AccountId==currentRecordId ){
                system.debug('reached4');
                List<AccountContactRelation> emptyCheck =[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c='Express')]; 
                system.debug('count'+emptyCheck.size());
                if(emptyCheck.size()==1){
                    system.debug('reached3'+ acrToUpdate[i].ContactId);
                    String shellAccId ='';

                    if(!acrMap.isEmpty() && acrMap.containskey(acrToUpdate[i].ContactId)){
                        shellAccId= acrMap.get(acrToUpdate[i].ContactId).AccountId;
                    }
                    else{
                        
                     Contact contactCreation = [Select Id, Name ,FirstName, LastName,Secondary_External_Id__c from Contact where Id=:acrToUpdate[i].ContactId];
                     Account shell= new Account();
                     shell.Name = contactCreation.LastName+', '+contactCreation.FirstName;
                     shell.Customer_Type__c = 'Individual';
                     shell.Account_External_Id__c ='IND-'+contactCreation.Secondary_External_Id__c;
                     insert shell;
                     shellAccId=shell.Id;

                    }
                     
                     System.debug('Inside 4' +shellAccId);
                    
                    
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name,Contact_Role__c,Express_OpCO__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c, Contact_Role_Express_Text__c,
                                                           Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                           Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                           Billing_Country__c,Billing_Postal_Code__c
                                                           from Contact where Id=:acrToUpdate[i].ContactId];
                    for(Contact con:updateContactAccount1){
                        if( con.Contact_Role_Express__c=='CSR_BI'){
                             con.AccountId=shellAccId;
                        con.Express_OpCO__c='';
                        con.Contact_Role__c='Shipper';
                        con.Express_OpCo_Text__c='';
                        con.Is_Express_Opco__c=false;
                        con.Contact_Role_Express__c='';
                        con.Contact_Role_Express_Text__c='';
                        con.Street_Address__c = con.Billing_Street_Address__c;
                        con.Street_Address1__c = con.Billing_Street_Address1__c;
                        con.Street_Address2__c = con.Billing_Street_Address2__c;
                        con.Street_Address3__c = con.Billing_Street_Address3__c;
                        con.City__c = con.Billing_City__c;
                        con.State__c = con.Billing_State__c;
                        con.Country__c = con.Billing_Country__c;
                        con.Postal_Code__c = con.Billing_Postal_Code__c;
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                        else{
                            con.AccountId=shellAccId;
                        con.Express_OpCO__c='';
                        con.Contact_Role__c='Shipper';
                        con.Express_OpCo_Text__c='';
                        con.Is_Express_Opco__c=false;
                        con.Contact_Role_Express__c='';
                        con.Contact_Role_Express_Text__c='';
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                    }
                    update updateContactAccount1;
                    delete acrToUpdate[i] ;   
                }
                if(emptyCheck.size()!=1){
                    system.debug('reached2');
                    string newacc=[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:currentRecordId AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c='Express')  LIMIT 1].AccountId;
                    if(!String.isEmpty(newacc) || !String.isBlank(newacc)){
                   // string assignParentExpress=[SELECT AccountId,Express_OpCo_Text__c from AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:newacc limit 1 ].Express_OpCo_Text__c;
                 //   string assignParentFrieght=[SELECT AccountId,Freight_OpCo_Text__c from AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:newacc limit 1 ].Freight_OpCo_Text__c;
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name  from Contact where Id=:acrToUpdate[i].ContactId];
                    list<AccountContactRelation> acrsizecheckEx = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where Express_OpCo_Text__c='Express' AND ContactId=:acrToUpdate[i].contactId and AccountId !=:currentRecordId];//ALM 617606 start
                    for(Contact con:updateContactAccount1){
                    if(acrsizecheckEx.Size()>0){
                        con.AccountId=newacc;
                        con.Postal_Code__c='68000-3333';
                        updateContactAccount.add(con);
                    }else{
                        con.AccountId=newacc;
                        con.Freight_OpCo__c='';
                        con.Freight_OpCo_Text__c='';
                        con.Contact_Role__c='Shipper';
                        con.Is_Freight_Opco__c=false;
                        con.Contact_Role_Freight__c='';
                        con.Contact_Role_Freight_Text__c='';
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                    }  //ALM 617606 end
                }
                    update updateContactAccount1;
                    System.debug('Inside 5');
                  /*  List<AccountContactRelation> acrObjItemss = new   List<AccountContactRelation>();
                    list<AccountContactRelation>relationshipUpdates = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Freight_OpCo_Text__c,Express_OpCo_Text__c FROM AccountContactRelation where ContactId=:acrToUpdate[i].ContactId and AccountId =:newacc ];
                    for(AccountContactRelation acr:relationshipUpdates){
                        acr.Express_OpCo_Text__c=assignParentExpress;
                        acr.Freight_OpCo_Text__c=assignParentFrieght;
                        acrObjItemss.add(acr);
                    }
                    update relationshipUpdates; */
                } 
                    delete acrToUpdate[i] ;
                    System.debug('Inside 6');  
                }
            }
            if(opcoVal == 'Freight' && acrToUpdate[i].Express_OpCo_Text__c!=null){
                acrToUpdate[i].Freight_OpCo_Text__c='';
                update acrToUpdate[i];
                expressAndFreightContactUpdate(opcoVal,acrToUpdate[i].ContactId, currentRecordId); //ALM 617606
                System.debug('Inside 7');
            }
            if(opcoVal == 'Freight' && acrToUpdate[i].Express_OpCo_Text__c==null && acrToUpdate[i].contact.AccountId!=currentRecordId ){
                system.debug('reached5');
                List<AccountContactRelation> emptyCheck =[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                if(emptyCheck.size()!=1){
                    delete acrToUpdate[i] ; 
                    System.debug('Inside 8');  
                }
                if(emptyCheck.size()==1){
                    system.debug('reached282'+ acrToUpdate[i].ContactId);
                    String shellAccId ='';

                    if(!acrMap.isEmpty() && acrMap.containskey(acrToUpdate[i].ContactId)){
                        shellAccId= acrMap.get(acrToUpdate[i].ContactId).AccountId;
                    }
                    else{
                        Contact accountCreation = [Select Id, Name ,FirstName,LastName,Secondary_External_Id__c from Contact where Id=:acrToUpdate[i].ContactId];
                        Account shell= new Account();
                        shell.Name = accountCreation.LastName+', '+accountCreation.FirstName;
                        shell.Customer_Type__c = 'Individual';
                        shell.Account_External_Id__c ='IND-'+accountCreation.Secondary_External_Id__c;
                        insert shell;
                        shellAccId=shell.Id;
                    }


                        System.debug('Inside 9' +shellAccId);
                        
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name,Contact_Role__c,Freight_OpCo__c,Freight_OpCo_Text__c,Is_Freight_Opco__c,Contact_Role_Freight__c,Contact_Role_Freight_Text__c,
                                                           Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                           Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                           Billing_Country__c,Billing_Postal_Code__c
                                                           from Contact where Id=:acrToUpdate[i].ContactId];
                    for(Contact con:updateContactAccount1){
                        if( con.Contact_Role_Freight__c=='CSR_BI'){
                        con.AccountId=shellAccId;
                        con.Freight_OpCo__c='';
                        con.Freight_OpCo_Text__c='';
                        con.Contact_Role__c='Shipper';
                        con.Is_Freight_Opco__c=false;
                        con.Contact_Role_Freight__c='';
                        con.Contact_Role_Freight_Text__c='';
                        con.Street_Address__c = con.Billing_Street_Address__c;
                        con.Street_Address1__c = con.Billing_Street_Address1__c;
                        con.Street_Address2__c = con.Billing_Street_Address2__c;
                        con.Street_Address3__c = con.Billing_Street_Address3__c;
                        con.City__c = con.Billing_City__c;
                        con.State__c = con.Billing_State__c;
                        con.Country__c = con.Billing_Country__c;
                        con.Postal_Code__c = con.Billing_Postal_Code__c;
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                        else{
                            con.AccountId=shellAccId;
                        con.Freight_OpCo__c='';
                        con.Freight_OpCo_Text__c='';
                        con.Contact_Role__c='Shipper';
                        con.Is_Freight_Opco__c=false;
                        con.Contact_Role_Freight__c='';
                        con.Contact_Role_Freight_Text__c='';
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                    }
                    update updateContactAccount1;
                    delete acrToUpdate[i] ;  
                }  
            }
            if(opcoVal == 'Freight' && acrToUpdate[i].Express_OpCo_Text__c==null && acrToUpdate[i].contact.AccountId==currentRecordId ){
                system.debug('reached6');
                List<AccountContactRelation> emptyCheck =[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c='Express')];
                if(emptyCheck.size()==1){
                    system.debug('reached7' +acrToUpdate[i].ContactId);
                    String shellAccId ='';

                    if(!acrMap.isEmpty() && acrMap.containskey(acrToUpdate[i].ContactId)){
                        shellAccId= acrMap.get(acrToUpdate[i].ContactId).AccountId;
                    }
                    else{
                        Contact contactCreation = [Select Id, Name,FirstName,LastName,Secondary_External_Id__c from Contact where Id=:acrToUpdate[i].ContactId];
                        Account shell= new Account();
                        shell.Name = contactCreation.LastName+', '+contactCreation.FirstName;
                        shell.Customer_Type__c ='Individual';
                        shell.Account_External_Id__c ='IND-'+contactCreation.Secondary_External_Id__c;
                        insert shell;
                        shellAccId=shell.Id;
                    }
                    
                        System.debug('Inside 10' +shellAccId);
                   
                    
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name,Contact_Role__c,Freight_OpCo__c,Freight_OpCo_Text__c,Is_Freight_Opco__c,Contact_Role_Freight__c,Contact_Role_Freight_Text__c,
                                                           Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                           Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                           Billing_Country__c,Billing_Postal_Code__c
                                                           from Contact where Id=:acrToUpdate[i].ContactId];
                    for(Contact con:updateContactAccount1){
                       if( con.Contact_Role_Freight__c=='CSR_BI'){
                        con.AccountId=shellAccId;
                        con.Freight_OpCo__c='';
                        con.Freight_OpCo_Text__c='';
                        con.Contact_Role__c='Shipper';
                        con.Is_Freight_Opco__c=false;
                        con.Contact_Role_Freight__c='';
                        con.Contact_Role_Freight_Text__c='';
                        con.Street_Address__c = con.Billing_Street_Address__c;
                        con.Street_Address1__c = con.Billing_Street_Address1__c;
                        con.Street_Address2__c = con.Billing_Street_Address2__c;
                        con.Street_Address3__c = con.Billing_Street_Address3__c;
                        con.City__c = con.Billing_City__c;
                        con.State__c = con.Billing_State__c;
                        con.Country__c = con.Billing_Country__c;
                        con.Postal_Code__c = con.Billing_Postal_Code__c;
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                        else{
                            con.AccountId=shellAccId;
                        con.Freight_OpCo__c='';
                        con.Freight_OpCo_Text__c='';
                        con.Contact_Role__c='Shipper';
                        con.Is_Freight_Opco__c=false;
                        con.Contact_Role_Freight__c='';
                        con.Contact_Role_Freight_Text__c='';
                        con.Billing_Street_Address__c = '';
                        con.Billing_Street_Address1__c = '';
                        con.Billing_Street_Address2__c = '';
                        con.Billing_Street_Address3__c = '';
                        con.Billing_City__c = '';
                        con.Billing_State__c = '';
                        con.Billing_Country__c = '';
                        con.Billing_Postal_Code__c = '';
                        updateContactAccount.add(con);
                        }
                    }
                    update updateContactAccount1;
                     delete acrToUpdate[i] ;   
                }
                if(emptyCheck.size()!=1){
                    system.debug('reached8');
                    string newacc=[SELECT AccountId from  AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:currentRecordId AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c='Express')  LIMIT 1].AccountId; //ALM 617606
                    if(!String.isEmpty(newacc) || !String.isBlank(newacc)){
                    //string assignParentExpress=[SELECT AccountId,Express_OpCo_Text__c from AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:newacc limit 1 ].Express_OpCo_Text__c;
                    //string assignParentFrieght=[SELECT AccountId,Freight_OpCo_Text__c from AccountContactRelation where ContactId=:acrToUpdate[i].ContactId  AND AccountId !=:newacc limit 1 ].Freight_OpCo_Text__c;
                    
                    List<Contact> updateContactAccount = new   List<Contact>();
                    List<Contact> updateContactAccount1 = [Select Id,AccountId, Name  from Contact where Id=:acrToUpdate[i].ContactId];
                    list<AccountContactRelation> acrsizecheckFr = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where Freight_OpCo_Text__c='Freight' AND ContactId=:acrToUpdate[i].ContactId  AND AccountId!=:currentRecordId]; //ALM 617606 start
                    for(Contact con:updateContactAccount1){
                        if(acrsizecheckFr.Size()>0){
                            con.AccountId=newacc;
                            updateContactAccount.add(con);
                        }else{
                            con.AccountId=newacc;
                            con.Freight_OpCo__c='';
                            con.Freight_OpCo_Text__c='';
                            con.Contact_Role__c='Shipper';
                            con.Is_Freight_Opco__c=false;
                            con.Contact_Role_Freight__c='';
                            con.Contact_Role_Freight_Text__c='';
                            con.Billing_Street_Address__c = '';
                            con.Billing_Street_Address1__c = '';
                            con.Billing_Street_Address2__c = '';
                            con.Billing_Street_Address3__c = '';
                            con.Billing_City__c = '';
                            con.Billing_State__c = '';
                            con.Billing_Country__c = '';
                            con.Billing_Postal_Code__c = '';
                            updateContactAccount.add(con);
                        }
                    } //ALM 617606 end
                      
                    if(updateContactAccount1!=Null){
                        update updateContactAccount1;
                    }
                    /*
                    List<AccountContactRelation> acrObjItemss = new   List<AccountContactRelation>();
                    list<AccountContactRelation>relationshipUpdates = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:acrToUpdate[i].ContactId and AccountId =:newacc ];
                    for(AccountContactRelation acr:relationshipUpdates){
                        
                        acr.Express_OpCo_Text__c=assignParentExpress;
                        acr.Freight_OpCo_Text__c=assignParentFrieght;
                        acrObjItemss.add(acr);
                    }
                    update relationshipUpdates; */
                } 
                     delete acrToUpdate[i];  
                     System.debug('Inside 11');
                }    
            }
        }
        
        return null;
    }

        //ALM 617606 Start
        Public static void expressAndFreightContactUpdate(string opco,string contactId, string accountId){
            System.debug('Inside expressAndFreightContactUpdate =>'+Opco + ''+contactId+''+accountId);
            list<AccountContactRelation> acrsizecheckEx = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where Express_OpCo_Text__c='Express' AND ContactId=:contactId and AccountId !=:AccountId];
            list<AccountContactRelation> acrsizecheckFr = [SELECT Id,Express_OpCo__c,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where Freight_OpCo_Text__c='Freight' AND ContactId=:contactId and AccountId !=:AccountId];
                        Contact con = [Select Id,AccountId, Name,Freight_OpCo__c,Freight_OpCo_Text__c,Is_Freight_Opco__c,Contact_Role_Freight__c,Contact_Role_Freight_Text__c,Contact_Role__c,Express_OpCO__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c, Contact_Role_Express_Text__c
                                                               from Contact where Id=:contactId];
                             System.debug('acrsizecheckEx'+acrsizecheckEx);
                             System.debug('acrsizecheckFr'+acrsizecheckFr);
                            if(opco=='Express' && acrsizecheckEx.size()==0){
                            con.Express_OpCO__c='';
                            con.Contact_Role__c='Shipper';
                            con.Express_OpCo_Text__c='';
                            con.Is_Express_Opco__c=false;
                            con.Contact_Role_Express__c='';
                            con.Contact_Role_Express_Text__c='';
                            update con;
                                System.debug('UpdatedCon=> '+con);
                            }
                            if(opco=='Freight' && acrsizecheckFr.size()==0){
                            con.Freight_OpCo__c='';
                            con.Freight_OpCo_Text__c='';
                            con.Contact_Role__c='Shipper';
                            con.Is_Freight_Opco__c=false;
                            con.Contact_Role_Freight__c='';
                            con.Contact_Role_Freight_Text__c='';
                            update con;
                                System.debug('UpdatedCon=> '+con);
                            }
                         
                    } //ALM 617606 End
    
    @AuraEnabled(cacheable=true)//JP
    public static List<AccountContactRelation> getcontactRelatedAccounts(Id val,String userId) {
        
         Boolean showTab =false;
        
        if(FeatureManagement.checkPermission('EnableTabUI')) //Start-Role_changes
        {
            showTab = true;
        }
        
        User u = [SELECT Id, UserRole.Name,UserRole.DeveloperName FROM User where Id =: userId];
        String roleName =u.UserRole.DeveloperName;
        system.debug('roleee'+roleName);
        if(roleName.contains('Express_Freight')){         
            return [SELECT AccountId,Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c), contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
        } 
        else if(roleName.contains('Express') || showTab){   
            return [SELECT AccountId,Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c), contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND Express_OpCo_Text__c ='Express']; 
        }
        else if(roleName.contains('Freight')){  
            return [SELECT AccountId,Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,ContactId,Id,Roles,Contact.AccountId,toLabel(Contact_Role_Express__c), toLabel(Contact_Role_Freight__c)S, contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND Freight_OpCo_Text__c='Freight'];
        }
        return null;
    }
    @AuraEnabled
    public static string removeMultipleAccountRecord(List<String>accObj,String val,String acId,List<String>friObj){
        list<AccountContactRelation> accountsToUpdate = new  List<AccountContactRelation>();
        list<AccountContactRelation>  accountsToUpdateFreight = new  list<AccountContactRelation>();
        if(accObj!=null){
            accountsToUpdate = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c,AccountId ,Contact.AccountId FROM AccountContactRelation where ContactId=:val and AccountId IN:accObj ];
        }
        
        if(friObj!=null){
            accountsToUpdateFreight = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c,AccountId ,Contact.AccountId FROM AccountContactRelation where ContactId=:val and AccountId IN:friObj ];
        }
        system.debug('^^^^^^^^^^'+accountsToUpdate);
        if(accountsToUpdate.size()>0){
            for(integer i=0;i<accountsToUpdate.size();i++){           
                if(accountsToUpdate[i].AccountId !=acId){
                    if(accountsToUpdate[i].Freight_OpCo_Text__c!=null){
                        system.debug('inside multle express');
                        accountsToUpdate[i].Express_OpCo_Text__c='';
                        
                        update accountsToUpdate[i];
                    }
                    if(accountsToUpdate[i].Freight_OpCo_Text__c==null){
                        
                         delete accountsToUpdate[i] ;  
                        
                        List<AccountContactRelation> emptyCheck =[SELECT AccountId,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                        system.debug('count3 '+emptyCheck.size());
                        if(emptyCheck.size()==0){
                            Contact accountCreation = [Select Id, Name, FirstName, LastName, Company_Name__c,Secondary_External_Id__c from Contact where Id=:val];
                            Account shell= new Account();
                            // if(accountCreation.Company_Name__c!=Null){
                            //     shell.Name = accountCreation.Company_Name__c;
                            //     insert shell;
                            // }                        
                           // else {
                                //shell.Name = accountCreation.Name;
                                //Manisha|| Req : shell account Name should be lastName,firstName
                                String contname = accountCreation.LastName+', '+ accountCreation.FirstName;
                                List<AccountContactRelation> acrrr =[Select Id ,AccountId,ContactId,Account.Name from AccountContactRelation where ContactId =:val AND Account.Name =:contname LIMIT 1];
                               System.debug('ACR>>>>>' +acrrr);
                               if(!acrrr.isEmpty()){
                                shell.Name = contname;
                                shell.Id = acrrr[0].AccountId;
                                System.debug('Inside acrr ::::'+shell.Name + shell.Id);
                                
                               }
                               else{
                                shell.Name = contname;
                                shell.Customer_Type__c ='Individual';
                                shell.Account_External_Id__c ='IND-'+accountCreation.Secondary_External_Id__c;

                                insert shell;

                               }
                           // }                        
                           // insert shell;
                            String shellAccId=shell.Id;
                            
                            List<Contact> updateContactAccount = new   List<Contact>();
                            List<Contact> updateContactAccount1 = [Select Id,AccountId, Name,Express_OpCO__c,Contact_Role__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c,Contact_Role_Express_Text__c,Is_Freight_Opco__c,Freight_OpCo_Text__c,Contact_Role_Freight_Text__c,
                                                                   Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                                   Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                                   Billing_Country__c,Billing_Postal_Code__c
                                                                   from Contact where Id=:val];
                            for(Contact con:updateContactAccount1){
                                if( con.Contact_Role_Express__c=='CSR_BI'){
                                con.AccountId=shellAccId;
                                con.Express_OpCO__c='';
                                con.Contact_Role__c='Shipper';
                                con.Express_OpCo_Text__c='';
                                con.Is_Express_Opco__c=false;
                                con.Contact_Role_Express__c='';
                                con.Contact_Role_Express_Text__c='';
                                con.Is_Freight_Opco__c=false;
                                con.Freight_OpCo_Text__c='';
                                con.Contact_Role_Freight_Text__c='';  
                                con.Street_Address__c = con.Billing_Street_Address__c;
                                con.Street_Address1__c = con.Billing_Street_Address1__c;
                                con.Street_Address2__c = con.Billing_Street_Address2__c;
                                con.Street_Address3__c = con.Billing_Street_Address3__c;
                                con.City__c = con.Billing_City__c;
                                con.State__c = con.Billing_State__c;
                                con.Country__c = con.Billing_Country__c;
                                con.Postal_Code__c = con.Billing_Postal_Code__c;
                                con.Billing_Street_Address__c = '';
                                con.Billing_Street_Address1__c = '';
                                con.Billing_Street_Address2__c = '';
                                con.Billing_Street_Address3__c = '';
                                con.Billing_City__c = '';
                                con.Billing_State__c = '';
                                con.Billing_Country__c = '';
                                con.Billing_Postal_Code__c = '';
                                updateContactAccount.add(con);
                            }else{	
                                con.AccountId=shellAccId;	
                                con.Express_OpCO__c='';	
                                con.Contact_Role__c='Shipper';	
                                con.Express_OpCo_Text__c='';	
                                con.Is_Express_Opco__c=false;	
                                con.Contact_Role_Express__c='';	
                                con.Contact_Role_Express_Text__c='';	
                                con.Billing_Street_Address__c = '';	
                                con.Billing_Street_Address1__c = '';	
                                con.Billing_Street_Address2__c = '';	
                                con.Billing_Street_Address3__c = '';	
                                con.Billing_City__c = '';	
                                con.Billing_State__c = '';	
                                con.Billing_Country__c = '';	
                                con.Billing_Postal_Code__c = '';	
                                updateContactAccount.add(con);	
                                }	
                            }
                            update updateContactAccount1;
                            List<AccountContactRelation> acrShellItemss = new   List<AccountContactRelation>();
                            list<AccountContactRelation>relationship = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:shellAccId ];
                            for(AccountContactRelation shellacr:relationship){
                                
                                shellacr.Express_OpCo_Text__c='';
                                shellacr.Freight_OpCo_Text__c='';
                                acrShellItemss.add(shellacr);
                            }
                            update relationship;
                            
                        }
                        
                        
                    }
                }
                List<AccountContactRelation> emptyChecks =[SELECT AccountId,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                
                if(accountsToUpdate[i].AccountId ==acId){
                    
                    system.debug('inside shell');
                    for(integer j=0;j<accountsToUpdateFreight.size();j++){
                        if(accountsToUpdateFreight[j].AccountId ==acId){
                            
                            List<AccountContactRelation> emptyCheckParent =[SELECT AccountId from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                            
                            if(emptyCheckParent.size()!=1){
                                
                                string assignParentAccountId=[SELECT AccountId from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].AccountId;
                                string assignParentExpress=[SELECT AccountId,Express_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Express_OpCo_Text__c;
                                string assignParentFrieght=[SELECT AccountId,Freight_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Freight_OpCo_Text__c;
                                
                                List<Contact> conObjItemss = new   List<Contact>();
                                List<Contact> conObjListss = [Select Id,AccountId, Name  from Contact where Id=:val];
                                for(Contact con:conObjListss){
                                    con.AccountId=assignParentAccountId;
                                    conObjItemss.add(con);
                                }
                                update conObjListss;
                                
                                acId=assignParentAccountId;
                                List<AccountContactRelation> acrObjItemss = new   List<AccountContactRelation>();
                                list<AccountContactRelation>relationshipUpdates = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:assignParentAccountId ];
                                for(AccountContactRelation acr:relationshipUpdates){
                                    
                                    acr.Express_OpCo_Text__c=assignParentExpress;
                                    acr.Freight_OpCo_Text__c=assignParentFrieght;
                                    acrObjItemss.add(acr);
                                }
                                update relationshipUpdates;
                                
                                
                            }
                            if(emptyCheckParent.size()==1){
                                
                                Contact createAcc = [Select Id, Name,FirstName,LastName,Company_Name__c,Secondary_External_Id__c from Contact where Id=:val];
                                Account a= new Account();
                                // if(createAcc.Company_Name__c!=Null){
                                //     a.Name = createAcc.Company_Name__c;
                                //     insert a;
                                // }                        
                                // else {
                                   // a.Name = createAcc.Name;
                                   String contnm = createAcc.LastName+', '+createAcc.FirstName;
                                   List<AccountContactRelation> accr =[Select Id ,AccountId,ContactId,Account.Name from AccountContactRelation where ContactId =:val AND Account.Name =:contnm LIMIT 1];
                                   System.debug('ACRRRRR>>>>>' +accr);
                                   if(!accr.isEmpty()){
                                    a.Name = contnm;
                                    a.Id = accr[0].AccountId;
                                    
                               }
                               else{
                                a.Name = contnm;
                                a.Customer_Type__c ='Individual';
                                a.Account_External_Id__c ='IND-'+createAcc.Secondary_External_Id__c;

                                insert a;
                                
                                System.debug('Inside acrr ::::'+a.Name + a.Id);

                               }
                                   
                                //}   
                                
                                //insert a;
                                String AccId=a.Id;
                                List<Contact> conObjItemsRemove = new   List<Contact>();
                                List<Contact> conObjListRemove = [Select Id,AccountId, Name,Express_OpCO__c,Contact_Role__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c,Contact_Role_Express_Text__c,Is_Freight_Opco__c,Freight_OpCo_Text__c,Contact_Role_Freight_Text__c, 
                                                                   Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                                   Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                                   Billing_Country__c,Billing_Postal_Code__c
                                                                   from Contact where Id=:val limit 1];
                                for(Contact con:conObjListRemove){
                                    if( con.Contact_Role_Express__c=='CSR_BI'){
                                    con.AccountId=AccId;
                                    con.Express_OpCO__c='';
                                    con.Contact_Role__c='Shipper';
                                    con.Express_OpCo_Text__c='';
                                    con.Is_Express_Opco__c=false;
                                    con.Contact_Role_Express__c='';
                                    con.Contact_Role_Express_Text__c='';      
                                    con.Is_Freight_Opco__c=false;
                                    con.Freight_OpCo_Text__c='';
                                    con.Contact_Role_Freight_Text__c='';
                                    con.Street_Address__c = con.Billing_Street_Address__c;
                                    con.Street_Address1__c = con.Billing_Street_Address1__c;
                                    con.Street_Address2__c = con.Billing_Street_Address2__c;
                                    con.Street_Address3__c = con.Billing_Street_Address3__c;
                                    con.City__c = con.Billing_City__c;
                                    con.State__c = con.Billing_State__c;
                                    con.Country__c = con.Billing_Country__c;
                                    con.Postal_Code__c = con.Billing_Postal_Code__c;
                                    con.Billing_Street_Address__c = '';
                                    con.Billing_Street_Address1__c = '';
                                    con.Billing_Street_Address2__c = '';
                                    con.Billing_Street_Address3__c = '';
                                    con.Billing_City__c = '';
                                    con.Billing_State__c = '';
                                    con.Billing_Country__c = '';
                                    con.Billing_Postal_Code__c = '';
                                    conObjItemsRemove.add(con);
                                }else{	
                                    con.AccountId=AccId;	
                                    con.Express_OpCO__c='';	
                                    con.Contact_Role__c='Shipper';	
                                    con.Express_OpCo_Text__c='';	
                                    con.Is_Express_Opco__c=false;	
                                    con.Contact_Role_Express__c='';	
                                    con.Contact_Role_Express_Text__c='';	
                                    con.Billing_Street_Address__c = '';	
                                    con.Billing_Street_Address1__c = '';	
                                    con.Billing_Street_Address2__c = '';	
                                    con.Billing_Street_Address3__c = '';	
                                    con.Billing_City__c = '';	
                                    con.Billing_State__c = '';	
                                    con.Billing_Country__c = '';	
                                    con.Billing_Postal_Code__c = '';
                                	conObjItemsRemove.add(con);	
                                }	
                    		}
                                
                                update conObjListRemove;
                                
                                List<AccountContactRelation> acrObjItemsRemove = new   List<AccountContactRelation>();
                                list<AccountContactRelation>relationshipUpdatesRemove = [SELECT Id,Freight_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:AccId ];
                                for(AccountContactRelation acr:relationshipUpdatesRemove){
                                    
                                    acr.Express_OpCo_Text__c='';
                                    acr.Freight_OpCo_Text__c='';
                                    acrObjItemsRemove.add(acr);
                                }
                                update relationshipUpdatesRemove;     
                            }
                            
                        }
                        
                    }
                    
                    if(accountsToUpdate[i].Freight_OpCo_Text__c!=null){
                        accountsToUpdate[i].Express_OpCo_Text__c='';
                        
                        update accountsToUpdate[i];
                    }
                    if(accountsToUpdate[i].Freight_OpCo_Text__c==null){
                        
                        List<AccountContactRelation> emptyCheckParent =[SELECT AccountId from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                        
                        if(emptyCheckParent.size()!=1){
                            string assignParentAccountId=[SELECT AccountId from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].AccountId;
                            string assignParentExpress=[SELECT AccountId,Express_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Express_OpCo_Text__c;
                            string assignParentFrieght=[SELECT AccountId,Freight_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Freight_OpCo_Text__c;
                            
                            List<Contact> conObjItemss = new   List<Contact>();
                            List<Contact> conObjListss = [Select Id,AccountId, Name  from Contact where Id=:val];
                            for(Contact con:conObjListss){
                                con.AccountId=assignParentAccountId;
                                conObjItemss.add(con);
                            }
                            update conObjListss;
                             delete accountsToUpdate[i] ;  
                            acId=assignParentAccountId;
                            List<AccountContactRelation> acrObjItemss = new   List<AccountContactRelation>();
                            list<AccountContactRelation>relationshipUpdates = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:assignParentAccountId ];
                            for(AccountContactRelation acr:relationshipUpdates){
                                
                                acr.Express_OpCo_Text__c=assignParentExpress;
                                acr.Freight_OpCo_Text__c=assignParentFrieght;
                                acrObjItemss.add(acr);
                            }
                            update relationshipUpdates;
                        }
                        if(emptyCheckParent.size()==1){
                            Contact createAcc = [Select Id, FirstName,LastName,Name,Company_Name__c,Secondary_External_Id__c from Contact where Id=:val];
                            Account a= new Account();
                            // if(createAcc.Company_Name__c!=Null){
                            //     a.Name = createAcc.Company_Name__c;
                            //     insert a;
                            // }                 
                           // else {
                               // a.Name = createAcc.Name; //Manisha added
                               String nm = createAcc.LastName+', '+createAcc.FirstName;
                               System.debug('Manisha' + nm);
                               List<AccountContactRelation> acrr =[Select Id ,AccountId,ContactId,Account.Name from AccountContactRelation where ContactId =:val AND Account.Name=:nm LIMIT 1];
                               System.debug('ACR>>>>>' +acrr);
                               if(!acrr.isEmpty()){
                                a.Name = nm;
                                a.Id = acrr[0].AccountId;
                                System.debug('Inside acrr ::::'+a.Name + a.Id);
                               }
                               else{
                                
                                a.Name = nm;
                                a.Customer_Type__c = 'Individual';
                                a.Account_External_Id__c ='IND-'+createAcc.Secondary_External_Id__c;

                                insert a;
                               }

                           // }  
                            
                          // insert a;
                            String AccId=a.Id;
                            List<Contact> conObjItemsRemove = new   List<Contact>();
                            List<Contact> conObjListRemove = [Select Id,AccountId, Name,Express_OpCO__c,Contact_Role__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c,Contact_Role_Express_Text__c,Is_Freight_Opco__c,Freight_OpCo_Text__c,Contact_Role_Freight_Text__c,
                                                                   Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                                   Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                                   Billing_Country__c,Billing_Postal_Code__c
                                                                   from Contact where Id=:val];
                            for(Contact con:conObjListRemove){
                                if( con.Contact_Role_Express__c=='CSR_BI'){
                                con.AccountId=AccId;   
                                con.Express_OpCO__c='';
                                con.Contact_Role__c='Shipper';
                                con.Express_OpCo_Text__c='';
                                con.Is_Express_Opco__c=false;
                                con.Contact_Role_Express__c='';
                                con.Contact_Role_Express_Text__c='';  
                                con.Is_Freight_Opco__c=false;
                                con.Freight_OpCo_Text__c='';
                                con.Contact_Role_Freight_Text__c=''; 
                                con.Street_Address__c = con.Billing_Street_Address__c;
                                con.Street_Address1__c = con.Billing_Street_Address1__c;
                                con.Street_Address2__c = con.Billing_Street_Address2__c;
                                con.Street_Address3__c = con.Billing_Street_Address3__c;
                                con.City__c = con.Billing_City__c;
                                con.State__c = con.Billing_State__c;
                                con.Country__c = con.Billing_Country__c;
                                con.Postal_Code__c = con.Billing_Postal_Code__c;
                                con.Billing_Street_Address__c = '';
                                con.Billing_Street_Address1__c = '';
                                con.Billing_Street_Address2__c = '';
                                con.Billing_Street_Address3__c = '';
                                con.Billing_City__c = '';
                                con.Billing_State__c = '';
                                con.Billing_Country__c = '';
                                con.Billing_Postal_Code__c = '';
                                conObjItemsRemove.add(con);
                            }else{	
                                con.AccountId=AccId;	
                                con.Express_OpCO__c='';	
                                con.Contact_Role__c='Shipper';	
                                con.Express_OpCo_Text__c='';	
                                con.Is_Express_Opco__c=false;	
                                con.Contact_Role_Express__c='';	
                                con.Contact_Role_Express_Text__c='';	
                                con.Billing_Street_Address__c = '';	
                                con.Billing_Street_Address1__c = '';	
                                con.Billing_Street_Address2__c = '';	
                                con.Billing_Street_Address3__c = '';	
                                con.Billing_City__c = '';	
                                con.Billing_State__c = '';	
                                con.Billing_Country__c = '';	
                                con.Billing_Postal_Code__c = '';
                                conObjItemsRemove.add(con);	
                                }	
                    		}
                            update conObjListRemove;
                             delete accountsToUpdate[i] ;  
                             if(AccId!='' && AccId!= NULL){
                            List<AccountContactRelation> acrObjItemsRemove = new   List<AccountContactRelation>();
                            list<AccountContactRelation>relationshipUpdatesRemove = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:AccId ];
                            for(AccountContactRelation acr:relationshipUpdatesRemove){
                                
                                acr.Express_OpCo_Text__c='';
                                acr.Freight_OpCo_Text__c='';
                                acrObjItemsRemove.add(acr);
                            }
                            update relationshipUpdatesRemove;  
                        }   
                        }
                    }
                }
                
            }
        }
        try {
            if(accountsToUpdateFreight.size()>0) {
                removeMultipleAccountRecordFreight(accObj,val,acId,friObj);
            }
            return 'SUCCESS';
        }
        catch(exception e){
            return 'ERROR';
        }
    }
    @AuraEnabled
    public static  string removeMultipleAccountRecordFreight(List<String>accObj,String val,String acId,List<String>friObj){
        list<AccountContactRelation>accountsToUpdate = new list<AccountContactRelation>();
        list<AccountContactRelation>accountsToUpdateFreight = new  list<AccountContactRelation>();
        if(accObj!=null) {
            accountsToUpdate = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c,AccountId ,Contact.AccountId FROM AccountContactRelation where ContactId=:val and AccountId IN:accObj ];
        }
        if(friObj!=null){
            accountsToUpdateFreight = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c,AccountId ,Contact.AccountId FROM AccountContactRelation where ContactId=:val and AccountId IN:friObj ];
        }
        try{
            if(accountsToUpdateFreight.size()>0) {
                for(integer j=0;j<accountsToUpdateFreight.size();j++){
                    
                    if(accountsToUpdateFreight[j].AccountId !=acId){
                        if(accountsToUpdateFreight[j].Express_OpCo_Text__c!=null){
                            accountsToUpdateFreight[j].Freight_OpCo_Text__c='';
                            update accountsToUpdateFreight[j];
                        }
                        if(accountsToUpdateFreight[j].Express_OpCo_Text__c==null){
                            delete accountsToUpdateFreight[j];
                            
                            List<AccountContactRelation> emptyCheckFreight =[SELECT AccountId,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Phone,contact.Address__c,contact.Other_Email__c,Express_OpCo_Text__c,Freight_OpCo_Text__c from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                            
                            if(emptyCheckFreight.size()==0){
                                Contact accountCreationFreight = [Select Id, FirstName,LastName,Name,Company_Name__c,Secondary_External_Id__c from Contact where Id=:val];
                                Account shellFreight= new Account();
                                // if(accountCreationFreight.Company_Name__c!=Null){
                                //     shellFreight.Name = accountCreationFreight.Company_Name__c;
                                // }                        
                                //else {
                                    //shellFreight.Name = accountCreationFreight.Name;
                                    shellFreight.Name = accountCreationFreight.LastName+', '+accountCreationFreight.FirstName;
                                    shellFreight.Customer_Type__c = 'Individual';
                                    shellFreight.Account_External_Id__c ='IND-'+accountCreationFreight.Secondary_External_Id__c;
                               // }  
                                
                                insert shellFreight;
                                String shellFreightAccId=shellFreight.Id;
                                
                                List<Contact> updateContactAccountFreight = new   List<Contact>();
                                List<Contact> updateContactAccountFreight1 = [Select Id,AccountId, Name,Express_OpCO__c,Contact_Role__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c,Contact_Role_Express_Text__c,Is_Freight_Opco__c,Freight_OpCo_Text__c,Contact_Role_Freight_Text__c,Contact_Role_Freight__c,
                                                                              Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                                              Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                                              Billing_Country__c,Billing_Postal_Code__c
                                                                              from Contact where Id=:val];
                                for(Contact con:updateContactAccountFreight1){
                                    if( con.Contact_Role_Freight__c=='CSR_BIs' ){
                                    con.AccountId=shellFreightAccId;
                                    con.Express_OpCO__c='';
                                    con.Contact_Role__c='Shipper';
                                    con.Express_OpCo_Text__c='';
                                    con.Is_Express_Opco__c=false;
                                    con.Contact_Role_Express__c='';
                                    con.Contact_Role_Express_Text__c='';
                                    con.Is_Freight_Opco__c=false;
                                    con.Freight_OpCo_Text__c='';
                                    con.Contact_Role_Freight_Text__c='';  
                                    con.Street_Address__c = con.Billing_Street_Address__c;
                                    con.Street_Address1__c = con.Billing_Street_Address1__c;
                                    con.Street_Address2__c = con.Billing_Street_Address2__c;
                                    con.Street_Address3__c = con.Billing_Street_Address3__c;
                                    con.City__c = con.Billing_City__c;
                                    con.State__c = con.Billing_State__c;
                                    con.Country__c = con.Billing_Country__c;
                                    con.Postal_Code__c = con.Billing_Postal_Code__c;
                                    con.Billing_Street_Address__c = '';
                                    con.Billing_Street_Address1__c = '';
                                    con.Billing_Street_Address2__c = '';
                                    con.Billing_Street_Address3__c = '';
                                    con.Billing_City__c = '';
                                    con.Billing_State__c = '';
                                    con.Billing_Country__c = '';
                                    con.Billing_Postal_Code__c = '';
                                    updateContactAccountFreight.add(con);
                                }else{
                                    con.AccountId=shellFreightAccId;
                                    con.Freight_OpCo__c='';
                                    con.Freight_OpCo_Text__c='';
                                    con.Contact_Role__c='Shipper';
                                    con.Is_Freight_Opco__c=false;
                                    con.Contact_Role_Freight__c='';
                                    con.Contact_Role_Freight_Text__c='';
                                    con.Billing_Street_Address__c = '';
                                    con.Billing_Street_Address1__c = '';
                                    con.Billing_Street_Address2__c = '';
                                    con.Billing_Street_Address3__c = '';
                                    con.Billing_City__c = '';
                                    con.Billing_State__c = '';
                                    con.Billing_Country__c = '';
                                    con.Billing_Postal_Code__c = '';
                                    updateContactAccountFreight.add(con);
                                    }
                                }
                                update updateContactAccountFreight1;
                                List<AccountContactRelation> acrShellItemFreight = new   List<AccountContactRelation>();
                                list<AccountContactRelation>relationshipFreight = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:shellFreightAccId ];
                                for(AccountContactRelation shellacr:relationshipFreight){
                                    
                                    shellacr.Express_OpCo_Text__c='';
                                    shellacr.Freight_OpCo_Text__c='';
                                    acrShellItemFreight.add(shellacr);
                                }
                                update relationshipFreight;
                                
                            } 
                        }
                    }
                    if(accountsToUpdateFreight[j].AccountId ==acId){
                        
                        if(accountsToUpdateFreight[j].Express_OpCo_Text__c!=null){
                            accountsToUpdateFreight[j].Freight_OpCo_Text__c='';
                            
                            update accountsToUpdateFreight[j];
                        }
                        if(accountsToUpdateFreight[j].Express_OpCo_Text__c==null){
                            List<AccountContactRelation> emptyCheckParent =[SELECT AccountId from  AccountContactRelation where ContactId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')];
                            
                            if(emptyCheckParent.size()!=1){
                                string assignParentAccountId=[SELECT AccountId from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].AccountId;
                                string assignParentExpress=[SELECT AccountId,Express_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Express_OpCo_Text__c;
                                string assignParentFrieght=[SELECT AccountId,Freight_OpCo_Text__c from AccountContactRelation where ContactId=:val  AND AccountId !=:acId limit 1 ].Freight_OpCo_Text__c;
                                
                                List<Contact> conObjItemss = new   List<Contact>();
                                List<Contact> conObjListss = [Select Id,AccountId, Name  from Contact where Id=:val];
                                for(Contact con:conObjListss){
                                    con.AccountId=assignParentAccountId;
                                    //con.Postal_Code__c='68000-3333';
                                    conObjItemss.add(con);
                                }
                                update conObjListss;
                                delete accountsToUpdateFreight[j];
                                acId=assignParentAccountId;
                                List<AccountContactRelation> acrObjItemss = new   List<AccountContactRelation>();
                                list<AccountContactRelation>relationshipUpdates = [SELECT Id,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:assignParentAccountId ];
                                for(AccountContactRelation acr:relationshipUpdates){
                                    
                                    acr.Express_OpCo_Text__c=assignParentExpress;
                                    acr.Freight_OpCo_Text__c=assignParentFrieght;
                                    acrObjItemss.add(acr);
                                }
                                update relationshipUpdates;
                            }
                            if(emptyCheckParent.size()==1){
                                contact createAcc = [Select Id, FirstName,LastName,Name,Company_Name__c,Secondary_External_Id__c from Contact where Id=:val];
                                Account a= new Account();
                                // if(createAcc.Company_Name__c!=Null){
                                //     a.Name = createAcc.Company_Name__c;
                                //     insert a;
                                // }                        
                               // else {
                                   // a.Name = createAcc.Name;
                                   String conname = createAcc.LastName+', '+createAcc.FirstName;
                                   List<AccountContactRelation> accr = [Select Id ,AccountId,Account.Name,ContactId from AccountContactRelation where ContactId =:val AND Account.Name =:conname LIMIT 1];
                                   System.debug('ACRRR >>>'+accr);
                                   if(!accr.isEmpty()){ 
                                    a.Name = conname;
                                    a.Id = accr[0].AccountId;
                                    
                                   }
                                   else{
                                    a.Name = conname;
                                    a.Customer_Type__c ='Individual';
                                    a.Customer_Type__c = 'Individual';
                                    a.Account_External_Id__c ='IND-'+createAcc.Secondary_External_Id__c;
                                    insert a;
                                   }
                                  

                              //  }  
                               // insert a;
                                String AccId=a.Id;
                                if(AccId!='' && AccId!=null){
                                List<Contact> conObjItemsRemove = new   List<Contact>();
                                List<Contact> conObjListRemove = [Select Id,AccountId, Name,Express_OpCO__c,Contact_Role__c,Express_OpCo_Text__c,Is_Express_Opco__c,Contact_Role_Express__c,Contact_Role_Express_Text__c,Is_Freight_Opco__c,Freight_OpCo_Text__c,Contact_Role_Freight_Text__c,Contact_Role_Freight__c,
                                                                   Street_Address__c,Street_Address1__c,Street_Address2__c,Street_Address3__c, City__c,State__c,Country__c,Postal_Code__c,
                                                                   Billing_Street_Address__c,Billing_Street_Address1__c,Billing_Street_Address2__c,Billing_Street_Address3__c,Billing_City__c,Billing_State__c,
                                                                   Billing_Country__c,Billing_Postal_Code__c
                                                                   from Contact where Id=:val];
                                for(Contact con:conObjListRemove){
                                    if( con.Contact_Role_Freight__c=='CSR_BI' ){
                                    con.AccountId=AccId; 
                                    con.Express_OpCO__c='';
                                    con.Contact_Role__c='Shipper';
                                    con.Express_OpCo_Text__c='';
                                    con.Is_Express_Opco__c=false;
                                    con.Contact_Role_Express__c='';
                                    con.Contact_Role_Express_Text__c='';
                                    con.Is_Freight_Opco__c=false;
                                    con.Freight_OpCo_Text__c='';
                                    con.Contact_Role_Freight_Text__c='';    
                                    con.Street_Address__c = con.Billing_Street_Address__c;
                                    con.Street_Address1__c = con.Billing_Street_Address1__c;
                                    con.Street_Address2__c = con.Billing_Street_Address2__c;
                                    con.Street_Address3__c = con.Billing_Street_Address3__c;
                                    con.City__c = con.Billing_City__c;
                                    con.State__c = con.Billing_State__c;
                                    con.Country__c = con.Billing_Country__c;
                                    con.Postal_Code__c = con.Billing_Postal_Code__c;
                                    con.Billing_Street_Address__c = '';
                                    con.Billing_Street_Address1__c = '';
                                    con.Billing_Street_Address2__c = '';
                                    con.Billing_Street_Address3__c = '';
                                    con.Billing_City__c = '';
                                    con.Billing_State__c = '';
                                    con.Billing_Country__c = '';
                                    con.Billing_Postal_Code__c = '';
                                    conObjItemsRemove.add(con);
                                }else{
                            		con.AccountId=AccId;
                                    con.Freight_OpCo__c='';
                                    con.Freight_OpCo_Text__c='';
                                    con.Contact_Role__c='Shipper';
                                    con.Is_Freight_Opco__c=false;
                                    con.Contact_Role_Freight__c='';
                                    con.Contact_Role_Freight_Text__c='';
                                    con.Billing_Street_Address__c = '';
                                    con.Billing_Street_Address1__c = '';
                                    con.Billing_Street_Address2__c = '';
                                    con.Billing_Street_Address3__c = '';
                                    con.Billing_City__c = '';
                                    con.Billing_State__c = '';
                                    con.Billing_Country__c = '';
                                    con.Billing_Postal_Code__c = '';
                                    conObjItemsRemove.add(con);
                                    }
                                }
                                update conObjListRemove;
                            }
                                delete accountsToUpdateFreight[j];
                                if(AccId!=null && AccId!=''){
                                List<AccountContactRelation> acrObjItemsRemove = new   List<AccountContactRelation>();
                                list<AccountContactRelation>relationshipUpdatesRemove = [SELECT Id,Express_OpCo__c,Express_OpCo_Text__c,Freight_OpCo_Text__c FROM AccountContactRelation where ContactId=:val and AccountId =:AccId ];
                                for(AccountContactRelation acr:relationshipUpdatesRemove){
                                    
                                    acr.Express_OpCo_Text__c='';
                                    acr.Freight_OpCo_Text__c='';
                                    acrObjItemsRemove.add(acr);
                                }
                                update relationshipUpdatesRemove;  
                            }   
                            }
                        }
                    }
                    
                }
            }
            return 'SUCCESS';
        }
        catch(exception e){
            return 'ERROR';
        }
    }
    @AuraEnabled
    public static List<Task> createInteraction(String contactId, Datetime datetimes,String Opco) {
        system.debug('@@@REmoveRelationship');
        List<Task> tlist = new List<Task>();
        Contact c = new Contact();
        if(contactId != null) {
            c = [SELECT id,CreatedDate,LastModifiedDate FROM Contact WHERE id =:contactId];          
        }
        
        HelperUtility hu = new HelperUtility();
        Task t = new Task();
        User u = [SELECT id,Name,EmployeeNumber FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        Date myDate = date.newinstance(c.CreatedDate.year(), c.CreatedDate.month(), c.CreatedDate.day());
        // t.Customer_Email__c =   contact.Email;
        // t.Customer_First_Name__c = contact.FirstName;
        // t.Customer_Last_Name__c = contact.LastName;
        // t.Customer_Fax_Number__c = contact.Fax;
        // t.Account_Number__c = con.account.account_number;
        // t.Customer_Phone_Number__c = con.primary_Phone__c
        t.ActivityDate = myDate;
        // t.Company_Name__c = contact.Account.Express_Company_Name; if the Opco is selected as Express
        // t.Company_Name__c = contact.Account.Freight_Company_Name; If the Opco is selected as Freight
        if(u!=null){
            t.Employee_Number__c = u.EmployeeNumber;
        }
        //t.Success_Flag__c = true;
        // t.End_Date__c = API response  date;
        t.Interaction_Sub_Type__c = 'UNLINK ACCOUNT';
        t.Interaction_Type__c = 'CONTACT';
        t.OpCo__c = Opco;
        t.Reason_Description__c = 'UNLINK CONTACT WITH ACCOUNT';
        /*t.CIH_Sub_Reason__c = linkName;
t.CIH_Reason__c = 'QuickLink';
t.Call_Center__c = c.Name;  */         
        t.Source_System__c = 'CED';
        t.Interaction_Description__c = 'DISSOCIATING CONTACT WITH ACCOUNT';           
        t.Subject = 'CONTACT - DISSOCIATING CONTACT WITH ACCOUNT';
        t.Status = 'Completed';
        t.Start_Date__c = datetimes;
        t.End_Date__c = c.LastModifiedDate;
        // t.WhatId = Contact.accountId;
        t.WhoId = contactId;    
        tlist.add(t);     
        return tlist;     
    }
    @AuraEnabled(cacheable=true)
    public static List<AccountContactRelation> getcontactExpressWithSearch(Id val,String userId,String strConName) {
        String roleStr = strConName;
         Boolean showTab =false;
        strConName = '%' + strConName + '%';
        User u = [SELECT Id, UserRole.Name,UserRole.DeveloperName FROM User where Id =: userId];
        String roleName =u.UserRole.DeveloperName;
        system.debug('roleee'+roleName);
        
         if(FeatureManagement.checkPermission('EnableTabUI')) //Start-Role_changes
        {
            showTab = true;
        }
            
        if(roleName =='Express_Freight'){
            system.debug('mmmmmmmmmm');
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND (Freight_OpCo_Text__c='Freight' OR Express_OpCo_Text__c ='Express')
                    AND (contact.name LIKE :strConName
                         OR contact.middlename LIKE :strConName 
                         OR contact.Primary_Phone__c LIKE :strConName 
                         OR contact.Secondary_Phone__c LIKE :strConName 
                         OR contact.Email LIKE :strConName
                         OR contact.Other_Email__c LIKE :strConName
                         OR account.name LIKE :strConName
                         OR contact.Address__c LIKE :strConName
                         //  OR contact.Contact_Role_Express__c INCLUDES(' + String.join(strConName, ',')+ ') 
                         OR contact.Contact_Role_Express__c INCLUDES(:roleStr)
                         
                         
                        )];
            
        } else if(roleName =='Express' || showTab){  
            
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,Contact.AccountId, ContactId,Id,Roles,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND Express_OpCo_Text__c ='Express'
                    AND (contact.name LIKE :strConName
                         OR contact.middlename LIKE :strConName 
                         OR contact.Primary_Phone__c LIKE :strConName 
                         OR contact.Secondary_Phone__c LIKE :strConName 
                         OR contact.Email LIKE :strConName
                         OR contact.Other_Email__c LIKE :strConName
                         OR account.name LIKE :strConName
                         OR contact.Address__c LIKE :strConName
                         OR contact.Contact_Role_Express__c INCLUDES(:roleStr)
                         
                         
                        )]; 
            
        } else if(roleName =='Freight'){
            system.debug('qqqqqqqq');
            return [SELECT Account.Express_Company_Name__c,Account.Freight_Company_Name__c ,Account.Name,Account.AccountNumber,ContactId,Id,Roles,Contact.AccountId,Contact_Role_Express__c, Contact_Role_Freight__c, contact.name,contact.Email,contact.Primary_Phone__c,contact.Secondary_Phone__c,contact.Address__c,contact.Other_Email__c,Express_OpCo__c,Freight_Opco__c,Express_OpCo_Text__c,Freight_OpCo_Text__c,contact.recordtype.Name from  AccountContactRelation where AccountId=:val  AND Freight_OpCo_Text__c='Freight'
                    AND (contact.name LIKE :strConName
                         OR contact.middlename LIKE :strConName 
                         OR contact.Primary_Phone__c LIKE :strConName 
                         OR contact.Secondary_Phone__c LIKE :strConName 
                         OR contact.Email LIKE :strConName
                         OR contact.Other_Email__c LIKE :strConName
                         OR account.name LIKE :strConName
                         OR contact.Address__c LIKE :strConName
                         OR contact.Contact_Role_Express__c INCLUDES(:roleStr)
                        )];
        }
        return null;
    }
    @AuraEnabled() 
    public static list<task> createInteractionRecord(List<String>conObj,String currentRecordId,String opcoVal)
    {
        list<contact> contactLst = new list<contact>();
        List<Task> taskLst = new List<Task>();
        
        system.debug('contact passed'+conObj);
        User usr = [SELECT id,Name,EmployeeNumber FROM User WHERE Id =: UserInfo.getUserId() LIMIT 1];
        if(conObj.size()>0) {
            contactLst = [SELECT id,CreatedDate,LastModifiedDate,email FROM Contact WHERE id in : conObj];          
        }
        if(contactLst.size()>0){
            for(Contact con : contactLst){
                Date myDate = date.newinstance(con.CreatedDate.year(), con.CreatedDate.month(), con.CreatedDate.day());
                Task taskRec = new Task();
                taskRec.ActivityDate=myDate;
                if(usr!=null){
                    taskRec.Employee_Number__c = usr.EmployeeNumber;
                }
                taskRec.Interaction_Sub_Type__c = 'UNLINK ACCOUNT';
                taskRec.Interaction_Type__c = 'CONTACT';
                taskRec.OpCo__c = opcoVal;
                taskRec.Source_System__c = 'CED';
                taskRec.Interaction_Description__c = 'DISSOCIATING CONTACT WITH ACCOUNT';           
                taskRec.Subject = 'CONTACT - TESTING';
                taskRec.Status = 'Completed';
                taskRec.Start_Date__c = system.now();
                taskRec.End_Date__c = con.LastModifiedDate;
                taskRec.WhoId = con.id;  
                taskRec.WhatId = currentRecordId;      
                taskLst.add(taskRec);
            }  
        }        
        system.debug('Task Created==>'+taskLst);
        return taskLst;
    }
}
