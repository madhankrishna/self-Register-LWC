public without sharing class B2B_SelfRegisterController {
    public B2B_SelfRegisterController() {}
    
    @AuraEnabled
    public static Map<String,Object> registerUser(String firstName, String lastName, String username, String email, String communityNickname, String password, string AccountName,string PhoneNumber){
        try {

            Map<String,Object> resp = new Map<String,Object>();

            List<Account> accList = [Select Id, Name,Phone From Account Where Phone = :PhoneNumber];
            List<User> userList = [Select Id, Name From User Where Email = :email];

            if(!userList.isEmpty()){
                //if email was there
                resp.put('isEmailExist', true);
                return resp;
            }
            else if(!accList.isEmpty()){
                resp.put('isPhoneNumberExits', true);
                return resp;
            }
            else{
                String nickname = ((firstname != null && firstname.length() > 0) ? firstname.substring(0, 1) : '') + lastname.substring(0, 1);
                nickname += String.valueOf(Crypto.getRandomInteger()).substring(1, 7);

                User u = new User();
                u.firstName = firstName;
                u.lastName = lastName;
                u.Username = username;
                u.Email = email;
                u.CommunityNickname = nickname; 
                     
    
                String accountId;
    
                // create Account
    
                Account portalAccount = new Account();
                portalAccount.Name = AccountName;
                portalAccount.Phone = PhoneNumber;
                insert portalAccount;
    
                portalAccount.IsPartner = true;
                update portalAccount;
    
                //asign buyers
    
                setUpAccountAsBuyer(portalAccount);
    
                accountId = portalAccount.Id;
                
                // craete user 
    
                String userId = Site.createPortalUser(u, accountId, password,true);
                system.debug(userId);

                if (userId != null) {
                    if (password != null && password.length() > 1) {
                        List<String> listOfPermissions = new List<String>{
                            'B2B_Commerce_Buyer'
                        };
                        insertCommunityUserPermissionSet(userId, listOfPermissions);
                        ApexPages.PageReference pageRef = Site.login(username, password, 'https://training202104--mkrishna.sandbox.my.site.com/HeroCycles/s');
                        if(pageRef != null) {
                            resp.put('url',pageRef.getUrl());
                            return resp;
                        }
                            
                    }
                }
                return resp;
            }
        } catch (Exception e) {
            system.debug('e.getMessage+   '+e.getMessage());
            throw new AuraHandledException(e.getMessage());
            
            
        }
    }

    public static void setUpAccountAsBuyer(Account a) {
        BuyerAccount buyerAccount = new BuyerAccount();
        buyerAccount.BuyerId = a.Id;
        buyerAccount.Name = a.Name;
        buyerAccount.IsActive = true;

        insert buyerAccount;

        BuyerGroup buyerGroupID = [select id,Name from BuyerGroup where name = 'HeroCycles Buyer Group'];
        BuyerGroupMember bgm = new BuyerGroupMember(
                BuyerGroupId = buyerGroupID.Id,
                BuyerId = a.Id
        );
        insert bgm;
    }
    @future
    public static void insertCommunityUserPermissionSet(String userId,List<String> listOfPermissionSet) {
    List<PermissionSet> PermissionSetList = [select id,name from PermissionSet  where name in : listOfPermissionSet];
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