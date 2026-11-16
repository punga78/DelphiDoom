{******************************************************************************}
{                                                                              }
{  DelphiDoom: script host - a list of names with a hash table                 }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{  It is THashStringList of psi_globals.pas as a class of its own.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ScriptHost.Variables.HashList;

interface

uses
  System.Classes,
  DelphiDoom.ScriptHost.Variables.HashTable;

type
  /// <summary>
  ///   A list of strings that finds a string through a hash table. Search is case sensitive
  ///   (the variables use upper case names): it is not the search of TStringList
  /// </summary>
  TScriptHashStringList = class(TStringList)
  strict private
    FHash: TScriptHashTable;
  protected
    procedure InsertItem(AIndex: Integer; const AString: string; AObject: TObject); override;
  public
    constructor Create;
    destructor Destroy; override;
    function IndexOf(const AString: string): Integer; override;
  end;

implementation

{ TScriptHashStringList }

constructor TScriptHashStringList.Create;
begin
  FHash := TScriptHashTable.Create;
  inherited Create;
  FHash.AssignStringList(Self);
end;

destructor TScriptHashStringList.Destroy;
begin
  inherited Destroy;
  FHash.Free;
end;

procedure TScriptHashStringList.InsertItem(AIndex: Integer; const AString: string; AObject: TObject);
var
  LRebuild: Boolean;
begin
  LRebuild := AIndex < Count;
  inherited InsertItem(AIndex, AString, AObject);
  if LRebuild then
  begin
    if not Sorted then
      FHash.AssignStringList(Self);
  end
  else
    FHash.Insert(AString, AIndex);
end;

function TScriptHashStringList.IndexOf(const AString: string): Integer;
begin
  if Count = 0 then
    Exit(-1);

  if Sorted then
  begin
    if not Find(AString, Result) then
      Result := -1;
    Exit;
  end;

  Result := FHash.CheckPos(AString);
end;

end.
