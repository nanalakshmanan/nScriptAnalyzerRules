$here = Split-Path -Parent $MyInvocation.MyCommand.Path

Import-Module PSScriptAnalyzer
Import-Module "$here\..\nScriptAnalyzerRules.psm1" -Force
