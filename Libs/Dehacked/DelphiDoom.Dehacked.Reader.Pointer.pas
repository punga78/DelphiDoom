{******************************************************************************}
{                                                                              }
{  DelphiDoom: Dehacked library - the block Pointer                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Dehacked.Reader.Pointer;

interface

uses
  DelphiDoom.Logging.Intf, DelphiDoom.Dehacked.Section, DelphiDoom.Dehacked.Intf,
  DelphiDoom.Dehacked.Reader.Base;

type
  /// <summary>
  ///   Pointer n (Frame m) and the line "Codep Frame = k": the action of the frame m is the one that the
  ///   frame k had. The block has one entry; Reference.Number is m and Number of the entry is k
  /// </summary>
  TDehackedPointerReader = class(TDehackedReaderBase)
  public
    function Read(const AKeyword, ARest: string;
      const ASource: IDehackedLineSource): TDehackedSection; override;
  end;

implementation

uses
  DelphiDoom.Dehacked.Types, DelphiDoom.Dehacked.Strings;

{ TDehackedPointerReader }

function TDehackedPointerReader.Read(const AKeyword, ARest: string;
  const ASource: IDehackedLineSource): TDehackedSection;
var
  LText, LWord, LNumberText, LLine, LKey, LValue: string;
  LHeaderLine, LFrame: Integer;
  LReference: TDehackedReference;
  LEntry: TDehackedEntry;
begin
  Result := nil;
  LHeaderLine := ASource.LineNumber;
  LText := TDehackedStrings.SecondWord(ARest, '(');
  if Length(LText) < 7 then
    Exit;
  if LText[Length(LText)] <> ')' then
    Exit;
  SetLength(LText, Length(LText) - 1);
  TDehackedStrings.SplitChar(LText, LWord, LNumberText);
  if LWord <> 'FRAME' then
    Exit;
  LFrame := TDehackedStrings.ToInteger(LNumberText, -1);
  if LFrame < 0 then
    Exit;

  if not ASource.Next(LLine) then
    Exit;
  if TDehackedStrings.IndexOfChar('=', LLine) = 0 then
  begin
    ASource.PushBack;
    Exit;
  end;
  TDehackedStrings.SplitChar(LLine, LKey, LValue, '=');
  if LKey <> 'CODEP FRAME' then
  begin
    ASource.PushBack;
    Exit;
  end;

  LEntry := Default(TDehackedEntry);
  LEntry.Line := ASource.LineNumber;
  LEntry.Key := LKey;
  LEntry.Text := LValue;
  LEntry.Number := TDehackedStrings.ToInteger(LValue, -1);
  LReference := Default(TDehackedReference);
  LReference.Number := LFrame;
  Result := TDehackedSection.Create(dskPointer, LHeaderLine, AKeyword, ARest);
  Result.Reference := LReference;
  Result.AddEntry(LEntry);
end;

end.
