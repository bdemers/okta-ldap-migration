Okta LDAP Migration Lab
=====================

**Background:**

The application stores usernames and passwords in an LDAP Server. This lab will migrate those users to Okta.

**TODO:**
- [ ] Deal with passwords through files (`docker-compose.yml`)
- [ ] Flush out readme
- [ ] Change name of `web-app` and it's Maven artifactId
- [ ] Requires feature: `LDAP_INTERFACE_APP_GROUP_SUPPORT`
- [ ] Lots of TODO's in this readme
- [ ] Test this doc on a clean org 

**Prerequisites** 
- [Docker](https://docs.docker.com/get-docker/)
- [openldap](https://www.openldap.org/) - Optional, the `ldapsearch` command is used to test a connection.

Clone this repo:

```bash
git clone https://github.com/TBD -b ldap-users
cd TBD
```

Start up the application:

```bash
docker compose up
```

Open a browser to `http://localhost:8080`
Login with the database user `user01` and `password1`.

Success!

## Migrate Users to Okta

Create an Okta account using the Okta CLI:

```bash
okta register
```

Make a note of your Okta URL.

### Set up  the Okta LDAP Agent

Checkout the `agent` branch which contains a Docker image that runs the Okta LDAP Agent. For more information on other 
installation options see [Okta's LDAP Agent documentation](https://help.okta.com/en/prod/Content/Topics/Directory/ldap-agent-manage-integration.htm).

Rebuild the images:

```bash
# stop the current running containers with ^C or by running:
# docker compose down

# Build the containers
docker compose build
```

Create a `.env` file to store Okta related configuration:

```bash
OKTA_URL="https://dev-123456.okta.com" docker compose up
```

> **NOTE:** The first time the container starts you will be prompted to link the Okta LDAP Agent with your account, follow the instructions in your console.

The Okta LDAP Agent is now connected to the LDAP server and Okta, but it still needs to be configured via the Okta Admin Console.
Open the Okta Admin Console and navigate to **Directory** -> **Directory Integrations**, and select **LDAP**.

> **TODO:** Is there an API for this?

The **ldap-agent** should be green if it isn't, see the troubleshooting section. 

Open the **Provisioning** tab and select **Integration**. This is where you configure the details of the LDAP server, Okta provides defaults, but everyone does LDAP a little different so you may need to tweak things.  For this lab update the following values:

> **TODO:** add a troubleshooting section.
 

| Property            | Value                         | Description                               |
|---------------------|-------------------------------|-------------------------------------------|
| Group Search Base   | `ou=groups,dc=example,dc=org` | The full search path for your grouops     |
| Group Object Class  | `posixgroup`                  | The object class for your groups          |
| Group Object Filter | `(objectclass=posixgroup)`    | The group search filter                   |
| Member Attribute    | `memberuid`                   | The attribute that contains the user's dn |

Test the configuration with the username: `user01@example.com`

This will show the results:

| Status             | Active                                    |
|--------------------|-------------------------------------------|
| UID                | user01                                    |
| Unique ID          | `<generated-id>`                          |
| Distinguished Name | `cn=user01, ou=users, dc=example, dc=org` |
| Full Name          | User1 Bar1                                |
| Email              | `user01@example.com`                      |
| Groups             | `cn=allusers,ou=groups,dc=example,dc=org` |

Press the **Update Configuration** button to save.

### Import the users and groups

After making changes to the LDAP configuration, import the users by selecting the **Import** tab.
Click **Import Now** -> **Import** to see all the available users to import.
Click **OK** on the dialog that shows the statistics summary.

Select all available users and press the **Confirm Assignments** button.

All the LDAP users and groups have been imported!

## Update application to point to Okta's LDAP Interface

To minimize changes needed to migrate your applications to Okta. You can expose your Okta users and groups through an Okta's LDAP interface.

> **NOTE:** The LDAP configuration your application uses will likely need to change as Okta's structure will be different from the original directory.

We recommend updating your application to use OpenID Connect (see below section), so this section is optional.

### Enable the Okta LDAP Interface

In the Okta Admin Console select **Directory** -> **Directory Integrations**, and select **Add Directory** -> **Add LDAP Directory**.
Edit this directory's configuration and change **Configuration** to **Okta groups and app groups**.

Update the `.env` environment file with the following values from this page:

| Key                  | Value (example)                    | Description                                                                                                                                                       |
|----------------------|------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `OKTA_LDAP_HOST`     | `dev-123456.ldap.okta.com`         | Host                                                                                                                                                              |
| `OKTA_LDAP_BASE`     | `dc=dev-11013022, dc=okta, dc=com` | Base DN                                                                                                                                                           |
| `OKTA_LDAP_ID`       | `0oa123456abcd123`                 | The ID of the directory integration, found in the URL of integration named **LDAP**.  the URL should look something like: `/admin/app/ldap_sun_one/instance/{ID}` |
| `OKTA_LDAP_USERNAME` | `ldap-user`                        | A static user that has access to read user group information, see following section on how to create a user with restricted access                                |
| `OKTA_LDAP_PASSWORD` | `<change-me>`                      | Password for above user                                                                                                                                           |

### Create a user to access the Okta LDAP Interface

In the Okta Admin Console, select **Directory** -> **People** -> **Add People** and enter the following values, the press **Save**.

| Field Name                               | Value                   |
|------------------------------------------|-------------------------|
| First name                               | LDAP                    |
| Last name                                | User                    |
| Username                                 | `ldap-user@example.com` |
| I will set password                      | `<change-me>`           |
| User must change password on first login | false                   |

#### Create an Admin role

Select **Security** -> **Administrators** -> **Resources** -> **Create new resource set**.  Give it the name "Users & Groups".
Add the **Resource type** -> **Users**, then press **Add another resource type**, and select **Groups**.
Press **Save resource set**.

Select the **Roles** tab -> **Create new role**, enter the following values:

| Field Name   | Value         |
|--------------|---------------|
| Name         | groups-reader |
| Description  | Groups Reader |

Under **Users** select **View users and their details**. and under **Groups** select **View groups and their details**.
Press **Save role**.

#### Assign role to user

Select the **Admins** tab -> **Add administrator**, type `ldap-user@example.com`, select the **Role** "group-reader", and press **Save Changes**.

You can test the user's access using the `ldapsearch` command (update values with your configuration):

```bash
ldapsearch -x -b "ou=groups,dc=dev-123456,dc=okta,dc=com" -H ldaps://dev-123456.ldap.okta.com:636 -Duid=ldap-user,dc=dev-123456,dc=okta,dc=com -w '<change-me>'
```

The result will be a list of groups with `uniqueMember` attributes.

Restart the application:

```bash
# stop the docker compose process if it is running with ^C

# rebuild the application containing our changes
docker compose build
# start the application
docker compose up
```

Open a private/incognito window the same URL as before `http://localhost:8080`, this time you will be redirected to Okta
to sign-in. Sign in with the user's email address and password: `user01` and `password1`.

> **TODO:** Add link to commit to show what changed in application

## Update the application to use OAuth 2.0/OIDC 

Checkout the `main` branch which updates the code in the project to replace the LDAP 
authentication with OpenID Connect (OIDC).

```bash
git checkout `main`
```

> **TODO:** Add a link to the diff to explain what changed?

## Create an Okta OIDC Application

Register your application with Okta, run:

```bash
okta start
```

## Restart and Sign-In with Okta

Restart the application

```bash
# stop the docker compose process if it is running with ^C

# rebuild the application containing our changes
docker compose build
# start the application
docker compose up
```

Open a private/incognito window the same URL as before `http://localhost:8080`, this time you will be redirected to Okta
to sign-in. Sign in with the user's email address and password: `user01@example.com` and `password1`.

> **NOTE:** The initial version of this application used simple usernames e.g. `user01`. Okta default to using email 
> addresses for usernames e.g. `user01@example.com`.  You can configure [Okta to use simple usernames if needed](https://support.okta.com/help/s/article/How-can-I-remove-the-format-restriction-for-Okta-Username-from-using-an-email-address-format?language=en_US).


## Migrate users from LDAP to Okta

The LDAP users are already stored in Okta, but the password is managed by the LDAP server. Users can be completely migrated to Okta, see:
[Okta Help Center article](https://support.okta.com/help/s/question/0D50Z00008Vr0MLSAZ/migrating-users-from-ldap-to-okta-universal-directory?language=en_US)

> **NOTE:** This will require resetting the user's passwords.  If you do not want to reset all user passwords, you could use a Okta Password Import Hook, 
> See the [DB user migration guide](#TBD) for a similar example.