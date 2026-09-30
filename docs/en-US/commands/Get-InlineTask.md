---
external help file: ConfluencePSVII-help.xml
online version: https://atlassianps.org/docs/ConfluencePS/commands/Get-InlineTask/
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
layout: documentation
permalink: /docs/ConfluencePS/commands/Get-InlineTask/
---
# Get-InlineTask

## SYNOPSIS

Retrieve Confluence inline tasks (checkbox action items embedded in pages).

## SYNTAX

### byFilter (Default)

```powershell
Get-ConfluenceInlineTask -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-PageID <UInt64>] [-SpaceID <UInt64>] [-Status <String>] [-AssignedTo <String>]
 [-CreatedBy <String>] [-CreatedAfter <DateTime>] [-CreatedBefore <DateTime>]
 [-DueAfter <DateTime>] [-DueBefore <DateTime>] [-PageSize <UInt32>]
 [-IncludeTotalCount] [-Skip <UInt64>] [-First <UInt64>]
```

### byId

```powershell
Get-ConfluenceInlineTask -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 [-TaskID] <UInt64[]> [-PageSize <UInt32>] [-IncludeTotalCount] [-Skip <UInt64>]
 [-First <UInt64>]
```

## DESCRIPTION

Return Confluence inline tasks, filtered by ID or by any combination of page, space,
status, assignee, creator, and creation/due date range.

This is a Cloud-only operation: inline tasks are exposed as a dedicated queryable resource
only by Cloud v2. Confluence's v1/Data Center content API only ever surfaced them as inline
markup inside a page's storage-format body, with no separate listing/filtering/status API.
There is no -DeploymentType parameter here and -BaseUri is mandatory.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -TaskID 589824
```

Returns the inline task with ID 589824.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -PageID 196608 -Status incomplete
```

Returns all incomplete inline tasks on page 196608.

### -------------------------- EXAMPLE 3 --------------------------

```powershell
Get-ConfluenceInlineTask -BaseUri "https://example.atlassian.net" -AssignedTo "712020:aaaa" -DueBefore (Get-Date)
```

Returns all overdue inline tasks assigned to the given account.

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

### -TaskID

Filter results by task ID.

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

Filter results to tasks embedded in this page.

```yaml
Type: UInt64
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -SpaceID

Filter results to tasks in this space.

```yaml
Type: UInt64
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Status

Filter results by task status.

```yaml
Type: String
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -AssignedTo

Filter results by the assignee's Cloud account ID.

```yaml
Type: String
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedBy

Filter results by the creator's Cloud account ID.

```yaml
Type: String
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedAfter

Filter results to tasks created at or after this date/time.

```yaml
Type: DateTime
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -CreatedBefore

Filter results to tasks created at or before this date/time.

```yaml
Type: DateTime
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DueAfter

Filter results to tasks due at or after this date/time.

```yaml
Type: DateTime
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -DueBefore

Filter results to tasks due at or before this date/time.

```yaml
Type: DateTime
Parameter Sets: byFilter
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
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

## INPUTS

## OUTPUTS

### ConfluencePSVII.InlineTask

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/AtlassianPS/ConfluencePS](https://github.com/AtlassianPS/ConfluencePS)
