---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-Info/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-Info/
---
# Set-Info

## SYNOPSIS

Specify wiki location and authorization for use in this session's REST API requests.

## SYNTAX

```powershell
Set-ConfluenceInfo [-BaseURi <Object>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-OAuthAccessToken <SecureString>] [-CloudId <String>]
 [-OAuthClientId <String>] [-OAuthClientSecret <SecureString>] [-SiteName <String>] [-SiteUrl <Uri>]
 [-Certificate <X509Certificate>] [-PageSize <UInt32>] [-PromptCredentials]
```

## DESCRIPTION

Set-ConfluenceInfo uses scoped variables and PSDefaultParameterValues to supply
URI/auth info to all other functions in the module (e.g. Get-ConfluenceSpace).
These session defaults can be overwritten on any single command, but using
Set-ConfluenceInfo avoids repetitively specifying -ApiUri and -Credential parameters.
The `-BaseUri` parameter still accepts the legacy URI or string value.
It also accepts an AtlassianPSVII.Configuration server entry from the pipeline or by property name.
When the entry includes `Product`, `DeploymentType`, `AuthenticationType`, or `CloudId`, ConfluencePSVII keeps that metadata in the current module session and uses it to build a deterministic REST API URI.

`-OAuthAccessToken` and `-CloudId` configure an OAuth 2.0 (3LO) Cloud session from a caller-supplied access token, without needing an AtlassianPSVII.Configuration entry: they are mutually exclusive with `-BaseUri`, and both must be supplied together. Use `Get-ConfluenceOAuthResource` to discover a site's `CloudId` from the token itself. The access token is reused as this session's `-PersonalAccessToken` default, since Confluence's REST API already accepts an OAuth access token the same way it accepts a Data Center Personal Access Token: as an `Authorization: Bearer` header.

`-OAuthClientId` and `-OAuthClientSecret` configure a fully non-interactive OAuth 2.0 client-credentials session for a service account: ConfluencePSVII exchanges the client credentials for an access token, discovers which site(s) it can reach, and configures the session the same way `-OAuthAccessToken` does. When the client credentials can reach more than one site, supply `-CloudId`, `-SiteName`, or `-SiteUrl` to pick one; otherwise the command throws rather than guessing. ConfluencePSVII has no session object to cache this token in, so the token exchange happens again on every `Set-ConfluenceInfo -OAuthClientId` call.

Confluence's REST API supports passing basic authentication in headers. For
Confluence Cloud, use your Atlassian account email address as the username and
an Atlassian API token as the password. Do not use your Atlassian account
password for Cloud authentication.

Unless allowing anonymous access to your instance, credentials are needed.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
$Cred = Get-Credential -UserName 'me@example.com'
Set-ConfluenceInfo -BaseURI 'https://yournamehere.atlassian.net/wiki' -Credential $Cred
```

Declare the URI of your Confluence Cloud instance and authenticate with an
Atlassian account email address and API token. When prompted, enter the API
token as the password. Cloud instances use the /wiki subdirectory.
When explicit Cloud metadata is supplied, ConfluencePSVII normalizes the REST API URI to `/wiki/rest/api`.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com'
```

