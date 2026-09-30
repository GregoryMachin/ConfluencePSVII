---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Set-BlogPost/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Set-BlogPost/
---
# Set-BlogPost

## SYNOPSIS

Edit an existing Confluence blog post.

## SYNTAX

### byParameters (Default)

```powershell
Set-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -BlogPostID <UInt64> [-Title <String>] [-Body <String>] [-Convert] [-WhatIf] [-Confirm]
```

### byObject

```powershell
Set-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -InputObject <BlogPost> [-WhatIf] [-Confirm]
```

## DESCRIPTION

For existing blog post(s): Edit content and/or title.

Content needs to be in "Confluence storage format". Use `-Convert` if not preconditioned.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Set-ConfluenceBlogPost -BlogPostID 262144 -Title 'Sprint 13 Recap'
```

For existing blog post 262144, change its name to "Sprint 13 Recap".

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Set-ConfluenceBlogPost -BlogPostID 262144 -Body 'Hello World!' -Convert
```

For existing blog post 262144, update its content to "Hello World!"
-Convert applies the "Confluence storage format" to your given string.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
$post = Get-ConfluenceBlogPost -BlogPostID 262144
$post.Title = "New Title"

Set-ConfluenceBlogPost -InputObject $post
$post | Set-ConfluenceBlogPost
```

For existing blog post 262144, update its title.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
$post = Get-ConfluenceBlogPost -BlogPostID 262144
$post.Title = "New Title"
$post.Version.Message = "Updated blog post title!"

Set-ConfluenceBlogPost -InputObject $post
$post | Set-ConfluenceBlogPost
```

For existing blog post 262144, update its title and add a version message of "Updated blog post title!"
When using `-InputObject`, `Version.Message` is sent when provided.

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

The site's base URi, used together with -DeploymentType to route blog post updates to Confluence Cloud REST API v2's PUT /blogposts/{id}.
The current version number is read first (via Get-ConfluenceBlogPost on the byParameters path) and incremented; a conflicting concurrent edit is rejected by Confluence's own optimistic concurrency check on the submitted version number.
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

BlogPost Object which will be used to replace the current content.

```yaml
Type: BlogPost
Parameter Sets: byObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -BlogPostID

The ID of the blog post to edit.

```yaml
Type: UInt64
Parameter Sets: byParameters
Aliases: ID

Required: True
Position: Named
Default value: 0
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -Title

Name of the blog post; existing or new value can be used.
Existing will be automatically supplied via Get-BlogPost if not manually included.

```yaml
Type: String
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

The full contents of the updated body (existing contents will be overwritten).
If not yet in "storage format"--or you don't know what that is--also use -Convert.

```yaml
Type: String
Parameter Sets: byParameters
Aliases:

Required: False
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

### ConfluencePSVII.BlogPost

## NOTES

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
