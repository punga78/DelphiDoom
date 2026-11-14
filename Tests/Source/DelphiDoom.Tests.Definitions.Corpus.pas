{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the definitions library - the corpus and the dumps     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Definitions.Corpus;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  DelphiDoom.Definitions.Types;

type
  /// <summary>
  ///   Runs the texts of Tests\Data\Definitions through the library and writes the same dump
  ///   that the harness of the old code wrote (see Tests\Data\Definitions\README.md)
  /// </summary>
  TDefinitionsCorpus = class
  public
    class function DataPath(const AFileName: string): string; static;
    class function LoadLines(const APath: string): TStringList; static;
    /// <summary>The characters outside 32..126 as \xNNNN</summary>
    class function Escape(const AText: string): string; static;
    class function DumpAnimations(const ACasesFile: string): TStringList; static;
    class function DumpSwitches(const ACasesFile: string; AStrife: Boolean): TStringList; static;
    class function DumpTerrain(AGame: TDefGame; const ANamesFile: string): TStringList; static;
    class function DumpSwitchTable(AGame: TDefGame): TStringList; static;
    /// <summary>The number that the game gave to the kind of floor in p_local.pas</summary>
    class function OldTerrainNumber(AGame: TDefGame; AKind: TDefTerrainKind): Integer; static;
    /// <summary>Compares two dumps by case: the names of the cases that differ, and the first line that differs</summary>
    class function Compare(AActual, AExpected: TStringList; out ADetail: string): Integer; static;
  end;

implementation

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Definitions.Intf, DelphiDoom.Definitions.Factory,
  DelphiDoom.Scanner.Strings, DelphiDoom.Tests.Definitions.Fakes;

function SplitWords(const AText: string): TArray<string>;
var
  LList: TList<string>;
  LWord: string;
begin
  LList := TList<string>.Create;
  try
    for LWord in AText.Split([' ']) do
      if LWord <> '' then
        LList.Add(TScannerStrings.UpperAscii(LWord));
    Result := LList.ToArray;
  finally
    LList.Free;
  end;
end;

function EscapeLine(const AText: string): string;
begin
  Result := TDefinitionsCorpus.Escape(AText.Replace(#13, '\r').Replace(#10, '\n'));
end;

procedure AddWarnings(ADump: TStringList; ALog: TFakeLog);
var
  LIndex: Integer;
begin
  for LIndex := 0 to ALog.Count - 1 do
    ADump.Add('W ' + EscapeLine(ALog[LIndex]));
end;

function GenerateText(ACount, AFrames: Integer): string;
var
  LAnimation: Integer;
  LFrame: Integer;
begin
  Result := '';
  for LAnimation := 1 to ACount do
  begin
    Result := Result + 'flat NUKAGE1';
    for LFrame := 1 to AFrames do
      Result := Result + Format(' pic %d tics 8', [LFrame]);
    Result := Result + #10;
  end;
end;

{ TDefinitionsCorpus }

class function TDefinitionsCorpus.DataPath(const AFileName: string): string;
begin
  Result := TPath.GetFullPath(TPath.Combine(TPath.GetDirectoryName(ParamStr(0)),
    '..\..\..\..\Tests\Data\Definitions\' + AFileName));
end;

class function TDefinitionsCorpus.LoadLines(const APath: string): TStringList;
begin
  Result := TStringList.Create;
  Result.LoadFromFile(APath);
end;

class function TDefinitionsCorpus.Escape(const AText: string): string;
var
  LIndex: Integer;
begin
  Result := '';
  for LIndex := 1 to Length(AText) do
    if (Ord(AText[LIndex]) < 32) or (Ord(AText[LIndex]) > 126) then
      Result := Result + Format('\x%.4X', [Ord(AText[LIndex])])
    else
      Result := Result + AText[LIndex];
end;

class function TDefinitionsCorpus.DumpAnimations(const ACasesFile: string): TStringList;
var
  LLines: TStringList;
  LCatalog: TFakeCatalog;
  LCatalogIntf: IDefAnimNameCatalog;
  LName: string;
  LText: string;
  LSeparator: string;
  LHaveCase: Boolean;
  LLine: string;
  LIndex: Integer;
  LWords: TArray<string>;

  procedure RunCase;
  var
    LLog: TFakeLog;
    LLogIntf: ILog;
    LParser: IDefAnimDefsParser;
    LAnimations: TArray<TDefAnimation>;
    LAnimation: TDefAnimation;
    LFrame: TDefAnimFrame;
    LBase: Integer;
    LOffset: Integer;
    LFlats: string;
    LTextures: string;
    LKind: string;
  begin
    Result.Add('=== ' + LName);
    LLog := TFakeLog.Create;
    LLogIntf := LLog;
    LParser := TDefinitionsFactory.CreateAnimDefsParser(LCatalogIntf, LLogIntf);
    try
      LAnimations := LParser.Parse(LText);
    except
      on E: EDefinitionsException do
      begin
        AddWarnings(Result, LLog);
        Result.Add('E ' + E.Message);
        Exit;
      end;
    end;
    AddWarnings(Result, LLog);
    LFlats := 'LF';
    LTextures := 'LT';
    for LAnimation in LAnimations do
    begin
      if LAnimation.Kind = TDefAnimKind.Flat then
        LBase := LCatalog.FlatIndex(LAnimation.Name)
      else
        LBase := LCatalog.TextureIndex(LAnimation.Name);
      if LAnimation.Kind = TDefAnimKind.Flat then
        LKind := 'flat'
      else
        LKind := 'texture';
      Result.Add(Format('A %s %s index=%d frames=%d', [LKind, LAnimation.Name, LBase,
        Length(LAnimation.Frames)]));
      for LFrame in LAnimation.Frames do
        Result.Add(Format('F %d %d', [LBase + LFrame.PicNumber - 1, LFrame.PackedTics]));
      for LOffset in LAnimation.AnimatedOffsets do
        if LAnimation.Kind = TDefAnimKind.Flat then
          LFlats := LFlats + ' ' + IntToStr(LBase + LOffset)
        else
          LTextures := LTextures + ' ' + IntToStr(LBase + LOffset);
    end;
    Result.Add(LFlats);
    Result.Add(LTextures);
  end;

begin
  Result := TStringList.Create;
  LLines := LoadLines(ACasesFile);
  LCatalog := TFakeCatalog.Create([], []);
  LCatalogIntf := LCatalog;
  try
    LHaveCase := False;
    LSeparator := #10;
    LText := '';
    LName := '';
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LLine := LLines[LIndex];
      if Copy(LLine, 1, 7) = '@flats ' then
        LCatalog.SetFlats(SplitWords(Copy(LLine, 8, MaxInt)))
      else if Copy(LLine, 1, 10) = '@textures ' then
        LCatalog.SetTextures(SplitWords(Copy(LLine, 11, MaxInt)))
      else if Copy(LLine, 1, 4) = '@@@ ' then
      begin
        if LHaveCase then
          RunCase;
        LHaveCase := True;
        LName := Copy(LLine, 5, MaxInt);
        LText := '';
        LSeparator := #10;
      end
      else if LLine = '@crlf' then
        LSeparator := #13#10
      else if Copy(LLine, 1, 5) = '@gen ' then
      begin
        LWords := SplitWords(Copy(LLine, 6, MaxInt));
        LText := LText + GenerateText(StrToInt(LWords[0]), StrToInt(LWords[1]));
      end
      else
        LText := LText + LLine + LSeparator;
    end;
    if LHaveCase then
      RunCase;
  finally
    LLines.Free;
    LCatalogIntf := nil;
  end;
end;

class function TDefinitionsCorpus.DumpSwitches(const ACasesFile: string; AStrife: Boolean): TStringList;
var
  LLines: TStringList;
  LCatalog: TFakeCatalog;
  LCatalogIntf: IDefTextureLookup;
  LName: string;
  LBytes: TBytes;
  LNoLump: Boolean;
  LEpisode: Integer;
  LDefaultTextures: TArray<string>;
  LMissing: TList<string>;
  LHaveCase: Boolean;
  LLine: string;
  LIndex: Integer;
  LWord: string;
  LWords: TArray<string>;
  LGame: TDefGame;
  LValue: Integer;

  procedure AddBytes(const ABytes: array of Byte);
  var
    LFirst: Integer;
    LByte: Integer;
  begin
    LFirst := Length(LBytes);
    SetLength(LBytes, LFirst + Length(ABytes));
    for LByte := 0 to High(ABytes) do
      LBytes[LFirst + LByte] := ABytes[LByte];
  end;

  procedure AddName(const AText: string);
  var
    LField: array[0..8] of Byte;
    LChar: Integer;
  begin
    FillChar(LField, SizeOf(LField), 0);
    if AText <> '-' then
      for LChar := 1 to Length(AText) do
        if LChar <= 9 then
          LField[LChar - 1] := Ord(AText[LChar]);
    AddBytes(LField);
  end;

  procedure ApplyTextures;
  var
    LTable: TArray<TDefSwitchPair>;
    LPair: TDefSwitchPair;
    LNames: TList<string>;
    LKept: TList<string>;
    LEntry: string;
  begin
    LNames := TList<string>.Create;
    LKept := TList<string>.Create;
    try
      if (Length(LDefaultTextures) > 0) and (LDefaultTextures[0] = '@FIXED') then
      begin
        LTable := TDefinitionsFactory.CreateSwitchTable(LGame);
        for LPair in LTable do
        begin
          LNames.Add(LPair.Name1);
          LNames.Add(LPair.Name2);
        end;
      end
      else
        LNames.AddRange(LDefaultTextures);
      for LEntry in LNames do
        if not LMissing.Contains(LEntry) then
          LKept.Add(LEntry);
      LCatalog.SetTextures(LKept.ToArray);
    finally
      LNames.Free;
      LKept.Free;
    end;
  end;

  procedure RunCase;
  var
    LLog: TFakeLog;
    LLogIntf: ILog;
    LTable: TArray<TDefSwitchPair>;
    LPair: TDefSwitchPair;
    LResolved: TArray<TDefResolvedSwitch>;
    LEntry: TDefResolvedSwitch;
  begin
    Result.Add('=== ' + LName);
    ApplyTextures;
    LLog := TFakeLog.Create;
    LLogIntf := LLog;
    if LNoLump then
      LTable := TDefinitionsFactory.CreateSwitchTable(LGame)
    else
      LTable := TDefinitionsFactory.CreateSwitchLumpReader(AStrife).Read(LBytes);
    LResolved := TDefinitionsFactory.CreateSwitchSelector(LCatalogIntf, LLogIntf).Select(LTable, LEpisode);
    AddWarnings(Result, LLog);
    for LPair in LTable do
      Result.Add(Format('R %s|%s|%d|%d', [Escape(LPair.Name1), Escape(LPair.Name2), LPair.Episode,
        LPair.Sound]));
    for LEntry in LResolved do
      Result.Add(Format('S %d %d %s %s', [LEntry.Texture1, LEntry.Texture2, Escape(LEntry.Pair.Name1),
        Escape(LEntry.Pair.Name2)]));
  end;

  procedure ResetCase;
  begin
    SetLength(LBytes, 0);
    LNoLump := False;
    if AStrife then
      LEpisode := 2
    else
      LEpisode := 3;
    LMissing.Clear;
  end;

begin
  Result := TStringList.Create;
  LLines := LoadLines(ACasesFile);
  LCatalog := TFakeCatalog.Create([], []);
  LCatalogIntf := LCatalog;
  LMissing := TList<string>.Create;
  if AStrife then
    LGame := TDefGame.Strife
  else
    LGame := TDefGame.Doom;
  try
    LHaveCase := False;
    ResetCase;
    for LIndex := 0 to LLines.Count - 1 do
    begin
      LLine := LLines[LIndex];
      if Copy(LLine, 1, 4) = '@@@ ' then
      begin
        if LHaveCase then
          RunCase;
        LHaveCase := True;
        LName := Copy(LLine, 5, MaxInt);
        ResetCase;
      end
      else if Copy(LLine, 1, 10) = '@textures ' then
        LDefaultTextures := SplitWords(Copy(LLine, 11, MaxInt))
      else if LLine = '@nolump' then
        LNoLump := True
      else if Copy(LLine, 1, 9) = '@episode ' then
        LEpisode := StrToInt(Trim(Copy(LLine, 10, MaxInt)))
      else if Copy(LLine, 1, 9) = '@missing ' then
        LMissing.AddRange(SplitWords(Copy(LLine, 10, MaxInt)))
      else if Copy(LLine, 1, 4) = 'hex ' then
      begin
        for LWord in SplitWords(Copy(LLine, 5, MaxInt)) do
          AddBytes([Byte(StrToInt('$' + LWord))]);
      end
      else if Copy(LLine, 1, 6) = 'entry ' then
      begin
        LWords := Copy(LLine, 7, MaxInt).Split([' ']);
        AddName(LWords[0]);
        AddName(LWords[1]);
        LValue := StrToInt(LWords[2]);
        AddBytes([Byte(LValue and $FF), Byte((LValue shr 8) and $FF)]);
        if AStrife then
        begin
          LValue := 0;
          if Length(LWords) > 3 then
            LValue := StrToInt(LWords[3]);
          AddBytes([Byte(LValue and $FF), Byte((LValue shr 8) and $FF), Byte((LValue shr 16) and $FF),
            Byte((LValue shr 24) and $FF)]);
        end;
      end;
    end;
    if LHaveCase then
      RunCase;
  finally
    LLines.Free;
    LMissing.Free;
    LCatalogIntf := nil;
  end;
end;

class function TDefinitionsCorpus.OldTerrainNumber(AGame: TDefGame; AKind: TDefTerrainKind): Integer;
begin
  case AGame of
    TDefGame.Hexen:
      case AKind of
        TDefTerrainKind.Ice: Result := 1;
        TDefTerrainKind.Water: Result := 3;
        TDefTerrainKind.Lava: Result := 4;
        TDefTerrainKind.Sludge: Result := 5;
      else
        Result := 0;
      end;
  else
    case AKind of
      TDefTerrainKind.Water: Result := 1;
      TDefTerrainKind.Lava: Result := 2;
      TDefTerrainKind.Sludge: Result := 3;
      TDefTerrainKind.Nukage: Result := 4;
    else
      Result := 0;
    end;
  end;
end;

class function TDefinitionsCorpus.DumpTerrain(AGame: TDefGame; const ANamesFile: string): TStringList;
var
  LNames: TStringList;
  LTable: IDefTerrainTable;
  LIndex: Integer;
begin
  Result := TStringList.Create;
  LNames := LoadLines(ANamesFile);
  try
    LTable := TDefinitionsFactory.CreateTerrainTable(AGame);
    for LIndex := 0 to LNames.Count - 1 do
      Result.Add(Format('%s'#9'%d', [LNames[LIndex],
        OldTerrainNumber(AGame, LTable.KindForName(LNames[LIndex]))]));
  finally
    LNames.Free;
  end;
end;

class function TDefinitionsCorpus.DumpSwitchTable(AGame: TDefGame): TStringList;
var
  LPair: TDefSwitchPair;
begin
  Result := TStringList.Create;
  for LPair in TDefinitionsFactory.CreateSwitchTable(AGame) do
    Result.Add(Format('%s|%s|%d|%s', [LPair.Name1, LPair.Name2, LPair.Episode, LPair.SoundName]));
end;

class function TDefinitionsCorpus.Compare(AActual, AExpected: TStringList; out ADetail: string): Integer;
var
  LActual: TDictionary<string, string>;
  LExpected: TDictionary<string, string>;
  LNames: TList<string>;

  procedure Split(ALines: TStringList; ACases: TDictionary<string, string>; ANames: TList<string>);
  var
    LIndex: Integer;
    LCurrent: string;
  begin
    LCurrent := '';
    for LIndex := 0 to ALines.Count - 1 do
      if Copy(ALines[LIndex], 1, 4) = '=== ' then
      begin
        LCurrent := Copy(ALines[LIndex], 5, MaxInt);
        ACases.AddOrSetValue(LCurrent, '');
        if Assigned(ANames) then
          ANames.Add(LCurrent);
      end
      else if LCurrent <> '' then
        ACases[LCurrent] := ACases[LCurrent] + ALines[LIndex] + #10;
  end;

var
  LName: string;
begin
  Result := 0;
  ADetail := '';
  LActual := TDictionary<string, string>.Create;
  LExpected := TDictionary<string, string>.Create;
  LNames := TList<string>.Create;
  try
    Split(AExpected, LExpected, LNames);
    Split(AActual, LActual, nil);
    for LName in LNames do
      if (not LActual.ContainsKey(LName)) or (LActual[LName] <> LExpected[LName]) then
      begin
        Inc(Result);
        if ADetail = '' then
        begin
          ADetail := 'case ' + LName + #10 + 'expected: ' + LExpected[LName];
          if LActual.ContainsKey(LName) then
            ADetail := ADetail + #10'actual: ' + LActual[LName]
          else
            ADetail := ADetail + #10'actual: (missing)';
        end;
      end;
    if LActual.Count <> LExpected.Count then
      Inc(Result);
  finally
    LActual.Free;
    LExpected.Free;
    LNames.Free;
  end;
end;

end.
