---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/New-InlineComment/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/New-InlineComment/
---
# New-InlineComment

## SYNOPSIS

Add an inline (text-anchored) comment to a Confluence Cloud page.

## SYNTAX

```powershell
New-ConfluenceInlineComment -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -PageID <UInt64> -TextSelection <String> [-TextSelectionMatchCount <UInt32>]
 [-TextSelectionMatchIndex <UInt32>] [-ParentCommentID <UInt64>] -Body <String> [-Convert] [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new inline comment anchored to a specific piece of text on an existing Cloud page.

This is a Cloud-only operation: Confluence's v1/Data Center content API has no way to create
a text-anchored comment, only generic page comments, so there is no -DeploymentType parameter
here and -BaseUri is mandatory.

-TextSelection must match text that actually appears in the page's rendered body; Confluence
resolves the anchor server-side. If the same text appears more than once, use
-TextSelectionMatchCount and -TextSelectionMatchIndex to disambiguate which occurrence to
anchor to.

Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluenceInlineComment -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "the exact phrase" -Body 'Please clarify this.' -Convert
```

Add an inline comment anchored to "the exact phrase" on page 196608.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
New-ConfluenceInlineComment -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "TODO" -TextSelectionMatchCount 3 -TextSelectionMatchIndex 1 -Body 'Second TODO addressed.' -Convert
```

Anchor to the second (index 1) of three occurrences of "TODO" on the page.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
New-ConfluenceInlineComment -BaseUri "https://example.atlassian.net" -PageID 196608 -TextSelection "the exact phrase" -ParentCommentID 327679 -Body 'Agreed.' -Convert
```

Reply to inline comment 327679.

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

The Cloud site's base URi, used to route comment creation to Confluence Cloud REST API v2's POST /inline-comments.
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

### -PageID

The ID of the Cloud page to comment on.

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

### -TextSelection

The exact text on the page to anchor the comment to.
Must match text that appears in the page's rendered body.

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

### -TextSelectionMatchCount

The total number of times -TextSelection appears in the page.
Defaults to 1 (the text is expected to be unique).

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 1
Accept pipeline input: False
Accept wildcard characters: False
```

### -TextSelectionMatchIndex

The zero-based index of which occurrence of -TextSelection to anchor to, when it appears more than once.
Defaults to 0 (the first occurrence).

```yaml
Type: UInt32
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### -ParentCommentID

Optionally, the ID of the inline comment being replied to.
If unspecified, the new comment starts a new thread.

```yaml
Type: UInt64
Parameter Sets: (All)
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
Parameter Sets: (All)
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
Parameter Sets: (All)
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

### ConfluencePS.Comment

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