Declare the URI of your Confluence instance. You will not be prompted for credentials,
and other commands would attempt to connect anonymously with read-only permissions.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Set-ConfluenceInfo -BaseURI 'https://wiki.contoso.com' -PromptCredentials -PageSize 50
```

Declare the URI of your Confluence instance; be prompted for username and password.
Set the default "page size" for all your commands in this session to 50 (see Notes).

### -------------------------- EXAMPLE 4 --------------------------

```powershell
$Cred = Get-Credential
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -Credential $Cred
```

Declare the URI of your Confluence instance and the credentials. For Confluence
Cloud, the credential username is your Atlassian account email address and the
password is an Atlassian API token.

### -------------------------- EXAMPLE 5 --------------------------

```powershell
$Pat = '<personal-access-token>'
Set-ConfluenceInfo -BaseURI 'https://wiki.yourcompany.com' -PersonalAccessToken $Pat
```

Declare the URI of your Confluence instance and the Personal Access Token. 
See: <https://confluence.atlassian.com/enterprise/using-personal-access-tokens-1026032365.html>

### -------------------------- EXAMPLE 6 --------------------------

```powershell
Get-AtlassianServerConfiguration -Name 'Confluence Cloud' | Set-ConfluenceInfo
```

Configure ConfluencePSVII from an AtlassianPSVII.Configuration server entry.
Explicit Cloud metadata preserves `/wiki`, and explicit Data Center metadata preserves custom context paths such as `/confluence`.

### -------------------------- EXAMPLE 7 --------------------------

```powershell
$resource = Get-ConfluenceOAuthResource -OAuthAccessToken $token -SiteUrl 'https://yournamehere.atlassian.net'
Set-ConfluenceInfo -OAuthAccessToken $token -CloudId $resource.CloudId
```

Discover a site's Cloud ID from an OAuth 2.0 (3LO) access token, then configure an
OAuth-authenticated Cloud session for it. `-BaseUri`/`-ApiUri` are computed automatically as
the Cloud API gateway address for that Cloud ID.

### -------------------------- EXAMPLE 8 --------------------------

```powershell
$clientSecret = Read-Host -AsSecureString -Prompt 'Client secret'
Set-ConfluenceInfo -OAuthClientId $clientId -OAuthClientSecret $clientSecret -SiteUrl 'https://yournamehere.atlassian.net'
```

Configure a fully non-interactive OAuth 2.0 client-credentials session for a service account,
selecting a specific site by URL when the client credentials can reach more than one.

## PARAMETERS

### -BaseURi

Address of your base Confluence install, or a configuration object with a `Uri` property.
Configuration objects can also include `Product`, `DeploymentType`, `AuthenticationType`, and `CloudId` metadata.
Only Confluence entries are accepted.
For Atlassian Cloud instances, include /wiki unless explicit Cloud metadata is supplied.
Cloud and OAuth entries must use HTTPS.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:
- Uri

Required: False
Position: Named
Default value: None
Accept pipeline input: True
Accept wildcard characters: False
```

### -Credential

The username/password combo used to authenticate to Confluence. For Confluence
Cloud, use your Atlassian account email address as the username and an Atlassian
API token as the password.

```yaml
Type: PSCredential
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PersonalAccessToken

The PersonalAccessToken you created in your Confluence User Settings. This is
for Confluence Data Center and Server personal access tokens. For Confluence
Cloud, use the -Credential parameter with your Atlassian account email address
and an Atlassian API token.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OAuthAccessToken

An OAuth 2.0 (3LO) Cloud access token. Requires `-CloudId`; mutually exclusive with `-BaseUri`.
Configures an OAuth-authenticated Cloud session and is also used as this session's
`-PersonalAccessToken` default.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CloudId

The Cloud ID of the Confluence site the OAuth access token authenticates to. Required with
`-OAuthAccessToken`. Discover it with `Get-ConfluenceOAuthResource`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OAuthClientId

The OAuth 2.0 client ID for a non-interactive service-account session. Requires
`-OAuthClientSecret`; mutually exclusive with `-BaseUri` and `-OAuthAccessToken`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -OAuthClientSecret

The OAuth 2.0 client secret for a non-interactive service-account session. Requires
`-OAuthClientId`.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteName

Selects a single site by display name when `-OAuthClientId`/`-OAuthClientSecret` can reach more
than one. Only valid together with `-OAuthClientId`/`-OAuthClientSecret`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteUrl

Selects a single site by URL when `-OAuthClientId`/`-OAuthClientSecret` can reach more than
one. Only valid together with `-OAuthClientId`/`-OAuthClientSecret`.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Default PageSize for the invocations.
More info in the Notes field of this help file.

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -PromptCredentials

Prompt the user for credentials

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

The default page size for all commands is 25.
Using the -PageSize parameter changes the default for all commands in your current session.

Tweaking PageSize can help improve pipeline performance when returning many objects.
See related links for implementation discussion and details.

(If you don't know exactly what this means, feel free to ignore it.)

For Confluence Cloud authentication, create an API token at
https://id.atlassian.com/manage-profile/security/api-tokens. Use your Atlassian
account email address as the credential username and paste the API token as the
credential password. The BaseURI must include /wiki, for example
https://yournamehere.atlassian.net/wiki.
If an AtlassianPSVII.Configuration entry explicitly sets `DeploymentType = 'Cloud'`,
ConfluencePSVII adds `/wiki` when it is missing.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)

[ConfluencePSVII PR#59: Add proper Paging to Get functions](https://github.com/AtlassianPS/ConfluencePS/pull/59)

[about_ConfluencePSVII_Authentication](/docs/ConfluencePS/about/authentication.html)

[Manage API tokens for your Atlassian account](https://support.atlassian.com/atlassian-account/docs/manage-api-tokens-for-your-atlassian-account/)
