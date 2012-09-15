public with sharing class Auth2Controller {

    public String service { get; set; }
    public String token { get; set; }
    
    public String authUrl { get; set; }
    
    public boolean authSuccess { get; set; }

    public String message { get; set; }

    public List<SelectOption> services {
        get {
            if(services==null) {
                List<OAuth2Service__c> l = [SELECT name FROM OAuth2Service__c];
                services = new List<SelectOption>();
                for(OAuth2Service__c obj : l) {
                    services.add(new SelectOption(obj.name,obj.name));
                    System.debug('service: '+obj.name);
                }
            }
            if(services==null){
            	this.message = 'You have no OAuth2 services.  Please add one.';
            }
            return services;
        }
        set;
    }
    
    public PageReference authorize() {
    	Schema.DescribeSObjectResult result = OAuth2Service__c.sObjectType.getDescribe();
        String key = result.getKeyPrefix();
        System.debug(result.getKeyPrefix());
        try{
	        OAuth2 oa = new OAuth2();
	        authUrl = oa.newAuthorization(service);
	        System.debug(authUrl);
	        if(authUrl==null) {
	        	this.message = oa.message;
	        	return null;
	        } else {
	            return new PageReference(authUrl);
	        }
        }catch(Exception e){
        	System.debug(e);
        	return new PageReference('/'+key+'/o');
        }
    }
    
    public PageReference completeAuthorization() {
        String code = ApexPages.currentPage().getParameters().get('code');
        String service = ApexPages.currentPage().getParameters().get('sid');
        if(code!=null&&service!=null)
        {
            OAuth2 oa = new OAuth2();
            authSuccess = oa.completeAuthorization(code,service);
            this.message = oa.message;
        }
        else {
            message = 'Invalid request. Missing parameter (OAuth22) code';
        }
        return null;
    }
    
}