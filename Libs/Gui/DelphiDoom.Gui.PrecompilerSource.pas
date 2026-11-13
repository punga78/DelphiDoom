{******************************************************************************}
{                                                                              }
{  DelphiDoom: Gui library - tokens of a menu file from the idParser           }
{                                                                              }
{  The trap_PC_* calls of the ui module of Quake III Arena reach the botlib    }
{  precompiler (l_script.c, l_precomp.c). idLexer and idParser of Doom 3       }
{  (Libs\Scanner, Libs\IdLib) come from the same lineage and read the same     }
{  dialect (#define with parameters, #include, #ifdef, strings that join,      }
{  C punctuation), so they are used here instead of a second port: see         }
{  Libs\Gui\README.md for the differences that were found.                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.PrecompilerSource;

interface

uses
  System.SysUtils, DelphiDoom.Gui.Types, DelphiDoom.Gui.Intf, DelphiDoom.IdLib.Core.Intf,
  DelphiDoom.Scanner.IdParser;

type
  /// <summary>An open menu file: an idParser configured as the botlib precompiler of the ui module (PC_ReadTokenHandle)</summary>
  TGuiPrecompilerSource = class(TInterfacedObject, IGuiTokenSource)
  strict private
    FParser: TIdParser;
    FFileName: AnsiString;
  public
    /// <summary>Opens AFileName through the file system; nil when it cannot be read</summary>
    class function Open(const AFileName: AnsiString; const AFileSystem: IIdLibFileSystem;
      const ALog: IIdLibLog): TGuiPrecompilerSource; static;
    destructor Destroy; override;
    function ReadToken(out AToken: TGuiToken): Boolean;
    function FileName: AnsiString;
    function Line: Integer;
  end;

implementation

uses
  DelphiDoom.IdLib.Text.Token, DelphiDoom.IdLib.Text.Types;

class function TGuiPrecompilerSource.Open(const AFileName: AnsiString; const AFileSystem: IIdLibFileSystem;
  const ALog: IIdLibLog): TGuiPrecompilerSource;
var
  LParser: TIdParser;
begin
  // no fatal errors (a mistake is reported and the reading goes on), no $ directives (botlib has none)
  LParser := TIdParser.Create(LEXFL_NOFATALERRORS or LEXFL_NODOLLARPRECOMPILE, ALog, AFileSystem);
  if not LParser.LoadFile(AFileName) then
  begin
    LParser.Free;
    Exit(nil);
  end;
  Result := TGuiPrecompilerSource.Create;
  Result.FParser := LParser;
  Result.FFileName := AFileName;
end;

destructor TGuiPrecompilerSource.Destroy;
begin
  FParser.Free;
  inherited Destroy;
end;

function TGuiPrecompilerSource.ReadToken(out AToken: TGuiToken): Boolean;
var
  LToken: TIdToken;
begin
  AToken := Default(TGuiToken);
  LToken := TIdToken.Create;
  Result := FParser.ReadToken(LToken);
  AToken.Text := LToken.Text;
  AToken.TokenType := LToken.TokenType;
  AToken.SubType := LToken.SubType;
  if LToken.TokenType = TT_NUMBER then
  begin
    AToken.IntValue := LToken.GetIntValue;
    AToken.FloatValue := LToken.GetFloatValue;
  end;
end;

function TGuiPrecompilerSource.FileName: AnsiString;
begin
  Result := FFileName;
end;

function TGuiPrecompilerSource.Line: Integer;
begin
  Result := FParser.LineNum;
end;

end.
