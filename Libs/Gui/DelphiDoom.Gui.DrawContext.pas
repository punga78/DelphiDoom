{******************************************************************************}
{                                                                              }
{  DelphiDoom: gui library - TGuiDrawContext, the device context of the        }
{  windows of a .gui of Doom 3                                                 }
{                                                                              }
{  Port of ui\DeviceContext.h and DeviceContext.cpp (idDeviceContext, id       }
{  Software, GPL v3): fonts by name and by size, the clipping rectangles,      }
{  the transform of a window, pictures, rectangles, the layout of text         }
{  (alignment, wrapping, the cursor of an edit field) and the cursor of the    }
{  mouse. It draws nothing: every picture ends in IGuiDeviceContext.           }
{  Copyright (C) 1999-2011 id Software LLC, a ZeniMax Media company.           }
{                                                                              }
{  This unit is derived from the Doom 3 GPL source code and is therefore      }
{  available under the GNU General Public License, version 3, with the        }
{  additional terms of the Doom 3 Source Code License (see README.md of        }
{  Framework\IdLib); the repository as a whole is GPL v2 or later.             }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Gui.DrawContext;

interface

uses
  System.Generics.Collections, DelphiDoom.IdLib.Core.Intf, DelphiDoom.IdLib.Math.Vec3, DelphiDoom.IdLib.Math.Vec4,
  DelphiDoom.MathCore.Float.Mat3, DelphiDoom.Gui.Rectangle, DelphiDoom.Gui.Cvars.Intf,
  DelphiDoom.Gui.Material.Intf, DelphiDoom.Gui.DeviceContext.Intf, DelphiDoom.Gui.Font.Doom,
  DelphiDoom.Gui.Font.DoomEx, DelphiDoom.Gui.Window.Intf, DelphiDoom.Gui.UncountedObject;

const
  /// <summary>VIRTUAL_WIDTH and VIRTUAL_HEIGHT: the screen of a gui is 640 by 480</summary>
  GUI_VIRTUAL_WIDTH = 640;
  GUI_VIRTUAL_HEIGHT = 480;
  /// <summary>idDeviceContext::ALIGN_LEFT, ALIGN_CENTER, ALIGN_RIGHT</summary>
  GUI_ALIGN_LEFT = 0;
  GUI_ALIGN_CENTER = 1;
  GUI_ALIGN_RIGHT = 2;
  /// <summary>idDeviceContext::SCROLLBAR_*: the images of the scroll bars</summary>
  GUI_SCROLLBAR_HBACK = 0;
  GUI_SCROLLBAR_VBACK = 1;
  GUI_SCROLLBAR_THUMB = 2;
  GUI_SCROLLBAR_RIGHT = 3;
  GUI_SCROLLBAR_LEFT = 4;
  GUI_SCROLLBAR_UP = 5;
  GUI_SCROLLBAR_DOWN = 6;
  GUI_SCROLLBAR_COUNT = 7;
  /// <summary>idDeviceContext::CURSOR_COUNT (the arrow and the hand are in Window.Types)</summary>
  GUI_CURSOR_COUNT = 2;

