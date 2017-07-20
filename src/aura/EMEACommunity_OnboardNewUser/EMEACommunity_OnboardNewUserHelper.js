({
    helperMethod : function() {
        
    },
    init: function(component){
        var action = component.get("c.displayOnboardModal");
        action.setCallback(this, function(response) {
            console.log('### response after submitting details' + response.getState());
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                if(response.getReturnValue() == true)
                    component.set("v.isOpen", true);
            } else {
                component.set("v.isOpen", false);                
            }
            
        });
        $A.enqueueAction(action);
        
    },
    getUserName: function(component){
        var action = component.get("c.getUserName");
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                component.set("v.userFirstName", response.getReturnValue());
            }
        });
        $A.enqueueAction(action);
    },
    getParams: function(component, event, helper) {
        var companyName = component.get('v.companyName');
        var stAddr1 = component.get('v.stAddr1');
        var stAddr2 = component.get('v.stAddr2');
        var city = component.get('v.city');
        var state = component.get('v.state');
        var country = component.get('v.selectedCountry');
        var postalCode = component.get('v.postalCode');
        var partnerType = component.get('v.partnerType'); //component.find("partnerType").get("v.value");
        var companyRegNo = component.get('v.companyRegNo');
        var website = component.get('v.companyURL');
        var yearEstablished = component.get('v.yearBusiness');
        var primaryEmail = component.get('v.primaryEmail');
        var customersLocatedInCountry = component.get('v.percentageCustomers');
        var averageSalesVolume = component.get('v.averageSalesVolume');
        var partnerSubType = component.get('v.partnerSubType')
        if(component.get('v.otherValue') != null){
            partnerSubType = partnerSubType + ';' + component.get('v.otherValue');
        }
        var businessVolume = component.get('v.businessVolume');
        console.log('## after fetch');
        if(partnerType == 'Agency Partner'){
            return {
                AgencyPartnerType: partnerSubType,
                PaymentIntegrations: businessVolume,
                CompanyName: companyName,
                CompanyAddr1: stAddr1,
                CompanyAddr2: stAddr2,
                PostCode: postalCode,
                CompanyRegNo: companyRegNo,
                PartnerType: partnerType,
                Country: country,
                City: city,
                State: state,
                Website: website,
                YearEstablished: yearEstablished,
                PrimaryEmail: primaryEmail,
                CustomersLocatedInCountry: customersLocatedInCountry,
                AverageSalesVolume: averageSalesVolume
            };
        }
        else if(partnerType == 'Solution Partner'){
            return {
                SolutionPartnerType: partnerSubType,
                CountMerchantsUsingSol: businessVolume,
                CompanyName: companyName,
                CompanyAddr1: stAddr1,
                CompanyAddr2: stAddr2,
                PostCode: postalCode,
                CompanyRegNo: companyRegNo,
                PartnerType: partnerType,
                Country: country,
                City: city,
                State: state,
                Website: website,
                YearEstablished: yearEstablished,
                PrimaryEmail: primaryEmail,
                CustomersLocatedInCountry: customersLocatedInCountry,
                AverageSalesVolume: averageSalesVolume
            };
        }
            else {
                return {};
            }
    },
    getRecordDetailsJS: function(component){
        var action = component.get("c.getCompanyDetails");
        console.log('## ServerMethod ' + JSON.stringify(component.get("c.getCompanyDetails")));
        console.log('## CompanyRegNo ' + component.get('v.companyRegNo') + ' ## CountryCode ' + component.get('v.countryCode'));
        action.setParams({
            companyRegNo: component.get('v.companyRegNo'),
            countryCode: component.get('v.countryCode')
        });
        console.log('### Action ' + action);
        // Add callback behavior for when response is received
        component.set("v.spinner",true);
        action.setCallback(this, function(response) {
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                var returnMsg  = JSON.parse(response.getReturnValue());
                console.log('### return message ' + returnMsg.regAddress.postcode);
                if(returnMsg.companyName != null)
                    component.set('v.companyName', returnMsg.companyName);
                if(returnMsg.countryOfOrigin != null)
                    component.set('v.country', returnMsg.countryOfOrigin);
                if(returnMsg.regAddress.postTown != null)
                    component.set('v.city', returnMsg.regAddress.postTown);
                if(returnMsg.regAddress.postcode != null)
                    component.set('v.postalCode', returnMsg.regAddress.postcode);
                if(returnMsg.regAddress.addressLine1 != null)
                    component.set('v.stAddr1', returnMsg.regAddress.addressLine1);
                if(returnMsg.regAddress.addressLine2 != null)
                    component.set('v.stAddr2', returnMsg.regAddress.addressLine2);
                if(returnMsg.regAddress.county != null)
                    component.set('v.state', returnMsg.regAddress.county);
                
                console.log('#### response value ' + returnMsg.regAddress.postTown);
                //alert(JSON.parse(response.getReturnValue()));
            }
            else {
                console.log("Failed with state: " + state);
            }
            component.set("v.spinner",false);
        });
        $A.enqueueAction(action);
    },
    getAgencyPartnerSubTypeJS: function(component){
        var action = component.get("c.getAgencyPartnerSubType");
        var inputsel = component.find("partnerSubType");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            if(inputsel != null){
                inputsel.set("v.options", opts);
            }
        });
        $A.enqueueAction(action); 
    },
    getSolutionPartnerSubTypeJS: function(component){
        var action = component.get("c.getSolutionPartnerSubType");
        var inputsel = component.find("partnerSubType");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            if(inputsel != null)
                inputsel.set("v.options", opts);
            
        });
        $A.enqueueAction(action); 
    },
    getAverageSalesVolumeJS: function(component){
        var action = component.get("c.getAverageSalesVolume");
        var inputsel = component.find("averageSalesVolume");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            if(inputsel != null)
                inputsel.set("v.options", opts);
            
        });
        $A.enqueueAction(action); 
    },
    getCountryListJS: function(component){
        console.log('## inside getCountryListJS');
        var action = component.get("c.getCountryList");
        var opts=[];
        action.setCallback(this, function(a) {
            for(var i=0;i< a.getReturnValue().length;i++){
                opts.push({"class": "optionClass", label: a.getReturnValue()[i], value: a.getReturnValue()[i]});
            }
            if(opts != null){
                component.set("v.countryList", opts);
            }            
        });
        $A.enqueueAction(action); 
    },
    clearRecordDetailsJS: function(component, event, helper){
        console.log('## In the clear record details ');
        component.set('v.companyName', null);
        component.set('v.country', null);
        component.set('v.stAddr2', null);
        component.set('v.stAddr1', null);
        component.set('v.postalCode', null);
        component.set('v.city', null);
        component.set('v.state', null);
    },
    submitRecordJS: function(component, event, helper){
        var action = component.get("c.submitDetails");
        action.setParams({
            jsonString: JSON.stringify(helper.getParams(component, event, helper))
        });
        console.log('### Action ' + action);
        // Add callback behavior for when response is received
        component.set("v.spinner",true);
        action.setCallback(this, function(response) {
            console.log('### response after submitting details' + response.getState());
            var state = response.getState();
            if (component.isValid() && state === "SUCCESS") {
                //Implement some logic
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "type" : "success",
                    "message": "Success. Thank you for submitting the details",
                    "duration": 4000
                });
                toastEvent.fire();
                component.set("v.isOpen", false);
            } else {
                
                if (response.getState() === "ERROR") {
                    var errors = response.getError();
                    console.log(errors);
                    console.log('INSIDE ERRORS ERROR MESSAGE IS >>>' + errors[0].message + '<<<');
                    if (errors) {
                        if (errors[0] && errors[0].message) {
                            console.log(errors[0].message);
                        }
                    }
                }
                
            }
            component.set("v.spinner",false);
        });
        $A.enqueueAction(action);
    },
    validate: function(component){
        var valid = true;
        console.log('## Inside validate');
        // Validation - Company Name must not be blank
        var nameField = component.find("companyName");
        var merchantName = nameField.get("v.value");
        if ($A.util.isEmpty(merchantName)){
            valid = false;
            nameField.set("v.errors", [{message:"Company name can't be blank."}]);
        }
        else {
            nameField.set("v.errors", null);
        }
        // Validation - Street Address1 must not be blank
        var stAddr1Field = component.find("stAddr1");
        var stAddr1Value = stAddr1Field.get("v.value");
        if ($A.util.isEmpty(stAddr1Value)){
            valid = false;
            stAddr1Field.set("v.errors", [{message:"Street Address1 can't be blank."}]);
        }
        else {
            stAddr1Field.set("v.errors", null);
        }
        // Validation - City must not be blank
        var cityField = component.find("city");
        var cityValue = cityField.get("v.value");
        if ($A.util.isEmpty(cityValue)){
            valid = false;
            cityField.set("v.errors", [{message:"City can't be blank."}]);
        }
        else {
            cityField.set("v.errors", null);
        }
        // Validation - State must not be blank
        var stateField = component.find("state");
        var stateValue = stateField.get("v.value");
        if ($A.util.isEmpty(stateValue)){
            valid = false;
            stateField.set("v.errors", [{message:"State can't be blank."}]);
        }
        else {
            stateField.set("v.errors", null);
        }
        // Validation - PostCode must not be blank
        var postCodeField = component.find("postalCode");
        var postCodeValue = postCodeField.get("v.value");
        if ($A.util.isEmpty(postCodeValue)){
            valid = false;
            postCodeField.set("v.errors", [{message:"Post Code can't be blank."}]);
        }
        else {
            postCodeField.set("v.errors", null);
        }
        // Validation - Country must not be blank
        var countryField = component.find("country");
        var countryValue = countryField.get("v.value");
        if ($A.util.isEmpty(countryValue)){
            valid = false;
            countryField.set("v.errors", [{message:"Country can't be blank."}]);
        }
        else {
            countryField.set("v.errors", null);
        }
        // Validation - Partner Type must not be blank
        var partnerTypeField = component.find("partnerType");
        var partnerTypeValue = partnerTypeField.get("v.value");
        if (partnerTypeValue == '--Select One--'){
            valid = false;
            partnerTypeField.set("v.errors", [{message:"Partner Type can't be blank."}]);
        }
        else {
            partnerTypeField.set("v.errors", null);
        }
        console.log('## valid' + valid);
        if(valid == false){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "error",
                "message": "There are some errors on the page preventing details submission. Please correct them (You may have to scroll down / up)",
                "duration": 10000
            });
            toastEvent.fire();
        }
        return(valid);
    },
    validateSubmit: function(component){
        var valid = true;
        var toastMsg = "There are some errors on the page preventing details submission. Please correct them (You may have to scroll down / up)";
        // Validation - Company URL must not be blank
        var urlField = component.find("companyURL");
        var urlValue = urlField.get("v.value");
        if ($A.util.isEmpty(urlValue)){
            valid = false;
            urlField.set("v.errors", [{message:"Company URL can't be blank."}]);
        }
        else if(urlValue == 'https://www.'){
            valid = false;
            urlField.set("v.errors", [{message:"Not a valid URL"}]);
        }
            else {
                urlField.set("v.errors", null);
            }        
        // Validation - Percentage Customers must not be blank
        var perCustField = component.find("percentageCustomers");
        var perCustVal = perCustField.get("v.value");
        if ($A.util.isEmpty(perCustVal)){
            valid = false;
            perCustField.set("v.errors", [{message:"Percentage Customers can't be blank."}]);
        }
        else {
            if(perCustVal > 100 || perCustVal < 0){
                valid = false;
                perCustField.set("v.errors", [{message:"Percentage must be between 0 and 100"}]);  
            }
            else{
                perCustField.set("v.errors", null);
            }
        }
        // Validation - Percentage Customers must not be blank
        var saleVolumeField = component.find("averageSalesVolume");
        var salesVal = saleVolumeField.get("v.value");
        if ($A.util.isEmpty(salesVal)){
            valid = false;
            saleVolumeField.set("v.errors", [{message:"Average Sales Volume per year can't be blank."}]);
        }
        else {
            saleVolumeField.set("v.errors", null);
        }
        // Validation - businessVolume must not be blank
        var busVolField = component.find("businessVolume");
        var busVolVal = busVolField.get("v.value");
        if ($A.util.isEmpty(busVolVal)){
            if(component.get("v.partnerType") == "Solution Partner"){
                valid = false;
                busVolField.set("v.errors", [{message:"Number of merchants can't be blank."}]);
            }
            else if (component.get("v.partnerType") == 'Agency Partner'){
                valid = false;
                busVolField.set("v.errors", [{message:"Payment Integrations can't be blank."}]);
            }
                else
                    busVolField.set("v.errors", null);
        }
        else {
            busVolField.set("v.errors", null);
        }
        // Validation - other field
        var partnerSubTypeField = component.find("partnerSubType");
        var subTypeVal = partnerSubTypeField.get("v.value");
        if ($A.util.isEmpty(subTypeVal)){
            valid=false;
            partnerSubTypeField.set("v.errors", [{message:"Partner Type can't be blank."}]);
        }
        else {
            partnerSubTypeField.set("v.errors", null);
        }
        if (component.get("v.partnerSubType").includes("Other, please specify")){
            var otherField = component.find("otherValue");
            var otherVal = otherField.get("v.value");
            if($A.util.isEmpty(otherVal)){
                valid = false;
                otherField.set("v.errors", [{message:"Other value can't be blank."}]);
            }
            else
                otherField.set("v.errors", null);
        }
        // Terms and condition validation, update the toast message
        if(!document.getElementById('termCondition').checked){
            toastMsg = "You must accept PayPal Terms and Conditions";
            valid = false;
        }
        if(valid == false){
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "error",
                "message": toastMsg,
                "duration": 10000
            });
            toastEvent.fire();
        }
        return(valid);
    },
})