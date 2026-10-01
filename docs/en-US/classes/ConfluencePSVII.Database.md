# ConfluencePSVII.Database

## SYNOPSIS

Defines an object for Confluence Cloud databases (Smart Links-backed embedded database views).

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.Database [-Property @{}]

[ConfluencePSVII.Database]@{}
```

## DESCRIPTION

The `Database` is an object that describes a Confluence Cloud database, a modern content type
introduced by Confluence Cloud REST API v2. It has no legacy v1/Data Center equivalent and no
`Body`/storage representation -- unlike a `Page` or `BlogPost`, a database is an embedded view
over a linked data source, not editable rich text.

## REFERENCES

_No other class currently references `Database`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `Database`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### Status

The Status describes the current status of the `Database`.

```yaml
Type: String
Required: True
Default value: current
```

### Title

The Name / Title of the `Database`.

```yaml
Type: String
Required: True
Default value: None
```

### Space

The Space in which the `Database` is in.
Only the numeric Id is populated; Confluence Cloud v2 does not embed the full space object.

```yaml
Type: ConfluencePSVII.Space
Required: True
Default value: None
```

### ParentID

The Id of the page or folder the `Database` is nested under, if any.

```yaml
Type: UInt64
Required: False
Default value: 0
```

### Version

Contains the information about the latest version of the `Database`.

```yaml
Type: ConfluencePSVII.Version
Required: True
Default value: None
```

### URL

Contains the URL under which the `Database` is accessible.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Title`.
