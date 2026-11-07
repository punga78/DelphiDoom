{******************************************************************************}
{                                                                              }
{  DelphiDoom: the defines of the game that every script finds                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Engine.Scanner.DefinesSource;

interface

uses
  DelphiDoom.Scanner.Preprocessor.Intf;

type
  /// <summary>The list gamedefines of sc_defines, read at every script as the old SC_Preprocess did</summary>
  TEngineScriptDefinesSource = class(TInterfacedObject, IScriptDefinesSource)
  public
    function Defines: TArray<string>;
  end;

implementation

uses
  sc_defines;

{ TEngineScriptDefinesSource }

function TEngineScriptDefinesSource.Defines: TArray<string>;
var
  LIndex: Integer;
begin
  SetLength(Result, gamedefines.Count);
  for LIndex := 0 to gamedefines.Count - 1 do
    Result[LIndex] := gamedefines.Strings[LIndex];
end;

end.
