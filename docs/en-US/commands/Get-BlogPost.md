---
external help file: ConfluencePS-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-BlogPost/
Module Name: ConfluencePS
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-BlogPost/
---
# Get-BlogPost

## SYNOPSIS

Retrieve a listing of blog posts in your Confluence instance.

## SYNTAX

### byId (Default)

```powershell
Get-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-BlogPostID] <UInt64[]> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>] [-ExcludeBody]
```

### bySpace

```powershell
Get-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceKey <String> [-Title <String>] [-PageSize <UInt32>] [-IncludeTotalCount]
 [-Skip <UInt64>] [-First <UInt64>] [-ExcludeBody]
```

### byQuery

```powershell
Get-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-Query] <String> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>] [-ExcludeBody]
```

### bySpaceObject

```powershell
Get-ConfluenceBlogPost -ApiUri <Uri> [-BaseUri <Uri>] [-DeploymentType <String>] [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -Space <Space> [-Title <String>] [-PageSize <UInt32>] [-IncludeTotalCount]
 [-Skip <UInt64>] [-First <UInt64>] [-ExcludeBody]
```

## DESCRIPTION

Return Confluence blog posts, filtered by ID, Name, or Space.
Pass the optional parameter -ExcludeBody to avoid fetching the blog posts' HTML content.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceBlogPost -SpaceKey HOTH
Get-ConfluenceSpace -SpaceKey HOTH | Get-ConfluenceBlogPost
```

Two different methods to return all blog posts in space "HOTH".
Both examples should return identical results.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceBlogPost -BlogPostID 262144 | Format-List *
```

Returns the blog post with ID 262144.
`Format-List *` displays all of the object's properties, including the full body.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceBlogPost -Title 'release*' -SpaceKey HOTH
```

Return all blog posts in HOTH whose names start with "release" (case-insensitive).
Wildcards (*) can be inserted to support partial matching.

### -------------------------- EXAMPLE 4 --------------------------

```powershell
Get-ConfluenceBlogPost -Query "mention = jSmith and creator != jSmith"
```

Return all blog posts matching the query.

### -------------------------- EXAMPLE 5 --------------------------

```powershell
Get-ConfluenceBlogPost -SpaceKey HOTH -ExcludeBody
```

Return all blog posts in space "HOTH" without their content.

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

The site's base URi, used together with -DeploymentType to route to Confluence Cloud REST API v2.
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
The byQuery parameter set always uses the v1 CQL search route, since Cloud v2 has no equivalent for arbitrary CQL search.
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

If no sessions is available, the request will be executed anonymously.

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

### -BlogPostID

Filter results by blog post ID.

Best option if you already know the ID.

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

### -Title

Filter results by blog post name (case-insensitive).

This supports wildcards (*) to allow for partial matching.

```yaml
Type: String
Parameter Sets: bySpace, bySpaceObject
Aliases: Name

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: True
```

### -SpaceKey

Filter results by space key (case-insensitive).

```yaml
Type: String
Parameter Sets: bySpace
Aliases: Key

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Space

Filter results by space object, typically from the pipeline.

```yaml
Type: Space
Parameter Sets: bySpaceObject
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: True (ByPropertyName, ByValue)
Accept wildcard characters: False
```

### -Query

Use Confluences advanced search: [CQL](https://developer.atlassian.com/cloud/confluence/advanced-searching-using-cql/).

This cmdlet will always append a filter to only look for blog posts (`type=blogpost`).

```yaml
Type: String
Parameter Sets: byQuery
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -PageSize

Maximum number of results to fetch per call.

This setting can be tuned to get better performance according to the load on the server.

> Warning: too high of a PageSize can cause a timeout on the request.

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

Note this is actually a uInt64, but with a custom string representation.

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

Defaults to 0.

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

Avoids fetching blog posts' body

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

### ConfluencePS.BlogPost

## NOTES

Piped output into other cmdlets is generally tested and supported.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
