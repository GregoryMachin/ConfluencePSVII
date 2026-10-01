---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Get-InlineComment.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Get-InlineComment

## SYNOPSIS

Retrieve inline (text-anchored) comments from your Confluence instance.

## SYNTAX

### byId (Default)

```powershell
Get-ConfluenceInlineComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-CommentID] <UInt64[]> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>] [-ExcludeBody]
```

### byPage

```powershell
Get-ConfluenceInlineComment -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -PageID <UInt64> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>] [-ExcludeBody]
```

## DESCRIPTION

Return Confluence inline comments, filtered by comment ID or by the page they're attached to.
Pass the optional parameter -ExcludeBody to avoid fetching the comments' HTML content.

Confluence's classic v1/Data Center content API has no dedicated inline-comment resource --
inline and footer comments are both just generic `type=comment` content items there, with no
reliable field distinguishing an inline anchor. This command's v1 path returns the same
comments Get-ConfluenceFooterComment's v1 path would for the same page; only the Cloud v2
opt-in (via -BaseUri and -DeploymentType Cloud) reads the actually dedicated inline-comments
collection. See docs/api-contract-inventory.md for details.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceInlineComment -CommentID 327680
```

Returns the inline comment with ID 327680.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceInlineComment -PageID 196608 -BaseUri "https://example.atlassian.net" -DeploymentType Cloud
```

Returns all inline comments attached to page 196608, using the dedicated Cloud v2 collection.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceInlineComment -PageID 196608 -ExcludeBody
```

Returns all inline comments attached to page 196608 without their content.

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

The site's base URi, used together with -DeploymentType to route to Confluence Cloud REST API v2's dedicated inline-comments resource.
Without it, requests fall back to the v1 route (which cannot distinguish inline from footer comments) regardless of -DeploymentType.
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

### -CommentID

Filter results by comment ID.

```yaml
Type: UInt64[]
Parameter Sets: byId
Aliases: ID

Required: True
Position: 1
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -PageID

Filter results to comments attached to this page ID.

```yaml
Type: UInt64
Parameter Sets: byPage
Aliases:

Required: True
Position: Named
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

### -ExcludeBody

Avoids fetching comments' body

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

## INPUTS

## OUTPUTS

### ConfluencePSVII.Comment

## NOTES

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
