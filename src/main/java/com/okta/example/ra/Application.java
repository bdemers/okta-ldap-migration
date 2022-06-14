package com.okta.example.ra;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.annotation.Bean;
import org.springframework.ldap.core.support.BaseLdapPathContextSource;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.ldap.LdapBindAuthenticationManagerFactory;
import org.springframework.security.core.Authentication;
import org.springframework.security.ldap.userdetails.DefaultLdapAuthoritiesPopulator;
import org.springframework.security.ldap.userdetails.PersonContextMapper;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.servlet.ModelAndView;

import java.util.Map;

@SpringBootApplication
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

    @Bean
    public SecurityFilterChain filterChain(HttpSecurity http) throws Exception {
        http
            .authorizeHttpRequests((authz) -> authz
                .anyRequest().authenticated()
            )
            .formLogin();
        return http.build();
    }

    @Bean
    AuthenticationManager ldapAuthenticationManager(BaseLdapPathContextSource contextSource, @Value("${okta.ldap.id}")String oktaLdapId) {
        LdapBindAuthenticationManagerFactory factory = new LdapBindAuthenticationManagerFactory(contextSource);
        factory.setUserDnPatterns("uid={0}@example.com,ou=users", "uid={0},ou=users"); // allow users to sign in with username or email address
        factory.setUserDetailsContextMapper(new PersonContextMapper());

        // if you want all Okta groups (Okta defined and original LDAP Groups)
        // DefaultLdapAuthoritiesPopulator ldapAuthoritiesPopulator = new DefaultLdapAuthoritiesPopulator(contextSource, "ou=groups");
        // ldapAuthoritiesPopulator.setGroupSearchFilter("(uniqueMember={0})");
        // ldapAuthoritiesPopulator.setSearchSubtree(true);

        // otherwise if you just want the original LDAP Groups
        DefaultLdapAuthoritiesPopulator ldapAuthoritiesPopulator = new DefaultLdapAuthoritiesPopulator(contextSource, "cn=" + oktaLdapId + ",ou=apps,ou=groups");
        ldapAuthoritiesPopulator.setGroupSearchFilter("(uniqueMember={0})");

        factory.setLdapAuthoritiesPopulator(ldapAuthoritiesPopulator);
        return factory.createAuthenticationManager();
    }

    @Controller
    static class ProfileController {

        @GetMapping("/")
        public String home() {
            return "home";
        }

        @GetMapping("/profile")
        public ModelAndView userDetails(Authentication authentication) {
            return new ModelAndView("userProfile" , Map.of(
                    "user", authentication.getPrincipal(),
                    "simpleAuth", authentication instanceof UsernamePasswordAuthenticationToken));
        }
    }
}
