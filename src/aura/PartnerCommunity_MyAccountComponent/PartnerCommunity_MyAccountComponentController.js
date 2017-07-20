({
	myAction : function(component, event, helper) {
		
	},
    doInit: function(component, event, helper) {
        /*helper.getReferralSalesType(component);*/
        helper.getAccountDetailsJS(component);
    },
    editAccount: function(component, event, helper){
        component.set("v.readonly", false);
    },
    cancel: function(component, event, helper){
        component.set("v.readonly", true);
    }
})