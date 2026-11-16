{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - wildcard masks                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.MaskMatcher;

interface

type
  /// <summary>
  ///   Chooses the names that fit a mask with "*" (the old C_GetMachingList). The rules are the
  ///   old ones, defects included: every piece of the mask is searched from the start of the
  ///   name, and the end of the name is not checked ("e*o" fits "echo2")
  /// </summary>
  TConsoleMaskMatcher = class
  public
    class function Filter(const ANames: TArray<string>; const AMask: string): TArray<string>; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Console.Text;

{ TConsoleMaskMatcher }

class function TConsoleMaskMatcher.Filter(const ANames: TArray<string>;
  const AMask: string): TArray<string>;
var
  LPieces: TArray<string>;
  LPiece: string;
  LFromStart: Boolean;
  LName: string;
  LIndex: Integer;
  LNameIndex: Integer;
  LPosition: Integer;
  LLastEnd: Integer;
  LFits: Boolean;
  LCount: Integer;
begin
  LFromStart := True;
  LPiece := '';
  SetLength(LPieces, 0);
  for LIndex := 1 to Length(AMask) do
    if AMask[LIndex] = '*' then
    begin
      if LIndex = 1 then
        LFromStart := False;
      if LPiece <> '' then
      begin
        SetLength(LPieces, Length(LPieces) + 1);
        LPieces[High(LPieces)] := LPiece;
        LPiece := '';
      end;
    end
    else
      LPiece := LPiece + TConsoleText.UpperCase(AMask[LIndex]);
  if LPiece <> '' then
  begin
    SetLength(LPieces, Length(LPieces) + 1);
    LPieces[High(LPieces)] := LPiece;
  end;

  SetLength(Result, Length(ANames));
  LCount := 0;
  for LNameIndex := 0 to High(ANames) do
  begin
    LLastEnd := 0;
    LFits := True;
    LName := TConsoleText.UpperCase(ANames[LNameIndex]);
    for LIndex := 0 to High(LPieces) do
    begin
      LPosition := Pos(LPieces[LIndex], LName);
      if LFromStart and (LIndex = 0) and (LPosition <> 1) then
        LFits := False
      else if LPosition = 0 then
        LFits := False
      else if LPosition + Length(LPieces[LIndex]) > LLastEnd then
        LLastEnd := LPosition + Length(LPieces[LIndex])
      else
        LFits := False;
      if not LFits then
        Break;
    end;
    if LFits then
    begin
      Result[LCount] := ANames[LNameIndex];
      Inc(LCount);
    end;
  end;
  SetLength(Result, LCount);
end;

end.
