{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - a sprite font (Font of OpenXcom)          }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Font;

interface

uses
  System.SysUtils, System.Generics.Collections, DelphiDoom.XcomSurface.Types, DelphiDoom.XcomSurface.Surface,
  DelphiDoom.XcomSurface.Intf;

type
  /// <summary>One picture of a font: the size of a character cell, its spacing and the surface with the cells</summary>
  TXcomFontImage = record
    Width: Integer;
    Height: Integer;
    Spacing: Integer;
    Surface: TXcomSurface;
  end;

  /// <summary>Where a character is: the picture and the rectangle of the picture that draws it</summary>
  TXcomFontChar = record
    ImageIndex: Integer;
    Rect: TXcomRect;
  end;

  /// <summary>One image of a font in the ruleset, with the size already resolved (an image without its own size takes the font's)</summary>
  TXcomFontImageDefinition = record
    Width: Integer;
    Height: Integer;
    Spacing: Integer;
    /// <summary>The file, relative to the Language folder of the game</summary>
    FileName: string;
    /// <summary>The characters of the picture, in the order of the cells</summary>
    Chars: string;
  end;

  /// <summary>The ruleset entry of a font (the node read by Font::load)</summary>
  TXcomFontDefinition = record
    Monospace: Boolean;
    Images: TArray<TXcomFontImageDefinition>;
  end;

  /// <summary>
  ///   Takes care of storing each character of a sprite font. Sprite fonts are pictures split in cells of a fixed
  ///   size; the characters do not need to fill the cell and, unless the font is monospace, are lined up by the
  ///   columns of pixels they really use. The font owns its surfaces
  /// </summary>
  TXcomFont = class
  strict private
    FImages: TList<TXcomFontImage>;
    FChars: TDictionary<Cardinal, TXcomFontChar>;
    FMonospace: Boolean;
    function EntryOf(ACode: Cardinal): TXcomFontChar;
  public
    constructor Create;
    destructor Destroy; override;
    property Monospace: Boolean read FMonospace write FMonospace;
    /// <summary>Adds a picture (taking its ownership) and returns its index</summary>
    function AddImage(AWidth, AHeight, ASpacing: Integer; ASurface: TXcomSurface): Integer;
    /// <summary>
    ///   Font::init: locates every character of AChars in the cells of the picture AIndex, one cell after
    ///   the other, row after row; unless monospace, the rectangle is cropped to the used pixel columns
    /// </summary>
    procedure Init(AIndex: Integer; const AChars: array of Cardinal);
    /// <summary>
    ///   Font::load: for every image of the definition loads its surface with ALoader and places its characters.
    ///   The surface is created at the cell size first, as the C++ does
    /// </summary>
    procedure Load(const ADefinition: TXcomFontDefinition; const ALoader: IXcomSurfaceLoader);
    /// <summary>The surface that draws ACode; an unknown character is drawn as '?'</summary>
    function GetChar(ACode: Cardinal): TXcomSurface;
    /// <summary>
    ///   Font::getCharSize: the size a character takes (rectangle width plus spacing); the spaces and the control
    ///   characters have a size derived from the font. X and Y repeat W and H
    /// </summary>
    function GetCharSize(ACode: Cardinal): TXcomRect;
    /// <summary>The rectangle of the character in its picture, or false if the font does not have it</summary>
    function TryGetChar(ACode: Cardinal; out AChar: TXcomFontChar): Boolean;
    function Width: Integer;
    function Height: Integer;
    function Spacing: Integer;
    /// <summary>The code points of a string (a surrogate pair is one code point), as Unicode::convUtf8ToUtf32</summary>
    class function CodePoints(const AText: string): TArray<Cardinal>; static;
  end;

implementation

const
  // Unicode::TOK_NBSP
  NBSP = $A0;
  SNoImages = 'Xcom: the font has no images';
  SCellTooWide = 'Xcom: the picture of the font is narrower than a character cell';

{ TXcomFont }

constructor TXcomFont.Create;
begin
  inherited Create;
  FImages := TList<TXcomFontImage>.Create;
  FChars := TDictionary<Cardinal, TXcomFontChar>.Create;
end;

destructor TXcomFont.Destroy;
var
  LImage: TXcomFontImage;
begin
  for LImage in FImages do
    LImage.Surface.Free;
  FImages.Free;
  FChars.Free;
  inherited Destroy;
end;

function TXcomFont.AddImage(AWidth, AHeight, ASpacing: Integer; ASurface: TXcomSurface): Integer;
var
  LImage: TXcomFontImage;
begin
  LImage.Width := AWidth;
  LImage.Height := AHeight;
  LImage.Spacing := ASpacing;
  LImage.Surface := ASurface;
  Result := FImages.Add(LImage);
end;

procedure TXcomFont.Init(AIndex: Integer; const AChars: array of Cardinal);
var
  LImage: TXcomFontImage;
  LSurface: TXcomSurface;
  LLength, LIndex, LStartX, LStartY, LLeft, LRight, LX, LY: Integer;
  LChar: TXcomFontChar;
