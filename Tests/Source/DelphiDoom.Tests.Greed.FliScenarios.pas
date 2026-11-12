{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the greed library - the scenarios of the FLI movies     }
{                                                                              }
{  The same movies (made here, or the files of the game) and the same keys go   }
{  to TGreedFliPlayer and to the original playfli.pas of xGreed (the harness    }
{  Tools\Verifica\175-menu, FliParity): screen and palette must be the same at  }
{  every tic                                                                    }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Greed.FliScenarios;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, DelphiDoom.Greed.Types, DelphiDoom.Greed.Intf,
  DelphiDoom.Greed.Canvas, DelphiDoom.Greed.Display, DelphiDoom.Greed.MenuInput, DelphiDoom.Greed.FliDecoder,
  DelphiDoom.Greed.FliPlayer, DelphiDoom.Tests.Greed.MenuScenarios;

const
  FLI_SEED = 20261114;
  FLI_SCENARIOS = 48;

type
  /// <summary>Writes the bytes of a FLI movie: header, frames and chunks</summary>
  TFliBuilder = class
  strict private
    FBytes: TBytes;
    FFrames: Integer;
    FHeaderAt: Integer;
    FFrameAt: Integer;
    FChunks: Integer;
    procedure Put(AValue: Byte);
    procedure PutWord(AValue: Integer);
    procedure PutLong(AOffset, AValue: Integer);
  public
    /// <summary>The header: the frames are counted by BeginFrame. APrefix bytes come before it</summary>
    constructor Create(AHeight, ASpeed: Integer; APrefix: Integer = 0);
    procedure BeginFrame(AMagic: Integer = GREED_FLI_FRAME_MAGIC);
    /// <summary>The sizes of the frame are written; AEmpty writes 0 as its size</summary>
    procedure EndFrame(AEmpty: Boolean = False);
    procedure Chunk(AType: Integer; const AData: TBytes);
    /// <summary>The number of frames of the header, if it must not be the true one</summary>
    procedure SetFrameCount(ACount: Integer);
    function Build: TBytes;
  end;

  TFliScenario = record
    /// <summary>One or two movies, played one after the other</summary>
    Movies: TArray<TBytes>;
    /// <summary>Where each movie starts in its bytes</summary>
    Offsets: TArray<Integer>;
    Keys: TArray<TMenuKeyEvent>;
    StartTime: Integer;
    BackgroundSeed: Cardinal;
    MaxTics: Integer;
  end;

  TFliOutcome = record
    Tics: Integer;
    Pixels: Cardinal;
    Palette: Cardinal;
    Finish: Cardinal;
    function Line(const AName: string): string;
  end;

  TFliScenarios = class
  public
    /// <summary>A movie of generated frames with every chunk that the original knows</summary>
    class function SyntheticMovie(ASeed: Cardinal; AFullPalette: Boolean; APrefix: Integer = 0): TBytes; static;
    class function Scenario(AIndex: Integer): TFliScenario; static;
    /// <summary>A scenario that plays one movie of the game to its end, without keys</summary>
    class function FileScenario(const AMovie: TBytes): TFliScenario; static;
    /// <summary>The palette shown before a scenario</summary>
    class function StartPalette: TBytes; static;
    class function FinishHash(ACompleted, AFrame, ATimeCount: Integer): Cardinal; static;
  end;

  TFliLibraryRunner = class
  strict private
    FArchive: IGreedArchive;
    FCanvas: TGreedCanvas;
    FDisplay: TGreedDisplay;
    FInput: TGreedMenuInput;
    FPlayer: TGreedFliPlayer;
  public
    constructor Create;
    destructor Destroy; override;
    function Run(const AScenario: TFliScenario; AFrames: TList<Cardinal> = nil): TFliOutcome;
  end;

/// <summary>The lines of the golden file of the synthetic movies, computed with the library</summary>
function FliLibraryLines: TStringList;
/// <summary>The lines for the movies of a folder (*.FLI, by name), computed with the library</summary>
function FliLibraryFileLines(const AFolder: string): TStringList;
/// <summary>The *.FLI files of a folder, sorted by name</summary>
function FliFiles(const AFolder: string): TArray<string>;

implementation

uses
  System.IOUtils, System.Generics.Defaults, DelphiDoom.Tests.Greed.Builders;

type
  TFliRandom = record
    Seed: Cardinal;
    function Next(ARange: Integer): Integer;
    function Chance(APercent: Integer): Boolean;
  end;

function TFliRandom.Next(ARange: Integer): Integer;
begin
  Seed := Seed * 1103515245 + 12345;
  if ARange <= 0 then
    Result := 0
  else
    Result := Integer((Seed shr 8) mod Cardinal(ARange));
