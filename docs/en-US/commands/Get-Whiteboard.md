---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Get-Whiteboard.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Get-Whiteboard

## SYNOPSIS

Retrieve Confluence Cloud whiteboards.

## SYNTAX

### byId (Default)

```powershell
Get-ConfluenceWhiteboard -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-WhiteboardID] <UInt64[]> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>]
```

### bySpace

```powershell
Get-ConfluenceWhiteboard -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceKey <String> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>]
```

## DESCRIPTION

Return Confluence Cloud whiteboards, filtered by ID or by space.

This is a Cloud-only operation: Confluence whiteboards do not exist in the legacy v1/Data
Center content model at all, so there is no -DeploymentType parameter here and -BaseUri is
mandatory.

This is a read-only command. Write support (New-/Set-/Remove-ConfluenceWhiteboard) is
deliberately deferred until this read model is proven stable.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceWhiteboard -BaseUri "https://example.atlassian.net" -WhiteboardID 524288
```

Returns the whiteboard with ID 524288.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceWhiteboard -BaseUri "https://example.atlassian.net" -SpaceKey HOTH
```

Returns all whiteboards in space "HOTH".

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

The Cloud site's base URi, used to route requests to Confluence Cloud REST API v2's dedicated whiteboards resource.
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

### -WhiteboardID

Filter results by whiteboard ID.

```yaml
Type: UInt64[]
Parameter Sets: byId
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -SpaceKey

Filter results by space key (case-insensitive).

```yaml
Type: String
Parameter Sets: bySpace
Aliases: Key

Required: True
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

### ConfluencePSVII.Whiteboard

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
