---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Set-InlineComment.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Set-InlineComment

## SYNOPSIS

Edit an existing Confluence inline comment.

## SYNTAX

### byParameters (Default)

```powershell
Set-ConfluenceInlineComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -CommentID <UInt64> -Body <String> [-Convert] [-WhatIf] [-Confirm]
```

### byObject

```powershell
Set-ConfluenceInlineComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -InputObject <Comment> [-WhatIf] [-Confirm]
```

## DESCRIPTION

For an existing inline comment: edit its content.

Updating a comment's body needs no text-selection anchor, so unlike New-ConfluenceInlineComment
this command works on v1/Data Center as well as Cloud v2 -- it is just a generic comment-body
update either way.

Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Set-ConfluenceInlineComment -CommentID 327680 -Body 'Clarified, thanks!' -Convert
```

For existing comment 327680, update its content.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
$comment = Get-ConfluenceInlineComment -CommentID 327680
$comment.Body = '<p>Clarified, thanks!</p>'

Set-ConfluenceInlineComment -InputObject $comment
$comment | Set-ConfluenceInlineComment
```

For existing comment 327680, update its content using an object.

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

The site's base URi, used together with -DeploymentType to route comment updates to Confluence Cloud REST API v2's PUT /inline-comments/{id}.
The current version number is read first (via Get-ConfluenceInlineComment on the byParameters path) and incremented; a conflicting concurrent edit is rejected by Confluence's own optimistic concurrency check on the submitted version number.
Without -BaseUri, requests fall back to the v1 route regardless of -DeploymentType.
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

### -InputObject

Comment Object which will be used to replace the current content.

```yaml
Type: Comment
Parameter Sets: byObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -CommentID

The ID of the comment to edit.

```yaml
Type: UInt64
Parameter Sets: byParameters
Aliases: ID

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Body

The full contents of the updated comment (existing contents will be overwritten).

```yaml
Type: String
Parameter Sets: byParameters
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Convert

Optional switch flag for calling ConvertTo-ConfluenceStorageFormat against your Body.

```yaml
Type: SwitchParameter
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: False
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

### ConfluencePSVII.Comment

## NOTES

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