end;

function TFliRandom.Chance(APercent: Integer): Boolean;
begin
  Result := Next(100) < APercent;
end;

{ TFliBuilder }

constructor TFliBuilder.Create(AHeight, ASpeed, APrefix: Integer);
var
  LIndex: Integer;
begin
  inherited Create;
  SetLength(FBytes, APrefix + GREED_FLI_HEADER_BYTES);
  for LIndex := 0 to APrefix - 1 do
    FBytes[LIndex] := $A5;
  FillChar(FBytes[APrefix], GREED_FLI_HEADER_BYTES, 0);
  FHeaderAt := APrefix;
  FFrameAt := APrefix;
  // signature AF11, width, height, depth, speed
  TGreedLumps.PutWord(FBytes, APrefix + 4, $AF11);
  TGreedLumps.PutWord(FBytes, APrefix + 8, 320);
  TGreedLumps.PutWord(FBytes, APrefix + 10, AHeight);
  TGreedLumps.PutWord(FBytes, APrefix + 12, 8);
  TGreedLumps.PutWord(FBytes, APrefix + 16, ASpeed);
  FFrames := 0;
end;

procedure TFliBuilder.Put(AValue: Byte);
begin
  SetLength(FBytes, Length(FBytes) + 1);
  FBytes[High(FBytes)] := AValue;
end;

procedure TFliBuilder.PutWord(AValue: Integer);
begin
  Put(AValue and $FF);
  Put((AValue shr 8) and $FF);
end;

procedure TFliBuilder.PutLong(AOffset, AValue: Integer);
begin
  FBytes[AOffset] := AValue and $FF;
  FBytes[AOffset + 1] := (AValue shr 8) and $FF;
  FBytes[AOffset + 2] := (AValue shr 16) and $FF;
  FBytes[AOffset + 3] := (AValue shr 24) and $FF;
end;

procedure TFliBuilder.BeginFrame(AMagic: Integer);
var
  LIndex: Integer;
begin
  FFrameAt := Length(FBytes);
  FChunks := 0;
  for LIndex := 1 to 4 do
    Put(0);
  PutWord(AMagic);
  PutWord(0);
  for LIndex := 1 to 8 do
    Put(0);
  Inc(FFrames);
end;

procedure TFliBuilder.EndFrame(AEmpty: Boolean);
begin
  if AEmpty then
    PutLong(FFrameAt, 0)
  else
    PutLong(FFrameAt, Length(FBytes) - FFrameAt);
  TGreedLumps.PutWord(FBytes, FFrameAt + 6, FChunks);
end;

procedure TFliBuilder.Chunk(AType: Integer; const AData: TBytes);
var
  LAt: Integer;
begin
  LAt := Length(FBytes);
  SetLength(FBytes, LAt + GREED_FLI_CHUNK_HEADER_BYTES + Length(AData));
  PutLong(LAt, GREED_FLI_CHUNK_HEADER_BYTES + Length(AData));
  TGreedLumps.PutWord(FBytes, LAt + 4, AType);
  if Length(AData) > 0 then
    Move(AData[0], FBytes[LAt + GREED_FLI_CHUNK_HEADER_BYTES], Length(AData));
  Inc(FChunks);
end;

procedure TFliBuilder.SetFrameCount(ACount: Integer);
begin
  FFrames := ACount;
end;

function TFliBuilder.Build: TBytes;
begin
  Result := Copy(FBytes);
  TGreedLumps.PutWord(Result, FHeaderAt + 6, FFrames);
end;

// ---------------------------------------------------------------------------------------------------------
// the chunks
// ---------------------------------------------------------------------------------------------------------

type
  TChunkWriter = record
    Data: TBytes;
    procedure Add(AValue: Integer);
    procedure AddWord(AValue: Integer);
  end;

procedure TChunkWriter.Add(AValue: Integer);
begin
  SetLength(Data, Length(Data) + 1);
  Data[High(Data)] := Byte(AValue and $FF);
end;

procedure TChunkWriter.AddWord(AValue: Integer);
begin
  Add(AValue and $FF);
  Add((AValue shr 8) and $FF);
end;

function ColorChunk(var ARandom: TFliRandom; AFull: Boolean): TBytes;
var
  LWriter: TChunkWriter;
  LPackets, LPacket, LSkip, LTotal, LIndex: Integer;
