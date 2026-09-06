function ConvertTo-CippReportPdf {
    <#
    .SYNOPSIS
        Render a report component tree to PDF bytes server-side.
    .DESCRIPTION
        Thin wrapper over the CIPPSharp component kit ([CIPP.Reporting.ReportPdf]::Render), which is
        loaded with CIPPCore via RequiredAssemblies. Takes the declarative component tree (Report
        Builder blocks, or a fixed report's composed component nodes), the resolved branding, and the
        %variable% values, and returns the finished PDF as a byte array. All layout lives in the shared
        component kit - callers never touch OfficeIMO.
    .PARAMETER Blocks
        The component tree: an array of block/component nodes, or a JSON string of the same.
    .PARAMETER Branding
        Branding settings (Get-CIPPBrandingSettings / a preset) as an object or JSON string.
    .PARAMETER Variables
        %variable% values for footer/watermark/cover text, as a hashtable or JSON string.
    .PARAMETER TenantName
        Client name shown on the cover and available as %tenantname%.
    .PARAMETER ReportName
        Report title shown on the cover and in the page header.
    .PARAMETER GeneratedOn
        Human-readable generation date shown on the cover / available as %reportdate%.
    #>
    [CmdletBinding()]
    [OutputType([byte[]])]
    param(
        [Parameter(Mandatory = $true)]$Blocks,
        $Branding,
        $Variables,
        [string]$TenantName = 'Organization',
        [string]$ReportName = 'Report',
        [string]$GeneratedOn = ((Get-Date).ToString('MMMM d, yyyy')),
        [string]$PageSize = 'A4',
        [switch]$Landscape
    )

    # Accept objects or pre-serialised JSON for each structured input.
    $BlocksJson = if ($Blocks -is [string]) { $Blocks } else { ConvertTo-Json -InputObject @($Blocks) -Depth 20 -Compress }
    $BrandingJson = if ($null -eq $Branding) { '{}' } elseif ($Branding -is [string]) { $Branding } else { ConvertTo-Json -InputObject $Branding -Depth 10 -Compress }
    $VariablesJson = if ($null -eq $Variables) { '{}' } elseif ($Variables -is [string]) { $Variables } else { ConvertTo-Json -InputObject $Variables -Depth 5 -Compress }

    # Unary comma: return the byte[] as a single object so PowerShell does not unroll it into a stream
    # of bytes (which would reach callers as object[] and only work by implicit coercion).
    return , [CIPP.Reporting.ReportPdf]::Render(
        $BlocksJson, $BrandingJson, $VariablesJson,
        $TenantName, $ReportName, $GeneratedOn,
        $PageSize, [bool]$Landscape
    )
}
