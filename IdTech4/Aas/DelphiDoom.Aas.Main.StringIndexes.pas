{******************************************************************************}
{                                                                              }
{  DelphiDoom: AAS library - the string indexes of the game                     }
{                                                                              }
{  Port of AAS_UpdateStringIndexes, AAS_StringFromIndex, AAS_IndexFromString,   }
{  AAS_ModelFromIndex and AAS_IndexFromModel of be_aas_main.c. Based on the     }
{  Quake III Arena GPL Source Code (id Software). Copyright (C) 1999-2005 Id    }
{  Software, Inc. This unit is derived from the Quake III Arena source code     }
{  and is therefore available under the GNU General Public License, version 2   }
{  or (at your option) any later version.                                       }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Aas.Main.StringIndexes;

interface

uses
  DelphiDoom.BotAi.Import.Intf;

const
  /// <summary>MAX_CONFIGSTRINGS, CS_MODELS and MAX_MODELS of the game</summary>
  AAS_MAX_CONFIGSTRINGS = 1024;
  AAS_CS_MODELS = 32;
  AAS_MAX_MODELS = 256;

type
  /// <summary>
  ///   The configuration strings that the game gives (a copy). A string that is empty counts as not given: the
  ///   original tells a NULL pointer from an empty string, this does not. The import is not owned
  /// </summary>
  TAasStringIndexes = class
  strict private
    FImport: IBotImport;
    FSetup: Boolean;
    FStrings: array[0..AAS_MAX_CONFIGSTRINGS - 1] of AnsiString;
    function StringFromIndex(const AIndexName: AnsiString; const AFirst, ACount, AIndex: Integer): AnsiString;
    function IndexFromString(const AIndexName: AnsiString; const AFirst, ACount: Integer;
      const AText: AnsiString): Integer;
  public
    constructor Create(const AImport: IBotImport);
    /// <summary>AAS_UpdateStringIndexes: the strings beyond the 1024 of the table are not kept</summary>
    procedure Update(const AConfigStrings: TArray<AnsiString>);
    /// <summary>AAS_ModelFromIndex: the name of the model, empty (with a message) if it is not there</summary>
    function ModelFromIndex(const AIndex: Integer): AnsiString;
    /// <summary>AAS_IndexFromModel: the index of the model, ignoring the case; 0 if not found</summary>
    function IndexFromModel(const AModelName: AnsiString): Integer;
    /// <summary>aasworld.indexessetup</summary>
    property IsSetup: Boolean read FSetup;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.BotAi.Types, DelphiDoom.Aas.Printer;

resourcestring
  SNotSetup = '%s: index %d not setup'#10;
  SNotSetupName = '%s: index not setup "%s"'#10;
  SOutOfRange = '%s: index %d out of range'#10;
  SUnused = '%s: reference to unused index %d'#10;

{ TAasStringIndexes }

constructor TAasStringIndexes.Create(const AImport: IBotImport);
begin
  inherited Create;
  FImport := AImport;
end;

procedure TAasStringIndexes.Update(const AConfigStrings: TArray<AnsiString>);
var
  LIndex: Integer;
begin
  for LIndex := 0 to High(AConfigStrings) do
    if (LIndex < AAS_MAX_CONFIGSTRINGS) and (AConfigStrings[LIndex] <> '') then
      FStrings[LIndex] := AConfigStrings[LIndex];
  FSetup := True;
end;

function TAasStringIndexes.StringFromIndex(const AIndexName: AnsiString; const AFirst, ACount,
  AIndex: Integer): AnsiString;
begin
  Result := '';
  if not FSetup then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SNotSetup, [string(AIndexName), AIndex]));
    Exit;
  end;
  if (AIndex < 0) or (AIndex >= ACount) then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SOutOfRange, [string(AIndexName), AIndex]));
    Exit;
  end;
  if FStrings[AFirst + AIndex] = '' then
  begin
    if AIndex <> 0 then
      TAasPrinter.Print(FImport, PRT_ERROR, Format(SUnused, [string(AIndexName), AIndex]));
    Exit;
  end;
  Result := FStrings[AFirst + AIndex];
end;

function TAasStringIndexes.IndexFromString(const AIndexName: AnsiString; const AFirst, ACount: Integer;
  const AText: AnsiString): Integer;
var
  LIndex: Integer;
begin
  Result := 0;
  if not FSetup then
  begin
    TAasPrinter.Print(FImport, PRT_ERROR, Format(SNotSetupName, [string(AIndexName), string(AText)]));
    Exit;
  end;
  for LIndex := 0 to ACount - 1 do
  begin
    if FStrings[AFirst + LIndex] = '' then
      Continue;
    // Q_stricmp: the case of the ASCII letters is ignored
    if SameText(string(FStrings[AFirst + LIndex]), string(AText)) then
      Exit(LIndex);
  end;
end;

function TAasStringIndexes.ModelFromIndex(const AIndex: Integer): AnsiString;
begin
  Result := StringFromIndex('ModelFromIndex', AAS_CS_MODELS, AAS_MAX_MODELS, AIndex);
end;

function TAasStringIndexes.IndexFromModel(const AModelName: AnsiString): Integer;
begin
  Result := IndexFromString('IndexFromModel', AAS_CS_MODELS, AAS_MAX_MODELS, AModelName);
end;

end.
