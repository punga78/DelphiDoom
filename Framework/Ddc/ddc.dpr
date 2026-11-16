program ddc;

{$APPTYPE CONSOLE}

uses
  cmdline_compiler in 'cmdline_compiler.pas',
  DelphiDoom.ScriptHost.Compiled in '..\ScriptHost\DelphiDoom.ScriptHost.Compiled.pas',
  ddc_base in 'ddc_base.pas';

{$R ddc_icon.res}

begin
  CmdLineCompiler;
end.
