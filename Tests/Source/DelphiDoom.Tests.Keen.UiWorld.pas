{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the keen library - a screen, a keyboard driven by a     }
{  script and made up graphics for the user interface                           }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Keen.UiWorld;

{$Q-}
{$R-}

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.Keen.Types, DelphiDoom.Keen.GameTypes,
  DelphiDoom.Keen.UserTypes, DelphiDoom.Keen.Intf, DelphiDoom.Keen.UserIntf, DelphiDoom.Keen.ScriptedHost;

const
  UI_FONT_HEIGHT = 10;

type
  /// <summary>
  ///   Graphics that no game has: a font whose characters are 3 to 8 pixels wide (the digits of fixed width 129..138
  ///   are 6) with bits that depend on the character and on the row, 65 pictures of 4 bytes by 16 rows, two masked
  ///   pictures, four sprites and the 8x8 tiles, all from a little generator. The chunk STARTFONT is the font
  /// </summary>
  TUiFakeGraphics = class(TInterfacedObject, IKeenGraphics, IKeenChunkSource)
  strict private
    function Random(AKey, ACount: Integer): TBytes;
    function MaskedRandom(AKey, APlaneBytes: Integer): TBytes;
  public
    class function FontChunk: TBytes; static;
    class function CharWidth(ACharacter: Integer): Integer; static;
    class function CharRow(ACharacter, ARow: Integer): Byte; static;
    function GetChunks: IKeenChunkSource;
    function GetPictureTable: TArray<TKeenPictureEntry>;
    function GetMaskedPictureTable: TArray<TKeenPictureEntry>;
    function GetSpriteTable: TArray<TKeenSpriteEntry>;
    function PicturePlanar(AIndex: Integer): TBytes;
    function MaskedPicturePlanar(AIndex: Integer): TBytes;
    function SpritePlanar(AIndex: Integer): TBytes;
    function Tile8(AIndex: Integer): TBytes;
    function Tile8Masked(AIndex: Integer): TBytes;
    function Tile16(AIndex: Integer): TBytes;
    function Tile16Masked(AIndex: Integer): TBytes;
    function GetChunkCount: Integer;
    function HasChunk(AIndex: Integer): Boolean;
    function ReadCompressed(AIndex: Integer): TBytes;
    function Read(AIndex: Integer): TBytes;
  end;

  /// <summary>Files in memory</summary>
  TUiFakeFiles = class(TInterfacedObject, IKeenUserFiles)
  strict private
    FFiles: TDictionary<string, TBytes>;
  public
    /// <summary>Writes fail (a full disk)</summary>
    ReadOnly: Boolean;
    constructor Create;
    destructor Destroy; override;
    function TryRead(const AName: string; out ABytes: TBytes): Boolean;
    function TryWrite(const AName: string; const ABytes: TBytes): Boolean;
    procedure Delete(const AName: string);
    function Has(const AName: string): Boolean;
    procedure Put(const AName: string; const ABytes: TBytes);
    function Count: Integer;
  end;

  /// <summary>
  ///   The parts of the user interface put together for a test: the video memory, the refresh manager (for its
  ///   update array), the double buffered drawing, the input manager and the windows, with the clock and the keys
  ///   of a script. A screen update is a step of the script, as in the program
  /// </summary>
  TKeenUiWorld = class
  public
    Host: TKeenScriptedHost;
    Clock: IKeenClock;
    Graphics: IKeenGraphics;
    Memory: IKeenEgaMemory;
    Sprites: IKeenSpriteCache;
    Video: IKeenVideo;
    Refresh: IKeenRefresh;
    Blocks: IKeenUpdateBlocks;
    Buffered: IKeenBufferedVideo;
    Input: IKeenInput;
    Windows: IKeenUserWindows;
    /// <param name="AGraphics">nil for the made up graphics</param>
    /// <param name="AScript">The keys of the test (TKeenScript)</param>
    constructor Create(const AGraphics: IKeenGraphics; const AScript: string);
    destructor Destroy; override;
    /// <summary>The color of a pixel of the page that is shown</summary>
    function DisplayPixel(AX, AY: Integer): Byte;
    /// <summary>The color of a pixel of the buffer page</summary>
    function BufferPixel(AX, AY: Integer): Byte;
    /// <summary>FNV-1a of the 320x200 picture that the card shows</summary>
    function ScreenHash: Cardinal;
  end;

implementation

uses
  DelphiDoom.Keen.EgaMemory, DelphiDoom.Keen.Video, DelphiDoom.Keen.SpriteCache, DelphiDoom.Keen.TileInfo,
  DelphiDoom.Keen.Refresh, DelphiDoom.Keen.BufferedVideo, DelphiDoom.Keen.Input, DelphiDoom.Keen.UserWindows,
  DelphiDoom.Keen.Script, DelphiDoom.Keen.DisplayCapture, DelphiDoom.Keen.Font, DelphiDoom.Keen.InputTypes,
  DelphiDoom.Tests.Keen.VideoFakes;

