---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/New-FooterComment/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/New-FooterComment/
---
# New-FooterComment

## SYNOPSIS

Add a footer comment to a Confluence page or blog post.

## SYNTAX

### byParameters (Default)

```powershell
New-ConfluenceFooterComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -PageID <UInt64> [-ParentCommentID <UInt64>] -Body <String> [-Convert] [-WhatIf] [-Confirm]
```

### byObject

```powershell
New-ConfluenceFooterComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -InputObject <Comment> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new footer comment on an existing page or blog post, or reply to an existing comment
by also supplying -ParentCommentID.

Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluenceFooterComment -PageID 196608 -Body 'Nice work!' -Convert
```

Add a footer comment to page 196608.
-Convert applies the "Confluence storage format" to your given string.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
New-ConfluenceFooterComment -PageID 196608 -ParentCommentID 327679 -Body 'Agreed.' -Convert
```

Reply to comment 327679 on page 196608.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
$commentObject = [ConfluencePSVII.Comment]@{
    PageID = 196608
    Body   = '<p>Nice work!</p>'
}

New-ConfluenceFooterComment -InputObject $commentObject
```

Create a new footer comment from an object `ConfluencePSVII.Comment`.

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

The site's base URi, used together with -DeploymentType to route comment creation to Confluence Cloud REST API v2's POST /footer-comments.
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

A ConfluencePSVII.Comment object from which to create a new footer comment.

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

### -PageID

The ID of the page or blog post to comment on.

```yaml
Type: UInt64
Parameter Sets: byParameters
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName)
Accept wildcard characters: False
```

### -ParentCommentID

Optionally, the ID of the comment being replied to.
If unspecified, the new comment is a top-level comment on the page.

```yaml
Type: UInt64
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

The contents of your new comment.

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

Optionally, convert the provided body to Confluence's storage format.
Has the same effect as calling ConvertTo-ConfluenceStorageFormat against your Body.

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
