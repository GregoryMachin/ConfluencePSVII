---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-SpaceRoleAssignment/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-SpaceRoleAssignment/
---
# Get-SpaceRoleAssignment

## SYNOPSIS

Retrieve the current space-role assignments on a Confluence Cloud space.

## SYNTAX

```powershell
Get-ConfluenceSpaceRoleAssignment -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-SpaceID] <UInt64> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>]
```

## DESCRIPTION

Return every current space-role assignment on a space: for each assignment, the principal
(a user or a group) and the assigned role.

This is a Cloud-only operation: space role assignments are exposed as a dedicated queryable
resource only by Cloud v2, with no v1/Data Center equivalent, so there is no -DeploymentType
parameter here and -BaseUri is mandatory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceSpaceRoleAssignment -BaseUri "https://example.atlassian.net" -SpaceID 98307
```

Returns every role assignment on space 98307.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceSpaceRoleAssignment -BaseUri "https://example.atlassian.net" -SpaceID 98307 |
    Where-Object RoleName -eq 'Admin'
```

Returns only the admins of space 98307.

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

The Cloud site's base URi, used to route requests to Confluence Cloud REST API v2's dedicated space-role-assignments resource.
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

The Id of the space whose role assignments to return.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName)
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

### ConfluencePSVII.SpaceRoleAssignment

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
