# ConfluencePSVII.ContentLabelSet

## SYNOPSIS

Defines an object for ContentLabelSets in Confluence.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.ContentLabelSet [-Property @{}]

[ConfluencePSVII.ContentLabelSet]@{}
```

## DESCRIPTION

The `ContentLabelSet` is an object that describes the `Label`s that are assigned to a `Page`.

## REFERENCES

_This class is not used by any other class._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Page

Contains the `Page` that is being described.

```yaml
Type: ConfluencePSVII.Page
Required: True
Default value: None
```

### Labels

Contains a list of `Label`s that are assigned to the `Page`.

```yaml
Type: ConfluencePSVII.Label
Required: False
Default value: None
```

## METHODS

### ToString()

_No behavior of casting to string is defined._