type
  /// <summary>
  ///   idDeviceContext. <c>Initialize</c> is <c>Init</c>: it finds the images and the default font, and
  ///   it must be called before anything draws. The tic counter that makes the cursor of an edit field blink
  ///   (<c>com_ticNumber</c>) is <c>TickNumber</c>, set by the host before each frame. The colors keep the
  ///   values <c>Init</c> gives them: <c>ColorOrange</c> is (1, 1, 0, 1) and <c>ColorYellow</c> is (0, 1, 1, 1),
  ///   as in the original. Two fonts that fail to load stay in the list, empty, as they do there.
  /// </summary>
  TGuiDrawContext = class(TGuiUncountedObject, IGuiFontLookup)
  strict private
    FSurface: IGuiDeviceContext;
    FMaterials: IGuiMaterialLookup;
    FFileSystem: IIdLibFileSystem;
    FLog: IIdLibLog;
    FCvars: IGuiCvars;
    FFonts: TObjectList<TGuiDoomFontEx>;
    FActiveFont: TGuiDoomFontEx;
    FUseFont: TGuiDoomFont;
    FFontLang: AnsiString;
    FCursorImages: array[0..GUI_CURSOR_COUNT - 1] of IGuiMaterial;
    FScrollBarImages: array[0..GUI_SCROLLBAR_COUNT - 1] of IGuiMaterial;
    FWhiteImage: IGuiMaterial;
    FXScale: Single;
    FYScale: Single;
    FVidWidth: Single;
    FVidHeight: Single;
    FCursor: Integer;
    FClipRects: TList<TGuiRectangle>;
    FEnableClipping: Boolean;
    FOverStrikeMode: Boolean;
    FMat: TIdMat3;
    FOrigin: TIdVec3;
    FInitialized: Boolean;
    FTickNumber: Integer;
    FColorPurple: TIdVec4;
    FColorOrange: TIdVec4;
    FColorYellow: TIdVec4;
    FColorGreen: TIdVec4;
    FColorBlue: TIdVec4;
    FColorRed: TIdVec4;
    FColorWhite: TIdVec4;
    FColorBlack: TIdVec4;
    FColorNone: TIdVec4;
    procedure SetupFonts;
    procedure SetFontByScale(const AScale: Single);
    procedure BuildQuad(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single; out AQuad: TGuiQuad;
      out ATransformed: Boolean);
    procedure MaterialCoords(var AW, AH, AS0, AT0, AS1, AT1: Single; const AScaleX, AScaleY: Single);
    function RequireFont: TGuiDoomFontEx;
    function ClipCoords(var AX, AY, AW, AH: Single; const AHasTexture: Boolean; var AS1, AT1, AS2, AT2: Single): Boolean;
    procedure PaintChar(const AX, AY: Single; const AWidth, AHeight: Integer; const AScale, AS1, AT1, AS2, AT2: Single;
      const AShader: IGuiMaterial);
    function DrawChars(AX, AY: Single; const AScale: Single; const AColor: TIdVec4; const AText: AnsiString;
      const AAdjust: Single; const ALimit, AStyle: Integer; const ACursor: Integer): Integer;
    function GetOverStrike: Boolean;
    procedure SetOverStrike(const AValue: Boolean);
    function GetFontCount: Integer;
    function GetClipCount: Integer;
  public
    constructor Create(const ASurface: IGuiDeviceContext; const AMaterials: IGuiMaterialLookup;
      const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog; const ACvars: IGuiCvars);
    destructor Destroy; override;
    /// <summary>Init: the 640 by 480 size, the white image, the cursors, the scroll bars, the fonts and the colors</summary>
    procedure Initialize;
    /// <summary>Shutdown: the fonts and the clipping rectangles go away</summary>
    procedure Shutdown;
    /// <summary>
    ///   FindFont: the number of a font by name (without distinction of case); a font that is not in the list is
    ///   read from <c>fonts/&lt;language&gt;/...</c> and -1 if it cannot be read
    /// </summary>
    function FindFont(const AName: AnsiString): Integer;
    /// <summary>SetFont: a number outside the list is the first font</summary>
    procedure SetFont(const ANumber: Integer);
    procedure SetSize(const AWidth, AHeight: Single);
    procedure SetCursor(const ANumber: Integer);
    procedure GetTransformInfo(out AOrigin: TIdVec3; out AMat: TIdMat3);
    procedure SetTransformInfo(const AOrigin: TIdVec3; const AMat: TIdMat3);
    procedure PushClipRect(const ARect: TGuiRectangle); overload;
    procedure PushClipRect(const AX, AY, AW, AH: Single); overload;
    procedure PopClipRect;
    procedure EnableClipping(const AValue: Boolean);
    procedure AdjustCoords(var AX, AY, AW, AH: Single);
    /// <summary>ClippedCoords without texture coordinates: true when nothing is left to draw</summary>
    function ClippedCoords(var AX, AY, AW, AH: Single): Boolean; overload;
    /// <summary>ClippedCoords: the texture coordinates follow the clipped rectangle</summary>
    function ClippedCoords(var AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single): Boolean; overload;
    procedure DrawStretchPic(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single; const AShader: IGuiMaterial);
    procedure DrawStretchPicRotated(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single; const AShader: IGuiMaterial;
      const AAngle: Single = 0.0);
    procedure DrawMaterial(const AX, AY, AW, AH: Single; const AMaterial: IGuiMaterial; const AColor: TIdVec4;
      const AScaleX: Single = 1.0; const AScaleY: Single = 1.0);
    procedure DrawMaterialRotated(const AX, AY, AW, AH: Single; const AMaterial: IGuiMaterial; const AColor: TIdVec4;
      const AScaleX: Single = 1.0; const AScaleY: Single = 1.0; const AAngle: Single = 0.0);
    procedure DrawMaterialRect(const AX, AY, AW, AH, ASize: Single; const AMaterial: IGuiMaterial; const AColor: TIdVec4);
    procedure DrawFilledRect(const AX, AY, AW, AH: Single; const AColor: TIdVec4);
    procedure DrawRect(const AX, AY, AW, AH, ASize: Single; const AColor: TIdVec4);
    /// <summary>DrawCursor: the pointer image at the position (the position is clamped to the screen)</summary>
    procedure DrawCursor(var AX, AY: Single; const ASize: Single);
    procedure DrawEditCursor(const AX, AY, AScale: Single);
    /// <summary>
    ///   DrawText: the text in the rectangle, wrapped or on one line, aligned, with the cursor of an edit
    ///   field at the character <c>ACursor</c> (-1 for none). The result is the number of characters that fit
    ///   in a line, or, without wrapping, where the line broke. <c>ABreaks</c> (optional) gets the start of each
    ///   line. A line of 1024 characters or more raises <c>EGuiDrawException</c> (the original overflows its buffer).
    /// </summary>
    function DrawText(const AText: AnsiString; const AScale: Single; const AAlign: Integer; const AColor: TIdVec4;
      const ARect: TGuiRectangle; const AWrap: Boolean; const ACursor: Integer = -1; const ACalcOnly: Boolean = False;
      const ABreaks: TList<Integer> = nil; const ALimit: Integer = 0): Integer;
    function CharWidth(const AChar: AnsiChar; const AScale: Single): Integer;
    function TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    function TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
    function MaxCharHeight(const AScale: Single): Integer;
    function MaxCharWidth(const AScale: Single): Integer;
    function GetScrollBarImage(const AIndex: Integer): IGuiMaterial;
    property Initialized: Boolean read FInitialized;
    property TickNumber: Integer read FTickNumber write FTickNumber;
    property OverStrike: Boolean read GetOverStrike write SetOverStrike;
    property FontCount: Integer read GetFontCount;
    property ClipEnabled: Boolean read FEnableClipping;
    property ClipCount: Integer read GetClipCount;
    property ColorPurple: TIdVec4 read FColorPurple;
    property ColorOrange: TIdVec4 read FColorOrange;
    property ColorYellow: TIdVec4 read FColorYellow;
    property ColorGreen: TIdVec4 read FColorGreen;
    property ColorBlue: TIdVec4 read FColorBlue;
    property ColorRed: TIdVec4 read FColorRed;
    property ColorWhite: TIdVec4 read FColorWhite;
    property ColorBlack: TIdVec4 read FColorBlack;
    property ColorNone: TIdVec4 read FColorNone;
    property VideoWidth: Single read FVidWidth;
    property VideoHeight: Single read FVidHeight;
    property Cursor: Integer read FCursor;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.IdLib.Math.Math, DelphiDoom.IdLib.Text.Strings, DelphiDoom.MathCore.Float.Mat4,
  DelphiDoom.Gui.Window.Types, DelphiDoom.Gui.Font.Types, DelphiDoom.Gui.Font.DoomLoader, DelphiDoom.Gui.Types;

const
  // gui_smallFontLimit and gui_mediumFontLimit when the host has not the variables
  DEFAULT_SMALL_FONT_LIMIT = 0.30;
  DEFAULT_MEDIUM_FONT_LIMIT = 0.60;
  // char buff[1024] of DrawText
  TEXT_BUFFER_SIZE = 1024;
  // idStr: g_color_table
  COLOR_TABLE: array[0..15] of array[0..2] of Single = ((0, 0, 0), (1, 0, 0), (0, 1, 0), (1, 1, 0), (0, 0, 1),
    (0, 1, 1), (1, 0, 1), (1, 1, 1), (0.5, 0.5, 0.5), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0), (0, 0, 0),
    (0, 0, 0));

function ColorForIndex(const AIndex: Integer): TIdVec4;
begin
  Result := TIdVec4.Create(COLOR_TABLE[AIndex and 15][0], COLOR_TABLE[AIndex and 15][1], COLOR_TABLE[AIndex and 15][2],
    1.0);
end;

// the text up to the first zero, as the char pointer of the original would see it
function CText(const AText: AnsiString): AnsiString;
var
  LPosition: Integer;
