---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/Get-ServerInformation.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# Get-ServerInformation

## SYNOPSIS

Retrieve system information for a Confluence instance.

## SYNTAX

```powershell
Get-ConfluenceServerInformation -ApiUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
```

## DESCRIPTION

Returns the Confluence system information resource from `settings/systemInfo` as a `ConfluencePSVII.ServerInformation` object.
Cloud responses include Cloud-specific fields such as `CloudId`; Data Center responses are mapped to `DeploymentType = DataCenter`.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
Get-ConfluenceServerInformation
```

Return system information from the Confluence instance configured with `Set-ConfluenceInfo`.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
Get-ConfluenceServerInformation -ApiUri "https://example.atlassian.net/wiki/rest/api"
```

Return system information from a specific Confluence API URL.

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

## INPUTS

### None

## OUTPUTS

### ConfluencePSVII.ServerInformation

## NOTES

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
