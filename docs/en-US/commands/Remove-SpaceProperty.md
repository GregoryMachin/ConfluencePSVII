---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Remove-SpaceProperty/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Remove-SpaceProperty/
---
# Remove-SpaceProperty

## SYNOPSIS

Delete a Confluence Cloud space property.

## SYNTAX

```powershell
Remove-ConfluenceSpaceProperty -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceID <UInt64> -PropertyID <UInt64[]> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Delete one or more existing space properties by ID.

This is a Cloud-only operation: space properties do not exist in the legacy v1/Data Center
content model at all, so there is no -DeploymentType parameter here and -BaseUri is mandatory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Remove-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PropertyID 1000 -Confirm
```

Deletes property 1000 from space 98307, prompting for confirmation first.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "temp.*" |
    Remove-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -WhatIf
```

Simulates deleting every property piped in.
-WhatIf prevents any changes.

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

Certificate for authentication.

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

The Id of the space the property is attached to.

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

The property ID(s) to delete.
Accepts multiple IDs via pipeline input.

```yaml
Type: UInt64[]
Parameter Sets: (All)
Aliases: ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -WhatIf

Shows what would happen if the cmdlet runs.
The cmdlet is not run.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: wi

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm

Prompts you for confirmation before running the cmdlet.

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases: cf

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

### System.Boolean

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
