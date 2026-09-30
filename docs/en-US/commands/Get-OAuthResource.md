---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-OAuthResource/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-OAuthResource/
---
# Get-OAuthResource

## SYNOPSIS

Discover the Confluence sites an OAuth 2.0 (3LO) access token can reach.

## SYNTAX

### default (Default)

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken <SecureString>
```

### byCloudId

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken <SecureString> -CloudId <String>
```

### bySiteName

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken <SecureString> -SiteName <String>
```

### bySiteUrl

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken <SecureString> -SiteUrl <Uri>
```

## DESCRIPTION

Calls Atlassian's `https://api.atlassian.com/oauth/token/accessible-resources` endpoint to list
every Atlassian Cloud resource (typically a Confluence site) the given OAuth 2.0 (3LO) access
token is authorized to reach, and returns the resulting `ConfluencePSVII.OAuthResource` objects.

This is an Atlassian identity endpoint, external to any single Confluence site: there is no
-BaseUri or -DeploymentType parameter, and the request is never resolved through
Resolve-ConfluenceRoute. The returned `CloudId` is what `Set-ConfluenceInfo -CloudId` uses to
configure an OAuth-authenticated Cloud session's -BaseUri.

Supply at most one of -CloudId, -SiteName, or -SiteUrl to narrow the result to a single
resource; the command throws if that selector matches zero or more than one resource. With no
selector, every accessible resource is returned.

This response shape has not been live-verified against a Cloud tenant; see
docs/api-contract-inventory.md.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken $token
```

Returns every Atlassian Cloud resource the access token can reach.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceOAuthResource -OAuthAccessToken $token -SiteUrl "https://example.atlassian.net"
```

Returns the single resource for `https://example.atlassian.net`, throwing if the token cannot
reach that site.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
$resource = Get-ConfluenceOAuthResource -OAuthAccessToken $token -SiteName "Example Site"
Set-ConfluenceInfo -OAuthAccessToken $token -CloudId $resource.CloudId
```

Discovers a site's Cloud ID by name, then configures an OAuth-authenticated Cloud session for
it.

## PARAMETERS

### -OAuthAccessToken

The OAuth 2.0 (3LO) access token to authenticate the discovery request with.

```yaml
Type: SecureString
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CloudId

Filter the result to the single resource with this Cloud ID. Mutually exclusive with -SiteName
and -SiteUrl.

```yaml
Type: String
Parameter Sets: byCloudId
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteName

Filter the result to the single resource with this display name. Mutually exclusive with
-CloudId and -SiteUrl.

```yaml
Type: String
Parameter Sets: bySiteName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SiteUrl

Filter the result to the single resource with this site URL. Mutually exclusive with -CloudId
and -SiteName.

```yaml
Type: Uri
Parameter Sets: bySiteUrl
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### ConfluencePSVII.OAuthResource

## NOTES

Cloud v2 only. See the DESCRIPTION for why there is no -BaseUri or -DeploymentType parameter.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
