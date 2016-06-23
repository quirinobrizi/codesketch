import jenkins.model.*
import hudson.security.*
import org.jenkinsci.plugins.*

def env = System.getenv()
String securityType = env["SECURITY_TYPE"] ?: 'PASSWORD';
println "* Configuring security " + securityType + "for JENKINS instance"
if(['PASSWORD', 'LDAP'].contains(securityType)) {
	configureSecurity(securityType, env)
} else {
	println "security type " + securityType + "is not supported, supported are PASSWORD, LDAP";
}

void configureSecurity(String securityType, Map env) {
	if("PASSWORD".equalsIgnoreCase(securityType)) {
		configurePasswordBasedSecurity(env)
	} else {
		configureLdapBasedSecurity(env)
	}
}

void configurePasswordBasedSecurity(Map env) {
	String username = env['JENKINS_USERNAME'] ?: "admin"
	String password = env['JENKINS_PASSWORD'] ?: "password"

	def instance = Jenkins.getInstance()

	// Create admin user
	def hudsonRealm = new HudsonPrivateSecurityRealm(false)
	hudsonRealm.createAccount(username, password)
	instance.setSecurityRealm(hudsonRealm)

	// Grant admin privilege
	def strategy = new GlobalMatrixAuthorizationStrategy()
	strategy.add(Jenkins.ADMINISTER, username)
	instance.setAuthorizationStrategy(strategy)

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

	def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
	instance.setAuthorizationStrategy(strategy)

	instance.save()
}