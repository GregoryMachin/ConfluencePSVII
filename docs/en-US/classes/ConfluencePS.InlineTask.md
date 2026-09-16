---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.InlineTask/
---

# ConfluencePS.InlineTask

## SYNOPSIS

Defines an object for Confluence inline tasks (checkbox action items embedded in a page).

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.InlineTask [-Property @{}]

[ConfluencePS.InlineTask]@{}
```

## DESCRIPTION

The `InlineTask` is an object that describes a Confluence Cloud inline task -- a checkbox
action item embedded in a page's body -- exposed as a dedicated queryable resource by
Confluence Cloud REST API v2. It has no legacy v1/Data Center equivalent as a separate
resource; the only editable field through this resource is `Status`. The task's text is
edited through the owning page's body, not through this type.

## REFERENCES

_No other class currently references `InlineTask`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of the `InlineTask`.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### LocalID

The task's position/index among the tasks embedded in its page, as assigned by Confluence.

```yaml
Type: UInt64
Required: True
Default value: None
```

### PageID

The Id of the page the `InlineTask` is embedded in.

```yaml
Type: UInt64
Required: True
Default value: None
```

### Status

Whether the task is `complete` or `incomplete`.

```yaml
Type: String
Required: True
Default value: None
```

### Body

The text of the task.

```yaml
Type: String
Required: True
Default value: None
```

### CreatedBy

The user who created the task.
Only `UserKey` (the Cloud account ID) is populated.

```yaml
Type: ConfluencePS.User
Required: True
Default value: None
```

### AssignedTo

The user the task is assigned to, if any.
Only `UserKey` (the Cloud account ID) is populated.

```yaml
Type: ConfluencePS.User
Required: False
Default value: None
```

### CompletedBy

The user who completed the task, if it has been completed.
Only `UserKey` (the Cloud account ID) is populated.

```yaml
Type: ConfluencePS.User
Required: False
Default value: None
```

### CreatedAt

When the task was created.

```yaml
Type: DateTime
Required: True
Default value: None
```

### DueAt

The task's due date, if one is set.

```yaml
Type: DateTime
Required: False
Default value: None
```

### CompletedAt

When the task was completed, if it has been completed.

```yaml
Type: DateTime
Required: False
Default value: None
```

### Version

Contains the information about the latest version of the `InlineTask`.

```yaml
Type: ConfluencePS.Version
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$Id] $Status`.
