---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Get-SpaceProperty.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Get-SpaceProperty

## SYNOPSIS

Retrieve Confluence Cloud space properties.

## SYNTAX

### byKey (Default)

```powershell
Get-ConfluenceSpaceProperty -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceID <UInt64> [-Key <String>] [-PageSize <UInt32>] [-IncludeTotalCount]
 [-Skip <UInt64>] [-First <UInt64>]
```

### byId

```powershell
Get-ConfluenceSpaceProperty -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceID <UInt64> -PropertyID <UInt64[]> [-PageSize <UInt32>] [-IncludeTotalCount]
 [-Skip <UInt64>] [-First <UInt64>]
```

## DESCRIPTION

Return Confluence Cloud space properties, filtered by property ID or by key, or list all
properties on a space.

This is a Cloud-only operation: space properties do not exist in the legacy v1/Data Center
content model at all, so there is no -DeploymentType parameter here and -BaseUri is mandatory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307
```

Returns every property on space 98307.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "my-app.settings"
```

Returns the property with key "my-app.settings" on space 98307.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000
```

Returns the property with ID 1000 on space 98307.

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

The Cloud site's base URi, used to route requests to Confluence Cloud REST API v2's dedicated space-properties resource.
Mandatory, since this operation has no v1/Data Center equivalent.
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

### -SpaceID

The Id of the space whose properties to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -PropertyID

Filter results by property ID.

```yaml
Type: UInt64[]
Parameter Sets: byId
Aliases: ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -Key

Filter results by property key.

```yaml
Type: String
Parameter Sets: byKey
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum number of results to fetch per call.

```yaml
Type: UInt32
Parameter Sets: (All)
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

### ConfluencePSVII.SpaceProperty

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
