---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Set-SpaceRoleAssignment.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Set-SpaceRoleAssignment

## SYNOPSIS

Assign a Confluence Cloud space role to a user or group.

## SYNTAX

```powershell
Set-ConfluenceSpaceRoleAssignment -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceID <UInt64> -PrincipalType <String> -PrincipalID <String> -RoleID <String>
 [-WhatIf] [-Confirm]
```

## DESCRIPTION

Assign (or change) a space role for a principal (a user or a group). This is the only
mutation surface Confluence Cloud v2 exposes for space access governance -- individual
permission grants (Get-ConfluenceSpacePermission) cannot be changed directly, only role
assignments.

This is a Cloud-only operation: role assignments have no v1/Data Center equivalent, so there
is no -DeploymentType parameter here and -BaseUri is mandatory.

This command is high-impact by design: changing or removing a principal's role can revoke
their access to the entire space, so a confirmation prompt appears unless -Confirm:$false is
passed explicitly. Genuine self-lockout detection (warning when you are about to remove your
own admin access) would require resolving your own Cloud account ID, which this module has no
command for yet -- review the target principal and role carefully before confirming a change
to your own account.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Set-ConfluenceSpaceRoleAssignment -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PrincipalType user -PrincipalID "712020:aaaa" -RoleID "role-viewer"
```

Assigns the Viewer role to the given user on space 98307, prompting for confirmation first.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Set-ConfluenceSpaceRoleAssignment -BaseUri "https://example.atlassian.net" -SpaceID 98307 -PrincipalType group -PrincipalID "confluence-users" -RoleID "role-viewer" -WhatIf
```

Simulates assigning the Viewer role to a group.
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

The Id of the space to assign the role on.

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

### -PrincipalType

Whether -PrincipalID identifies a `user` or a `group`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PrincipalID

The principal's identifier: a Cloud account ID for a `user`, or a group ID for a `group`.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -RoleID

The Id of the role to assign.

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
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

### ConfluencePSVII.SpaceRoleAssignment

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter and why this
command always prompts for confirmation unless told not to.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