begin
  LWriter := Default(TChunkWriter);
  if AFull then
  begin
    // one packet with the 256 colors: a total of 0 means 256
    LWriter.AddWord(1);
    LWriter.Add(0);
    LWriter.Add(0);
    for LIndex := 0 to 767 do
      LWriter.Add(ARandom.Next(256));
  end
  else
  begin
    LPackets := 1 + ARandom.Next(3);
    LWriter.AddWord(LPackets);
    for LPacket := 1 to LPackets do
    begin
      LSkip := ARandom.Next(200);
      LTotal := 1 + ARandom.Next(256 - LSkip - 1);
      LWriter.Add(LSkip);
      LWriter.Add(LTotal);
      for LIndex := 0 to LTotal * 3 - 1 do
        LWriter.Add(ARandom.Next(256));
    end;
  end;
  Result := LWriter.Data;
end;

function RunChunk(var ARandom: TFliRandom; AHeight: Integer): TBytes;
var
  LWriter: TChunkWriter;
  LRow, LLeft, LPackets, LCount, LIndex, LTotal: Integer;
  LCounts: TArray<Integer>;
begin
  // the rows may be shorter or longer than 320 pixels (the original does not go back to the start of a row), but
  // the whole picture stays inside the screen
  LWriter := Default(TChunkWriter);
  LTotal := 0;
  for LRow := 0 to AHeight - 1 do
  begin
    LLeft := 320;
    if ARandom.Chance(10) then
      LLeft := 250 + ARandom.Next(60);
    if LTotal + LLeft > 64000 then
      LLeft := 64000 - LTotal;
    LCounts := nil;
    while LLeft > 0 do
    begin
      LCount := 1 + ARandom.Next(127);
      if LCount > LLeft then
        LCount := LLeft;
      SetLength(LCounts, Length(LCounts) + 1);
      LCounts[High(LCounts)] := LCount;
      LLeft := LLeft - LCount;
      if Length(LCounts) = 255 then
        Break;
    end;
    LPackets := Length(LCounts);
    LWriter.Add(LPackets);
    for LIndex := 0 to LPackets - 1 do
    begin
      LCount := LCounts[LIndex];
      LTotal := LTotal + LCount;
      if ARandom.Chance(40) then
      begin
        // literal pixels
        LWriter.Add(-LCount);
        while LCount > 0 do
        begin
          LWriter.Add(ARandom.Next(256));
          Dec(LCount);
        end;
      end
      else
      begin
        LWriter.Add(LCount);
        LWriter.Add(ARandom.Next(256));
      end;
    end;
  end;
  Result := LWriter.Data;
end;

function LinesChunk(var ARandom: TFliRandom): TBytes;
var
  LWriter: TChunkWriter;
  LFirst, LRows, LRow, LPackets, LPacket, LX, LSkip, LCount, LIndex: Integer;
begin
  LWriter := Default(TChunkWriter);
  LFirst := ARandom.Next(190);
  LRows := 1 + ARandom.Next(199 - LFirst);
  LWriter.AddWord(LFirst);
  LWriter.AddWord(LRows);
  for LRow := LFirst to LFirst + LRows - 1 do
  begin
    LPackets := ARandom.Next(5);
    LWriter.Add(LPackets);
    LX := 0;
    for LPacket := 1 to LPackets do
    begin
      LSkip := ARandom.Next(60);
      LCount := 1 + ARandom.Next(60);
      // the last row must not run past the end of the screen
      if (LRow = 199) and (LX + LSkip + LCount > 320) then
      begin
        LSkip := 0;
        LCount := 0;
      end;
      LX := LX + LSkip + LCount;
      LWriter.Add(LSkip);
      if ARandom.Chance(50) then
      begin
        // a run
        LWriter.Add(-LCount);
        LWriter.Add(ARandom.Next(256));
      end
      else
      begin
        LWriter.Add(LCount);
        for LIndex := 1 to LCount do
          LWriter.Add(ARandom.Next(256));
      end;
    end;
  end;
  Result := LWriter.Data;
end;

function CopyChunk(var ARandom: TFliRandom): TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, GREED_FLI_SCREEN_BYTES);
  for LIndex := 0 to High(Result) do
    Result[LIndex] := ARandom.Next(7) * 37;
end;

class function TFliScenarios.SyntheticMovie(ASeed: Cardinal; AFullPalette: Boolean; APrefix: Integer): TBytes;
var
  LRandom: TFliRandom;
  LBuilder: TFliBuilder;
  LFrames, LFrame, LChunks, LChunk, LHeight, LRoll: Integer;
