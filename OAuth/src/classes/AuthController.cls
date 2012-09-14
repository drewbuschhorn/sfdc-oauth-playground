public with sharing class AuthController {

    public String service { get; set; }
    public String token { get; set; }
    
    public String authUrl { get; set; }
    
    public boolean authSuccess { get; set; }

    public String message { get; set; }

    public List<SelectOption> services {
        get {
            if(services==null) {
                List<OAuthService__c> l = [SELECT name FROM OAuthService__c];
                services = new List<SelectOption>();
                for(OAuthService__c obj : l) {
                    services.add(new SelectOption(obj.name,obj.name));
                    System.debug('service: '+obj.name);
                }
            }
            return services;
        }
        set;
    }
    
    public PageReference authorize() {
        OAuth oa = new OAuth();
        authUrl = oa.newAuthorization(service);
        System.debug(authUrl);
        if(authUrl==null) {
            this.message = oa.message;
            return null;
        } else {
            return new PageReference(authUrl);
        }
    }
    
    public PageReference completeAuthorization() {
        String code = ApexPages.currentPage().getParameters().get('code');
        String service = ApexPages.currentPage().getParameters().get('sid');
        if(code!=null&&service!=null)
        {
            OAuth oa = new OAuth();
            authSuccess = oa.completeAuthorization(code,service);
            this.message = oa.message;
        }
        else {
            message = 'Invalid request. Missing parameter (oauth2) code';
        }
        return null;
    }
    
}