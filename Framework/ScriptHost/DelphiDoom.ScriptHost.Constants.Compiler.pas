{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - the constants of the scripts in the compiler      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Constants.Compiler;

interface

uses
  ps_defs,
  ps_compiler,
  DelphiDoom.ScriptHost.Constants.Intf;

type
  /// <summary>The table of constants that writes in a compiler of scripts (AddConstant)</summary>
  TScriptCompilerConstants = class(TInterfacedObject, IScriptConstantTable)
  strict private
    FCompiler: TPSPascalCompiler;
    FIntegerType: TPSType;
    FLongWordType: TPSType;
    FExtendedType: TPSType;
  public
    /// <summary>The compiler must know the types integer, longword and extended</summary>
    constructor Create(const ACompiler: TPSPascalCompiler);
    procedure AddInteger(const AName: string; const AValue: Integer);
    procedure AddLongWord(const AName: string; const AValue: Cardinal);
    procedure AddExtended(const AName: string; const AValue: Extended);
  end;

implementation

uses
  System.SysUtils;

{ TScriptCompilerConstants }

constructor TScriptCompilerConstants.Create(const ACompiler: TPSPascalCompiler);
begin
  inherited Create;
  if not Assigned(ACompiler) then
    raise EArgumentNilException.Create('ACompiler');
  FCompiler := ACompiler;
  FExtendedType := ACompiler.FindType('extended');
  FIntegerType := ACompiler.FindType('integer');
  FLongWordType := ACompiler.FindType('longword');
end;

procedure TScriptCompilerConstants.AddInteger(const AName: string; const AValue: Integer);
begin
  FCompiler.AddConstant(TbtString(AName), FIntegerType).Value.ts32 := AValue;
end;

procedure TScriptCompilerConstants.AddLongWord(const AName: string; const AValue: Cardinal);
begin
  FCompiler.AddConstant(TbtString(AName), FLongWordType).Value.tu32 := AValue;
end;

procedure TScriptCompilerConstants.AddExtended(const AName: string; const AValue: Extended);
begin
  FCompiler.AddConstant(TbtString(AName), FExtendedType).Value.textended := AValue;
end;

end.