{ TUiFakeGraphics }

class function TUiFakeGraphics.CharWidth(ACharacter: Integer): Integer;
begin
  if (ACharacter >= 129) and (ACharacter <= 138) then
    Result := 6
  else
    Result := 3 + (ACharacter mod 6);
end;

class function TUiFakeGraphics.CharRow(ACharacter, ARow: Integer): Byte;
var
  LMask: Byte;
begin
  // only the bits of the width of the character, from the left
  LMask := Byte($FF shl (8 - CharWidth(ACharacter)));
  Result := Byte(ACharacter * 37 + ARow * 11 + 1) and LMask;
  // the space has no ink
  if ACharacter = 32 then
    Result := 0;
end;

class function TUiFakeGraphics.FontChunk: TBytes;
var
  LCharacter: Integer;
  LRow: Integer;
  LLocation: Integer;
begin
  SetLength(Result, KEEN_FONT_HEADER_BYTES + 256 * UI_FONT_HEIGHT);
  Result[0] := UI_FONT_HEIGHT;
  Result[1] := 0;
  for LCharacter := 0 to 255 do
  begin
    LLocation := KEEN_FONT_HEADER_BYTES + LCharacter * UI_FONT_HEIGHT;
    Result[2 + LCharacter * 2] := Byte(LLocation);
    Result[3 + LCharacter * 2] := Byte(LLocation shr 8);
    Result[2 + 512 + LCharacter] := Byte(CharWidth(LCharacter));
    for LRow := 0 to UI_FONT_HEIGHT - 1 do
      Result[LLocation + LRow] := CharRow(LCharacter, LRow);
  end;
end;

function TUiFakeGraphics.Random(AKey, ACount: Integer): TBytes;
var
  LState: Cardinal;
  LIndex: Integer;
begin
  SetLength(Result, ACount);
  LState := Cardinal(AKey) * 40503 + 977;
  for LIndex := 0 to ACount - 1 do
  begin
    LState := LState * 1664525 + 1013904223;
    Result[LIndex] := Byte(LState shr 24);
  end;
end;

function TUiFakeGraphics.MaskedRandom(AKey, APlaneBytes: Integer): TBytes;
var
  LPlane: Integer;
  LIndex: Integer;
begin
  Result := Random(AKey, APlaneBytes * 5);
  for LIndex := 0 to APlaneBytes - 1 do
    for LPlane := 1 to KEEN_EGA_PLANES do
      Result[LPlane * APlaneBytes + LIndex] := Result[LPlane * APlaneBytes + LIndex] and not Result[LIndex];
end;

function TUiFakeGraphics.GetChunks: IKeenChunkSource;
begin
  Result := Self;
end;

function TUiFakeGraphics.GetPictureTable: TArray<TKeenPictureEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, KEEN_NUMPICS);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Width := 4;
    Result[LIndex].Height := 16;
  end;
end;

function TUiFakeGraphics.GetMaskedPictureTable: TArray<TKeenPictureEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, KEEN_NUMPICM);
  for LIndex := 0 to High(Result) do
  begin
    Result[LIndex].Width := 4;
    Result[LIndex].Height := 16;
  end;
end;

function TUiFakeGraphics.GetSpriteTable: TArray<TKeenSpriteEntry>;
var
  LIndex: Integer;
begin
  SetLength(Result, 4);
  for LIndex := 0 to High(Result) do
  begin
    FillChar(Result[LIndex], SizeOf(Result[LIndex]), 0);
    Result[LIndex].Width := 2;
    Result[LIndex].Height := 8;
    Result[LIndex].Shifts := 4;
  end;
end;

function TUiFakeGraphics.PicturePlanar(AIndex: Integer): TBytes;
begin
  Result := Random(1000 + AIndex, 4 * 16 * 4);
end;

function TUiFakeGraphics.MaskedPicturePlanar(AIndex: Integer): TBytes;
begin
  Result := MaskedRandom(2000 + AIndex, 4 * 16);
end;

function TUiFakeGraphics.SpritePlanar(AIndex: Integer): TBytes;
begin
  Result := MaskedRandom(3000 + AIndex, 2 * 8);
end;

function TUiFakeGraphics.Tile8(AIndex: Integer): TBytes;
begin
  Result := Random(4000 + AIndex, KEEN_TILE8_BYTES);
end;

