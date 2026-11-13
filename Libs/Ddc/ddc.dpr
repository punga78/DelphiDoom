program ddc;

{$APPTYPE CONSOLE}

uses
  cmdline_compiler in 'cmdline_compiler.pas',
{$IFNDEF CPUX86}
  DelphiDoom.MathCore.Types in '..\MathCore\DelphiDoom.MathCore.Types.pas',
  DelphiDoom.MathCore.FixedMath in '..\MathCore\DelphiDoom.MathCore.FixedMath.pas',
  DelphiDoom.MathCore.MemoryFill in '..\MathCore\DelphiDoom.MathCore.MemoryFill.pas',
{$ENDIF}
  d_delphi in '..\..\Common\d_delphi.pas',
  ddc_base in 'ddc_base.pas';

{$R ddc_icon.res}

begin
  CmdLineCompiler;
end.
