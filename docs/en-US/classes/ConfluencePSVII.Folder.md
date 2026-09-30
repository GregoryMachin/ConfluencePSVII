---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePSVII.Folder/
---

# ConfluencePSVII.Folder

## SYNOPSIS

Defines an object for Confluence Cloud folders (organizational content containers).

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.Folder [-Property @{}]

[ConfluencePSVII.Folder]@{}
```

## DESCRIPTION

The `Folder` is an object that describes a Confluence Cloud folder, a modern content type
introduced by Confluence Cloud REST API v2 for organizing pages, whiteboards, and other
content. It has no legacy v1/Data Center equivalent and no `Body`/storage representation --
a folder is a container, not editable rich text.

## REFERENCES

_No other class currently references `Folder`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `Folder`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### Status

The Status describes the current status of the `Folder`.

```yaml
Type: String
Required: True
Default value: current
```

### Title

The Name / Title of the `Folder`.

```yaml
Type: String
Required: True
Default value: None
```

### Space

The Space in which the `Folder` is in.
Only the numeric Id is populated; Confluence Cloud v2 does not embed the full space object.

```yaml
Type: ConfluencePSVII.Space
Required: True
Default value: None
```

### ParentID

The Id of the page or folder the `Folder` is nested under, if any.

```yaml
Type: UInt64
Required: False
Default value: 0
```

### Version

Contains the information about the latest version of the `Folder`.

```yaml
Type: ConfluencePSVII.Version
Required: True
Default value: None
```

### URL

Contains the URL under which the `Folder` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Title`.
