---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/New-BlogPost/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/New-BlogPost/
---
# New-BlogPost

## SYNOPSIS

Create a new blog post on your Confluence instance.

## SYNTAX

### byParameters (Default)

```powershell
New-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -Title <String> [-SpaceKey <String>] [-Space <Space>] [-Body <String>] [-Convert] [-WhatIf] [-Confirm]
```

### byObject

```powershell
New-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -InputObject <BlogPost> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new blog post on Confluence.

Optionally include content in -Body.
Body content needs to be in "Confluence storage format" -- see also -Convert.

Unlike a page, a blog post has no parent -- it always belongs directly to a space.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluenceBlogPost -Title 'Sprint 12 Recap' -SpaceKey Hoth
```

Create a new blank blog post at space "Hoth".

### -------------------------- EXAMPLE 2 --------------------------

```powershell
New-ConfluenceBlogPost -Title 'foo' -SpaceKey 'bar' -Body $PostContents
```

Create a new blog post named 'foo' in space 'bar'.
The blog post will contain the data stored in $PostContents.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
New-ConfluenceBlogPost -Title 'foo' -SpaceKey 'bar' -Body 'Testing 123' -Convert
```

Create a new blog post named 'foo' in space 'bar'.

The blog post will contain the text "Testing 123".
-Convert will condition the -Body parameter's string into storage format.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
$postObject = [ConfluencePS.BlogPost]@{
    Title = "My Title"
    Space = [ConfluencePS.Space]@{
        Key="ABC"
    }
}

# example 1
New-ConfluenceBlogPost -InputObject $postObject
# example 2
$postObject | New-ConfluenceBlogPost
```

Two different methods of creating a new blog post from an object `ConfluencePS.BlogPost`.

Both examples should return identical results.

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

The site's base URi, used together with -DeploymentType to route blog post creation to Confluence Cloud REST API v2's POST /blogposts.
The v2 request identifies the target space only by numeric ID; a -SpaceKey (or a -Space/-InputObject.Space with only a Key) is resolved to an ID through Get-ConfluenceSpace.
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

A ConfluencePS.BlogPost object from which to create a new blog post.

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

### -Title

Name of your new blog post.

```yaml
Type: String
Parameter Sets: byParameters
Aliases: Name

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### -SpaceKey

Key of the space where the new blog post should exist.

Only needed if you don't specify a -Space object with an Id or Key already set.

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

### -Space

Space Object in which to create the new blog post.

```yaml
Type: Space
Parameter Sets: byParameters
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Body

The contents of your new blog post.

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

### ConfluencePS.BlogPost

## NOTES

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
