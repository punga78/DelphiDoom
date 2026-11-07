{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a compiler that answers as told      }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeScriptCompiler;

interface

uses
  DelphiDoom.Ide.Intf;

type
  /// <summary>Gives the answer the test put in it and remembers what it was asked</summary>
  TFakeIdeScriptCompiler = class(TInterfacedObject, IIdeScriptCompiler)
  public
    Succeeds: Boolean;
    PCode: string;
    Messages: string;
    DisassemblyText: string;
    LastGame: string;
    LastSource: string;
    LastDisassembledGame: string;
    LastDisassembledPCode: string;
    CompileCount: Integer;
    function Compile(const AGame, ASource: string; out APCode, AMessages: string): Boolean;
    function Disassemble(const AGame, APCode: string): string;
  end;

implementation

{ TFakeIdeScriptCompiler }

function TFakeIdeScriptCompiler.Compile(const AGame, ASource: string; out APCode,
  AMessages: string): Boolean;
begin
  Inc(CompileCount);
  LastGame := AGame;
  LastSource := ASource;
  APCode := PCode;
  AMessages := Messages;
  Result := Succeeds;
end;

function TFakeIdeScriptCompiler.Disassemble(const AGame, APCode: string): string;
begin
  LastDisassembledGame := AGame;
  LastDisassembledPCode := APCode;
  Result := DisassemblyText;
end;

end.