begin
  LRandom.Seed := ASeed;
  LRandom.Next(1);
  LHeight := 200;
  if LRandom.Chance(20) then
    LHeight := 100 + LRandom.Next(100);
  LBuilder := TFliBuilder.Create(LHeight, LRandom.Next(6), APrefix);
  try
    LFrames := 4 + LRandom.Next(14);
    for LFrame := 0 to LFrames - 1 do
    begin
      LBuilder.BeginFrame;
      if LFrame = 0 then
      begin
        if AFullPalette then
          LBuilder.Chunk(GREED_FLI_CHUNK_COLORS, ColorChunk(LRandom, True));
        LBuilder.Chunk(GREED_FLI_CHUNK_RUN, RunChunk(LRandom, LHeight));
        LBuilder.EndFrame;
        Continue;
      end;
      if LRandom.Chance(10) then
      begin
        // a frame that says it is empty: its chunks, if any, would be read as the next frame
        LBuilder.EndFrame(True);
        Continue;
      end;
      LChunks := LRandom.Next(4);
      for LChunk := 1 to LChunks do
      begin
        LRoll := LRandom.Next(100);
        if LRoll < 50 then
          LBuilder.Chunk(GREED_FLI_CHUNK_LINES, LinesChunk(LRandom))
        else if LRoll < 65 then
          LBuilder.Chunk(GREED_FLI_CHUNK_COLORS, ColorChunk(LRandom, False))
        else if LRoll < 75 then
          LBuilder.Chunk(GREED_FLI_CHUNK_RUN, RunChunk(LRandom, LHeight))
        else if LRoll < 82 then
          LBuilder.Chunk(GREED_FLI_CHUNK_COPY, CopyChunk(LRandom))
        else if LRoll < 90 then
          LBuilder.Chunk(GREED_FLI_CHUNK_CLEAR, nil)
        else
          // a chunk that the original does not know (the 256 colors of a FLC)
          LBuilder.Chunk(4, ColorChunk(LRandom, False));
      end;
      LBuilder.EndFrame;
    end;
    Result := LBuilder.Build;
  finally
    LBuilder.Free;
  end;
end;

class function TFliScenarios.StartPalette: TBytes;
var
  LIndex: Integer;
begin
  SetLength(Result, 768);
  for LIndex := 0 to 767 do
    Result[LIndex] := Byte(LIndex * 7 + 40);
end;

class function TFliScenarios.FinishHash(ACompleted, AFrame, ATimeCount: Integer): Cardinal;
var
  LTrace: TMenuTrace;
begin
  LTrace.Clear;
  LTrace.Add(ACompleted);
  LTrace.Add(AFrame);
  LTrace.Add(ATimeCount);
  Result := LTrace.Hash;
end;

class function TFliScenarios.Scenario(AIndex: Integer): TFliScenario;
var
  LRandom: TFliRandom;
  LCount, LIndex, LPrefix, LTic: Integer;
begin
  LRandom.Seed := FLI_SEED + Cardinal(AIndex) * 104729;
  LRandom.Next(1);
  Result := Default(TFliScenario);
  LCount := 1 + LRandom.Next(2);
  SetLength(Result.Movies, LCount);
  SetLength(Result.Offsets, LCount);
  for LIndex := 0 to LCount - 1 do
  begin
    LPrefix := 0;
    if LRandom.Chance(30) then
      LPrefix := 1 + LRandom.Next(500);
    // the first movie of a scenario sets every color: the palette of the movies is kept from the scenario before
    Result.Movies[LIndex] := SyntheticMovie(FLI_SEED + Cardinal(AIndex) * 31 + Cardinal(LIndex), LIndex = 0, LPrefix);
    Result.Offsets[LIndex] := LPrefix;
  end;
  Result.StartTime := LRandom.Next(3000);
  Result.BackgroundSeed := 9000 + Cardinal(AIndex);
  Result.MaxTics := 400;
  if LRandom.Chance(40) then
  begin
    // a key stops the movie
    LTic := 1 + LRandom.Next(40);
    SetLength(Result.Keys, 2);
    Result.Keys[0].Tic := LTic;
    Result.Keys[0].ScanCode := GREED_SC_SPACE;
    Result.Keys[0].Down := True;
    Result.Keys[1].Tic := LTic + 3;
    Result.Keys[1].ScanCode := GREED_SC_SPACE;
    Result.Keys[1].Down := False;
  end;
end;

class function TFliScenarios.FileScenario(const AMovie: TBytes): TFliScenario;
begin
  Result := Default(TFliScenario);
  SetLength(Result.Movies, 1);
  SetLength(Result.Offsets, 1);
  Result.Movies[0] := AMovie;
  Result.Offsets[0] := 0;
  Result.StartTime := 0;
  Result.BackgroundSeed := 9999;
  Result.MaxTics := 100000;
end;

