program ddc;

{$APPTYPE CONSOLE}

uses
  cmdline_compiler in 'cmdline_compiler.pas',
  d_delphi in '..\..\Common\d_delphi.pas',
  ddc_base in 'ddc_base.pas';

{$R ddc_icon.res}

begin
  CmdLineCompiler;
end.
