{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Text                               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Text;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Text old new: the two lengths, and the lines that follow hold the old text and the new one one after
  ///   the other. The lines are joined with a line feed up to the length of both texts; the blank
  ///   lines count and so do the spaces (a line that starts with # or // does not, and from
  ///   there the lines are trimmed)
  /// </summary>
  TDehackedTextReader = class(TDehackedReaderBase)
  public
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedTextReader }

function TDehackedTextReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LFirst, LSecond, LText, LLine: string;
  LOldLength, LNewLength, LHeaderLine: Integer;
begin
  Result := nil;
  LHeaderLine := ASource.LineNumber;
  TDehackedStrings.SplitChar(ARest, LFirst, LSecond);

  LOldLength := TDehackedStrings.ToInteger(LFirst, -1);
  if LOldLength <= 0 then
    Exit;
  LNewLength := TDehackedStrings.ToInteger(LSecond, -1);
  if LNewLength <= 0 then
    Exit;

  LText := '';
  while True do
  begin
    if not ASource.Next(LLine, False) then
      Break;
    LText := LText + LLine;
    if Length(LText) >= LOldLength + LNewLength then
      Break;
    LText := LText + #10;
    if Length(LText) >= LOldLength + LNewLength then
      Break;
  end;
  LNewLength := Length(LText) - LOldLength;
  if LNewLength <= 0 then
    Exit;

  Result := TDehackedSection.Create(dskText, LHeaderLine, AKeyword, ARest);
  Result.OldLength := LOldLength;
  Result.NewLength := LNewLength;
  Result.OldText := Copy(LText, 1, LOldLength);
  Result.NewText := Copy(LText, LOldLength + 1, LNewLength);
end;

end.
