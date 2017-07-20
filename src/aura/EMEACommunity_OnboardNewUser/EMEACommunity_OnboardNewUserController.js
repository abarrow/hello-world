({
    openModel: function(component, event, helper) {
        // for Display Model,set the "isOpen" attribute to "true"
        component.set("v.isOpen", true);
    },
    
    closeModel: function(component, event, helper) {
        // for Hide/Close Model,set the "isOpen" attribute to "Fasle"  
        component.set("v.isOpen", false);
    },
    doInit: function(component, event, helper) {
        helper.init(component);
        helper.getUserName(component);
        helper.getCountryListJS(component);
    },
    onChangeCountryCode: function(component, event, helper){
        if(!event.getParam("value")){
            helper.clearRecordDetailsJS(component);
            component.set('v.companyRegNo', null);
            //component.set('v.enableCompanyName', true);
        }
        /*else if(event.getParam("value"))
            component.set('v.enableCompanyName', false);*/
        else
            console.log('## Change event on country code, do nothing');
    },
    onChangeCompanyReg: function(component, event, helper) {
        console.log("old value: " + event.getParam("oldValue"));
        console.log("current value: " + event.getParam("value"));
        console.log(component.get("v.countryCode"));
        if(!event.getParam("value"))
            helper.clearRecordDetailsJS(component);
        else if(event.getParam("value")){
            helper.getRecordDetailsJS(component);
        }
            else if(event.getParm("value") && !component.get("v.countryCode")){
                alert("Notification");
            }
                else
                    console.log('## Change event on company reg number, do nothing');
        
    },
    buttonController: function(component, event, helper){ // controller method
        if(component.get('v.displayAddQstns') == true){
            if(helper.validate(component)){
                component.set("v.displayAddQstns", false);
                component.set("v.submitButtonName", "Submit Details");
                component.set("v.partnerType", component.find("partnerType").get("v.value"));
                component.set("v.progressText" , "(step 2/2)");
                console.log('### partner type ' + component.find("partnerType").get("v.value"));
                if(component.find("partnerType").get("v.value") == 'Agency Partner'){
                    component.set("v.businessVolumeLabel", "How many Payment Integrations have you completed in the past 12 months?");
                	component.set("v.partnerSubTypeLabel", "What type of Web Agency and Development Partner are you?");
                    helper.getAverageSalesVolumeJS(component);
                    console.log('### before getAgencyPartnerSubTypeJS');
                    helper.getAgencyPartnerSubTypeJS(component);
                }
                else if(component.find("partnerType").get("v.value") == 'Solution Partner'){
                    component.set("v.businessVolumeLabel", "Number of merchants/clients using your solution");
                	component.set("v.partnerSubTypeLabel", "What type of Solutions Partner are you?");
                    helper.getSolutionPartnerSubTypeJS(component);
                    helper.getAverageSalesVolumeJS(component);
                }
                else
                    console.log('## Do nothing');
            }
        }
        else if(component.get('v.displayAddQstns') == false){
            if(helper.validateSubmit(component))
                helper.submitRecordJS(component, event, helper);
            	//window.location.href= https://emeapcp-goto-community.cs30.force.com/secure/logout.jsp;
        }
            else
                console.log('## Do nothing');
    },
    back: function(component, event, helper){
        component.set("v.displayAddQstns", true);
        component.set("v.submitButtonName", "Next");
        component.set("v.progressText" , "(step 1/2)");
    },
    selectPartnerSubType: function(component, event, helper){
        console.log('## Insider select Partner sub Type ' + component.get("v.partnerSubType"));
        if(component.get("v.partnerSubType").includes("Other, please specify")){
            component.set("v.displayOtherField", true);
        }
        else
            component.set("v.displayOtherField", false);
        
        if(component.get("v.partnerSubType").includes("System Integrator")){
            component.set("v.displaySolIntField", true);
        }
        else
            component.set("v.displaySolIntField", false);
    }
    
})