begin
  LImage := FImages[AIndex];
  LSurface := LImage.Surface;
  LLength := LSurface.Width div LImage.Width;
  if LLength = 0 then
    raise EXcomSurfaceException.Create(SCellTooWide);
  for LIndex := 0 to High(AChars) do
  begin
    LStartX := LIndex mod LLength * LImage.Width;
    LStartY := LIndex div LLength * LImage.Height;
    LChar.ImageIndex := AIndex;
    if FMonospace then
      LChar.Rect := TXcomRect.Make(LStartX, LStartY, LImage.Width, LImage.Height)
    else
    begin
      LLeft := -1;
      LRight := -1;
      for LX := LStartX to LStartX + LImage.Width - 1 do
      begin
        LY := LStartY;
        while (LY < LStartY + LImage.Height) and (LLeft = -1) do
        begin
          if LSurface.GetPixel(LX, LY) <> 0 then
            LLeft := LX;
          Inc(LY);
        end;
      end;
      for LX := LStartX + LImage.Width - 1 downto LStartX do
      begin
        LY := LStartY + LImage.Height;
        while LY > LStartY do
        begin
          Dec(LY);
          if LRight <> -1 then
            Break;
          if LSurface.GetPixel(LX, LY) <> 0 then
            LRight := LX;
        end;
      end;
      LChar.Rect := TXcomRect.Make(LLeft, LStartY, LRight - LLeft + 1, LImage.Height);
    end;
    FChars.AddOrSetValue(AChars[LIndex], LChar);
  end;
end;

procedure TXcomFont.Load(const ADefinition: TXcomFontDefinition; const ALoader: IXcomSurfaceLoader);
var
  LDefinition: TXcomFontImageDefinition;
  LIndex: Integer;
begin
  FMonospace := ADefinition.Monospace;
  for LDefinition in ADefinition.Images do
  begin
    LIndex := AddImage(LDefinition.Width, LDefinition.Height, LDefinition.Spacing,
      ALoader.LoadImage(LDefinition.FileName, LDefinition.Width, LDefinition.Height));
    Init(LIndex, CodePoints(LDefinition.Chars));
  end;
end;

function TXcomFont.EntryOf(ACode: Cardinal): TXcomFontChar;
begin
  // operator[] of the C++ map inserts a zero entry (the first image, an empty rectangle) when it is missing
  if not FChars.TryGetValue(ACode, Result) then
  begin
    Result.ImageIndex := 0;
    Result.Rect := TXcomRect.Make(0, 0, 0, 0);
    FChars.Add(ACode, Result);
  end;
end;

function TXcomFont.GetChar(ACode: Cardinal): TXcomSurface;
begin
  if not FChars.ContainsKey(ACode) then
    ACode := Ord('?');
  Result := FImages[EntryOf(ACode).ImageIndex].Surface;
end;

function TXcomFont.TryGetChar(ACode: Cardinal; out AChar: TXcomFontChar): Boolean;
begin
  Result := FChars.TryGetValue(ACode, AChar);
end;

function TXcomFont.GetCharSize(ACode: Cardinal): TXcomRect;
var
  LChar: TXcomFontChar;
  LImage: TXcomFontImage;
  LWidth, LHeight: Integer;
begin
  if (ACode > 32) and (ACode <> NBSP) then
  begin
    if not FChars.ContainsKey(ACode) then
      ACode := Ord('?');
    LChar := EntryOf(ACode);
    LImage := FImages[LChar.ImageIndex];
    LWidth := LChar.Rect.W + LImage.Spacing;
    LHeight := LChar.Rect.H + LImage.Spacing;
  end
  else
  begin
    if FMonospace then
      LWidth := Width + Spacing
    else if ACode = NBSP then
      LWidth := Width div 4
    else if ACode = 9 then
      LWidth := Width * 3 div 4
    else
      LWidth := Width div 2;
    LHeight := Height + Spacing;
  end;
  Result := TXcomRect.Make(LWidth, LHeight, LWidth, LHeight);
end;

function TXcomFont.Width: Integer;
begin
  if FImages.Count = 0 then
    raise EXcomSurfaceException.Create(SNoImages);
  Result := FImages[0].Width;
end;

function TXcomFont.Height: Integer;
begin
  if FImages.Count = 0 then
    raise EXcomSurfaceException.Create(SNoImages);
  Result := FImages[0].Height;
end;

function TXcomFont.Spacing: Integer;
begin
  if FImages.Count = 0 then
    raise EXcomSurfaceException.Create(SNoImages);
  Result := FImages[0].Spacing;
end;

class function TXcomFont.CodePoints(const AText: string): TArray<Cardinal>;
var
  LIndex, LCount: Integer;
  LCode: Cardinal;
begin
  SetLength(Result, Length(AText));
  LCount := 0;
  LIndex := 1;
  while LIndex <= Length(AText) do
  begin
    LCode := Ord(AText[LIndex]);
    if (LCode >= $D800) and (LCode <= $DBFF) and (LIndex < Length(AText)) and
      (Ord(AText[LIndex + 1]) >= $DC00) and (Ord(AText[LIndex + 1]) <= $DFFF) then
    begin
      LCode := Cardinal($10000) + ((LCode - $D800) shl 10) + Cardinal(Ord(AText[LIndex + 1]) - $DC00);
      Inc(LIndex);
    end;
    Result[LCount] := LCode;
    Inc(LCount);
    Inc(LIndex);
  end;
  SetLength(Result, LCount);
end;

end.