function TUiFakeGraphics.Tile8Masked(AIndex: Integer): TBytes;
begin
  Result := MaskedRandom(5000 + AIndex, 8);
end;

function TUiFakeGraphics.Tile16(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TUiFakeGraphics.Tile16Masked(AIndex: Integer): TBytes;
begin
  Result := nil;
end;

function TUiFakeGraphics.GetChunkCount: Integer;
begin
  Result := KEEN_NUMCHUNKS;
end;

function TUiFakeGraphics.HasChunk(AIndex: Integer): Boolean;
begin
  Result := AIndex = KEEN_STARTFONT;
end;

function TUiFakeGraphics.ReadCompressed(AIndex: Integer): TBytes;
begin
  Result := Read(AIndex);
end;

function TUiFakeGraphics.Read(AIndex: Integer): TBytes;
begin
  if AIndex = KEEN_STARTFONT then
    Result := FontChunk
  else
    Result := nil;
end;

{ TUiFakeFiles }

constructor TUiFakeFiles.Create;
begin
  inherited Create;
  FFiles := TDictionary<string, TBytes>.Create;
end;

destructor TUiFakeFiles.Destroy;
begin
  FFiles.Free;
  inherited Destroy;
end;

function TUiFakeFiles.TryRead(const AName: string; out ABytes: TBytes): Boolean;
begin
  Result := FFiles.TryGetValue(UpperCase(AName), ABytes);
  if Result then
    ABytes := Copy(ABytes)
  else
    ABytes := nil;
end;

function TUiFakeFiles.TryWrite(const AName: string; const ABytes: TBytes): Boolean;
begin
  if ReadOnly then
    Exit(False);
  FFiles.AddOrSetValue(UpperCase(AName), Copy(ABytes));
  Result := True;
end;

procedure TUiFakeFiles.Delete(const AName: string);
begin
  FFiles.Remove(UpperCase(AName));
end;

function TUiFakeFiles.Has(const AName: string): Boolean;
begin
  Result := FFiles.ContainsKey(UpperCase(AName));
end;

procedure TUiFakeFiles.Put(const AName: string; const ABytes: TBytes);
begin
  FFiles.AddOrSetValue(UpperCase(AName), Copy(ABytes));
end;

function TUiFakeFiles.Count: Integer;
begin
  Result := FFiles.Count;
end;

{ TKeenUiWorld }

constructor TKeenUiWorld.Create(const AGraphics: IKeenGraphics; const AScript: string);
var
  LRefresh: TKeenRefresh;
  LHost: TKeenScriptedHost;
  LInput: IKeenInput;
begin
  inherited Create;
  Host := TKeenScriptedHost.Create(TKeenScript.Parse(AScript));
  Clock := Host;
  if Assigned(AGraphics) then
    Graphics := AGraphics
  else
    Graphics := TUiFakeGraphics.Create;
  Memory := TKeenEgaMemory.Create;
  Sprites := TKeenSpriteCache.Create(Graphics);
  Video := TKeenVideo.Create(Memory, Graphics, Sprites);
  LRefresh := TKeenRefresh.Create(Video, Graphics, TKeenTileInfo.Create(TFakeKeenTiles.EmptyTable), Sprites, Clock);
  Refresh := LRefresh;
  Blocks := LRefresh;
  Buffered := TKeenBufferedVideo.Create(Video, Blocks, Graphics, Sprites, Clock);
  Input := TKeenInput.Create(Clock, nil, nil, nil);
  Input.SetControlType(0, kctKeyboard1);
  Windows := TKeenUserWindows.Create(Buffered, Input, Clock);
  LHost := Host;
  LInput := Input;
  Host.Keys :=
    procedure(AByte: Byte)
    begin
      LInput.KeyService(AByte);
    end;
  // a screen update takes time: the script goes on
  Buffered.SetUpdateHook(
    procedure
    begin
      LHost.Step;
    end);
end;

destructor TKeenUiWorld.Destroy;
begin
  // the host and the input manager hold each other through the two hooks
  Host.Keys := nil;
  Buffered.SetUpdateHook(nil);
  inherited Destroy;
end;

function TKeenUiWorld.DisplayPixel(AX, AY: Integer): Byte;
begin
  Result := TFakeKeenPixels.Pixel(Memory, Video.DisplayOfs, Video.LineWidth, AX, AY);
end;

function TKeenUiWorld.BufferPixel(AX, AY: Integer): Byte;
begin
  Result := TFakeKeenPixels.Pixel(Memory, Video.BufferOfs, Video.LineWidth, AX, AY);
end;

function TKeenUiWorld.ScreenHash: Cardinal;
begin
  Result := TFakeKeenPixels.ImageHash(TKeenDisplayCapture.CaptureVideo(Video));
end;

end.
