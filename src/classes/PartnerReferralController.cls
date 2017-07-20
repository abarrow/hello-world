/********************************************************************************************
 *  History - Case : 03771386 
 *  Date         Who                  Description
 *  2017/12/03 - Bhargav (slalom)     Created. Handles the referral flow on the lightning component and public vf page
 ********************************************************************************************/
/*  History - Case : 03771386 
 *  Date         Who                  Description
 *  2017/09/07 - Bhargav (slalom)     Updated. Added updateAccountStats Method
 ********************************************************************************************/

public without sharing class PartnerReferralController {

    public Referral__c referral {get;set;}
    public boolean isValidReferral {get; set;}
    public string currentURL {get; set;}
    public string errorMessage {get; set;}
    public boolean isSaveError {get; set;}

    /* VF Page Controller methods */
    public PartnerReferralController(ApexPages.StandardController stdController) {
        string recId = ApexPages.currentPage().getParameters().get('id');
        if (recId != null) {
            this.referral = [select City__c, Contact_Name__c, Country__c, I_Accept_Terms_and_Conditions__c, 
                                    Merchant_Company_Name__c, PayPal_Email__c, PayPal_Merchant_Id__c, Phone__c, 
                                    Shop_URL__c, Sales_Type__c, State_Provence__c, Street__c, Technical_Contact__c, 
                                    Terms_Accepted_Date__c, Title__c, TOV__c, Type_Of_Project__c, Zip_Post_Code__c, 
                                    Lead__c, CreatedBy.Name, isActiveLink__c, Contact_Email__c, CreatedBy.CompanyName, Account__c
                            from Referral__c where id = :recId][0];
        }
    }
    /* Constructor when invoked programatically*/
    public PartnerReferralController(){
        isValidReferral = false;
        isSaveError = false;
        //TODO - Replace this with a label
        errorMessage = 'Sorry, we are not able to find the Referral link in our system, please contact your Partner to receive a valid link';
        string recId = ApexPages.currentPage().getParameters().get('id');
        if (recId != null) {
            List<Referral__c> ref= [select City__c, Contact_Name__c, Country__c, I_Accept_Terms_and_Conditions__c, Account__c, 
                                            Merchant_Company_Name__c, PayPal_Email__c, PayPal_Merchant_Id__c, Phone__c, 
                                            Shop_URL__c, Sales_Type__c, State_Provence__c, Street__c, Technical_Contact__c, 
                                            Terms_Accepted_Date__c, Title__c, TOV__c, Type_Of_Project__c, Zip_Post_Code__c, 
                                            Lead__c, CreatedBy.Name, isActiveLink__c, Contact_Email__c, CreatedBy.CompanyName
                                    from Referral__c where id = :recId];
            if(!ref.isEmpty()){
                if(ref[0].isActiveLink__c == false){ // prevent submitting the duplicate information
                   errorMessage = 'This referral form is disabled as the information has already been submitted'; 
                }
                else {
                this.referral = ref[0];
                isValidReferral = true;
                }
            }
        }  
    }
    /* Method - extSave
       Description - Udpate the referral record with Merchant's information. Create lead and assign it to EMEA Partner Program Campaign.
    */
    public PageReference extSave() {
        try {
            isSaveError = false;
            if(validSave()){
                    // Create Lead record
                    Schema.RecordTypeInfo leadRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('EU Dublin Leads');
                    if (leadRecordType != null) {
                        id leadRecordTypeId = leadRecordType.getRecordTypeId();
                        string countryCode = getCountryCode(referral.Country__c);
                        Lead l = new Lead(Company=referral.Merchant_Company_Name__c, LastName=referral.Contact_Name__c, Sales_Type__c=referral.Sales_Type__c, LeadSource='Partner',
                                        Industry='*Other', RecordTypeId=leadRecordTypeId, Referral_Id__c=referral.Id, Account__c=referral.Account__c, 
                                        street = referral.Street__c, City = referral.City__c, State = referral.State_Provence__c, 
                                        PostalCode = referral.Zip_Post_Code__c, Country = countryCode, 
                                        Email=referral.Contact_Email__c, Phone=referral.Phone__c, Country__c=countryCode, Annual_Online_Sales__c=referral.TOV__c);
                        insert l;
                        system.debug('### Lead ' + l);
                        //Associate Campaign
                        string campId = getReferralCampaignId();
                        if(campId != null){
                            CampaignMember mem = new CampaignMember (campaignid=campId, leadid=l.id);
                            insert mem;
                        }
                        else{
                            PartnerCommunity_GenUtility.sendSystemError(referral.Id, 'EMEA Partner Program Campaign not found in the system');
                        }
                        referral.Lead__c = l.Id;
                        referral.Status__c = 'Responded';
                        referral.isActiveLink__c = false;
                    } 
                    update referral;
                    if(referral.Account__c != null){
                        PartnerCommunity_GenUtility.updateAccountStats(referral.Account__c);
                    } 
                    PageReference successPage = Page.CommunityPartnerReferrals_successpage;
                    successPage.setRedirect(true);
                    return successPage;
                }
            else{
                system.debug('### There is an error message ');
                errorMessage = 'There are errors on the page that are preventing from Submitting details, please correct them. Note - You may have to scroll down';
                isSaveError = true;
                return null;
            }
        } catch (Exception e) {
            isSaveError = true;
            errorMessage = 'Sorry, something went wrong, we are working on getting this fixed as soon as we can. If you need additional assistance please reach out to our support';
            PartnerCommunity_GenUtility.sendSystemError(referral.Id, e.getMessage());
        }
        return null;
    }

    /* Method - validSave
       Description - validate the data before save. Invoked from the public visualforce page
    */
    public boolean validSave(){
        boolean valid = true;
        if(this.referral != null){
            if(this.referral.I_Accept_Terms_and_Conditions__c == false){
                //TODO - Replace with a label
                this.referral.I_Accept_Terms_and_Conditions__c.addError('You must accept the Terms and Conditions to Submit the details');
                valid = false;
            }
            if(this.referral.Contact_Email__c == null){
                //TODO - Replace with a label
                this.referral.Contact_Email__c.addError('Contact Email is required');
                valid = false;}
            else{
                if(!validEmail(this.referral.Contact_Email__c)){
                    //TODO - Replace with a label
                    this.referral.Contact_Email__c.addError('Email is not valid');
                    valid = false;
                }
            }
            if(this.referral.Phone__c == null){
                //TODO - Replace with a label
                this.referral.Phone__c.addError('Phone is required');
                valid = false;
            }
            if(this.referral.Contact_Name__c == null){
                //TODO - Replace with a label
                this.referral.Contact_Name__c.addError('Contact is required');
                valid = false;
            }
            if(this.referral.Street__c == null){
                //TODO - Replace with a label
                this.referral.Street__c.addError('Street is required');
                valid = false;
            }
            if(this.referral.City__c == null){
                //TODO - Replace with a label
                this.referral.City__c.addError('City is required');
                valid = false;
            }
            if(this.referral.State_Provence__c == null){
                //TODO - Replace with a label
                this.referral.State_Provence__c.addError('State is required');
                valid = false;
            }
            if(this.referral.Country__c == null){
                //TODO - Replace with a label
                this.referral.Country__c.addError('Country is required');
                valid = false;
            }
            if(this.referral.Zip_Post_Code__c == null){
                //TODO - Replace with a label
                this.referral.Zip_Post_Code__c.addError('Postal Code is required');
                valid = false;
            }
            if(this.referral.Shop_URL__c == null){
                //TODO - Replace with a label
                this.referral.Shop_URL__c.addError('Website URL is required');
                valid = false;
            }
            if(this.referral.TOV__c == null){
                //TODO - Replace with a label
                this.referral.TOV__c.addError('Annual Sales is required');
                valid = false;
            }
        }
        return valid;
    }
    /* Method - validEmail
       Description - validate email. Invoked from the public visualforce page
    */
    public boolean validEmail(string email){
        Boolean res = true;
        String emailRegex = '^[a-zA-Z0-9._|\\\\%#~`=?&/$^*!}{+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,4}$'; // http://www.regular-expressions.info/email.html
        Pattern MyPattern = Pattern.compile(emailRegex);
        Matcher MyMatcher = MyPattern.matcher(email);
        if (!MyMatcher.matches()){ 
            res = false;
        }
        return res; 
    }
    /* Method - getCountryCode
       Description - get 2 digit country code.
    */
    public string getCountryCode(string countryName){
        string countryCode = '';
        List<Country__c> countryList = [select id, Full_Country_Name__c, name from country__c where full_country_Name__c = :countryName];
        if(!countryList.isEmpty()){
            return countryList[0].Name;
        }

        return countryCode;
    }
    /* Method - getReferralCampaignId
       Description - get referral campaign id.
    */
    public static string getReferralCampaignId(){
        string campaignId = null;
        List<Partner_Community_Settings__c> commRefsettings= Partner_Community_Settings__c.getall().values();
        if (commRefsettings.size() > 0) {
            List<Campaign> c = [select id, name from campaign where name = :commRefsettings[0].Campaign_Name__c limit 1];
            if(!c.isEmpty()){
                return c[0].Id;
            }
        }
        return campaignId;
    }

    /* LIGHTNING METHODS */

    /* Method - getReferral
       Description - Instantiates a new referral. Invoked from lightning component
    */
    @AuraEnabled
    public static Referral__c getReferral(){
        Referral__c ref = new Referral__c();
        List<User> usr = [select id, Country, name from user where id = :userinfo.getUserId()];
        ref.Status__c = 'Not Responded';
        if(!usr.isEmpty()){
            ref.country__c = usr[0].Country;
        }
        return ref;
    }
    /* Method - saveReferral
       Description - save the referral and generate a unique link. Invoked from lightning component
    */
    @AuraEnabled
    public static Referral__c saveReferral(Referral__c ref){
        if(ref != null){
            User usr = [select Id, ContactId from User where id = :userinfo.getUserId()];
            if(usr.ContactId != null){
                Contact con = [select id, AccountId from Contact where id = :usr.ContactId];
                if(con.AccountId != null)
                    ref.Account__c = con.AccountId;
            }
            ref.campaign__c = getReferralCampaignId();
            insert ref;

            ref = [select City__c, Contact_Name__c, Country__c, I_Accept_Terms_and_Conditions__c, 
                          Merchant_Company_Name__c, PayPal_Email__c, PayPal_Merchant_Id__c, Phone__c, 
                          Shop_URL__c, Sales_Type__c, State_Provence__c, Street__c, Technical_Contact__c, 
                          Terms_Accepted_Date__c, Title__c, TOV__c, Type_Of_Project__c, Zip_Post_Code__c, Referral_Link__c, isActiveLink__c, Contact_Email__c, Id, createdby.contactId, createdbyId
                  from Referral__c where id = :ref.Id][0];
        }
        return ref;
    }
    /* Method - getReferralSalesType
       Description - get Sales type picklist values. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getReferralSalesType (){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Referral__c.Sales_Type__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            if(f.isActive()){
                options.add(f.getLabel());
            }
        }
        return options;
    }
    /* Method - getReferralCountry
       Description - get country list. Invoked from lightning component
    */
    @AuraEnabled
    public static List<String> getReferralCountry (){
        List<String> options = new List<String>();
        options.add('--None--');
        Schema.DescribeFieldResult fieldResult = Referral__c.Country__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            if(f.isActive()){
                options.add(f.getLabel());
            }
        }
        return options;
    }
    /* Method - getEmailText
       Description - generate the email text from the template. Invoked from lightning component
    */
    @AuraEnabled
    public static string getEmailText (string referralId){
        string emailText = '';
        string locale = userinfo.getLanguage(); //TODO - After the language specific templates are defined incorporate locale logic
        EmailTemplate template = [SELECT Id,HTMLValue,Name,Body FROM EmailTemplate where name = 'EMEA Referral Template English2'];
        if(template != null){
         emailText = system.Messaging.renderStoredEmailTemplate(template.Id, referralId, referralId).getHtmlBody();
        }
        system.debug('#### Email Body ' + emailText);
        return emailText;
    }
    /* Method - emailReferralText
       Description - send email. This is used when copy to clipboard is not supported. Invoked from lightning component
    */
    @AuraEnabled
    public static boolean emailReferralText (Referral__c ref){
        boolean success = false;
        //Referral__c ref = [select id, createdby.contactId, createdbyId from Referral__c where id = :referralId];
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
        string templateName = 'EMEA_Referral_Email_Link_English'; //TODO - locale template yet to be defined
        EmailTemplate et = [select id, name from EmailTemplate where developername = :templateName]; 
        if(et != null){
            message.setTemplateId(et.Id);
            if(ref.createdby.contactId != null){
                message.setTargetObjectId(ref.createdby.contactId);
                message.whatId = ref.Id;
            }
            else{
                message.setTargetObjectId(ref.createdbyId);
                message.saveAsActivity = false;
                message.plainTextBody = system.Messaging.renderStoredEmailTemplate(et.Id, ref.Id, ref.Id).getHtmlBody();
                //message.plainTextBody = 'Please send the following referral link to the referred project owner <br/> <br/>' + ref.Referral_Link__c;
                message.subject = 'PayPal Community - Referral Link';
            }
        }
        else{
            message.subject = 'PayPal Community - Referral Link';
            message.plainTextBody = 'Please send the following referral link to the referred project owner <br/> <br/>' + ref.Referral_Link__c;
        }
        Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        if (results[0].success) 
        {
            System.debug('The email was sent successfully.');
            success = true;
        } else 
        {
            System.debug('The email failed to send: ' + results[0].errors[0].message);
            success = false;
        }
        return success;
    }

}