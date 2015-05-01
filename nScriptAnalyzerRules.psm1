<#
.SYNOPSIS
    Ensures module manifest has Description and Author field which are required for publishing
.DESCRIPTION
    PowerShell Modules are accompanied by module manifests. Some fields from these module
    manifests are used for publishing them into the gallery. This rule checks if the
    'Description' and 'Author' fields are specified
.EXAMPLE
    nTestDescriptionAndAuthorField -ScriptBlockAst $ScriptBlockAst
.INPUTS
    [System.Management.Automation.Language.ScriptBlockAst]
.OUTPUTS
    [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]]
.NOTES
    None
#>
function nTestDescriptionAndAuthorField
{
    [CmdletBinding()]
     [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]

    param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )
   
    $results = @()
    $HashTableAst = $null
    foreach($s in $ScriptBlockAst.EndBlock.Statements)
    {
      if ($s -is [Management.Automation.Language.PipelineAst])
      {
        foreach($p in $s.PipelineElements)
        {
          if ($p -is [Management.Automation.Language.CommandExpressionAst]) 
          {
            if ($p.Expression -is [Management.Automation.Language.HashtableAst])
            {
              $HashTableAst = $p.Expression
            }
          }
        }
      }
    }

    if ($null -eq $HashTableAst)
    {
      $result = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                                                  'Message'  = 'Specified file is not a module manifest'; 
                                                  'Extent'   = $ScriptBlockAst.Extent
                                                  'RuleName' = $PSCmdlet.MyInvocation.InvocationName;
                                                  'Severity' = 'Information'
                                                  }
      $results += $result

      return $results
    }

    $DescriptionFound = $false
    $AuthorFound      = $false

    foreach($Entry in $HashTableAst.KeyValuePairs)
    {
      if ($Entry.Item1.Extent.Text -ieq 'Description') {$DescriptionFound = $true}
      if ($Entry.Item1.Extent.Text -ieq 'Author') {$AuthorFound = $true}
    }

    

    if (-not $DescriptionFound)
    {    
      $result = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                                                  'Message'  = 'Description not defined in module manifest, required for publishing'; 
                                                  'Extent'   = $HashTableAst.Extent
                                                  'RuleName' = $PSCmdlet.MyInvocation.InvocationName;
                                                  'Severity' = 'Error'
                                                  }
      $results += $result
    }

    if (-not $AuthorFound)
    {    
      $result = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{
                                                  'Message'  = 'Author not defined in module manifest, required for publishing'; 
                                                  'Extent'   = $HashTableAst.Extent
                                                  'RuleName' = $PSCmdlet.MyInvocation.InvocationName;
                                                  'Severity' = 'Error'
                                                  }
      $results += $result
    }


     return $results
}
