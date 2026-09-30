---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-PageVersion/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-PageVersion/
---
# Get-PageVersion

## SYNOPSIS

Retrieve the version history of a wiki page, or a single historical revision.

## SYNTAX

### byList (Default)

```powershell
Get-ConfluencePageVersion -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>]
 [-Credential <PSCredential>] [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-PageID] <UInt64> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### byVersion

```powershell
Get-ConfluencePageVersion -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>]
 [-Credential <PSCredential>] [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-PageID] <UInt64> -VersionNumber <UInt32> [-IncludeBody] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>]
```

## DESCRIPTION

Without -VersionNumber, returns the full version history of a page as a list of
`ConfluencePSVII.Version` objects -- useful for auditing who changed a page and when.

With -VersionNumber, returns that single historical revision as a `ConfluencePSVII.Page` object.
Pass -IncludeBody to also fetch that revision's content, for example to compare it against the
current page or to plan a rollback.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluencePageVersion -PageID 196608
```

Returns the full version history of page 196608.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluencePageVersion -PageID 196608 -VersionNumber 3
```

Returns version 3 of page 196608's metadata, without its body.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluencePageVersion -PageID 196608 -VersionNumber 3 -IncludeBody
```

Returns version 3 of page 196608, including its historical body content.

## PARAMETERS

### -ApiUri

The URi of the API interface.
Value can be set persistently with Set-ConfluenceInfo.

```yaml
Type: Uri
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -BaseUri

The site's base URi, used together with -DeploymentType to route to Confluence Cloud REST API v2's dedicated version resources.
Without it, requests fall back to the v1 route regardless of -DeploymentType.
The -VersionNumber path on Cloud v2 is based on the same field conventions as the main page v2 response and has not been live-verified; see docs/api-contract-inventory.md.
Value can be set persistently with Set-ConfluenceInfo.

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

### -DeploymentType

Selects Confluence Cloud REST API v2 routing when set to `Cloud` and -BaseUri is also supplied.
Value can be set persistently with Set-ConfluenceInfo.

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

### -Credential

Confluence's credentials for authentication.
Value can be set persistently with Set-ConfluenceInfo.

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

Confluence's Personal Access Token for authentication.
Value can be set persistently with Set-ConfluenceInfo.

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

### -Certificate

Certificate to use for the authentication with the REST Api.

```yaml
Type: X509Certificate
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageID

The ID of the page whose version history to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -VersionNumber

The specific version number to retrieve.
When omitted, the full version-history list is returned instead.

```yaml
Type: UInt32
Parameter Sets: byVersion
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeBody

Also fetch the historical body content for -VersionNumber.

```yaml
Type: SwitchParameter
Parameter Sets: byVersion
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum number of results to fetch per call.

```yaml
Type: UInt32
Parameter Sets: byList
Aliases:

Required: False
Position: Named
Default value: 25
Accept pipeline input: False
Accept wildcard characters: False
```

### -IncludeTotalCount

>NOTE: Not yet implemented.

Causes an extra output of the total count at the beginning.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Skip

Controls how many things will be skipped before starting output.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -First

> NOTE: Not yet implemented.

Indicates how many items to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 18446744073709551615
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### ConfluencePSVII.Version

### ConfluencePSVII.Page

## NOTES

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
