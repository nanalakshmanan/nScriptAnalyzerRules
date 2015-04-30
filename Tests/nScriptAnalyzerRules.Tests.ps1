$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$sut = (Split-Path -Leaf $MyInvocation.MyCommand.Path).Replace(".Tests.", ".")
. "$here\$sut"

function Get-ScriptBlockAst
{
    param(
        [string]
        $Path
    )

    New-Variable Tokens
    New-Variable ParseErrors

    $Ast = [Management.Automation.Language.Parser]::ParseFile($Path, [ref]$Tokens, [ref]$ParseErrors)

    $Ast
}

Describe "nScriptAnalyzerRules" {

    Context "DescriptionFiledMissing" {

        $ExpectedResult = @{Message  = 'Description not defined in module manifest, required for publishing'; 
                            RuleName = 'nTestDescriptionAndAuthorField';
                            Severity = 'Error'}

        $result = nTestDescriptionAndAuthorField -ScriptBlockAst (Get-ScriptBlockAst -Path "$here\TestData\1.psd1")
        
        It 'Test result object returned for DescriptionFiledMissing' {
            $result -ne $null | should be $true
        }

        $ExpectedResult.Keys | % {
            It "DescriptionFiledMissing : Testing if $($_) is $($ExpectedResult[$_])" {
                $result.$_ | Should be $ExpectedResult[$_]
            }
        }        
    }

    Context "AuthorFiledMissing" {

        $ExpectedResult = @{Message  = 'Author not defined in module manifest, required for publishing'; 
                            RuleName = 'nTestDescriptionAndAuthorField';
                            Severity = 'Error'}

        $result = nTestDescriptionAndAuthorField -ScriptBlockAst (Get-ScriptBlockAst -Path "$here\TestData\2.psd1")
        
        It 'Test result object returned for AuthorFiledMissing' {
            $result -ne $null | should be $true
        }

        $ExpectedResult.Keys | % {
            It "AuthorFiledMissing : Testing if $($_) is $($ExpectedResult[$_])" {
                $result.$_ | Should be $ExpectedResult[$_]
            }
        }        
    }

    Context "TestInvalidPsd1" {

        $ExpectedResult = @{Message  = 'Specified file is not a module manifest'; 
                            RuleName = 'nTestDescriptionAndAuthorField';
                            Severity = 'Information'}

        $result = nTestDescriptionAndAuthorField -ScriptBlockAst (Get-ScriptBlockAst -Path "$here\TestData\3.psd1")
        
        It 'Test result object returned for TestInvalidPsd1' {
            $result -ne $null | should be $true
        }

        $ExpectedResult.Keys | % {
            It "TestInvalidPsd1 : Testing if $($_) is $($ExpectedResult[$_])" {
                $result.$_ | Should be $ExpectedResult[$_]
            }
        }        
    }
}
