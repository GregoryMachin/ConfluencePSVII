---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePSVII.BlogPost/
---

# ConfluencePSVII.BlogPost

## SYNOPSIS

Defines an object for blog posts in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.BlogPost [-Property @{}]

[ConfluencePSVII.BlogPost]@{}
```

## DESCRIPTION

The `BlogPost` is an object that describes blog posts in Confluence.
Unlike `ConfluencePSVII.Page`, it has no `Ancestors`: blog posts are not part of a page hierarchy.

## REFERENCES

_No other class currently references `BlogPost`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `BlogPost`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### Status

The Status describes the current status of the `BlogPost`.

Possible values are: `current`, `trashed` and `draft`.

```yaml
Type: String
Required: True
Default value: current
```

### Title

The Name / Title of the `BlogPost`.

```yaml
Type: String
Required: True
Default value: None
```

### Space

The Space in which the `BlogPost` is in.

```yaml
Type: ConfluencePSVII.Space
Required: True
Default value: None
```

### Version

Contains the information about the latest version of the `BlogPost`.

```yaml
Type: ConfluencePSVII.Version
Required: True
Default value: None
```

### Body

The Content / Body of the `BlogPost`.

_The content is in Confluence's storage format, which must be a valid XHTML string._

```yaml
Type: String
Required: True
Default value: null
```

### URL

Contains the URL under which the `BlogPost` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

### ShortURL

Contains a shortened URL under which the `BlogPost` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Title`.
