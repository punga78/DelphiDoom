{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the UMAPINFO library - the fakes of the game          }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.MapInfo.Fakes;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Logging.Intf, DelphiDoom.MapInfo.Intf;

type
  /// <summary>
  ///   The rules of the stubs that the harness of the golden files was linked with:
  ///   MAPxx (01..99) and ExMy (1..8, 1..9) are maps; a lump exists if its name starts with D_
  /// </summary>
  TFakeGame = class(TInterfacedObject, IMapNameValidator, IMapLumpCatalog, IMapMusicResolver,
    IMapActorResolver)
  public
    function IsValidMapName(const AName: string): Boolean;
    function LumpExists(const AName: string): Boolean;
    function MusicNumberFor(const AName: string): Integer;
    function ActorTypeFor(const AUpperName: string): Integer;
  end;

  /// <summary>Keeps the calls on the episode list as lines of text, like the stub of m_menu</summary>
  TFakeEpisodes = class(TInterfacedObject, IMapEpisodeSink)
  private
    FLog: string;
  public
    procedure ClearEpisodes;
    procedure AddEpisode(const AMapName, APicture, AText: string; AKey: Char);
    property Log: string read FLog;
  end;

  /// <summary>The warnings as they were written, with nothing added</summary>
  TFakeLog = class(TInterfacedObject, ILog)
  private
    FWarnings: string;
  public
    procedure Info(const AText: string);
    procedure Warning(const AText: string);
    procedure DevWarning(const AText: string);
    procedure Error(const AText: string);
    property Warnings: string read FWarnings;
  end;

  /// <summary>Lumps and PAK entries in a list</summary>
  TFakeTextSource = class(TInterfacedObject, IMapInfoTextSource)
  private
    FLumpNames: TList<string>;
    FLumpTexts: TList<string>;
    FPakNames: TList<string>;
    FPakTexts: TList<string>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure AddLump(const AName, AText: string);
    procedure AddPak(const AName, AText: string);
    function WadLumpTexts(const AUpperName: string): TArray<string>;
    function PakTexts(const AFileName: string): TArray<string>;
  end;

  /// <summary>A text filter that marks the text it was given, to see when it is used</summary>
  TFakeFilter = class(TInterfacedObject, IMapInfoTextFilter)
  private
    FCalls: Integer;
  public
    function Filter(const AText: string): string;
    property Calls: Integer read FCalls;
  end;

implementation

uses
  DelphiDoom.Scanner.Strings;

const
  FAKE_ACTORS: array[0..2] of string = ('DOOMPLAYER', 'ZOMBIEMAN', 'CYBERDEMON');

function IsDigit(AChar: Char): Boolean;
begin
  Result := (AChar >= '0') and (AChar <= '9');
end;

{ TFakeGame }

function TFakeGame.IsValidMapName(const AName: string): Boolean;
var
  LName: string;
  LEpisode: Integer;
  LMap: Integer;
begin
  Result := False;
  if not (Length(AName) in [4, 5]) then
    Exit;
  LName := TScannerStrings.UpperAscii(AName);
  if (LName[1] = 'E') and (LName[3] = 'M') then
  begin
    if (Length(LName) = 4) and IsDigit(LName[2]) and IsDigit(LName[4]) then
    begin
      LEpisode := Ord(LName[2]) - 48;
      LMap := Ord(LName[4]) - 48;
      Result := (LEpisode >= 1) and (LEpisode <= 8) and (LMap >= 1) and (LMap <= 9);
    end;
  end
  else if (LName[1] = 'M') and (LName[2] = 'A') and (LName[3] = 'P') then
  begin
    if (Length(LName) = 5) and IsDigit(LName[4]) and IsDigit(LName[5]) then
    begin
      LMap := (Ord(LName[4]) - 48) * 10 + Ord(LName[5]) - 48;
      Result := (LMap >= 1) and (LMap <= 99);
    end;
  end;
end;

function TFakeGame.LumpExists(const AName: string): Boolean;
begin
  Result := Copy(AName, 1, 2) = 'D_';
end;

function TFakeGame.MusicNumberFor(const AName: string): Integer;
var
  LIndex: Integer;
begin
  Result := 100;
  for LIndex := 1 to Length(AName) do
    Result := Result + Ord(AName[LIndex]) * LIndex;
end;

function TFakeGame.ActorTypeFor(const AUpperName: string): Integer;
var
  LIndex: Integer;
begin
  // the names of the actors first, then the other names of the things
  for LIndex := Low(FAKE_ACTORS) to High(FAKE_ACTORS) do
    if FAKE_ACTORS[LIndex] = AUpperName then
      Exit(LIndex);
  if AUpperName = 'SPIDERMASTERMIND' then
    Result := 20
  else if AUpperName = 'MANCUBUS' then
    Result := 21
  else if AUpperName = 'BARON' then
    Result := 22
  else
    Result := -1;
end;

{ TFakeEpisodes }

procedure TFakeEpisodes.ClearEpisodes;
begin
  FLog := FLog + 'episode clear'#10;
end;

procedure TFakeEpisodes.AddEpisode(const AMapName, APicture, AText: string; AKey: Char);
begin
  FLog := FLog + 'episode add|' + AMapName + '|' + APicture + '|' + AText + '|' +
    IntToStr(Ord(AKey)) + #10;
end;

{ TFakeLog }

procedure TFakeLog.Info(const AText: string);
begin
end;

procedure TFakeLog.Warning(const AText: string);
begin
  FWarnings := FWarnings + AText;
end;

procedure TFakeLog.DevWarning(const AText: string);
begin
end;

procedure TFakeLog.Error(const AText: string);
begin
end;

{ TFakeTextSource }

constructor TFakeTextSource.Create;
begin
  inherited Create;
  FLumpNames := TList<string>.Create;
  FLumpTexts := TList<string>.Create;
  FPakNames := TList<string>.Create;
  FPakTexts := TList<string>.Create;
end;

destructor TFakeTextSource.Destroy;
begin
  FPakTexts.Free;
  FPakNames.Free;
  FLumpTexts.Free;
  FLumpNames.Free;
  inherited Destroy;
end;

procedure TFakeTextSource.AddLump(const AName, AText: string);
begin
  FLumpNames.Add(AName);
  FLumpTexts.Add(AText);
end;

procedure TFakeTextSource.AddPak(const AName, AText: string);
begin
  FPakNames.Add(AName);
  FPakTexts.Add(AText);
end;

function TFakeTextSource.WadLumpTexts(const AUpperName: string): TArray<string>;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to FLumpNames.Count - 1 do
    if FLumpNames[LIndex] = AUpperName then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FLumpTexts[LIndex];
    end;
end;

function TFakeTextSource.PakTexts(const AFileName: string): TArray<string>;
var
  LIndex: Integer;
begin
  Result := nil;
  for LIndex := 0 to FPakNames.Count - 1 do
    if FPakNames[LIndex] = AFileName then
    begin
      SetLength(Result, Length(Result) + 1);
      Result[High(Result)] := FPakTexts[LIndex];
    end;
end;

{ TFakeFilter }

function TFakeFilter.Filter(const AText: string): string;
begin
  Inc(FCalls);
  Result := AText;
end;

end.
