import jenkins.model.*
import hudson.security.*
import hudson.model.*
import hudson.PluginManager
import org.jenkinsci.plugins.* 
import com.cloudbees.plugins.credentials.*  
import hudson.plugins.active_directory.*

def env = System.getenv()
String securityType = env["SECURITY_TYPE"] ?: 'PASSWORD';
println "* Configuring security " + securityType + " for JENKINS instance"
if(['PASSWORD', 'LDAP'].contains(securityType)) {
	configureSecurity(securityType, env)
} else {
	println "security type " + securityType + " is not supported, supported are PASSWORD, LDAP";
}

void configureSecurity(String securityType, Map env) {
	if("PASSWORD".equalsIgnoreCase(securityType)) {
		configurePasswordBasedSecurity(env)
	} else {
		configureLdapBasedSecurity(env)
	}
	configureAuthorizationStrategy(env)
}

void configurePasswordBasedSecurity(Map env) {
	String username = env['JENKINS_USERNAME'] ?: "admin"
	String password = env['JENKINS_PASSWORD'] ?: "password"

	def instance = Jenkins.getInstance()

	// Create admin user
	def hudsonRealm = new HudsonPrivateSecurityRealm(false)
	hudsonRealm.createAccount(username, password)
	instance.setSecurityRealm(hudsonRealm)

	instance.save()
}

void configureLdapBasedSecurity(Map env) {
	println "* Configuring LDAP security"

	String server = env['JENKINS_LDAP_DOMAIN']
	String rootDN = env['JENKINS_LDAP_BASEDN']
	String userSearchBase = env['JENKINS_LDAP_SEARCH_BASE']
	String userSearch = env['JENKINS_LDAP_USER_SEARCH'] ?: 'uid{0}'
	String groupSearchBase = env['JENKINS_LDAP_GROUP_SEARCH']
	String managerDN = env['JENKINS_LDAP_MANAGER_DN']
	String managerPassword = env['JENKINS_LDAP_MANAGER_PASSWORD']
	boolean inhibitInferRootDN = false

	def instance = Jenkins.getInstance()

	SecurityRealm ldap_realm = new LDAPSecurityRealm(server, rootDN, userSearchBase, userSearch, groupSearchBase, managerDN, managerPassword, inhibitInferRootDN) 
	instance.setSecurityRealm(ldap_realm)

	instance.save()
}

void configureAuthorizationStrategy(Map env) {
	String authorizationStrategy = env['AUTHORIZATION_STRATEGY'] ?: 'FULL_CONTROL'
	println "* configuring " + authorizationStrategy + " authorization strategy"
	def instance = Jenkins.getInstance()
	if('FULL_CONTROL'.equals(authorizationStrategy)) {
		def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
		instance.setAuthorizationStrategy(strategy)
	} else if ('MATRIX'.equals(authorizationStrategy)) {
		def strategy = new GlobalMatrixAuthorizationStrategy()
		String authorizedEntities = env['AUTHORIZED_ENTITIES'] ?: ''
		for(entity in authorizedEntities.split(",")) {
			println "defining permissions using GlobalMatrixAuthorizationStrategy for " + entity
			if("administrators".equals(entity)) {
				println "* adding " + entity + " has Jenkins.ADMINISTER"
				strategy.add(Jenkins.ADMINISTER, entity)
				strategy.add(Jenkins.RUN_SCRIPTS, entity)
			}
			addGeneralPermissions(strategy, entity)
		}
		instance.setAuthorizationStrategy(strategy)
	}
	instance.save()
}

void addGeneralPermissions(GlobalMatrixAuthorizationStrategy strategy, String entity) {
	strategy.add(Jenkins.READ, entity)
	// Slave - http://javadoc.jenkins-ci.org/jenkins/model/Jenkins.MasterComputer.html
	strategy.add(Jenkins.MasterComputer.BUILD, entity)  
	strategy.add(Jenkins.MasterComputer.CONFIGURE, entity)  
	strategy.add(Jenkins.MasterComputer.CONNECT, entity)  
	strategy.add(Jenkins.MasterComputer.CREATE, entity)  
	strategy.add(Jenkins.MasterComputer.DELETE, entity)  
	strategy.add(Jenkins.MasterComputer.DISCONNECT, entity)
	 
	// Job - http://javadoc.jenkins-ci.org/hudson/model/Item.html
	strategy.add(Item.BUILD, entity)  
	strategy.add(Item.CANCEL, entity)  
	strategy.add(Item.CONFIGURE, entity)  
	strategy.add(Item.CREATE, entity)  
	strategy.add(Item.DELETE, entity)  
	strategy.add(Item.DISCOVER, entity)  
	strategy.add(Item.EXTENDED_READ, entity)  
	strategy.add(Item.READ, entity)  
	strategy.add(Item.WIPEOUT, entity)  
	strategy.add(Item.WORKSPACE, entity)
	 
	// View - http://javadoc.jenkins-ci.org/hudson/model/View.html
	strategy.add(View.CONFIGURE, entity)  
	strategy.add(View.CREATE, entity)  
	strategy.add(View.DELETE, entity)  
	strategy.add(View.READ, entity)
	 
	// Run - http://javadoc.jenkins-ci.org/hudson/model/Run.html
	strategy.add(Run.ARTIFACTS, entity)  
	strategy.add(Run.DELETE, entity)  
	strategy.add(Run.UPDATE, entity)
	 
	// Credentials - https://github.com/jenkinsci/credentials-plugin/blob/master/src/main/java/com/cloudbees/plugins/credentials/CredentialsProvider.java
	strategy.add(CredentialsProvider.CREATE, entity)  
	strategy.add(CredentialsProvider.UPDATE, entity)  
	strategy.add(CredentialsProvider.VIEW, entity)  
	strategy.add(CredentialsProvider.DELETE, entity)  
	strategy.add(CredentialsProvider.MANAGE_DOMAINS, entity)
	 
	// Plugin Manager http://javadoc.jenkins-ci.org/hudson/PluginManager.html
	strategy.add(PluginManager.UPLOAD_PLUGINS, entity)  
	strategy.add(PluginManager.CONFIGURE_UPDATECENTER, entity)
}