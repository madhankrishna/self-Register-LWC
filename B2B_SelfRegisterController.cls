/**
* @description       : Contoller for slef register 
* @author            : Madhan
* @group             :
* @last modified on  : 9.Dec.2022
* @last modified by  : Madhan
**/
public without sharing class B2B_SelfRegisterController {
    public B2B_SelfRegisterController() {}

    private static final String IS_EMAIL_EXIST = 'isEmailExist';
    private static final String IS_PHONE_NUMBER_EXITS = 'isPhoneNumberExits';
    private static final String B2B_COMMERCE_BUYER = 'B2B_Commerce_Buyer';
    private static final String HERO_CYCLES_BUYER_GROUP = 'HeroCycles Buyer Group';
    private static final String URL = 'url';


    @AuraEnabled
    public static Map<String,Object> registerUser(String firstName, String lastName, String userName, 
                                                    String email, String communityNickname, String password, string AccountName,string PhoneNumber){
        try {
            Map<String,Object> respMap = new Map<String,Object>();

            List<Account> accList = [Select Id, Name,Phone From Account Where Phone = :PhoneNumber];
            List<User> userList = [Select Id, Name From User Where Email = :email];

            if(!userList.isEmpty()) {
                //if email was there
                respMap.put(IS_EMAIL_EXIST, true);
            }
            else if(!accList.isEmpty()){
                respMap.put(IS_PHONE_NUMBER_EXITS, true);
            }
            else{
                String nickName = ((firstName != null && firstName.length() > 0) ? firstName.substring(0, 1) : '') + lastName.substring(0, 1);
                nickName += String.valueOf(Crypto.getRandomInteger()).substring(1, 7);

                User u = new User();
                u.firstName = firstName;
                u.lastName = lastName;
                u.UserName = userName;
                u.Email = email;
                u.CommunityNickname = nickName; 

                // create Account
                Account portalAccount = new Account();
                portalAccount.Name = AccountName;
                portalAccount.Phone = PhoneNumber;
                insert portalAccount;
    
                portalAccount.IsPartner = true;
                update portalAccount;
    
                //asign buyers
                setUpAccountAsBuyer(portalAccount);                
                // craete user
                String userId = Site.createPortalUser(u, portalAccount.Id, password,true);

                if (userId != null) {
                    if (password != null && password.length() > 1) {
                        List<String> listOfPermissions = new List<String>{
                            B2B_COMMERCE_BUYER
                        };
                        insertCommunityUserPermissionSet(userId, listOfPermissions);
                        ApexPages.PageReference pageRef = Site.login(userName, password, null);
                        if(pageRef != null) {
                            respMap.put(URL,pageRef.getUrl());
                        }        
                    }
                }
            }
            return respMap;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage()); 
        }
    }

    public static void setUpAccountAsBuyer(Account a) {
        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = a.Id;
        buyerAccount.Name = a.Name;
        buyerAccount.IsActive = true;

        insert buyerAccount;

        BuyerGroup buyerGroupID = [Select Id,Name From BuyerGroup Where Name = :HERO_CYCLES_BUYER_GROUP];
        BuyerGroupMember bgm = new BuyerGroupMember(
                BuyerGroupId = buyerGroupID.Id,
                BuyerId = a.Id
        );
        insert bgm;
    }

    @future
    public static void insertCommunityUserPermissionSet(String userId,List<String> listOfPermissionSet) {
    List<PermissionSet> PermissionSetList = [Select Id,Name From PermissionSet  Where Name in : listOfPermissionSet ];
    List<PermissionSetAssignment> pmaList = new List<PermissionSetAssignment>();
    for (PermissionSet rec : PermissionSetList) {
        PermissionSetAssignment permissionSetRec = new PermissionSetAssignment();
        permissionSetRec.AssigneeId = userId;
        permissionSetRec.PermissionSetId = rec.Id;
        pmaList.add(permissionSetRec);
    }
    if (!pmaList.isEmpty()) {
        insert pmaList;
    }
}
}
