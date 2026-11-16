{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - a goto that names a label                    }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.LabelMatcher;

interface

type
  /// <summary>Tells if the text of a goto is a label, with an offset or without</summary>
  TActorDefLabelMatcher = class
  public
    /// <summary>
    ///   True if AGoto (spaces do not count) is ALabel alone or ALabel followed by + or -: AOffset
    ///   is what follows (SPAWN+2 gives 2, SPAWN-1 gives -1, SPAWN gives 0)
    /// </summary>
    class function Match(const AGoto, ALabel: string; out AOffset: Integer): Boolean; static;
  end;

implementation

uses
  System.SysUtils, DelphiDoom.Scanner.Strings;

{ TActorDefLabelMatcher }

class function TActorDefLabelMatcher.Match(const AGoto, ALabel: string; out AOffset: Integer): Boolean;
var
  LText: string;
begin
  AOffset := 0;
  LText := AGoto.Replace(' ', '');
  if not LText.StartsWith(ALabel) then
    Exit(False);
  if Length(LText) = Length(ALabel) then
    Exit(True);
  if not CharInSet(LText[Length(ALabel) + 1], [' ', '+', '-']) then
    Exit(False);
  AOffset := TScannerStrings.ToInteger(Copy(LText, Length(ALabel) + 1, MaxInt));
  Result := True;
end;

end.
