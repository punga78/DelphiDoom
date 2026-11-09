program ddc;

{$APPTYPE CONSOLE}

uses
  cmdline_compiler in '..\SCRIPT\cmdline_compiler.pas',
  d_delphi in '..\Common\d_delphi.pas',
  ddc_base in '..\SCRIPT\ddc_base.pas';

{$R ddc_icon.res}

begin
  CmdLineCompiler;
end.
