---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Remove-Attachment/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Remove-Attachment/
---
# Remove-Attachment

## SYNOPSIS

Remove an Attachment.

## SYNTAX

```powershell
Remove-ConfluenceAttachment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-Attachment] <Attachment[]> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Remove Attachments from Confluence content.

Does accept multiple pages piped via Get-ConfluencePage.

> Untested against non-page content.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
$attachments = Get-ConfluenceAttachment -PageID 123456
Remove-ConfluenceAttachment -Attachment $attachments -Verbose -Confirm
```

Remove all attachment from page 12345
Verbose and Confirm flags both active; you will be prompted before deletion.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceAttachment -PageID 123456 | Remove-ConfluenceAttachment -WhatIf
```

Do trial deletion for all attachments on page with ID 123456, the WhatIf parameter prevents any modifications.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceAttachment -PageID 123456 | Remove-ConfluenceAttachment
```

Remove all Attachments on page 123456.

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

The site's base URi, used together with -DeploymentType to route deletion to Confluence Cloud REST API v2's dedicated attachment-delete route instead of the generic v1 content-delete route.
Without it, requests fall back to the v1 route regardless of -DeploymentType.
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

### -Attachment

The Attachment(s) to remove.

```yaml
Type: Attachment[]
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByValue)
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

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
