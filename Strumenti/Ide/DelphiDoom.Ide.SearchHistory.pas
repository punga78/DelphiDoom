{******************************************************************************}
{                                                                              }
{  DelphiDoom: ide library - the texts the user searched for                   }
{  Copyright (C) 2016-2022 by Jim Valavanis (original DD_IDE)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Ide.SearchHistory;

interface

uses
  System.Classes;

type
  /// <summary>
  ///   The drop down list of the search (or replace) dialog: the last texts, the newest first. A
  ///   text that is used again moves to the front (the case does not count, as in a combo box);
  ///   the list given back to the next dialog has at most IDE_SEARCH_HISTORY_LIMIT texts
  /// </summary>
  TIdeSearchHistory = class
  strict private
    FItems: TStringList;
    function GetCount: Integer;
    function GetItem(const AIndex: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;
    /// <summary>Puts the text at the front; an empty text is ignored</summary>
    procedure Remember(const AText: string);
    /// <summary>The first texts, one per line, as the dialogs keep it between two uses</summary>
    function AsText: string;
    procedure LoadFromText(const AText: string);
    property Count: Integer read GetCount;
    property Items[const AIndex: Integer]: string read GetItem; default;
  end;

implementation

uses
  DelphiDoom.Ide.Types;

{ TIdeSearchHistory }

constructor TIdeSearchHistory.Create;
begin
  inherited Create;
  FItems := TStringList.Create;
end;

destructor TIdeSearchHistory.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

function TIdeSearchHistory.GetCount: Integer;
begin
  Result := FItems.Count;
end;

function TIdeSearchHistory.GetItem(const AIndex: Integer): string;
begin
  Result := FItems[AIndex];
end;

procedure TIdeSearchHistory.Remember(const AText: string);
var
  LIndex: Integer;
begin
  if AText = '' then
    Exit;
  LIndex := FItems.IndexOf(AText);
  if LIndex > -1 then
    FItems.Delete(LIndex);
  FItems.Insert(0, AText);
end;

function TIdeSearchHistory.AsText: string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 0 to FItems.Count - 1 do
  begin
    if LIndex >= IDE_SEARCH_HISTORY_LIMIT then
      Break;
    if LIndex > 0 then
      Result := Result + #13#10;
    Result := Result + FItems[LIndex];
  end;
end;

procedure TIdeSearchHistory.LoadFromText(const AText: string);
begin
  FItems.Text := AText;
end;

end.
