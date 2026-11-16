{******************************************************************************}
{                                                                              }
{  DelphiDoom: IWAD library - lists of folders written as text                  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Iwad.PathList;

interface

type
  /// <summary>Folders separated by ';' (the value of DOOMWADPATH and the additional paths)</summary>
  TIwadPathList = class
  public
    const
      SEPARATOR = ';';
    /// <summary>The folders of a text; empty parts are skipped, nothing else is trimmed</summary>
    class function Split(const AText: string): TArray<string>; static;
  end;

implementation

{ TIwadPathList }

class function TIwadPathList.Split(const AText: string): TArray<string>;
var
  LIndex: Integer;
  LCurrent: string;
  LCount: Integer;

  procedure Flush;
  begin
    if LCurrent <> '' then
    begin
      SetLength(Result, LCount + 1);
      Result[LCount] := LCurrent;
      Inc(LCount);
      LCurrent := '';
    end;
  end;

begin
  SetLength(Result, 0);
  LCount := 0;
  LCurrent := '';
  for LIndex := 1 to Length(AText) do
  begin
    if AText[LIndex] = SEPARATOR then
      Flush
    else
      LCurrent := LCurrent + AText[LIndex];
  end;
  Flush;
end;

end.
