global class OAuth2 {

	private OAuth2Service__c service;
	private String token;
	private String consumerKey;
	private String consumerSecret;

	private Map<String,String> parameters = new Map<String,String>();
	
	public String message { get; set; }

	public String callbackUrl {get; set; }
	public String authUri {get; set; }
	
	public void setConsumerKey(String value) { consumerKey = value; }
	public void setConsumerSecret(String value) { consumerSecret = value; }

	/**
	 * Looks up service name and starts a new authorization process
	 * returns the authorization URL that the user should be redirected to
	 * If null is returned, the request failed. The message property will contain
	 * the reason.
	 */ 
	public String newAuthorization(String serviceName) {

		service = [SELECT access_token_url__c, consumer_key__c, 
						  consumer_secret__c, authorization_url__c,id,
						  (select token__c FROM tokens__r WHERE owner__c=:UserInfo.getUserId() ) 
						  FROM OAuth2Service__c WHERE name = :serviceName];
		
		if(service==null) {
			System.debug('Couldn\'t find OAuth2 Service '+serviceName);
			message = 'Service '+serviceName+' was not found in the local configuration';
			return null;
		}

		if(callbackUrl==null) { 
			if(ApexPages.currentPage()==null || ApexPages.currentPage().getHeaders().get('Host')==null) {
				message = 'No callback page was set and it couldn\'t be generated from Apex context';
				System.debug(message);
				return null;
			}
	
			callbackUrl = EncodingUtil.urlEncode('https://'+ApexPages.currentPage().getHeaders().get('Host')+
												 Page.CompleteAuth2.getUrl()+'?sid='+service.id,'UTF-8');
		}
		consumerKey = service.consumer_key__c;
		consumerSecret = service.consumer_secret__c;                
				
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('GET');
				
		authUri = service.authorization_url__c+'?client_id='+EncodingUtil.urlEncode(service.consumer_key__c,'UTF-8')+'&redirect_uri='+EncodingUtil.urlDecode(callbackUrl,'UTF-8')+'&type='+EncodingUtil.urlEncode('web','UTF-8')+'&response_type='+EncodingUtil.urlEncode('code','UTF-8');
		//req.setEndpoint(authUri);
		System.debug('Request body set to: '+req.getBody());
		
		return authUri;
	}
    
	public boolean completeAuthorization(String code, String serviceId) {
		System.debug('Completing authorization for request code '+code);
		service = [SELECT access_token_url__c, consumer_key__c, 
						  consumer_secret__c, authorization_url__c,id,name
						  FROM OAuth2Service__c WHERE id = :serviceId];

		callbackUrl = EncodingUtil.urlEncode('https://'+ApexPages.currentPage().getHeaders().get('Host')+
												 Page.CompleteAuth2.getUrl()+'?sid='+service.id,'UTF-8');        
		consumerKey = service.Consumer_Key__c;
		consumerSecret = service.Consumer_Secret__c;
		
		Http h = new Http();
		HttpRequest req = new HttpRequest();
		req.setMethod('POST');
		//req.setCompressed(true);
		req.setEndpoint(service.access_token_url__c);
		req.setBody('grant_type=authorization_code'+
                    '&type=web_server'+
                    '&client_id='+consumerKey+
                    '&client_secret='+consumerSecret+
                    '&redirect_uri='+callbackUrl+
                    '&code='+EncodingUtil.urlEncode(code,'UTF-8'));
		
		HttpResponse res = null;
		if(service.name=='test1234') {
			res = new HttpResponse();
		} else {
			res = h.send(req);
			System.debug('Response from request token request: ('+res.getStatusCode()+')'+res.getBody());
		}
		if(res.getStatusCode()>299) {
			message = 'Failed getting an access token. HTTP Code = '+res.getStatusCode()+'. Message: '+res.getStatus()+'. Response Body: '+res.getBody()+' Code:'+code;
			return false;
		}

		String resParams = service.name == 'test1234' ? 
			'OAuth2_token=token&OAuth2_token_secret=token_secret' : res.getBody();

		Map<String,String> rp = new Map<String,String>();
		JSONParser parser = System.JSON.createParser(res.getBody());
		// Parse JSON response to get individual field values.
		String token = null;
		while(parser.nextToken() != null)
		{
		   if((parser.getCurrentToken() == JSONToken.FIELD_NAME) && (parser.getText() == 'access_token')){ 
			  // store values as you walk the JSON
			  parser.nextToken();
			  token = parser.getText();
		   }
		}
		
		if(token == null){
			message = 'Failed getting an access token. 2 - HTTP Code = '+res.getStatusCode()+'. Message: '+res.getStatus()+'. Response Body: '+res.getBody();
			return false;
		}
		
		OAuth2_Token__c t = new OAuth2_Token__c();
		t.owner__c = UserInfo.getUserId();
		t.OAuth2_Service__c = service.id;
		t.token__c = token;
		insert t;
		
		return true;
	}

	public List<User> getUsersOfService(String serviceName) {
		List<OAuth2_Token__c> l =
			[SELECT OAuth2_Service__r.name, Owner__r.name FROM OAuth2_Token__c 
			 WHERE OAuth2_Service__r.name= :serviceName];
			 
		List<User> result = new List<User>();
		for(OAuth2_Token__c t : l) {
			result.add(t.owner__r);
		}
		return result;
	}

	public boolean setService(String serviceName) {
		return setService(serviceName,UserInfo.getUserId());
	}

	public boolean setService(String serviceName, ID userId) {
		OAuth2_Token__c t = null;
		try {
			t =
			[SELECT OAuth2_Service__r.name, OAuth2_Service__r.consumer_key__c, OAuth2_Service__r.consumer_secret__c, 
			 token__c FROM OAuth2_Token__c 
			 WHERE OAuth2_Service__r.name= :serviceName AND owner__c=:userId];
		} catch(System.QueryException e) {
			try {
				// Two-legged OAuth2 - try to find match on serviceName
				service = [SELECT id, name, consumer_key__c, consumer_secret__c 
				 FROM OAuth2Service__c 
				 WHERE name= :serviceName];
				
				System.debug('Preparing Two-legged OAuth2 request to service '+service.name);
				
				consumerKey = service.Consumer_Key__c;
				consumerSecret = service.Consumer_Secret__c;
				this.token = '';    
				return true;
			} catch(System.QueryException e1) {
				message = 'Couldn\'t find service '+serviceName+'. ['+e1+']';
				System.debug(message);
				return false;
			}
		}
		service = t.OAuth2_Service__r;
		
		System.debug('Preparing OAuth2 request to service '+service.name);
		
		consumerKey = service.Consumer_Key__c;
		consumerSecret = service.Consumer_Secret__c;
		this.token = t.token__c;     
		return true;
	}
}