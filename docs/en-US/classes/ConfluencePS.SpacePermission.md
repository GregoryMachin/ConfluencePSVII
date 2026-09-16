---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePS.SpacePermission/
---

# ConfluencePS.SpacePermission

## SYNOPSIS

Defines an object for one currently effective Confluence Cloud space permission grant.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePS.SpacePermission [-Property @{}]

[ConfluencePS.SpacePermission]@{}
```

## DESCRIPTION

The `SpacePermission` is an object that describes one permission grant on a Confluence Cloud
space: a principal (a user, a group, or a space role) and an operation the principal is
granted on the space. It is a read-only view of currently effective, possibly inherited
grants -- Confluence Cloud v2 does not expose a way to add or remove an individual permission
grant directly, only space role assignments (see `ConfluencePS.SpaceRoleAssignment`).

## REFERENCES

_No other class currently references `SpacePermission`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### Id

The Id is the unique identifier of this permission grant.

_This value can't be changed and is assigned by the server._

```yaml
Type: UInt64
Required: True
Default value: None
```

### SpaceID

The Id of the space this permission grant applies to.

```yaml
Type: UInt64
Required: True
Default value: None
```

### PrincipalType

The kind of principal the grant applies to: `user`, `group`, or `role`.

```yaml
Type: String
Required: True
Default value: None
```

### PrincipalID

The principal's identifier: a Cloud account ID for a `user`, a group ID for a `group`, or a
role ID for a `role`.

```yaml
Type: String
Required: True
Default value: None
```

### OperationKey

The granted operation, for example `read` or `create`.

```yaml
Type: String
Required: True
Default value: None
```

### OperationTargetType

The type of content the operation applies to, for example `space` or `page`.

```yaml
Type: String
Required: True
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$PrincipalType $PrincipalID] $OperationKey`.
