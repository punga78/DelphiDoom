{******************************************************************************}
{                                                                              }
{  DelphiDoom: actor definition library - the text of a parameter that is a    }
{  state name or a word of a script                                            }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
// Integer products wrap around as in the old code
{$Q-}
{$R-}
unit DelphiDoom.ActorDef.ParamString;

interface

uses
  DelphiDoom.ActorDef.ParamList.Intf;

type
  /// <summary>The old SC_EvalString: the text of a parameter, with RANDOMPICK and RANDOM computed</summary>
  TActorDefParamString = class sealed
  public
    /// <summary>
    ///   "RANDOMPICK(a, b, c)" is one of its words (quotes cut), "RANDOM(min, max)" a number,
    ///   anything else the text without the quotes at its ends. ARandom gives one number for
    ///   each RANDOMPICK or RANDOM, in the order they are read
    /// </summary>
    class function Evaluate(const AToken: string; const ARandom: IActorDefParamRandom): string; static;
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.ActorDef.ParamText,
  DelphiDoom.Scanner.Strings;

{ TActorDefParamString }

class function TActorDefParamString.Evaluate(const AToken: string;
  const ARandom: IActorDefParamRandom): string;
var
  LWords: TArray<string>;
  LFirst: Integer;
  LSecond: Integer;
  LWord: string;
begin
  if AToken = '' then
    Exit('');

  // a quick test, as in the old code: only words that start with R can be one of the two
  if (AToken[1] = 'R') or (AToken[1] = 'r') then
  begin
    LWords := TActorDefParamText.WordsToList(AToken, ['(', ')', ' ', ',', '[', ']']);
    if Length(LWords) > 1 then
    begin
      LWord := TScannerStrings.UpperAscii(LWords[0]);
      if LWord = 'RANDOMPICK' then
        Exit(TActorDefParamText.RemoveQuotes(LWords[1 + ARandom.Next mod (Length(LWords) - 1)]));
      if LWord = 'RANDOM' then
      begin
        if Length(LWords) > 2 then
        begin
          LFirst := TActorDefParamText.ToInteger(LWords[1], 0);
          LSecond := TActorDefParamText.ToInteger(LWords[2], 0);
        end
        else
        begin
          LFirst := 0;
          LSecond := TActorDefParamText.ToInteger(LWords[1], 0);
        end;
        Exit(IntToStr(LFirst + (ARandom.Next * (LSecond - LFirst + 1)) div 256));
      end;
    end;
  end;

  Result := TActorDefParamText.RemoveQuotes(AToken);
end;

end.
