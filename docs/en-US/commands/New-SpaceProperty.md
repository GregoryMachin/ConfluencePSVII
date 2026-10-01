---
external help file: ConfluencePSVII-help.xml
online version: https://github.com/GregoryMachin/ConfluencePSVII/blob/master/docs/en-US/commands/New-SpaceProperty.md
Module Name: ConfluencePSVII
locale: en-US
schema: 2.0.0
---
# New-SpaceProperty

## SYNOPSIS

Add a JSON property to a Confluence Cloud space.

## SYNTAX

```powershell
New-ConfluenceSpaceProperty -ApiUri <Uri> -BaseUri <Uri> [-Credential <PSCredential>]
 [-PersonalAccessToken <String>] [-Certificate <X509Certificate>]
 -SpaceID <UInt64> -Key <String> -Value <Object> [-WhatIf] [-Confirm]
```

## DESCRIPTION

Create a new JSON property on a space. -Value can be any JSON-serializable data: a string,
number, boolean, object, or array.

This is a Cloud-only operation: space properties do not exist in the legacy v1/Data Center
content model at all, so there is no -DeploymentType parameter here and -BaseUri is mandatory.

-Key and -Value are validated before anything is sent: keys and nested value keys are
rejected if they look like they are meant to carry a secret (password, token, credential,
API key, ...), credentials/secure strings/script blocks are rejected outright, and the
serialized value is capped at 32,768 UTF-8 bytes -- space properties must never be used to
store secrets.

## EXAMPLES

### -------------------------- EXAMPLE 1 --------------------------

```powershell
New-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "my-app.settings" -Value @{ enabled = $true; retries = 3 }
```

Adds a property named "my-app.settings" to space 98307 with an object value.

### -------------------------- EXAMPLE 2 --------------------------

```powershell
New-ConfluenceSpaceProperty -BaseUri "https://example.atlassian.net" -SpaceID 98307 -Key "team.owner" -Value "platform-team"
```

Adds a property with a plain string value.

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

The Cloud site's base URi, used to route requests to Confluence Cloud REST API v2's dedicated space-properties resource.
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

### -SpaceID

The Id of the space to attach the new property to.

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

### -Key

The property's key.

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

### -Value

The property's value.
Can be any JSON-serializable data.

```yaml
Type: Object
Parameter Sets: (All)
Aliases:

Required: True
Position: Named
Default value: None
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

### ConfluencePSVII.SpaceProperty

## NOTES

Cloud only. See the DESCRIPTION for why there is no -DeploymentType parameter.

## RELATED LINKS

[https://github.com/GregoryMachin/ConfluencePSVII](https://github.com/GregoryMachin/ConfluencePSVII)
