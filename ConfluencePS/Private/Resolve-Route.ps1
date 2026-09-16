function Resolve-Route {
    <#
    .SYNOPSIS
    Resolves the deployment- and version-aware base route for a Confluence resource operation.

    .DESCRIPTION
    Confluence Cloud resource operations that have a supported v2 replacement resolve under
    `/wiki/api/v2`. Confluence Cloud operations with a documented v2 parity gap, and every
    Data Center operation, resolve under `/rest/api` (with the Cloud `/wiki` prefix retained
    where applicable). Routes are built from fixed templates and validated identifiers only;
    no caller-supplied host or path fragment is ever accepted.
    #>
    [CmdletBinding()]
    [OutputType([Uri])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [String]
        $BaseUri,

        [Parameter(Mandatory)]
        [ValidateSet(
            'SpaceCollection', 'SpaceById', 'SpaceCreate', 'SpaceDelete',
            'PageCollection', 'PageById', 'PageSearch', 'PageCreate', 'PageUpdate', 'PageDelete',
            'ChildPage', 'DescendantPage',
            'AttachmentCollection', 'AttachmentUpload', 'AttachmentUpdate', 'AttachmentDownload', 'AttachmentDelete',
            'LabelCollection', 'LabelAdd', 'LabelRemove',
            'StorageFormatConversion', 'ServerInformation'
        )]
        [String]
        $Resource,

        [Parameter()]
        [ValidateSet('', 'Cloud', 'DataCenter', 'Server')]
        [String]
        $DeploymentType,

        [Parameter()]
        [UInt64]
        $PageId,

        [Parameter()]
        [UInt64]
        $SpaceId,

        [Parameter()]
        [String]
        $SpaceKey,

        [Parameter()]
        [UInt64]
        $AttachmentId
    )

    process {
        $deployment = if ([String]::IsNullOrWhiteSpace($DeploymentType)) { 'DataCenter' } else { $DeploymentType }
        if ($deployment -eq 'Server') {
            $deployment = 'DataCenter'
        }

        $parsedBaseUri = $null
        if (-not [Uri]::TryCreate($BaseUri, [UriKind]::Absolute, [ref]$parsedBaseUri)) {
            throw "BaseUri '$BaseUri' is not an absolute URI."
        }

        if ($deployment -eq 'Cloud' -and $parsedBaseUri.Scheme -ne 'https') {
            throw "Confluence Cloud routes require an HTTPS BaseUri."
        }

        # Cloud v2 has a supported replacement for these operations; everything else (Cloud
        # parity gaps and all Data Center traffic) resolves to the v1 `/rest/api` route.
        $v2CapableResources = @(
            'SpaceCollection', 'SpaceById', 'SpaceCreate',
            'PageCollection', 'PageById', 'PageCreate', 'PageUpdate', 'PageDelete',
            'ChildPage', 'DescendantPage',
            'AttachmentCollection', 'AttachmentDelete',
            'LabelCollection'
        )
        $useV2 = ($deployment -eq 'Cloud') -and ($Resource -in $v2CapableResources)

        $root = ConvertTo-RouteRoot -BaseUri $parsedBaseUri -DeploymentType $deployment
        $apiBase = if ($useV2) { "$root/api/v2" } else { "$root/rest/api" }

        $path = switch ($Resource) {
            'SpaceCollection' { if ($useV2) { '/spaces' } else { '/space' } }
            'SpaceById' {
                if ($useV2) {
                    Assert-RouteId -Name SpaceId -Value $SpaceId
                    "/spaces/$SpaceId"
                }
                else {
                    Assert-RouteKey -Name SpaceKey -Value $SpaceKey
                    "/space/$SpaceKey"
                }
            }
            'SpaceCreate' { if ($useV2) { '/spaces' } else { '/space' } }
            'SpaceDelete' {
                Assert-RouteKey -Name SpaceKey -Value $SpaceKey
                "/space/$SpaceKey"
            }
            'PageCollection' { if ($useV2) { '/pages' } else { '/content' } }
            'PageById' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'PageSearch' { '/content/search' }
            'PageCreate' { if ($useV2) { '/pages' } else { '/content' } }
            'PageUpdate' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'PageDelete' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId" } else { "/content/$PageId" }
            }
            'ChildPage' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/direct-children" } else { "/content/$PageId/child/page" }
            }
            'DescendantPage' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/descendants" } else { "/content/$PageId/descendant/page" }
            }
            'AttachmentCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/attachments" } else { "/content/$PageId/child/attachment" }
            }
            'AttachmentUpload' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/child/attachment"
            }
            'AttachmentUpdate' {
                Assert-RouteId -Name PageId -Value $PageId
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                "/content/$PageId/child/attachment/$AttachmentId/data"
            }
            'AttachmentDownload' {
                Assert-RouteId -Name PageId -Value $PageId
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                "/content/$PageId/child/attachment/$AttachmentId/download"
            }
            'AttachmentDelete' {
                Assert-RouteId -Name AttachmentId -Value $AttachmentId
                if ($useV2) { "/attachments/$AttachmentId" } else { "/content/$AttachmentId" }
            }
            'LabelCollection' {
                Assert-RouteId -Name PageId -Value $PageId
                if ($useV2) { "/pages/$PageId/labels" } else { "/content/$PageId/label" }
            }
            'LabelAdd' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/label"
            }
            'LabelRemove' {
                Assert-RouteId -Name PageId -Value $PageId
                "/content/$PageId/label"
            }
            'StorageFormatConversion' { '/contentbody/convert/storage' }
            'ServerInformation' { '/settings/systemInfo' }
        }

        return [Uri]"$apiBase$path"
    }
}
