---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.OAuthResource/
---

# ConfluencePS.OAuthResource

## SYNOPSIS

Defines an object for one Atlassian Cloud resource (typically a Confluence site) an OAuth 2.0
(3LO) access token can reach.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.OAuthResource [-Property @{}]

[ConfluencePS.OAuthResource]@{}
```

## DESCRIPTION

The `OAuthResource` is an object returned by `Get-ConfluenceOAuthResource`, one per Atlassian
Cloud site (or other product) an OAuth 2.0 (3LO) access token is authorized to reach. Its
`CloudId` is the identifier used to build the Cloud API gateway URI
(`https://api.atlassian.com/ex/confluence/{CloudId}`) that `Set-ConfluenceInfo` configures as
`-BaseUri` for an OAuth-authenticated Cloud session.

## REFERENCES

_No other class currently references `OAuthResource`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### CloudId

The resource's Cloud ID, a UUID, normalized to lowercase with hyphens.

```yaml
Type: String
Required: True
Default value: None
```

### Name

The resource's display name, for example the Confluence site's name.

```yaml
Type: String
Required: True
Default value: None
```

### Url

The resource's site URL, for example `https://example.atlassian.net/`.

```yaml
Type: Uri
Required: True
Default value: None
```

### Scopes

The OAuth scopes the access token is authorized for on this resource.

```yaml
Type: String[]
Required: False
Default value: None
```

### AvatarUrl

The resource's avatar image URL, if one was returned. `$null` when not returned or not a valid
absolute URI.

```yaml
Type: Uri
Required: False
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$CloudId] $Name`.
