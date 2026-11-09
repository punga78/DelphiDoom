{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom interface library - NumberText of OpenXcom (a number in     }
{  the tiny 3 x 5 digits)                                                       }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomUi.NumberText;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Types, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Shade, DelphiDoom.XcomEngine.Types,
  DelphiDoom.XcomEngine.Widget;

type
  /// <summary>A number drawn with 3 x 5 pixel digits, optionally with a border; the color is added to the pixels</summary>
  TXcomNumberText = class(TXcomWidget)
  strict private
    FChars: array[0..9] of TXcomSurface;
    FBorderedChars: array[0..9] of TXcomSurface;
    FValue: Cardinal;
    FBordered: Boolean;
    FColor: Byte;
  public
    constructor Create(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0);
    destructor Destroy; override;
    procedure SetValue(AValue: Cardinal);
    function GetValue: Cardinal;
    procedure SetColor(AColor: Byte); override;
    function GetColor: Byte; override;
    procedure SetPalette(AColors: PXcomColor; AFirst: Integer = 0; ACount: Integer = 256); override;
    procedure Draw; override;
    procedure SetBordered(ABordered: Boolean);
  end;

implementation

const
  // the digits, five rows of three pixels (the leftmost pixel is the highest bit)
  DIGITS: array[0..9, 0..4] of Byte = (
    (7, 5, 5, 5, 7), (2, 6, 2, 2, 7), (7, 1, 7, 4, 7), (7, 1, 7, 1, 7), (5, 5, 7, 1, 1),
    (7, 4, 7, 1, 7), (7, 4, 7, 5, 7), (7, 1, 1, 1, 1), (7, 5, 7, 5, 7), (7, 5, 7, 1, 7));

constructor TXcomNumberText.Create(AWidth, AHeight, AX, AY: Integer);
var
  LDigit: Integer;
  LRow: Integer;
  LColumn: Integer;
  LJ: Integer;
  LK: Integer;
begin
  inherited Create(AWidth, AHeight, AX, AY);
  for LDigit := 0 to 9 do
  begin
    FChars[LDigit] := TXcomSurface.Create(3, 5);
    for LRow := 0 to 4 do
      for LColumn := 0 to 2 do
        if (DIGITS[LDigit, LRow] and (4 shr LColumn)) <> 0 then
          FChars[LDigit].SetPixel(LColumn, LRow, 1);
    FBorderedChars[LDigit] := TXcomSurface.Create(5, 7);
    LJ := 0;
    while LJ <= 2 do
    begin
      LK := 0;
      while LK <= 2 do
      begin
        TXcomSurfaceShader.Blit(FChars[LDigit], FBorderedChars[LDigit], LJ, LK, 11);
        Inc(LK, 2);
      end;
      Inc(LJ, 2);
    end;
    LJ := 0;
    while LJ <= 2 do
    begin
      TXcomSurfaceShader.Blit(FChars[LDigit], FBorderedChars[LDigit], LJ, 1, 8);
      TXcomSurfaceShader.Blit(FChars[LDigit], FBorderedChars[LDigit], 1, LJ, 8);
      Inc(LJ, 2);
    end;
    TXcomSurfaceShader.Blit(FChars[LDigit], FBorderedChars[LDigit], 1, 1, 0);
  end;
end;

destructor TXcomNumberText.Destroy;
var
  LDigit: Integer;
begin
  for LDigit := 0 to 9 do
  begin
    FChars[LDigit].Free;
    FBorderedChars[LDigit].Free;
  end;
  inherited Destroy;
end;

procedure TXcomNumberText.SetValue(AValue: Cardinal);
begin
  FValue := AValue;
  Redraw := True;
end;

function TXcomNumberText.GetValue: Cardinal;
begin
  Result := FValue;
end;

procedure TXcomNumberText.SetColor(AColor: Byte);
begin
  FColor := AColor;
  Redraw := True;
end;

function TXcomNumberText.GetColor: Byte;
begin
  Result := FColor;
end;

procedure TXcomNumberText.SetPalette(AColors: PXcomColor; AFirst, ACount: Integer);
var
  LDigit: Integer;
  LColors: TArray<TXcomColor>;
begin
  inherited SetPalette(AColors, AFirst, ACount);
  if ACount <= 0 then
    Exit;
  SetLength(LColors, ACount);
  Move(AColors^, LColors[0], ACount * SizeOf(TXcomColor));
  for LDigit := 0 to 9 do
  begin
    FChars[LDigit].SetColors(LColors, AFirst);
    FBorderedChars[LDigit].SetColors(LColors, AFirst);
  end;
end;

procedure TXcomNumberText.Draw;
var
  LText: string;
  LChar: Char;
  LX: Integer;
  LDigit: Integer;
begin
  inherited Draw;
  LText := UIntToStr(FValue);
  LX := 0;
  for LChar in LText do
  begin
    LDigit := Ord(LChar) - Ord('0');
    if FBordered then
      FBorderedChars[LDigit].X := LX
    else
      FChars[LDigit].X := LX;
    if FBordered then
    begin
      FBorderedChars[LDigit].Y := 0;
      FBorderedChars[LDigit].Blit(Self);
    end
    else
    begin
      FChars[LDigit].Y := 0;
      FChars[LDigit].Blit(Self);
    end;
    Inc(LX, FChars[LDigit].Width + 1);
  end;
  Offset(FColor);
end;

procedure TXcomNumberText.SetBordered(ABordered: Boolean);
begin
  FBordered := ABordered;
end;

end.
