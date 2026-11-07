{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the ide library - a compiler library read from files   }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Ide.FakeGameLibrary;

interface

uses
  System.SysUtils,
  System.Classes,
  System.Generics.Collections,
  DelphiDoom.Ide.Types,
  DelphiDoom.Ide.Intf;

type
  /// <summary>
  ///   Answers with the lines that the real ddc_*.dll gave (Tests\Data\Ide\Library\*.txt), or with
  ///   lines the test puts in it. A game or a list that was not given is "not available"
  /// </summary>
  TFakeIdeGameLibrary = class(TInterfacedObject, IIdeGameLibrary)
  strict private
    FLines: TDictionary<string, TArray<string>>;
    FUnits: TDictionary<string, TArray<TIdeUnitDeclarations>>;
  public
    OpenedGames: TStringList;
    CloseCount: Integer;
    constructor Create;
    destructor Destroy; override;
    /// <summary>Reads the files of a game that the old code saved (all the lists and the units)</summary>
    procedure LoadGameFromFiles(const AGame: string);
    procedure SetLines(const AData: TIdeLibraryData; const AGame: string; const ALines: array of string);
    procedure SetUnits(const AGame: string; const AUnits: TArray<TIdeUnitDeclarations>);
    procedure Open(const AGame: string);
    procedure Close;
    function TryGetLines(const AData: TIdeLibraryData; const AGame: string;
      out ALines: TArray<string>): Boolean;
    function TryGetUnitFunctions(const AGame: string;
      out AUnits: TArray<TIdeUnitDeclarations>): Boolean;
  end;

implementation

uses
  DelphiDoom.Tests.Ide.TestData;

const
  FILE_NAMES: array[TIdeLibraryData] of string = (
    'constants', 'variables', 'types', 'classes', 'events', 'actordeffunctions', 'mobjinfo',
    'states', 'sprites');

function Key(const AData: TIdeLibraryData; const AGame: string): string;
begin
  Result := AGame + '.' + FILE_NAMES[AData];
end;

{ TFakeIdeGameLibrary }

constructor TFakeIdeGameLibrary.Create;
begin
  inherited Create;
  FLines := TDictionary<string, TArray<string>>.Create;
  FUnits := TDictionary<string, TArray<TIdeUnitDeclarations>>.Create;
  OpenedGames := TStringList.Create;
end;

destructor TFakeIdeGameLibrary.Destroy;
begin
  OpenedGames.Free;
  FUnits.Free;
  FLines.Free;
  inherited Destroy;
end;

procedure TFakeIdeGameLibrary.LoadGameFromFiles(const AGame: string);
var
  LData: TIdeLibraryData;
  LFile: TStringList;
  LUnits: TList<TIdeUnitDeclarations>;
  LUnit: TIdeUnitDeclarations;
  LDeclarations: TList<string>;
  LLine: string;

  procedure Flush;
  begin
    if LUnit.UnitName <> '' then
    begin
      LUnit.Declarations := LDeclarations.ToArray;
      LUnits.Add(LUnit);
    end;
    LDeclarations.Clear;
  end;

begin
  for LData := Low(TIdeLibraryData) to High(TIdeLibraryData) do
  begin
    LFile := TIdeTestData.ReadLines('Library\' + Key(LData, AGame) + '.txt');
    try
      // the old generator wrote "<nil>" for a list the dll did not have
      if (LFile.Count = 1) and (LFile[0] = '<nil>') then
        Continue;
      FLines.AddOrSetValue(Key(LData, AGame), LFile.ToStringArray);
    finally
      LFile.Free;
    end;
  end;
  LFile := TIdeTestData.ReadLines('Library\' + AGame + '.unitfunctions.txt');
  LUnits := TList<TIdeUnitDeclarations>.Create;
  LDeclarations := TList<string>.Create;
  try
    LUnit.UnitName := '';
    for LLine in LFile do
      if (Length(LLine) > 2) and (LLine[1] = '[') and (LLine[Length(LLine)] = ']') then
      begin
        Flush;
        LUnit.UnitName := Copy(LLine, 2, Length(LLine) - 2);
      end
      else
        LDeclarations.Add(LLine);
    Flush;
    FUnits.AddOrSetValue(AGame, LUnits.ToArray);
  finally
    LDeclarations.Free;
    LUnits.Free;
    LFile.Free;
  end;
end;

procedure TFakeIdeGameLibrary.SetLines(const AData: TIdeLibraryData; const AGame: string;
  const ALines: array of string);
var
  LLines: TArray<string>;
  LIndex: Integer;
begin
  SetLength(LLines, Length(ALines));
  for LIndex := 0 to High(ALines) do
    LLines[LIndex] := ALines[LIndex];
  FLines.AddOrSetValue(Key(AData, AGame), LLines);
end;

procedure TFakeIdeGameLibrary.SetUnits(const AGame: string; const AUnits: TArray<TIdeUnitDeclarations>);
begin
  FUnits.AddOrSetValue(AGame, AUnits);
end;

procedure TFakeIdeGameLibrary.Open(const AGame: string);
begin
  OpenedGames.Add(AGame);
end;

procedure TFakeIdeGameLibrary.Close;
begin
  Inc(CloseCount);
end;

function TFakeIdeGameLibrary.TryGetLines(const AData: TIdeLibraryData; const AGame: string;
  out ALines: TArray<string>): Boolean;
begin
  Result := FLines.TryGetValue(Key(AData, AGame), ALines);
  if not Result then
    ALines := nil;
end;

function TFakeIdeGameLibrary.TryGetUnitFunctions(const AGame: string;
  out AUnits: TArray<TIdeUnitDeclarations>): Boolean;
begin
  Result := FUnits.TryGetValue(AGame, AUnits);
  if not Result then
    AUnits := nil;
end;

end.
