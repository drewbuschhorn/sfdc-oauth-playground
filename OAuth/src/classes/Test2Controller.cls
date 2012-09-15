public class Test2Controller {
	
    public String body { get; set; }
    public String method { get; set; }
    public String postParam { get; set; }
    public String url { get; set; }

    public String message { get; set; }
    
    public List<SelectOption> methodList { 
    	get {
    		if(methodList==null) {
    			methodList = new List<SelectOption>();
    			methodList.add(new SelectOption('GET','GET'));    			
    			methodList.add(new SelectOption('POST','POST'));
    			methodList.add(new SelectOption('PUT','PUT'));
    		}
    		return methodList;
    	}
    	set;
    }
    private Map<String,OAuth2Service__c> OAuth2Services {
    	get {
    		if(OAuth2Services==null) {
    			OAuth2Services = new Map<String,OAuth2Service__c>(); 
    			for(OAuth2Service__c o : 
    					[SELECT name 
    					 FROM OAuth2Service__c]) {
    				OAuth2Services.put(o.name,o);
    			}
    		}
    		return OAuth2Services;
    	}
    	set;
    }

    public String selectedService { 
    	get {
    		if(selectedService==null && OAuth2Services.size()>0) {
    			selectedService = OAuth2Services.values()[0].name;
    		}
    		return selectedService;
    	}
    	set; 
    }
    public String selectedServiceId { 
    	get {
    		if(selectedServiceId==null && OAuth2Services.size()>0) {
    			selectedServiceId = OAuth2Services.values()[0].id;
    		}
    		return selectedServiceId;
    	}
    	set; 
    }
    

    public List<SelectOption> services {
        get {
            services = new List<SelectOption>();
	        for(OAuth2Service__c obj : OAuth2Services.values()) {
                services.add(new SelectOption(obj.name,obj.name));
            }
            return services;
        }
        set;
    }

    public PageReference execute() {
        System.debug('Method: '+method+', Service: '+selectedService+'. URL: '+url);
        System.debug('selectedServiceId: '+selectedServiceId+', UserInfo.getUserId(): '+UserInfo.getUserId());
        String sId = selectedServiceId;
        String oId = UserInfo.getUserId();
        
        OAuth2_Token__c t = [SELECT token__c FROM OAuth2_Token__c 
        WHERE OAuth2_Service__c = :sId AND Owner__c = :oId LIMIT 1];
        
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        req.setMethod(method);
        req.setEndpoint(url);
        if(method=='POST' || method=='PUT') {
        	if(postParam!=null & postParam!='') {
	        	req.setBody(postParam);
				req.setHeader('Content-Type','application/x-www-form-urlencoded');
			} else {
				req.setBody(body);
			}
        }
        OAuth2 oa = new OAuth2();
        if(!oa.setService(selectedService)) {
        	System.debug(oa.message);
        	message=oa.message;
        	return null;
        }
        req.setEndpoint(req.getEndpoint()+'?access_token='+EncodingUtil.urlEncode(t.token__c,'UTF-8'));
        //oa.sign(req);
        System.debug('Sending request...');
        HttpResponse res = h.send(req);
        body = res.getBody();
        System.debug('Received response ('+res.getStatusCode()+' '+res.getStatus()+')');
        message = '';
        return null;
    }
}