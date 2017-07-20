/*Change Log -
	Author: Bhargav Kodali(Slalom)
	Purpose: Added lightning methods
	Date: 05/24/2017
*/
/*Change Log -
	Author: Bhargav Kodali(Slalom)
	Purpose: Added lightning methods to fetch Agency and Solution Partner sub type values
	Date: 06/07/2017
*/
/*Change Log -
	Author: Bhargav Kodali(Slalom)
	Purpose: Added BNCode generation for Solution Partner
	Date: 06/21/2017
*/
public without sharing class LIPP_RegistrationHandler implements Auth.RegistrationHandler {
    public static final String DEFAULT_ACCOUNT_NAME = 'Partner Community Default Account';
    
    public User createUser(Id portalId, Auth.UserData data) {        
	    system.debug('###In createUser');
        User usr;
	    LIPP_AuthUserData authData = new LIPP_AuthUserData(data);
	    authData.spillUserData();	// Show contents to System.debug

	    // Ensure user has Business PayPal Account
        if (authData.accountType.equalsIgnoreCase('BUSINESS') == false) {
        	throw new LIPP_CommunityException('Only BUSINESS PayPal Accounts are supported in Partner Community.');
        }
	    // Ensure user has verified PayPal Account
//        if (authData.verified.equalsIgnoreCase('false')) {
//        	throw new LIPP_CommunityException('Only VERIFIED PayPal Accounts are supported in Partner Community. Please log into your PayPal account to complete verification step.');
//        }

	    if (data.attributeMap.containsKey('sfdc_networkid')) {	// Is user coming from a community?
	    	system.debug('###In createUser = inside if statment containsKey(sfdc_networkid)');
	        //We have a community id, so create a user with community access 

	        // Get Account Id associated with user's Payer_Id - or get the DEFAULT Account Id
	        Id accountId = this.getAccountId(authData.payerId);
	        // Get Profile
	        Profile profile = this.getCommunityProfile(accountId);
	        // Construct Contact
	        Contact c = new Contact();
	        c.accountId = accountId;
	        c.email = authData.emailAddress;
	        c.firstName = authData.givenName;
	        c.lastName = authData.familyName;

	        usr = this.createUserSObject(authData);
	        if (usr.Id == null) {	// Only set Contact and Profile if this is BRAND NEW user
	        	insert(c);
		        usr.ContactId = c.Id;
		        usr.ProfileId = profile.Id;
	        }
	    }
        
        return usr;
    }
    
    public void updateUser(Id userId, Id portalId, Auth.UserData data) {
	    system.debug('In updateUser');
	    System.debug('userId=' + userId);
	    LIPP_AuthUserData authData = new LIPP_AuthUserData(data);
	    authData.spillUserData();	// Show contents to System.debug

    	// Find user record 
        User user = [select id, IsActive, UserName, ProfileId, Payer_Id__c from User where id = :userId limit 1];	

        // Ensure user is active
        if (user.IsActive == false) {
            throw new LIPP_CommunityException('Your account is deactivated, please contact ........');
        }
//        if (authData.verified.equalsIgnoreCase('false')) {
//        	throw new LIPP_CommunityException('Only VERIFIED PayPal Accounts are supported in Partner Community. Please log into your PayPal account to complete verification step.');
//        }

		// This is an opportunity to update user details from Auth.UserData if needed
		user.Payer_Id__c = authData.payerId;
		update user;
	
    }
/*
    public User getUserWithEmailAddress(String emailAddress) {
		User userRec;

		try {
			userRec = [select id, UserName, ProfileId, Payer_Id__c from User where Email = :emailAddress limit 1];	
		} catch(Exception e) {
			System.debug('In findUserWithEmailAddress - exception thrown: ' + e.getMessage());
		}

		return userRec;
	}
*/
	// Main purpose of this method is to locate Account with given CompanyRegNo. If not found, then create one.
	// Then tie Contact, associated with User's user record, to the Account.
	@AuraEnabled 
	public static Boolean getAccountWithCompanyReg(map<string, Object> onboardingDataMap) {
	    system.debug('In getAccountWithCompanyReg');
		list<Account> acctsList;
		Account acct;
		PayPal_Account__c payPalAccount;
		Contact contact;
		string companyName, companyAddr1, companyAddr2, postCode, countryCode, companyRegNumber, partnerType, userId, companyState,
				website, country, yearEstablished, primaryEmail, agencyPartnerType, solutionPartnerType, paymentIntegrations,
				averageSalesVolume, countMechantsnUsingSol, partnerSubType;
		Integer paymentIntegrationsInt, customersLocatedInCountryInt, businessVolume; 
		Boolean foundAccount = false;
		User user;

		// Extract data from map
		companyName = (string) onboardingDataMap.get('CompanyName');
		companyAddr1 = (string) onboardingDataMap.get('CompanyAddr1');
		companyAddr2 = (string) onboardingDataMap.get('CompanyAddr2');
		postCode = (string) onboardingDataMap.get('PostCode');
		countryCode = getCountryCode((string) onboardingDataMap.get('CountryCode'));
		companyRegNumber = (string) onboardingDataMap.get('CompanyRegNo');
		companyState = (string) onboardingDataMap.get('State');
		partnerType = (string) onboardingDataMap.get('PartnerType');
		website = (string) onboardingDataMap.get('Website');
		country = (string) onboardingDataMap.get('Country');
		yearEstablished = (string) onboardingDataMap.get('YearEstablished');
		agencyPartnerType = (string) onboardingDataMap.get('AgencyPartnerType');
		solutionPartnerType = (string) onboardingDataMap.get('SolutionPartnerType');
		customersLocatedInCountryInt = (Integer) onboardingDataMap.get('CustomersLocatedInCountry');
		averageSalesVolume = (string) onboardingDataMap.get('AverageSalesVolume');
		countMechantsnUsingSol = (string) onboardingDataMap.get('CountMechantsnUsingSol');
        if (Test.isRunningTest()) {
        	primaryEmail = (string) onboardingDataMap.get('PrimaryEmail');
			userId = (string) onboardingDataMap.get('UserId');
        } else {
            primaryEmail = userinfo.getUserEmail();
            userId = userinfo.getUserId();          
        }
		if (partnerType.equalsIgnoreCase('Solution Partner')) {
			partnerSubType = solutionPartnerType;
			businessVolume = (Integer) onboardingDataMap.get('CountMechantsnUsingSol');
		} else if (partnerType.equalsIgnoreCase('Agency Partner')) {
			partnerSubType = agencyPartnerType;			
			businessVolume = (Integer) onboardingDataMap.get('PaymentIntegrations');
		}

        // Get User record
		try {
			user = [select ContactId, ProfileId, Payer_Id__c from User where id = :userId limit 1];
		} catch(Exception e) {
			System.debug('In getAccountWithCompanyReg - exception thrown: ' + e.getMessage());
			throw new LIPP_CommunityException('Unable to locate USER with ID=' + userId);
		}

        // Get Account
        if (String.isNotBlank(companyRegNumber)) {
			acctsList = [select id, IsPartner, Name, BillingStreet, BillingPostalCode, BillingState, BillingCountry, Company_Number__c,
							Partner_Type__c, Website, Year_established__c, PayPal_Email__c, Partner_Sub_Type__c, Business_Volume__c,
							Partner_Avg_Sales_Vol__c, of_Merchants_Located_in_Program_Countr__c,PartnerCommTermsAndCondsAccepted__c, PartnerCommTermsAndCondsAcceptedBy__c
						from Account where Company_Number__c = :companyRegNumber limit 1];

			if (acctsList.size() > 0) {
				acct = acctsList[0];

				acct.Name=companyName; acct.IsPartner = true;
				acct.BillingStreet=companyAddr1; acct.BillingPostalCode=postCode; acct.BillingState=companyState; 
				acct.BillingCountry=countryCode; acct.Company_Number__c=companyRegNumber; acct.Partner_Type__c=partnerType;
				acct.Website=website; acct.Year_established__c=yearEstablished; acct.PayPal_Email__c=primaryEmail;
				acct.Partner_Sub_Type__c=partnerSubType; acct.Business_Volume__c=businessVolume;
				acct.Partner_Avg_Sales_Vol__c=averageSalesVolume; acct.of_Merchants_Located_in_Program_Countr__c=customersLocatedInCountryInt;
                acct.PartnerCommTermsAndCondsAccepted__c=System.now(); acct.PartnerCommTermsAndCondsAcceptedBy__c=user.Id;
								
	            update acct;
				foundAccount = true;
			}
        }
			
		if (foundAccount == false) {
			String partnerRecordTypeId = getPartnerRecordTypeId();
            String ownerId = getAdminUserId();
			acct = new Account(RecordTypeId=partnerRecordTypeId, OwnerId=ownerId, Name=companyName, Industry='Other*', Goods_Sold__c='Digital',
								BillingStreet=companyAddr1, BillingPostalCode=postCode, BillingState=companyState, 
								BillingCountry=countryCode, Company_Number__c=companyRegNumber, Partner_Type__c=partnerType,
								Website=website, Year_established__c=yearEstablished, PayPal_Email__c=primaryEmail,
								Partner_Sub_Type__c=partnerSubType, Business_Volume__c=businessVolume,
								Partner_Avg_Sales_Vol__c=averageSalesVolume, of_Merchants_Located_in_Program_Countr__c=customersLocatedInCountryInt,
                              	PartnerCommTermsAndCondsAccepted__c=System.now(), PartnerCommTermsAndCondsAcceptedBy__c=user.Id); 
			insert acct;
            
            // Enable Account as Partner Account 
            acct.IsPartner = true;
            update acct;
			foundAccount = true;
		}

        // Associate Contact with Account
        list<Contact> contactList = [select AccountId from Contact where id = :user.ContactId limit 1];
        if (contactList.size() > 0) {
            contactList[0].AccountId = acct.id;
            
            update contactList; 
        }
		
		// Get PayPal_Account record
		try {
			payPalAccount = [select Id, Account__c from PayPal_Account__c where Payer_Id__c = :user.Payer_Id__c limit 1];
            payPalAccount.Account__c = acct.id;
            
            update payPalAccount;
		} catch(Exception e) {
			payPalAccount = new PayPal_Account__c(Name=companyName, Account__c=acct.Id, Payer_Id__c=user.Payer_Id__c);
			insert payPalAccount;
			
			System.debug('In getAccountWithCompanyReg - exception thrown: ' + e.getMessage());
		}

		return foundAccount; 
	}

	public Profile getCommunityProfile(string acctId) {
		Profile profile;
        Partner_Community_Settings__c pc = Partner_Community_Settings__c.getValues('Community Settings');
        string agencyPartnerProfileName = pc.Agency_Partner_Profile_Name__c;
        string solutionPartnerProfileName = pc.Solution_Partner_Profile_Name__c;
        string agencyType = [select Partner_Type__c from Account where id = :acctId].Partner_Type__c;
        string newProfileName;
        Profile newProfile;

        if (agencyType == null) {
            newProfileName = 'Partner Community Default';                    	    
        } else if (agencyType.equalsIgnoreCase('Agency Partner')) {
            newProfileName = agencyPartnerProfileName;
        } else if (agencyType.equalsIgnoreCase('Solution Partner')) {
            newProfileName = solutionPartnerProfileName;
        } else {
            newProfileName = 'Partner Community Default';            
        }

        try {
            profile = [select id from Profile where Name = :newProfileName limit 1];
        } catch(Exception e) {
            system.debug('Unable to locate profile with name of ' + newProfileName);
			throw new LIPP_CommunityException('Unable to locate profile ' + newProfileName);
        }        

		return profile;
	}

	// Will first attempt getting Account Id via user's Payer_Id... if that fails, then look for DEFAULT account
	public Id getAccountId(String PayerId) {
		Id accountId = null;

		try { 
			PayPal_Account__c pa = [SELECT Id, Account__c FROM PayPal_Account__c WHERE Payer_Id__c = :PayerId and Account__c != null limit 1];	
			accountId = pa.Account__c;
		} catch(Exception e) {
			try {
				accountId = [SELECT Id from Account WHERE Name = :DEFAULT_ACCOUNT_NAME limit 1].id;
			} catch(Exception e1) {
				throw new LIPP_CommunityException('Unable to locate default account');
			}
		}

		return accountId;
	}

	public static Id getPartnerRecordTypeId() {

		Schema.RecordTypeInfo accountRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner');
        if (accountRecordType == null) {
			System.debug('In getPartnerRecordTypeId -  Unable to locate Account Record Type');
        	throw new LIPP_CommunityException('Unable to locate Account Record Type');
        }
		
		return accountRecordType.getRecordTypeId();
	}
	public static Id getAdminUserId() {

        Partner_Community_Settings__c pc = Partner_Community_Settings__c.getValues('Community Settings');

        try {
            User u = [select id from User where id = :pc.Admin_User_Id__c limit 1];
        } catch (Exception e) {
			System.debug('In getAdminUserId -  Unable to locate Admin User');
        	throw new LIPP_CommunityException('Unable to locate Admin User - is custom setting populated');
        }
		
		return pc.Admin_User_Id__c;
	}

	// Salesforce considers this person a "new user" so let's create a new User sObject
	public User createUserSObject(LIPP_AuthUserData authData) {
		User u;

        u = new User();
        String nicknameSuffix = DateTime.now().getTime().format().right(7).remove(',');
        
        u.Username = authData.emailAddress + '.paypal';
        u.Email = authData.emailAddress;
        u.LastName = authData.familyName;
        u.FirstName = authData.givenName;
        u.CommunityNickName = authData.givenName + nicknameSuffix;
        String alias = authData.familyName + authData.givenName;
        // Alias must be 8 characters or less
        if(alias.length() > 8) {
            alias = alias.substring(0, 8);
        }
        u.Alias = alias;
        if (Test.isRunningTest()) {
            u.LanguageLocaleKey='en_US';    
            u.LocaleSidKey='en_US';            
        } else {
            u.Languagelocalekey = UserInfo.getLocale();
            u.Localesidkey = UserInfo.getLocale();
        }
        u.LanguageLocaleKey='en_US';    
        u.LocaleSidKey='en_US';            
        u.EmailEncodingKey = 'UTF-8';
        u.TimeZoneSidKey = 'America/Los_Angeles';
		u.Payer_Id__c = authData.payerId;
        u.AD_GUID__c = 'XPORTAL';
        u.Country = 'UK';	// This should be remove during phase 2 (localisation)
		
        system.debug('###User object=' + u);
	    return u;
	}
    /* Method - getCountryCode
       Description - get 2 digit country code. Invoked from lightning component.
    */
	@AuraEnabled
    public static String getCountryCode(String country) {
    	list<Country__c> countryList = [select name from Country__c where Full_Country_Name__c = :country or Country_Adjective__c = :country limit 1];
        
        return (countryList.isEmpty() ? 'UK' : countryList[0].name);
    }   
	/* Method - displayOnboardModal
       Description - display onboard modal when user is assigned to default account. Invoked from lightning component.
    */
	@AuraEnabled
    public static Boolean displayOnboardModal(){
    	List<User> u = [select id, contactId from user where id = :userinfo.getUserId()];
    	
        if (!u.isEmpty()) {
    		List<Contact> c = [select id, accountid from contact where id = :u[0].contactId];
    		if (!c.isEmpty()) {
    			List<Account> a = [select id, name from Account where id = :c[0].accountId];
                if (a[0].Name == DEFAULT_ACCOUNT_NAME) {
                    return true;
                }
    		}
    	}
    	return false;
    }
	/* Method - submitDetails
       Description - Invoked from lightning, convert string to map and deserialize to a map
    */
    @AuraEnabled
    public static void submitDetails(String jsonString){
    	Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        system.debug('### jsonMap ' + jsonMap);
        LIPP_RegistrationHandler.getAccountWithCompanyReg(jsonMap);
    }
	/* Method - getCompanyDetails
       Description - Invoked from lightning, make a call to kycker and get the address details
    */
	@AuraEnabled
    public static String getCompanyDetails(String companyRegNo, String countryCode){
    	system.debug('### Inside getCompanyDetails ' + companyRegNo +  ' ## ' + countryCode);
    	CoInfoSearchComponentController addressClass = new CoInfoSearchComponentController();
    	List<Country__c> con = [select Name,Full_Country_Name__c from Country__c where id = :countryCode limit 1];
    	if(!con.isEmpty())
    		addressClass.countryCode = con[0].Name;
    	else
    		addressClass.countryCode = 'GB';	
        addressClass.selectedCoSearchResultItem = companyRegNo;
        addressClass.getDetails();
        BasicCoInfo companyInfo = addressClass.getBasicCoInfo();
        if(companyInfo != null){
        	system.debug('### Response ' + JSON.serialize(companyInfo).replaceAll(strike_utilities.NAMESPACE_API, ''));
            return JSON.serialize(companyInfo).replaceAll(strike_utilities.NAMESPACE_API, '');
        }
        else{
            return null;
        }
    }
	/* Method - getUserName
       Description - get logged in user name. Invoked from lightning component
    */
    @AuraEnabled
    public static String getUserName(){
    	User u = [select firstname from user where id=:userinfo.getuserid()];
        return u.firstname;
    }
	/* Method - getAgencyPartnerSubType
       Description - get agency partner type values from custom setting. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getAgencyPartnerSubType (){
        List<String> options = new List<String>();
        List<EMEA_Community_Agency_Partner_Type__c> values = 
        	[select id, value__c from EMEA_Community_Agency_Partner_Type__c order by Name];
        for (EMEA_Community_Agency_Partner_Type__c val: values) {
            options.add(val.value__c);
        }
        return options;
    }
	/* Method - getSolutionPartnerSubType
       Description - get solution partner type values from custom setting. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getSolutionPartnerSubType (){
        List<String> options = new List<String>();
        List<EMEA_Community_Solution_PartnerType__c> values = 
        	[select id, value__c from EMEA_Community_Solution_PartnerType__c order by Name];
        for (EMEA_Community_Solution_PartnerType__c val: values) {
            options.add(val.value__c);
        }
        return options;
    }
	/* Method - getAverageSalesVolume
       Description - get sales volume picklist values. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getAverageSalesVolume (){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Account.Partner_Avg_Sales_Vol__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }
    
        return options;
    }
	/* Method - getCountryList
       Description - get country list. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getCountryList (){
        List<String> options = new List<String>();
		List<Country__c> countryList = 
			[select id, Full_Country_Name__c, name from country__c where full_country_Name__c != null order by full_country_Name__c asc];
		for (Country__c c: countryList) {
		    options.add(c.Full_Country_Name__c);
		}
        return options;
    }

}