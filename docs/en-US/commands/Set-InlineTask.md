---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-InlineTask/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-InlineTask/
---
# Set-InlineTask

## SYNOPSIS

Mark a Confluence inline task complete or reopen it.

## SYNTAX

```powershell
Set-ConfluenceInlineTask -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -TaskID <UInt64> -Status <String> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Update an existing inline task's status to `complete` (check it off) or `incomplete`
(reopen it). The current version number is read first and incremented, so a conflicting
concurrent edit is rejected by Confluence's own optimistic concurrency check on the
submitted version number.

This is a Cloud-only operation, for the same reason as Get-ConfluenceInlineTask: inline
tasks have no v1/Data Center status-update API at all. There is no -DeploymentType
parameter here and -BaseUri is mandatory.

The task's text, assignee, and due date are edited through the owning page's body, not
through this command -- only -Status is supported.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Set-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -TaskID 589824 -Status complete
```

Marks inline task 589824 as complete.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -PageID 196608 -Status complete |
    Set-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -Status incomplete -WhatIf
```

Simulates reopening every completed task on page 196608.
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

The Cloud site's base URi, used to route requests to Confluence Cloud REST API v2's dedicated tasks resource.
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

### -TaskID

The ID of the task to update.

```yaml
Type: UInt64
Parameter Sets: (All)
Aliases: ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Status

The new status: `complete` or `incomplete`.

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

### ConfluencePS.InlineTask

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
