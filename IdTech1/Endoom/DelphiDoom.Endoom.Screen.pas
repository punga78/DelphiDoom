{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - the text screen that a tool edits               }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.Screen;

interface

uses
  System.SysUtils,
  DelphiDoom.Endoom.Types,
  DelphiDoom.Endoom.Intf;

type
  /// <summary>
  ///   The model of the old TEndScreen of ENDEDIT without the bitmap: 80x25 cells of a character
  ///   and an attribute, kept as the 4000 bytes of the lump. Colors are the indices of
  ///   ENDOOM_COLORS (TEndoomColorQuantizer turns a color of any kind into one)
  /// </summary>
  TEndoomScreen = class(TInterfacedObject, IEndoomScreen)
  strict private
    FCells: array[0..ENDOOM_CELLS - 1] of TEndoomCell;
    class function IndexOf(AX, AY: Integer): Integer; static;
    class procedure CheckForeground(AColor: Integer); static;
    class procedure CheckBackground(AColor: Integer); static;
    class function Clip(const ARect: TEndoomRect; out AClipped: TEndoomRect): Boolean; static;
  public
    constructor Create;
    function GetCell(AX, AY: Integer): TEndoomCell;
    procedure SetCell(AX, AY: Integer; const ACell: TEndoomCell);
    function GetCharacter(AX, AY: Integer): Byte;
    procedure SetCharacter(AX, AY: Integer; ACode: Byte);
    function GetForeground(AX, AY: Integer): Integer;
    procedure SetForeground(AX, AY: Integer; AColor: Integer);
    function GetBackground(AX, AY: Integer): Integer;
    procedure SetBackground(AX, AY: Integer; AColor: Integer);
    function GetBlink(AX, AY: Integer): Boolean;
    procedure SetBlink(AX, AY: Integer; ABlink: Boolean);
    procedure Clear;
    procedure FillBackground(const ARect: TEndoomRect; AColor: Integer);
    procedure FillForeground(const ARect: TEndoomRect; AColor: Integer);
    procedure FillCharacter(const ARect: TEndoomRect; ACode: Byte);
    function CopyBlock(const ARect: TEndoomRect): TEndoomBlock;
    procedure PasteBlock(const ABlock: TEndoomBlock; AX, AY: Integer);
    function ToBytes: TBytes;
    procedure LoadFromBytes(const ABytes: TBytes);
    procedure AssignFrom(const ASource: IEndoomScreen);
    function IsSameAs(const AOther: IEndoomScreen): Boolean;
  end;

implementation

{ TEndoomScreen }

constructor TEndoomScreen.Create;
begin
  inherited Create;
  Clear;
end;

class function TEndoomScreen.IndexOf(AX, AY: Integer): Integer;
begin
  if (AX < 0) or (AX >= ENDOOM_COLUMNS) or (AY < 0) or (AY >= ENDOOM_ROWS) then
    raise EEndoomException.CreateFmt(SEndoomBadCell, [AX, AY]);
  Result := AY * ENDOOM_COLUMNS + AX;
end;

class procedure TEndoomScreen.CheckForeground(AColor: Integer);
begin
  if (AColor < 0) or (AColor >= ENDOOM_COLOR_COUNT) then
    raise EEndoomException.CreateFmt(SEndoomBadColorIndex, [AColor]);
end;

class procedure TEndoomScreen.CheckBackground(AColor: Integer);
begin
  if (AColor < 0) or (AColor >= ENDOOM_BACKGROUND_COLOR_COUNT) then
    raise EEndoomException.CreateFmt(SEndoomBadColorIndex, [AColor]);
end;

class function TEndoomScreen.Clip(const ARect: TEndoomRect; out AClipped: TEndoomRect): Boolean;
begin
  AClipped := TEndoomRect.Between(ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  if AClipped.Left < 0 then
    AClipped.Left := 0;
  if AClipped.Top < 0 then
    AClipped.Top := 0;
  if AClipped.Right >= ENDOOM_COLUMNS then
    AClipped.Right := ENDOOM_COLUMNS - 1;
  if AClipped.Bottom >= ENDOOM_ROWS then
    AClipped.Bottom := ENDOOM_ROWS - 1;
  Result := (AClipped.Left <= AClipped.Right) and (AClipped.Top <= AClipped.Bottom);
end;

function TEndoomScreen.GetCell(AX, AY: Integer): TEndoomCell;
begin
  Result := FCells[IndexOf(AX, AY)];
end;

procedure TEndoomScreen.SetCell(AX, AY: Integer; const ACell: TEndoomCell);
begin
  FCells[IndexOf(AX, AY)] := ACell;
end;

function TEndoomScreen.GetCharacter(AX, AY: Integer): Byte;
begin
  Result := FCells[IndexOf(AX, AY)].Code;
end;

procedure TEndoomScreen.SetCharacter(AX, AY: Integer; ACode: Byte);
begin
  FCells[IndexOf(AX, AY)].Code := ACode;
end;

function TEndoomScreen.GetForeground(AX, AY: Integer): Integer;
begin
  Result := FCells[IndexOf(AX, AY)].Attributes and ENDOOM_FOREGROUND_MASK;
end;

procedure TEndoomScreen.SetForeground(AX, AY: Integer; AColor: Integer);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AX, AY);
  CheckForeground(AColor);
  FCells[LIndex].Attributes := (FCells[LIndex].Attributes and not ENDOOM_FOREGROUND_MASK) or Byte(AColor);
end;

