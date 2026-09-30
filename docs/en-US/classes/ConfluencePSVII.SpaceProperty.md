---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePSVII.SpaceProperty/
---

# ConfluencePSVII.SpaceProperty

## SYNOPSIS

Defines an object for Confluence Cloud space properties (arbitrary JSON key/value metadata
attached to a space).

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.SpaceProperty [-Property @{}]

[ConfluencePSVII.SpaceProperty]@{}
```

## DESCRIPTION

The `SpaceProperty` is an object that describes one JSON key/value property attached to a
Confluence Cloud space -- a modern content-configuration mechanism introduced by Confluence
Cloud REST API v2. It has no legacy v1/Data Center equivalent.

Space properties must never be used to store secrets: `New-ConfluenceSpaceProperty` and
`Set-ConfluenceSpaceProperty` reject keys or nested value keys that look like they are meant
to carry a secret (password, token, credential, API key, ...), and reject credentials, secure
strings, and script blocks outright.

## REFERENCES

_No other class currently references `SpaceProperty`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `SpaceProperty`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### SpaceID

The Id of the space this property is attached to.

```yaml
Type: UInt64
Required: True
Default value: None
```

### Key

The property's key.

```yaml
Type: String
Required: True
Default value: None
```

### Value

The property's value.
Can be any JSON-serializable data: a string, number, boolean, object, or array.

```yaml
Type: Object
Required: True
Default value: None
```

### Version

Contains the information about the latest version of the `SpaceProperty`.

```yaml
Type: ConfluencePSVII.Version
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `$Key`.
