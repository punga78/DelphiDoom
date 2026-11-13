{******************************************************************************}
{                                                                              }
{  DelphiDoom: scanner library - TIdParserGlobalDefines, the defines added to  }
{  every source a parser loads                                                 }
{                                                                              }
{  Port of idLib (id Software, Doom 3, GPL v3): idParser::globaldefines and    }
{  AddGlobalDefine, RemoveGlobalDefine, RemoveAllGlobalDefines.                }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore       }
{  available under the GNU General Public License, version 3, with the         }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Libs\IdLib); the repository as a whole is GPL v2 or later.                  }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Scanner.IdParser.GlobalDefines;

interface

uses
  System.Generics.Collections, DelphiDoom.Scanner.IdParser.Define;

type
  /// <summary>
  ///   The static list of the original, now an object the caller owns and gives to the parsers that
  ///   should see it (no global state). New defines go to the front, as in the original; the list
  ///   owns the defines. Add them with TIdParser.AddGlobalDefine (it parses the text).
  /// </summary>
  TIdParserGlobalDefines = class
  private
    FDefines: TObjectList<TIdParserDefine>;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Puts a define at the front; the list takes ownership</summary>
    procedure Push(const ADefine: TIdParserDefine);
    /// <summary>idParser::RemoveGlobalDefine: false if there is no define with the name</summary>
    function Remove(const AName: AnsiString): Boolean;
    /// <summary>idParser::RemoveAllGlobalDefines</summary>
    procedure Clear;
    function Count: Integer;
    /// <summary>From the front (the last added first)</summary>
    function Item(const AIndex: Integer): TIdParserDefine;
  end;

implementation

{ TIdParserGlobalDefines }

constructor TIdParserGlobalDefines.Create;
begin
  inherited Create;
  FDefines := TObjectList<TIdParserDefine>.Create(True);
end;

destructor TIdParserGlobalDefines.Destroy;
begin
  FDefines.Free;
  inherited Destroy;
end;

procedure TIdParserGlobalDefines.Push(const ADefine: TIdParserDefine);
begin
  FDefines.Insert(0, ADefine);
end;

function TIdParserGlobalDefines.Remove(const AName: AnsiString): Boolean;
var
  LIndex: Integer;
begin
  for LIndex := 0 to FDefines.Count - 1 do
    if FDefines[LIndex].Name = AName then
    begin
      FDefines.Delete(LIndex);
      Exit(True);
    end;
  Result := False;
end;

procedure TIdParserGlobalDefines.Clear;
begin
  FDefines.Clear;
end;

function TIdParserGlobalDefines.Count: Integer;
begin
  Result := FDefines.Count;
end;

function TIdParserGlobalDefines.Item(const AIndex: Integer): TIdParserDefine;
begin
  Result := FDefines[AIndex];
end;

end.