{ TFliOutcome }

function TFliOutcome.Line(const AName: string): string;
begin
  Result := Format('F %s tics=%d pixels=%.8x palette=%.8x end=%.8x', [AName, Tics, Pixels, Palette, Finish]);
end;

{ TFliLibraryRunner }

constructor TFliLibraryRunner.Create;
begin
  inherited Create;
  // the display wants an archive: the movies do not read it
  FArchive := TMenuScenarios.SyntheticArchive;
  FCanvas := TGreedCanvas.Create;
  FDisplay := TGreedDisplay.Create(FCanvas, FArchive);
  FInput := TGreedMenuInput.Create;
  FPlayer := TGreedFliPlayer.Create(FDisplay, FInput);
end;

destructor TFliLibraryRunner.Destroy;
begin
  FPlayer.Free;
  FInput.Free;
  FDisplay.Free;
  FCanvas.Free;
  inherited;
end;

function TFliLibraryRunner.Run(const AScenario: TFliScenario; AFrames: TList<Cardinal>): TFliOutcome;
var
  LNextKey: Integer;
  LMovie: Integer;
  LBackground: TBytes;
  LStopped: Boolean;

  procedure Capture;
  begin
    Result.Pixels := MenuFnv(Result.Pixels, FCanvas.Pixels[0], Length(FCanvas.Pixels));
    Result.Palette := MenuFnv(Result.Palette, FDisplay.Palette[0], GREED_DISPLAY_PALETTE_BYTES);
    if Assigned(AFrames) then
      AFrames.Add(MenuFnv(MENU_FNV_START, FCanvas.Pixels[0], Length(FCanvas.Pixels)));
  end;

begin
  FInput.ReleaseAll;
  FInput.TimeCount := AScenario.StartTime;
  FDisplay.SetPalette(TFliScenarios.StartPalette);
  LBackground := TMenuScenarios.Background(AScenario.BackgroundSeed);
  Move(LBackground[0], FCanvas.Pixels[0], Length(LBackground));
  Result.Tics := 0;
  Result.Pixels := MENU_FNV_START;
  Result.Palette := MENU_FNV_START;
  LNextKey := 0;
  LStopped := False;
  for LMovie := 0 to High(AScenario.Movies) do
  begin
    FPlayer.Open(AScenario.Movies[LMovie], AScenario.Offsets[LMovie]);
    while FPlayer.Active do
    begin
      if Result.Tics = AScenario.MaxTics then
      begin
        LStopped := True;
        Break;
      end;
      Capture;
      while (LNextKey < Length(AScenario.Keys)) and (AScenario.Keys[LNextKey].Tic <= Result.Tics + 1) do
      begin
        FInput.SetKey(AScenario.Keys[LNextKey].ScanCode, AScenario.Keys[LNextKey].Down);
        Inc(LNextKey);
      end;
      FPlayer.Tick;
      Inc(Result.Tics);
    end;
    if LStopped then
      Break;
  end;
  if not LStopped then
    Capture;
  // the frame count of the original is private: 0 on the two sides
  Result.Finish := TFliScenarios.FinishHash(Ord(FPlayer.Completed), 0, FInput.TimeCount);
end;

function FliLibraryLines: TStringList;
var
  LRunner: TFliLibraryRunner;
  LIndex: Integer;
begin
  Result := TStringList.Create;
  try
    LRunner := TFliLibraryRunner.Create;
    try
      for LIndex := 0 to FLI_SCENARIOS - 1 do
        Result.Add(LRunner.Run(TFliScenarios.Scenario(LIndex)).Line(IntToStr(LIndex)));
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function FliFiles(const AFolder: string): TArray<string>;
begin
  if (AFolder = '') or not TDirectory.Exists(AFolder) then
    Exit(nil);
  Result := TDirectory.GetFiles(AFolder, '*.FLI', TSearchOption.soAllDirectories);
  TArray.Sort<string>(Result, TComparer<string>.Construct(
    function(const ALeft, ARight: string): Integer
    begin
      Result := CompareText(ExtractFileName(ALeft), ExtractFileName(ARight));
    end));
end;

function FliLibraryFileLines(const AFolder: string): TStringList;
var
  LRunner: TFliLibraryRunner;
  LFile: string;
begin
  Result := TStringList.Create;
  try
    LRunner := TFliLibraryRunner.Create;
    try
      for LFile in FliFiles(AFolder) do
        Result.Add(LRunner.Run(TFliScenarios.FileScenario(TFile.ReadAllBytes(LFile))).Line(
          UpperCase(ExtractFileName(LFile))));
    finally
      LRunner.Free;
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
