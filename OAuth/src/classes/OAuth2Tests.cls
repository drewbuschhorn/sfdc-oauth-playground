@isTest
private class OAuth2Tests {

	public static void createTestData() {
		OAuth2Service__c s = new OAuth2Service__c();
		s.name='test1234';
		s.access_token_url__c = 'http://requesttokenurl';
		s.consumer_key__c = 'consumerkey';
		s.consumer_secret__c = 'consumersecret';
		s.authorization_url__c = 'http://testauthorizationurl';
		insert s;
	}
	
	public static testMethod void testGetUsersOfService() {
		OAuth2Tests.createTestData();
		OAuth2 o = new OAuth2();
		o.getUsersOfService('test1234');
	}

    public static testMethod void testAuthorize() {
    	
    	try {
    		OAuth2Tests.createTestData();
    		Test.setCurrentPage(Page.Auth2Page);
    		ApexPages.currentPage().getHeaders().put('Host','testhost');
    		Auth2Controller ac = new Auth2Controller();
    		ac.service = 'test1234';
    		ac.authUrl = 'bogus';
    		ac.message = 'bogus';
    		System.assert(ac.services.size()>0);
    		ac.authorize();
    		Test.setCurrentPage(Page.CompleteAuth2);
	        ApexPages.currentPage().getParameters().put('OAuth2_token','token');
	        ApexPages.currentPage().getParameters().put('OAuth2_verifier','verifier');
    		ac.completeAuthorization();

    	}
    	catch(Exception e) {
			throw e;
    	}
    }
    
    public static testMethod void testTest2Controller() {
    	
    	try {
    		String savedURLID = 'http://www.google.com';
    		Test.setCurrentPage(Page.Api2TestPage);
    		Test2Controller tc = new Test2Controller();
    		
    		System.assert(tc.methodList.size()>1);
    		
    		tc.selectedService = 'test1234';
    		
    		System.assert(tc.services.size()>0);
    		
    		tc.url = 'http://testurl';
    		tc.method='GET';
    		tc.postParam = '';
    		tc.body = '';
    		tc.selectedService = 'test1234';
    		
    		tc.execute();

    	}
    	catch(Exception e) {
			throw e;
    	}
    }
    
}