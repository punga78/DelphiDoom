{******************************************************************************}
{                                                                              }
{  DelphiDoom: fakes of the overlay drawer tests                               }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.ScriptHost.OverlayFakes;

interface

uses
  System.Generics.Collections,
  System.SysUtils,
  DelphiDoom.ScriptHost.Overlay.Intf,
  DelphiDoom.ScriptHost.Overlay.Types;

type
  /// <summary>
  ///   A canvas with a screen of the size that the test gives, patches made of bytes in memory (lump
  ///   n is the n-th patch added) and a font of 3x3 glyphs for the characters from '!' to 'Z'
  /// </summary>
  TFakeOverlayCanvas = class(TInterfacedObject, IOverlayCanvas)
  strict private
    FPatches: TList<TBytes>;
    FNames: TList<string>;
    FGlyph: TBytes;
  public
    Width: Integer;
    Height: Integer;
    Time: Integer;
    FirstInterpolation: Boolean;
    Warnings: TList<string>;
    DirtyCount: Integer;
    FlashCount: Integer;
    LastFlash: TOverlayFlashData;
    constructor Create(const AWidth: Integer = OVERLAYWIDTH; const AHeight: Integer = OVERLAYHEIGHT);
    destructor Destroy; override;
    /// <summary>A patch with one post for each column; the pixels are by column, then by row</summary>
    class function BuildPatch(const AWidth, AHeight, ALeftOffset, ATopOffset: Integer;
      const APixels: array of Byte): TBytes; static;
    /// <summary>Adds a patch with a name; the lump is the position it was added at</summary>
    function AddPatch(const AName: string; const APatch: TBytes): Integer;
    function ScreenWidth: Integer;
    function ScreenHeight: Integer;
    function LevelTime: Integer;
    function FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
    function FindPatchLump(const AName: string): Integer;
    function CachePatch(const ALump: Integer): Pointer;
    function FontPatch(const AChar: Char): Pointer;
    function IsFirstInterpolation: Boolean;
    procedure Warning(const AText: string);
    procedure MarkScreenDirty;
    procedure Flash(const AData: TOverlayFlashData);
  end;

implementation

{ TFakeOverlayCanvas }

constructor TFakeOverlayCanvas.Create(const AWidth, AHeight: Integer);
begin
  inherited Create;
  Width := AWidth;
  Height := AHeight;
  FPatches := TList<TBytes>.Create;
  FNames := TList<string>.Create;
  Warnings := TList<string>.Create;
  FGlyph := BuildPatch(3, 3, 0, 0, [1, 1, 1, 1, 1, 1, 1, 1, 1]);
end;

destructor TFakeOverlayCanvas.Destroy;
begin
  Warnings.Free;
  FNames.Free;
  FPatches.Free;
  inherited Destroy;
end;

class function TFakeOverlayCanvas.BuildPatch(const AWidth, AHeight, ALeftOffset,
  ATopOffset: Integer; const APixels: array of Byte): TBytes;
var
  LColumn, LRow, LPosition: Integer;
  LColumnSize: Integer;
begin
  LColumnSize := AHeight + 5;
  SetLength(Result, 8 + AWidth * 4 + AWidth * LColumnSize);
  PSmallInt(@Result[0])^ := AWidth;
  PSmallInt(@Result[2])^ := AHeight;
  PSmallInt(@Result[4])^ := ALeftOffset;
  PSmallInt(@Result[6])^ := ATopOffset;
  LPosition := 8 + AWidth * 4;
  for LColumn := 0 to AWidth - 1 do
  begin
    PInteger(@Result[8 + LColumn * 4])^ := LPosition;
    Result[LPosition] := 0;
    Result[LPosition + 1] := AHeight;
    Result[LPosition + 2] := 0;
    for LRow := 0 to AHeight - 1 do
      Result[LPosition + 3 + LRow] := APixels[LColumn * AHeight + LRow];
    Result[LPosition + 3 + AHeight] := 0;
    // every column ends with 255 (no more posts)
    Result[LPosition + 4 + AHeight] := $FF;
    Inc(LPosition, LColumnSize);
  end;
end;

function TFakeOverlayCanvas.AddPatch(const AName: string; const APatch: TBytes): Integer;
begin
  FNames.Add(UpperCase(AName));
  Result := FPatches.Add(APatch);
end;

function TFakeOverlayCanvas.ScreenWidth: Integer;
begin
  Result := Width;
end;

function TFakeOverlayCanvas.ScreenHeight: Integer;
begin
  Result := Height;
end;

function TFakeOverlayCanvas.LevelTime: Integer;
begin
  Result := Time;
end;

function TFakeOverlayCanvas.FindColorIndex(const ARed, AGreen, ABlue: Byte): Byte;
begin
  Result := Byte(1 + (ARed + AGreen + ABlue) mod 250);
end;

function TFakeOverlayCanvas.FindPatchLump(const AName: string): Integer;
begin
  Result := FNames.IndexOf(UpperCase(AName));
end;

function TFakeOverlayCanvas.CachePatch(const ALump: Integer): Pointer;
begin
  if (ALump >= 0) and (ALump < FPatches.Count) then
    Result := @FPatches[ALump][0]
  else
    Result := nil;
end;

function TFakeOverlayCanvas.FontPatch(const AChar: Char): Pointer;
begin
  if (AChar >= '!') and (AChar <= 'Z') then
    Result := @FGlyph[0]
  else
    Result := nil;
end;

function TFakeOverlayCanvas.IsFirstInterpolation: Boolean;
begin
  Result := FirstInterpolation;
end;

procedure TFakeOverlayCanvas.Warning(const AText: string);
begin
  Warnings.Add(AText);
end;

procedure TFakeOverlayCanvas.MarkScreenDirty;
begin
  Inc(DirtyCount);
end;

procedure TFakeOverlayCanvas.Flash(const AData: TOverlayFlashData);
begin
  Inc(FlashCount);
  LastFlash := AData;
end;

end.
