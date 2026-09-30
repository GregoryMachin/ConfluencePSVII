---
layout: documentation
permalink: /docs/ConfluencePS/classes/ConfluencePSVII.SpaceRoleAssignment/
---

# ConfluencePSVII.SpaceRoleAssignment

## SYNOPSIS

Defines an object for one Confluence Cloud space role assignment.

## SYNTAX

```powershell
New-Object -TypeName ConfluencePSVII.SpaceRoleAssignment [-Property @{}]

[ConfluencePSVII.SpaceRoleAssignment]@{}
```

## DESCRIPTION

The `SpaceRoleAssignment` is an object that describes one space role (for example Admin or
Viewer) assigned to a principal (a user or a group) on a Confluence Cloud space. Role
assignment is Cloud v2's supported way to manage space access governance -- individual
permission grants (`ConfluencePSVII.SpacePermission`) cannot be changed directly, only role
assignments.

## REFERENCES

_No other class currently references `SpaceRoleAssignment`._

## CONSTRUCTORS

_This class does not have a constructor._

## PROPERTIES

### SpaceID

The Id of the space this role assignment applies to.

```yaml
Type: UInt64
Required: True
Default value: None
```

### PrincipalType

The kind of principal the assignment applies to: `user` or `group`.

```yaml
Type: String
Required: True
Default value: None
```

### PrincipalID

The principal's identifier: a Cloud account ID for a `user`, or a group ID for a `group`.

```yaml
Type: String
Required: True
Default value: None
```

### RoleID

The assigned role's identifier.

```yaml
Type: String
Required: True
Default value: None
```

### RoleName

The assigned role's display name, for example "Admin" or "Viewer".

```yaml
Type: String
Required: False
Default value: None
```

## METHODS

### ToString()

The method for casting an object of this class to string is overwritten.

When cast to string, this will return `[$PrincipalType $PrincipalID] $RoleName`.
