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
                                                  'Extent'   = $HashTableAst.Extent
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


function Measure-RequiresRunAsAdministrator
{
    [CmdletBinding()]
    [OutputType([Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord[]])]
    Param
    (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [System.Management.Automation.Language.ScriptBlockAst]
        $ScriptBlockAst
    )

    Process
    {
        $results = @()

        try
        {
            #region Define predicates to find ASTs.

            # Finds specific method, IsInRole.
            [ScriptBlock]$predicate1 = {
                param ([System.Management.Automation.Language.Ast]$Ast)

                [bool]$returnValue = $false

                if ($Ast -is [System.Management.Automation.Language.MemberExpressionAst])
                {
                    [System.Management.Automation.Language.MemberExpressionAst]$meAst = $ast;
                    if ($meAst.Member -is [System.Management.Automation.Language.StringConstantExpressionAst])
                    {
                        [System.Management.Automation.Language.StringConstantExpressionAst]$sceAst = $meAst.Member;
                        if ($sceAst.Value -eq "isinrole")
                        {
                            $returnValue = $true;
                        }
                    }
                }

                return $returnValue
            }

            # Finds specific value, [system.security.principal.windowsbuiltinrole]::administrator.
            [ScriptBlock]$predicate2 = {
                param ([System.Management.Automation.Language.Ast]$Ast)

                [bool]$returnValue = $false

                if ($ast -is [System.Management.Automation.Language.AssignmentStatementAst])
                {
                    [System.Management.Automation.Language.AssignmentStatementAst]$asAst = $Ast;
                    if ($asAst.Right.ToString().ToLower() -eq "[system.security.principal.windowsbuiltinrole]::administrator")
                    {
                        $returnValue = $true
                    }
                }

                return $returnValue
            }

            #endregion

            #region Finds ASTs that match the predicates.
        
            [System.Management.Automation.Language.Ast[]]$methodAst     = $ScriptBlockAst.FindAll($predicate1, $true)
            [System.Management.Automation.Language.Ast[]]$assignmentAst = $ScriptBlockAst.FindAll($predicate2, $true)

            if ($null -ne $ScriptBlockAst.ScriptRequirements)
            {
                if ((!$ScriptBlockAst.ScriptRequirements.IsElevationRequired) -and 
                    ($methodAst.Count -ne 0) -and ($assignmentAst.Count -ne 0))
                {
                    $result = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{"Message"  = $Messages.MeasureRequiresRunAsAdministrator; 
                                                "Extent"   = $assignmentAst.Extent;
                                                "RuleName" = v;
                                                "Severity" = "Information"}
                    $results += $result               
                }
            }
            else
            {
                if (($methodAst.Count -ne 0) -and ($assignmentAst.Count -ne 0))
                {
                    $result = [Microsoft.Windows.Powershell.ScriptAnalyzer.Generic.DiagnosticRecord]@{"Message"  = $Messages.MeasureRequiresRunAsAdministrator; 
                                                "Extent"   = $assignmentAst.Extent;
                                                "RuleName" = $PSCmdlet.MyInvocation.InvocationName;
                                                "Severity" = "Information"}
                    $results += $result               
                }        
            }

            return $results

            #endregion 
        }
        catch
        {
            $PSCmdlet.ThrowTerminatingError($PSItem)
        }
    }
}