function TEndoomScreen.GetBackground(AX, AY: Integer): Integer;
begin
  Result := (FCells[IndexOf(AX, AY)].Attributes and ENDOOM_BACKGROUND_MASK) shr ENDOOM_BACKGROUND_SHIFT;
end;

procedure TEndoomScreen.SetBackground(AX, AY: Integer; AColor: Integer);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AX, AY);
  CheckBackground(AColor);
  FCells[LIndex].Attributes := (FCells[LIndex].Attributes and not ENDOOM_BACKGROUND_MASK) or
    Byte(AColor shl ENDOOM_BACKGROUND_SHIFT);
end;

function TEndoomScreen.GetBlink(AX, AY: Integer): Boolean;
begin
  Result := (FCells[IndexOf(AX, AY)].Attributes and ENDOOM_BLINK_MASK) <> 0;
end;

procedure TEndoomScreen.SetBlink(AX, AY: Integer; ABlink: Boolean);
var
  LIndex: Integer;
begin
  LIndex := IndexOf(AX, AY);
  if ABlink then
    FCells[LIndex].Attributes := FCells[LIndex].Attributes or ENDOOM_BLINK_MASK
  else
    FCells[LIndex].Attributes := FCells[LIndex].Attributes and not ENDOOM_BLINK_MASK;
end;

procedure TEndoomScreen.Clear;
begin
  FillChar(FCells, SizeOf(FCells), 0);
end;

procedure TEndoomScreen.FillBackground(const ARect: TEndoomRect; AColor: Integer);
var
  LRect: TEndoomRect;
  LX: Integer;
  LY: Integer;
begin
  CheckBackground(AColor);
  if not Clip(ARect, LRect) then
    Exit;
  for LY := LRect.Top to LRect.Bottom do
    for LX := LRect.Left to LRect.Right do
      SetBackground(LX, LY, AColor);
end;

procedure TEndoomScreen.FillForeground(const ARect: TEndoomRect; AColor: Integer);
var
  LRect: TEndoomRect;
  LX: Integer;
  LY: Integer;
begin
  CheckForeground(AColor);
  if not Clip(ARect, LRect) then
    Exit;
  for LY := LRect.Top to LRect.Bottom do
    for LX := LRect.Left to LRect.Right do
      SetForeground(LX, LY, AColor);
end;

procedure TEndoomScreen.FillCharacter(const ARect: TEndoomRect; ACode: Byte);
var
  LRect: TEndoomRect;
  LX: Integer;
  LY: Integer;
begin
  if not Clip(ARect, LRect) then
    Exit;
  for LY := LRect.Top to LRect.Bottom do
    for LX := LRect.Left to LRect.Right do
      SetCharacter(LX, LY, ACode);
end;

function TEndoomScreen.CopyBlock(const ARect: TEndoomRect): TEndoomBlock;
var
  LRect: TEndoomRect;
  LX: Integer;
  LY: Integer;
begin
  Result.Width := 0;
  Result.Height := 0;
  Result.Cells := nil;
  if not Clip(ARect, LRect) then
    Exit;
  Result.Width := LRect.Width;
  Result.Height := LRect.Height;
  SetLength(Result.Cells, Result.Width * Result.Height);
  for LY := 0 to Result.Height - 1 do
    for LX := 0 to Result.Width - 1 do
      Result.Cells[LY * Result.Width + LX] := FCells[(LRect.Top + LY) * ENDOOM_COLUMNS + LRect.Left + LX];
end;

procedure TEndoomScreen.PasteBlock(const ABlock: TEndoomBlock; AX, AY: Integer);
var
  LX: Integer;
  LY: Integer;
begin
  if Length(ABlock.Cells) <> ABlock.Width * ABlock.Height then
    raise EEndoomException.CreateFmt(SEndoomBadBlock,
      [ABlock.Width, ABlock.Height, ABlock.Width * ABlock.Height, Length(ABlock.Cells)]);
  for LY := 0 to ABlock.Height - 1 do
    for LX := 0 to ABlock.Width - 1 do
      if (AX + LX >= 0) and (AX + LX < ENDOOM_COLUMNS) and (AY + LY >= 0) and (AY + LY < ENDOOM_ROWS) then
        FCells[(AY + LY) * ENDOOM_COLUMNS + AX + LX] := ABlock.Cells[LY * ABlock.Width + LX];
end;

function TEndoomScreen.ToBytes: TBytes;
begin
  SetLength(Result, ENDOOM_LUMP_SIZE);
  Move(FCells[0], Result[0], ENDOOM_LUMP_SIZE);
end;

procedure TEndoomScreen.LoadFromBytes(const ABytes: TBytes);
begin
  if Length(ABytes) < ENDOOM_LUMP_SIZE then
    raise EEndoomException.CreateFmt(SEndoomBadScreenSize, [ENDOOM_LUMP_SIZE, Length(ABytes)]);
  Move(ABytes[0], FCells[0], ENDOOM_LUMP_SIZE);
end;

procedure TEndoomScreen.AssignFrom(const ASource: IEndoomScreen);
begin
  if not Assigned(ASource) then
    raise EArgumentNilException.Create('ASource');
  LoadFromBytes(ASource.ToBytes);
end;

function TEndoomScreen.IsSameAs(const AOther: IEndoomScreen): Boolean;
var
  LOther: TBytes;
begin
  if not Assigned(AOther) then
    Exit(False);
  LOther := AOther.ToBytes;
  Result := CompareMem(@FCells[0], @LOther[0], ENDOOM_LUMP_SIZE);
end;

end.