begin
  LPosition := Pos(#0, string(AText));
  if LPosition > 0 then
    Result := Copy(AText, 1, LPosition - 1)
  else
    Result := AText;
end;

// the character at a 1-based position, zero past the end (the terminator of a C string)
function CharAt(const AText: AnsiString; const APosition: Integer): Integer; inline;
begin
  if (APosition >= 1) and (APosition <= Length(AText)) then
    Result := Ord(AText[APosition])
  else
    Result := 0;
end;

function IsColorAt(const AText: AnsiString; const APosition: Integer): Boolean; inline;
begin
  Result := (CharAt(AText, APosition) = Ord('^')) and (CharAt(AText, APosition + 1) <> 0) and
    (CharAt(AText, APosition + 1) <> Ord(' '));
end;

{ TGuiDrawContext }

constructor TGuiDrawContext.Create(const ASurface: IGuiDeviceContext; const AMaterials: IGuiMaterialLookup;
  const AFileSystem: IIdLibFileSystem; const ALog: IIdLibLog; const ACvars: IGuiCvars);
begin
  inherited Create;
  FSurface := ASurface;
  FMaterials := AMaterials;
  FFileSystem := AFileSystem;
  FLog := ALog;
  FCvars := ACvars;
  FFonts := TObjectList<TGuiDoomFontEx>.Create(True);
  FClipRects := TList<TGuiRectangle>.Create;
  FMat := TIdMat3.Identity;
  FOrigin.Zero;
  FColorPurple := TIdVec4.Create(0.0, 0.0, 0.0, 0.0);
  FColorOrange := FColorPurple;
  FColorYellow := FColorPurple;
  FColorGreen := FColorPurple;
  FColorBlue := FColorPurple;
  FColorRed := FColorPurple;
  FColorWhite := FColorPurple;
  FColorBlack := FColorPurple;
  FColorNone := FColorPurple;
end;

destructor TGuiDrawContext.Destroy;
begin
  FClipRects.Free;
  FFonts.Free;
  inherited Destroy;
end;

procedure TGuiDrawContext.Initialize;
var
  LIndex: Integer;
begin
  FXScale := 0.0;
  SetSize(GUI_VIRTUAL_WIDTH, GUI_VIRTUAL_HEIGHT);
  FWhiteImage := FMaterials.FindMaterial('guis/assets/white.tga');
  FWhiteImage.SetGuiSort;
  SetupFonts;
  FActiveFont := FFonts[0];
  FColorPurple := TIdVec4.Create(1.0, 0.0, 1.0, 1.0);
  FColorOrange := TIdVec4.Create(1.0, 1.0, 0.0, 1.0);
  FColorYellow := TIdVec4.Create(0.0, 1.0, 1.0, 1.0);
  FColorGreen := TIdVec4.Create(0.0, 1.0, 0.0, 1.0);
  FColorBlue := TIdVec4.Create(0.0, 0.0, 1.0, 1.0);
  FColorRed := TIdVec4.Create(1.0, 0.0, 0.0, 1.0);
  FColorWhite := TIdVec4.Create(1.0, 1.0, 1.0, 1.0);
  FColorBlack := TIdVec4.Create(0.0, 0.0, 0.0, 1.0);
  FColorNone := TIdVec4.Create(0.0, 0.0, 0.0, 0.0);
  FCursorImages[0] := FMaterials.FindMaterial('ui/assets/guicursor_arrow.tga');
  FCursorImages[1] := FMaterials.FindMaterial('ui/assets/guicursor_hand.tga');
  FScrollBarImages[GUI_SCROLLBAR_HBACK] := FMaterials.FindMaterial('ui/assets/scrollbarh.tga');
  FScrollBarImages[GUI_SCROLLBAR_VBACK] := FMaterials.FindMaterial('ui/assets/scrollbarv.tga');
  FScrollBarImages[GUI_SCROLLBAR_THUMB] := FMaterials.FindMaterial('ui/assets/scrollbar_thumb.tga');
  FScrollBarImages[GUI_SCROLLBAR_RIGHT] := FMaterials.FindMaterial('ui/assets/scrollbar_right.tga');
  FScrollBarImages[GUI_SCROLLBAR_LEFT] := FMaterials.FindMaterial('ui/assets/scrollbar_left.tga');
  FScrollBarImages[GUI_SCROLLBAR_UP] := FMaterials.FindMaterial('ui/assets/scrollbar_up.tga');
  FScrollBarImages[GUI_SCROLLBAR_DOWN] := FMaterials.FindMaterial('ui/assets/scrollbar_down.tga');
  for LIndex := 0 to GUI_CURSOR_COUNT - 1 do
    FCursorImages[LIndex].SetGuiSort;
  for LIndex := 0 to GUI_SCROLLBAR_COUNT - 1 do
    FScrollBarImages[LIndex].SetGuiSort;
  FCursor := 0;
  FEnableClipping := True;
  FOverStrikeMode := True;
  FMat := TIdMat3.Identity;
  FOrigin.Zero;
  FInitialized := True;
end;

procedure TGuiDrawContext.Shutdown;
begin
  FClipRects.Clear;
  FFonts.Clear;
  FInitialized := False;
  FUseFont := nil;
  FActiveFont := nil;
end;

procedure TGuiDrawContext.SetupFonts;
begin
  if Assigned(FCvars) then
    FFontLang := FCvars.GetString('sys_lang')
  else
    FFontLang := 'english';
  // western european languages can use the english font
  if (FFontLang = 'french') or (FFontLang = 'german') or (FFontLang = 'spanish') or (FFontLang = 'italian') then
    FFontLang := 'english';
  // Default font has to be added first
  FindFont('fonts');
end;

function TGuiDrawContext.FindFont(const AName: AnsiString): Integer;
var
  LIndex: Integer;
  LFileName: AnsiString;
  LFont: TGuiDoomFontEx;
begin
  for LIndex := 0 to FFonts.Count - 1 do
    if TIdStrings.Icmp(AName, FFonts[LIndex].Name) = 0 then
      Exit(LIndex);
  // If the font was not found, try to register it
  LFileName := AnsiString(StringReplace(string(AName), 'fonts', 'fonts/' + string(FFontLang), [rfReplaceAll]));
  LFont := TGuiDoomFontEx.Create;
  Result := FFonts.Add(LFont);
  if TGuiDoomFontLoader.RegisterFont(FFileSystem, FMaterials, FLog, LFileName, LFont) then
    // idStr::Copynz( fonts[index].name, name, sizeof( fonts[index].name ) )
    LFont.Name := Copy(AName, 1, 63)
  else
  begin
    if Assigned(FLog) then
      FLog.Printf(Format('Could not register font %s [%s]'#10, [string(AName), string(LFileName)]));
    Result := -1;
  end;
end;

function TGuiDrawContext.GetFontCount: Integer;
begin
  Result := FFonts.Count;
end;

function TGuiDrawContext.GetClipCount: Integer;
begin
  Result := FClipRects.Count;
end;

function TGuiDrawContext.GetOverStrike: Boolean;
begin
  Result := FOverStrikeMode;
end;

procedure TGuiDrawContext.SetOverStrike(const AValue: Boolean);
begin
  FOverStrikeMode := AValue;
end;

function TGuiDrawContext.RequireFont: TGuiDoomFontEx;
begin
  if not Assigned(FActiveFont) then
    raise EGuiDrawException.Create('the device context has no font (Initialize was not called)');
  Result := FActiveFont;
end;

procedure TGuiDrawContext.SetFont(const ANumber: Integer);
begin
  if (ANumber >= 0) and (ANumber < FFonts.Count) then
    FActiveFont := FFonts[ANumber]
  else if FFonts.Count > 0 then
    FActiveFont := FFonts[0]
  else
    raise EGuiDrawException.Create('the device context has no font (Initialize was not called)');
end;

procedure TGuiDrawContext.SetFontByScale(const AScale: Single);
var
  LFont: TGuiDoomFontEx;
  LSmallLimit: Single;
  LMediumLimit: Single;
begin
  LFont := RequireFont;
  if Assigned(FCvars) then
  begin
    LSmallLimit := FCvars.GetFloat('gui_smallFontLimit');
    LMediumLimit := FCvars.GetFloat('gui_mediumFontLimit');
  end
  else
  begin
    LSmallLimit := DEFAULT_SMALL_FONT_LIMIT;
    LMediumLimit := DEFAULT_MEDIUM_FONT_LIMIT;
  end;
  if AScale <= LSmallLimit then
  begin
    FUseFont := LFont.FontSmall;
    LFont.MaxHeight := LFont.MaxHeightSmall;
    LFont.MaxWidth := LFont.MaxWidthSmall;
  end
  else if AScale <= LMediumLimit then
  begin
    FUseFont := LFont.FontMedium;
    LFont.MaxHeight := LFont.MaxHeightMedium;
    LFont.MaxWidth := LFont.MaxWidthMedium;
  end
  else
  begin
    FUseFont := LFont.FontLarge;
    LFont.MaxHeight := LFont.MaxHeightLarge;
    LFont.MaxWidth := LFont.MaxWidthLarge;
  end;
end;

procedure TGuiDrawContext.SetSize(const AWidth, AHeight: Single);
var
  LInverse: Single;
begin
  FVidWidth := GUI_VIRTUAL_WIDTH;
  FVidHeight := GUI_VIRTUAL_HEIGHT;
  FXScale := 0.0;
  FYScale := 0.0;
  if (AWidth <> 0.0) and (AHeight <> 0.0) then
  begin
    LInverse := 1.0 / AWidth;
    FXScale := FVidWidth * LInverse;
    LInverse := 1.0 / AHeight;
    FYScale := FVidHeight * LInverse;
  end;
end;

procedure TGuiDrawContext.SetCursor(const ANumber: Integer);
begin
  if (ANumber < 0) or (ANumber >= GUI_CURSOR_COUNT) then
    FCursor := 0
  else
    FCursor := ANumber;
end;

procedure TGuiDrawContext.GetTransformInfo(out AOrigin: TIdVec3; out AMat: TIdMat3);
begin
  AMat := FMat;
  AOrigin := FOrigin;
end;

procedure TGuiDrawContext.SetTransformInfo(const AOrigin: TIdVec3; const AMat: TIdMat3);
begin
  FOrigin := AOrigin;
  FMat := AMat;
end;

procedure TGuiDrawContext.PushClipRect(const ARect: TGuiRectangle);
begin
  FClipRects.Add(ARect);
end;

procedure TGuiDrawContext.PushClipRect(const AX, AY, AW, AH: Single);
begin
  FClipRects.Add(TGuiRectangle.Create(AX, AY, AW, AH));
end;

procedure TGuiDrawContext.PopClipRect;
begin
  if FClipRects.Count > 0 then
    FClipRects.Delete(FClipRects.Count - 1);
end;

procedure TGuiDrawContext.EnableClipping(const AValue: Boolean);
begin
  FEnableClipping := AValue;
end;

// A row of a matrix times a vector, with every product and sum rounded to a float (Win32 and Win64 alike)
function RowTimesVec3(const AX, AY, AZ: Single; const AVec: TIdVec3): Single;
var
  LFirst, LSecond, LThird: Single;
begin
  LFirst := AX * AVec.X;
  LSecond := AY * AVec.Y;
  LThird := AZ * AVec.Z;
  LFirst := LFirst + LSecond;
  Result := LFirst + LThird;
end;

// operator*=(idVec3 &, const idMat3 &): the columns of the matrix (the product of idMat3 and a vector)
procedure Mat3TimesVec3(const AMat: TIdMat3; var AVec: TIdVec3);
var
  LResult: TIdVec3;
begin
  LResult.X := RowTimesVec3(AMat.Rows[0].X, AMat.Rows[1].X, AMat.Rows[2].X, AVec);
  LResult.Y := RowTimesVec3(AMat.Rows[0].Y, AMat.Rows[1].Y, AMat.Rows[2].Y, AVec);
  LResult.Z := RowTimesVec3(AMat.Rows[0].Z, AMat.Rows[1].Z, AMat.Rows[2].Z, AVec);
  AVec := LResult;
end;

// idMat4::operator*(idVec3): the vector as a point, divided by the w of the result
procedure Mat4TimesVec3(const AMat: TIdMat4; var AVec: TIdVec3);
var
  LScale, LInverse, LX, LY, LZ: Single;
begin
  LScale := RowTimesVec3(AMat.Rows[3].X, AMat.Rows[3].Y, AMat.Rows[3].Z, AVec);
  LScale := LScale + AMat.Rows[3].W;
  if LScale = 0.0 then
  begin
    AVec.SetValues(0.0, 0.0, 0.0);
    Exit;
  end;
  LX := RowTimesVec3(AMat.Rows[0].X, AMat.Rows[0].Y, AMat.Rows[0].Z, AVec);
  LX := LX + AMat.Rows[0].W;
  LY := RowTimesVec3(AMat.Rows[1].X, AMat.Rows[1].Y, AMat.Rows[1].Z, AVec);
  LY := LY + AMat.Rows[1].W;
  LZ := RowTimesVec3(AMat.Rows[2].X, AMat.Rows[2].Y, AMat.Rows[2].Z, AVec);
  LZ := LZ + AMat.Rows[2].W;
  if LScale <> 1.0 then
  begin
    LInverse := 1.0 / LScale;
    LX := LX * LInverse;
    LY := LY * LInverse;
    LZ := LZ * LInverse;
  end;
  AVec.SetValues(LX, LY, LZ);
end;

function InterpolateTexture(const AFirst, ASecond, AU: Single): Single;
var
  LInverse: Single;
  LLeft: Single;
  LRight: Single;
begin
  // each step is a float, as the original computes it
  LInverse := 1.0 - AU;
  LLeft := AFirst * LInverse;
  LRight := ASecond * AU;
  Result := LLeft + LRight;
end;

function TGuiDrawContext.ClipCoords(var AX, AY, AW, AH: Single; const AHasTexture: Boolean;
  var AS1, AT1, AS2, AT2: Single): Boolean;
var
  LIndex: Integer;
  LClip: TGuiRectangle;
  LOX, LOY, LOW, LOH: Single;
  LDelta, LLimit, LU, LNS1, LNS2, LNT1, LNT2: Single;
begin
  if (not FEnableClipping) or (FClipRects.Count = 0) then
    Exit(False);
  // while( --c > 0 ): the rectangle at index 0 is never applied
  LIndex := FClipRects.Count;
  while True do
  begin
    Dec(LIndex);
    if LIndex <= 0 then
      Break;
    LClip := FClipRects[LIndex];
    LOX := AX;
    LOY := AY;
    LOW := AW;
    LOH := AH;
    if (LOW <= 0.0) or (LOH <= 0.0) then
      Break;
    if AX < LClip.X then
    begin
      LDelta := LClip.X - AX;
      AW := AW - LDelta;
      AX := LClip.X;
    end
    else
    begin
      LLimit := LClip.X + LClip.W;
      if AX > LLimit then
      begin
        AX := 0.0;
        AW := 0.0;
        AY := 0.0;
        AH := 0.0;
      end;
    end;
    if AY < LClip.Y then
    begin
      LDelta := LClip.Y - AY;
      AH := AH - LDelta;
      AY := LClip.Y;
    end
    else
    begin
      LLimit := LClip.Y + LClip.H;
      if AY > LLimit then
      begin
        AX := 0.0;
        AW := 0.0;
        AY := 0.0;
        AH := 0.0;
      end;
    end;
    if AW > LClip.W then
    begin
      LDelta := LClip.W - AX;
      AW := LDelta + LClip.X;
    end
    else
    begin
      LDelta := AX + AW;
      LLimit := LClip.X + LClip.W;
      if LDelta > LLimit then
        AW := LClip.Right - AX;
    end;
    if AH > LClip.H then
    begin
      LDelta := LClip.H - AY;
      AH := LDelta + LClip.Y;
    end
    else
    begin
      LDelta := AY + AH;
      LLimit := LClip.Y + LClip.H;
      if LDelta > LLimit then
        AH := LClip.Bottom - AY;
    end;
    if AHasTexture and (LOW > 0.0) then
    begin
      // upper left
      LDelta := AX - LOX;
      LU := LDelta / LOW;
      LNS1 := InterpolateTexture(AS1, AS2, LU);
      // upper right
      LDelta := AX + AW;
      LDelta := LDelta - LOX;
      LU := LDelta / LOW;
      LNS2 := InterpolateTexture(AS1, AS2, LU);
      // lower left
      LDelta := AY - LOY;
      LU := LDelta / LOH;
      LNT1 := InterpolateTexture(AT1, AT2, LU);
      // lower right
      LDelta := AY + AH;
      LDelta := LDelta - LOY;
      LU := LDelta / LOH;
      LNT2 := InterpolateTexture(AT1, AT2, LU);
      AS1 := LNS1;
      AS2 := LNS2;
      AT1 := LNT1;
      AT2 := LNT2;
    end;
  end;
  Result := (AW = 0.0) or (AH = 0.0);
end;

function TGuiDrawContext.ClippedCoords(var AX, AY, AW, AH: Single): Boolean;
var
  LS1, LT1, LS2, LT2: Single;
begin
  LS1 := 0.0;
  LT1 := 0.0;
  LS2 := 0.0;
  LT2 := 0.0;
  Result := ClipCoords(AX, AY, AW, AH, False, LS1, LT1, LS2, LT2);
end;

function TGuiDrawContext.ClippedCoords(var AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single): Boolean;
begin
  Result := ClipCoords(AX, AY, AW, AH, True, AS1, AT1, AS2, AT2);
end;

procedure TGuiDrawContext.AdjustCoords(var AX, AY, AW, AH: Single);
begin
  AX := AX * FXScale;
  AY := AY * FYScale;
  AW := AW * FXScale;
  AH := AH * FYScale;
end;

procedure TGuiDrawContext.BuildQuad(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single; out AQuad: TGuiQuad;
  out ATransformed: Boolean);
var
  LIndex: Integer;
  LRight, LBottom: Single;
begin
  LRight := AX + AW;
  LBottom := AY + AH;
  AQuad[0].Xyz := TIdVec3.Create(AX, AY, 0.0);
  AQuad[0].S := AS1;
  AQuad[0].T := AT1;
  AQuad[1].Xyz := TIdVec3.Create(LRight, AY, 0.0);
  AQuad[1].S := AS2;
  AQuad[1].T := AT1;
  AQuad[2].Xyz := TIdVec3.Create(LRight, LBottom, 0.0);
  AQuad[2].S := AS2;
  AQuad[2].T := AT2;
  AQuad[3].Xyz := TIdVec3.Create(AX, LBottom, 0.0);
  AQuad[3].S := AS1;
  AQuad[3].T := AT2;
  ATransformed := not FMat.IsIdentity;
  if ATransformed then
    for LIndex := 0 to 3 do
    begin
      AQuad[LIndex].Xyz := AQuad[LIndex].Xyz - FOrigin;
      Mat3TimesVec3(FMat, AQuad[LIndex].Xyz);
      AQuad[LIndex].Xyz := AQuad[LIndex].Xyz + FOrigin;
    end;
end;

procedure TGuiDrawContext.DrawStretchPic(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single;
  const AShader: IGuiMaterial);
var
  LQuad: TGuiQuad;
  LTransformed: Boolean;
begin
  BuildQuad(AX, AY, AW, AH, AS1, AT1, AS2, AT2, LQuad, LTransformed);
  FSurface.DrawStretchPic(LQuad, AShader, LTransformed);
end;

procedure TGuiDrawContext.DrawStretchPicRotated(const AX, AY, AW, AH, AS1, AT1, AS2, AT2: Single;
  const AShader: IGuiMaterial; const AAngle: Single);
var
  LQuad: TGuiQuad;
  LTransformed: Boolean;
  LIndex: Integer;
  LCenter: TIdVec3;
  LRotation: TIdMat4;
  LSin, LCos, LHalf: Single;
begin
  BuildQuad(AX, AY, AW, AH, AS1, AT1, AS2, AT2, LQuad, LTransformed);
  // a translation to the center of the image, to rotate and draw
  LHalf := AW / 2;
  LCenter.X := AX + LHalf;
  LHalf := AH / 2;
  LCenter.Y := AY + LHalf;
  LCenter.Z := 0.0;
  LRotation := TIdMat4.Identity;
  LSin := TIdMath.Sin(AAngle);
  LCos := TIdMath.Cos(AAngle);
  LRotation.Rows[0].X := LCos;
  LRotation.Rows[0].Y := LSin;
  LRotation.Rows[1].X := -LSin;
  LRotation.Rows[1].Y := LCos;
  for LIndex := 0 to 3 do
  begin
    LQuad[LIndex].Xyz := LQuad[LIndex].Xyz - LCenter;
    Mat4TimesVec3(LRotation, LQuad[LIndex].Xyz);
    LQuad[LIndex].Xyz := LQuad[LIndex].Xyz + LCenter;
  end;
  // the flag is only whether the angle is not zero
  FSurface.DrawStretchPic(LQuad, AShader, AAngle <> 0.0);
end;

procedure TGuiDrawContext.MaterialCoords(var AW, AH, AS0, AT0, AS1, AT1: Single; const AScaleX, AScaleY: Single);
var
  LScaleX, LScaleY: Single;
begin
  LScaleX := AScaleX;
  LScaleY := AScaleY;
  // handle negative scales as well
  if LScaleX < 0.0 then
  begin
    AW := AW * -1;
    LScaleX := LScaleX * -1;
  end;
  if LScaleY < 0.0 then
  begin
    AH := AH * -1;
    LScaleY := LScaleY * -1;
  end;
  if AW < 0.0 then
  begin
    // flip about vertical
    AW := -AW;
    AS0 := 1 * LScaleX;
    AS1 := 0.0;
  end
  else
  begin
    AS0 := 0.0;
    AS1 := 1 * LScaleX;
  end;
  if AH < 0.0 then
  begin
    // flip about horizontal
    AH := -AH;
    AT0 := 1 * LScaleY;
    AT1 := 0.0;
  end
  else
  begin
    AT0 := 0.0;
    AT1 := 1 * LScaleY;
  end;
end;

procedure TGuiDrawContext.DrawMaterial(const AX, AY, AW, AH: Single; const AMaterial: IGuiMaterial;
  const AColor: TIdVec4; const AScaleX, AScaleY: Single);
var
  LX, LY, LW, LH, LS0, LS1, LT0, LT1: Single;
begin
  FSurface.SetColor(AColor);
  LX := AX;
  LY := AY;
  LW := AW;
  LH := AH;
  MaterialCoords(LW, LH, LS0, LT0, LS1, LT1, AScaleX, AScaleY);
  if ClippedCoords(LX, LY, LW, LH, LS0, LT0, LS1, LT1) then
    Exit;
  AdjustCoords(LX, LY, LW, LH);
  DrawStretchPic(LX, LY, LW, LH, LS0, LT0, LS1, LT1, AMaterial);
end;

procedure TGuiDrawContext.DrawMaterialRotated(const AX, AY, AW, AH: Single; const AMaterial: IGuiMaterial;
  const AColor: TIdVec4; const AScaleX, AScaleY, AAngle: Single);
var
  LX, LY, LW, LH, LS0, LS1, LT0, LT1: Single;
begin
  FSurface.SetColor(AColor);
  LX := AX;
  LY := AY;
  LW := AW;
  LH := AH;
  MaterialCoords(LW, LH, LS0, LT0, LS1, LT1, AScaleX, AScaleY);
  if (AAngle = 0.0) and ClippedCoords(LX, LY, LW, LH, LS0, LT0, LS1, LT1) then
    Exit;
  AdjustCoords(LX, LY, LW, LH);
  DrawStretchPicRotated(LX, LY, LW, LH, LS0, LT0, LS1, LT1, AMaterial, AAngle);
end;

procedure TGuiDrawContext.DrawFilledRect(const AX, AY, AW, AH: Single; const AColor: TIdVec4);
var
  LX, LY, LW, LH: Single;
begin
  if AColor.W = 0.0 then
    Exit;
  FSurface.SetColor(AColor);
  LX := AX;
  LY := AY;
  LW := AW;
  LH := AH;
  if ClippedCoords(LX, LY, LW, LH) then
    Exit;
  AdjustCoords(LX, LY, LW, LH);
  DrawStretchPic(LX, LY, LW, LH, 0, 0, 0, 0, FWhiteImage);
end;

procedure TGuiDrawContext.DrawRect(const AX, AY, AW, AH, ASize: Single; const AColor: TIdVec4);
var
  LX, LY, LW, LH, LOffset: Single;
begin
  if AColor.W = 0.0 then
    Exit;
  FSurface.SetColor(AColor);
  LX := AX;
  LY := AY;
  LW := AW;
  LH := AH;
  if ClippedCoords(LX, LY, LW, LH) then
    Exit;
  AdjustCoords(LX, LY, LW, LH);
  DrawStretchPic(LX, LY, ASize, LH, 0, 0, 0, 0, FWhiteImage);
  LOffset := LX + LW;
  LOffset := LOffset - ASize;
  DrawStretchPic(LOffset, LY, ASize, LH, 0, 0, 0, 0, FWhiteImage);
  DrawStretchPic(LX, LY, LW, ASize, 0, 0, 0, 0, FWhiteImage);
  LOffset := LY + LH;
  LOffset := LOffset - ASize;
  DrawStretchPic(LX, LOffset, LW, ASize, 0, 0, 0, 0, FWhiteImage);
end;

procedure TGuiDrawContext.DrawMaterialRect(const AX, AY, AW, AH, ASize: Single; const AMaterial: IGuiMaterial;
  const AColor: TIdVec4);
var
  LOffset: Single;
begin
  if AColor.W = 0.0 then
    Exit;
  FSurface.SetColor(AColor);
  DrawMaterial(AX, AY, ASize, AH, AMaterial, AColor);
  LOffset := AX + AW;
  LOffset := LOffset - ASize;
  DrawMaterial(LOffset, AY, ASize, AH, AMaterial, AColor);
  DrawMaterial(AX, AY, AW, ASize, AMaterial, AColor);
  LOffset := AY + AH;
  LOffset := LOffset - ASize;
  DrawMaterial(AX, LOffset, AW, ASize, AMaterial, AColor);
end;

procedure TGuiDrawContext.DrawCursor(var AX, AY: Single; const ASize: Single);
var
  LSize: Single;
begin
  LSize := ASize;
  if AX < 0.0 then
    AX := 0.0;
  if AX >= FVidWidth then
    AX := FVidWidth;
  if AY < 0.0 then
    AY := 0.0;
  if AY >= FVidHeight then
    AY := FVidHeight;
  FSurface.SetColor(FColorWhite);
  // the size is both the width and the height: it is scaled twice
  AdjustCoords(AX, AY, LSize, LSize);
  DrawStretchPic(AX, AY, LSize, LSize, 0, 0, 1, 1, FCursorImages[FCursor]);
end;

procedure TGuiDrawContext.PaintChar(const AX, AY: Single; const AWidth, AHeight: Integer;
  const AScale, AS1, AT1, AS2, AT2: Single; const AShader: IGuiMaterial);
var
  LX, LY, LW, LH, LS, LT, LS2, LT2: Single;
begin
  LX := AX;
  LY := AY;
  LS := AS1;
  LT := AT1;
  LS2 := AS2;
  LT2 := AT2;
  LW := AWidth * AScale;
  LH := AHeight * AScale;
  if ClippedCoords(LX, LY, LW, LH, LS, LT, LS2, LT2) then
    Exit;
  AdjustCoords(LX, LY, LW, LH);
  DrawStretchPic(LX, LY, LW, LH, LS, LT, LS2, LT2, AShader);
end;

procedure TGuiDrawContext.DrawEditCursor(const AX, AY, AScale: Single);
var
  LUseScale, LYAdjust, LTop: Single;
  LGlyph: TGuiGlyph;
  LIndex: Integer;
begin
  if ((FTickNumber shr 4) and 1) <> 0 then
    Exit;
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  if FOverStrikeMode then
    LIndex := Ord('_')
  else
    LIndex := Ord('|');
  LGlyph := FUseFont.Info.Glyphs[LIndex];
  LYAdjust := LUseScale * LGlyph.Top;
  LTop := AY - LYAdjust;
  PaintChar(AX, LTop, LGlyph.ImageWidth, LGlyph.ImageHeight, LUseScale, LGlyph.S, LGlyph.T, LGlyph.S2, LGlyph.T2,
    FUseFont.Materials[LIndex]);
end;

function TGuiDrawContext.DrawChars(AX, AY: Single; const AScale: Single; const AColor: TIdVec4;
  const AText: AnsiString; const AAdjust: Single; const ALimit, AStyle: Integer; const ACursor: Integer): Integer;
var
  LText: AnsiString;
  LLength, LPosition, LCount, LIndex: Integer;
  LGlyph: TGuiGlyph;
  LUseScale, LPartialSkip, LYAdjust, LAdvance, LTop: Single;
  LNewColor: TIdVec4;
begin
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  LCount := 0;
  LText := CText(AText);
  if AColor.W <> 0.0 then
  begin
    FSurface.SetColor(AColor);
    LNewColor := AColor;
    LLength := Length(LText);
    if (ALimit > 0) and (LLength > ALimit) then
      LLength := ALimit;
    LPosition := 1;
    while (CharAt(LText, LPosition) <> 0) and (LCount < LLength) do
    begin
      LIndex := CharAt(LText, LPosition);
      LGlyph := FUseFont.Info.Glyphs[LIndex];
      if IsColorAt(LText, LPosition) then
      begin
        if CharAt(LText, LPosition + 1) = Ord('0') then
          LNewColor := AColor
        else
        begin
          LNewColor := ColorForIndex(CharAt(LText, LPosition + 1));
          LNewColor.W := AColor.W;
        end;
        if (ACursor = LCount) or (ACursor = LCount + 1) then
        begin
          LAdvance := LGlyph.XSkip * LUseScale;
          LAdvance := LAdvance + AAdjust;
          LPartialSkip := LAdvance / 5.0;
          if ACursor = LCount then
            LPartialSkip := LPartialSkip * 2.0
          else
            FSurface.SetColor(LNewColor);
          LTop := AX - LPartialSkip;
          DrawEditCursor(LTop, AY, AScale);
        end;
        FSurface.SetColor(LNewColor);
        Inc(LPosition, 2);
        Inc(LCount, 2);
        Continue;
      end;
      LYAdjust := LUseScale * LGlyph.Top;
      LTop := AY - LYAdjust;
      PaintChar(AX, LTop, LGlyph.ImageWidth, LGlyph.ImageHeight, LUseScale, LGlyph.S, LGlyph.T, LGlyph.S2, LGlyph.T2,
        FUseFont.Materials[LIndex]);
      if ACursor = LCount then
        DrawEditCursor(AX, AY, AScale);
      LAdvance := LGlyph.XSkip * LUseScale;
      LAdvance := LAdvance + AAdjust;
      AX := AX + LAdvance;
      Inc(LPosition);
      Inc(LCount);
    end;
    if ACursor = LLength then
      DrawEditCursor(AX, AY, AScale);
  end;
  Result := LCount;
end;

function TGuiDrawContext.DrawText(const AText: AnsiString; const AScale: Single; const AAlign: Integer;
  const AColor: TIdVec4; const ARect: TGuiRectangle; const AWrap: Boolean; const ACursor: Integer;
  const ACalcOnly: Boolean; const ABreaks: TList<Integer>; const ALimit: Integer): Integer;
var
  LText: AnsiString;
  LBuffer: array[0..TEXT_BUFFER_SIZE - 1] of Byte;
  LLength, LNewLine, LNewLineWidth, LCount, LCursor, LPointer, LNewLinePointer, LChar, LIterations,
    LMaxIterations: Integer;
  LY, LX, LTextWidth, LCharSkip, LLineSkip, LStep: Single;
  LLineBreak, LWordBreak: Boolean;
  LLine: AnsiString;
begin
  LText := CText(AText);
  LCursor := ACursor;
  LCharSkip := MaxCharWidth(AScale) + 1;
  LLineSkip := MaxCharHeight(AScale);
  SetFontByScale(AScale);
  LTextWidth := 0.0;
  LNewLinePointer := 0;
  if (not ACalcOnly) and (LText = '') then
  begin
    if LCursor = 0 then
    begin
      FSurface.SetColor(AColor);
      DrawEditCursor(ARect.X, LLineSkip + ARect.Y, AScale);
    end;
    Exit(TIdMath.FtoiFast(ARect.W / LCharSkip));
  end;
  LY := LLineSkip + ARect.Y;
  LLength := 0;
  LBuffer[0] := 0;
  LNewLine := 0;
  LNewLineWidth := 0;
  LPointer := 1;
  if Assigned(ABreaks) then
    ABreaks.Add(0);
  LCount := 0;
  LLineBreak := False;
  LWordBreak := False;
  LIterations := 0;
  LMaxIterations := 4 * (Length(LText) + 2) + 16;
  // while (p): a pointer that is zero here is NULL there; a position is counted from 1
  while LPointer <> 0 do
  begin
    Inc(LIterations);
    if LIterations > LMaxIterations then
      raise EGuiDrawException.Create('the layout of the text does not advance');
    LChar := CharAt(LText, LPointer);
    if (LChar = 10) or (LChar = 13) or (LChar = 0) then
    begin
      LLineBreak := True;
      if ((LChar = 10) and (CharAt(LText, LPointer + 1) = 13)) or
        ((LChar = 13) and (CharAt(LText, LPointer + 1) = 10)) then
        Inc(LPointer);
    end;
    // the width of the next character is taken as zero (a temporary hack of the original)
    if (not LLineBreak) and (LTextWidth > ARect.W) then
    begin
      // The next character will cause us to overflow, if we haven't yet found a suitable
      // break spot, set it to be this character
      if (LLength > 0) and (LNewLine = 0) then
      begin
        LNewLine := LLength;
        LNewLinePointer := LPointer;
        LNewLineWidth := TIdMath.Ftoi(LTextWidth);
      end;
      LWordBreak := True;
    end
    else if LLineBreak or (AWrap and ((CharAt(LText, LPointer) = 32) or (CharAt(LText, LPointer) = 9))) then
    begin
      // The next character is in view, so if we are a break character, store our position
      LNewLine := LLength;
      LNewLinePointer := LPointer + 1;
      LNewLineWidth := TIdMath.Ftoi(LTextWidth);
    end;
    if LLineBreak or LWordBreak then
    begin
      LX := ARect.X;
      if AAlign = GUI_ALIGN_RIGHT then
      begin
        LX := ARect.X + ARect.W;
        LX := LX - LNewLineWidth;
      end
      else if AAlign = GUI_ALIGN_CENTER then
      begin
        LStep := ARect.W - LNewLineWidth;
        LStep := LStep / 2;
        LX := ARect.X + LStep;
      end;
      if AWrap or (LNewLine > 0) then
      begin
        LBuffer[LNewLine] := 0;
        // This is a special case to handle breaking in the middle of a word.
        // if we didn't do this, the cursor would appear on the end of this line
        // and the beginning of the next.
        if LWordBreak and (LCursor >= LNewLine) and (LNewLine = LLength) then
          Inc(LCursor);
      end;
      if not ACalcOnly then
      begin
        SetString(LLine, PAnsiChar(@LBuffer[0]), StrLen(PAnsiChar(@LBuffer[0])));
        Inc(LCount, DrawChars(LX, LY, AScale, AColor, LLine, 0, 0, 0, LCursor));
      end;
      if LCursor < LNewLine then
        LCursor := -1
      else if LCursor >= 0 then
        LCursor := LCursor - (LNewLine + 1);
      if not AWrap then
        Exit(LNewLine);
      if ((ALimit <> 0) and (LCount > ALimit)) or (CharAt(LText, LPointer) = 0) then
        Break;
      LStep := LLineSkip + 5;
      LY := LY + LStep;
      if (not ACalcOnly) and (LY > ARect.Bottom) then
        Break;
      LPointer := LNewLinePointer;
      if Assigned(ABreaks) and (LPointer <> 0) then
        ABreaks.Add(LPointer - 1);
      LLength := 0;
      LNewLine := 0;
      LNewLineWidth := 0;
      LTextWidth := 0.0;
      LLineBreak := False;
      LWordBreak := False;
      Continue;
    end;
    if LLength > TEXT_BUFFER_SIZE - 2 then
      raise EGuiDrawException.CreateFmt('a line of %d characters or more does not fit the buffer of the text',
        [TEXT_BUFFER_SIZE - 1]);
    LBuffer[LLength] := Byte(LChar);
    Inc(LPointer);
    Inc(LLength);
    LBuffer[LLength] := 0;
    // update the width
    if (LBuffer[LLength - 1] <> Ord('^')) and ((LLength <= 1) or (LBuffer[LLength - 2] <> Ord('^'))) then
    begin
      LStep := AScale * FUseFont.Info.GlyphScale;
      LStep := LStep * FUseFont.Info.Glyphs[LBuffer[LLength - 1]].XSkip;
      LTextWidth := LTextWidth + LStep;
    end;
  end;
  Result := TIdMath.FtoiFast(ARect.W / LCharSkip);
end;

function TGuiDrawContext.CharWidth(const AChar: AnsiChar; const AScale: Single): Integer;
var
  LUseScale, LWidth: Single;
begin
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  LWidth := FUseFont.Info.Glyphs[Ord(AChar)].XSkip * LUseScale;
  Result := TIdMath.FtoiFast(LWidth);
end;

function TGuiDrawContext.TextWidth(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
var
  LText: AnsiString;
  LIndex, LWidth: Integer;
  LScaled: Single;
begin
  SetFontByScale(AScale);
  LText := CText(AText);
  LWidth := 0;
  LIndex := 1;
  while (CharAt(LText, LIndex) <> 0) and ((ALimit <= 0) or (LIndex - 1 < ALimit)) do
  begin
    if IsColorAt(LText, LIndex) then
      Inc(LIndex)
    else
      Inc(LWidth, FUseFont.Info.Glyphs[CharAt(LText, LIndex)].XSkip);
    Inc(LIndex);
  end;
  LScaled := AScale * FUseFont.Info.GlyphScale;
  LScaled := LScaled * LWidth;
  Result := TIdMath.FtoiFast(LScaled);
end;

function TGuiDrawContext.TextHeight(const AText: AnsiString; const AScale: Single; const ALimit: Integer): Integer;
var
  LText: AnsiString;
  LLength, LCount, LPosition: Integer;
  LMax, LUseScale: Single;
begin
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  LMax := 0.0;
  LText := CText(AText);
  LLength := Length(LText);
  if (ALimit > 0) and (LLength > ALimit) then
    LLength := ALimit;
  LCount := 0;
  LPosition := 1;
  while (CharAt(LText, LPosition) <> 0) and (LCount < LLength) do
  begin
    if IsColorAt(LText, LPosition) then
    begin
      Inc(LPosition, 2);
      Continue;
    end;
    if LMax < FUseFont.Info.Glyphs[CharAt(LText, LPosition)].Height then
      LMax := FUseFont.Info.Glyphs[CharAt(LText, LPosition)].Height;
    Inc(LPosition);
    Inc(LCount);
  end;
  LMax := LMax * LUseScale;
  Result := TIdMath.FtoiFast(LMax);
end;

function TGuiDrawContext.MaxCharWidth(const AScale: Single): Integer;
var
  LUseScale, LWidth: Single;
begin
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  LWidth := RequireFont.MaxWidth * LUseScale;
  Result := TIdMath.FtoiFast(LWidth);
end;

function TGuiDrawContext.MaxCharHeight(const AScale: Single): Integer;
var
  LUseScale, LHeight: Single;
begin
  SetFontByScale(AScale);
  LUseScale := AScale * FUseFont.Info.GlyphScale;
  LHeight := RequireFont.MaxHeight * LUseScale;
  Result := TIdMath.FtoiFast(LHeight);
end;

function TGuiDrawContext.GetScrollBarImage(const AIndex: Integer): IGuiMaterial;
begin
  if (AIndex >= GUI_SCROLLBAR_HBACK) and (AIndex < GUI_SCROLLBAR_COUNT) then
    Result := FScrollBarImages[AIndex]
  else
    Result := FScrollBarImages[GUI_SCROLLBAR_HBACK];
end;

end.
