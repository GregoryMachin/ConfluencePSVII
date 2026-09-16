---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.Comment/
---

# ConfluencePS.Comment

## SYNOPSIS

Defines an object for footer and inline comments in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.Comment [-Property @{}]

[ConfluencePS.Comment]@{}
```

## DESCRIPTION

The `Comment` is an object that describes both footer comments and inline (text-anchored)
comments in Confluence. `Type` records which kind of comment it is; the two kinds share the
same underlying shape but are created and read through separate cmdlets
(`Get-ConfluenceFooterComment`/`Get-ConfluenceInlineComment`, and so on) because Confluence
Cloud REST API v2 exposes them as separate resources.

## REFERENCES

_No other class currently references `Comment`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `Comment`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### Status

The Status describes the current status of the `Comment`.

Possible values are: `current` and `deleted`.

```yaml
Type: String
Required: True
Default value: current
```

### Body

The Content / Body of the `Comment`.

_The content is in Confluence's storage format, which must be a valid XHTML string._

```yaml
Type: String
Required: True
Default value: null
```

### Version

Contains the information about the latest version of the `Comment`.

```yaml
Type: ConfluencePS.Version
Required: True
Default value: None
```

### PageID

The Id of the page or blog post the `Comment` is attached to.

```yaml
Type: UInt64
Required: True
Default value: None
```

### ParentID

The Id of the parent `Comment`, when this comment is a reply.
Zero when this is a top-level comment on the page.

```yaml
Type: UInt64
Required: False
Default value: 0
```

### Type

Whether this is a `footer` or an `inline` comment.

```yaml
Type: String
Required: True
Default value: None
```

### URL

Contains the URL under which the `Comment` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

### ShortURL

Contains a shortened URL under which the `Comment` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Type`.
