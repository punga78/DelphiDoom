{******************************************************************************}
{                                                                              }
{  DelphiDoom: console library - the bytes of a cheat                          }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Console.CheatSequenceReader;

interface

type
  /// <summary>Makes the sequence of a cheat from the constant array of the game (old get_cheatseq_string)</summary>
  TCheatSequenceReader = class
  public
    /// <summary>
    ///   The bytes up to the end mark $FF, which is not part of the sequence. The first byte is
    ///   always taken. Without the end mark the array is wrong
    /// </summary>
    class function FromBytes(const ABytes: array of Byte): AnsiString; static;
  end;

implementation

uses
  DelphiDoom.Console.Types;

const
  END_MARK = $FF;

{ TCheatSequenceReader }

class function TCheatSequenceReader.FromBytes(const ABytes: array of Byte): AnsiString;
var
  LIndex: Integer;
begin
  Result := '';
  LIndex := 0;
  repeat
    if LIndex > High(ABytes) then
      raise EConsoleException.Create('The sequence of the cheat has no end mark');
    Result := Result + AnsiChar(ABytes[LIndex]);
    Inc(LIndex);
    if LIndex > High(ABytes) then
      raise EConsoleException.Create('The sequence of the cheat has no end mark');
  until ABytes[LIndex] = END_MARK;
end;

end.
