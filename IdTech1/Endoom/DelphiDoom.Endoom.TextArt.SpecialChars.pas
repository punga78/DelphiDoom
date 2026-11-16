{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: special characters                    }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.SpecialChars;

interface

uses
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf;

type
  /// <summary>
  ///   ta_specialchars and ta_extendedspecialchars: every cell tries each combination of a
  ///   background (8), a different foreground (16) and a character that covers some of its four
  ///   quarters with the foreground (F), the background (B) or the middle of the two (f), and keeps
  ///   the one whose quarters are nearest to the four pixels (sum of squared distances); the
  ///   blank character wins a tie. The first six characters are the blocks, the next nine are
  ///   frame corners, tees and the cross, whose thin lines are taken as quarters of the middle color
  /// </summary>
  TEndoomTextArtSpecialChars = class(TInterfacedObject, IEndoomTextArtMethod)
  strict private
    FExtended: Boolean;
  public
    /// <param name="AExtended">True for the fifteen characters, false for the first six</param>
    constructor Create(AExtended: Boolean);
    function GetKind: TEndoomTextArtKind;
    procedure Convert(const ASamples: TEndoomTextArtSamples; var ACell: TEndoomTextArtCell);
  end;

implementation

uses
  System.SysUtils,
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.ColorQuantizer;

const
  SPECIAL_COUNT = 6;
  EXTENDED_SPECIAL_COUNT = SPECIAL_COUNT + 9;
  SPECIAL_CODES: array[0..EXTENDED_SPECIAL_COUNT - 1] of Byte = (
    $DB, $DC, $DD, $DC, $DF, Ord(' '),
    $DA, $BF, $C0, $D9, $C1, $C2, $C3, $B4, $C5
  );
  /// <summary>The quarters (top left, top right, bottom left, bottom right) of each character</summary>
  SPECIAL_QUARTERS: array[0..EXTENDED_SPECIAL_COUNT - 1] of string = (
    'FFFF', 'BBFF', 'FBFB', 'BFBF', 'FFBB', 'BBBB',
    'BBBf', 'BBfB', 'BfBB', 'fBBB', 'ffBB', 'BBff', 'BfBf', 'fBfB', 'ffff'
  );

{ TEndoomTextArtSpecialChars }

constructor TEndoomTextArtSpecialChars.Create(AExtended: Boolean);
begin
  inherited Create;
  FExtended := AExtended;
end;

function TEndoomTextArtSpecialChars.GetKind: TEndoomTextArtKind;
begin
  if FExtended then
    Result := eakExtendedSpecialCharacters
  else
    Result := eakSpecialCharacters;
end;

procedure TEndoomTextArtSpecialChars.Convert(const ASamples: TEndoomTextArtSamples;
  var ACell: TEndoomTextArtCell);
var
  LCount: Integer;
  LBackground: Integer;
  LForeground: Integer;
  LCharacter: Integer;
  LQuarter: Integer;
  LBackgroundColor: Cardinal;
  LForegroundColor: Cardinal;
  LMiddleColor: Cardinal;
  LTarget: Cardinal;
  LBestBackground: Integer;
  LBestForeground: Integer;
  LBestCode: Byte;
  LBestDistance: Integer;
  LDistance: Integer;

  function Middle(AShift: Integer): Cardinal;
  begin
    Result := Cardinal((Integer((LBackgroundColor shr AShift) and $FF) +
      Integer((LForegroundColor shr AShift) and $FF)) div 2);
  end;

begin
  if FExtended then
    LCount := EXTENDED_SPECIAL_COUNT
  else
    LCount := SPECIAL_COUNT;
  LBestBackground := 0;
  LBestForeground := 0;
  LBestCode := SPECIAL_CODES[0];
  LBestDistance := MaxInt;
  for LBackground := 0 to ENDOOM_BACKGROUND_COLOR_COUNT - 1 do
  begin
    LBackgroundColor := ENDOOM_COLORS[LBackground];
    for LForeground := 0 to ENDOOM_COLOR_COUNT - 1 do
    begin
      if LBackground = LForeground then
        Continue;
      LForegroundColor := ENDOOM_COLORS[LForeground];
      LMiddleColor := (Middle(16) shl 16) or (Middle(8) shl 8) or Middle(0);
      for LCharacter := 0 to LCount - 1 do
      begin
        LDistance := 0;
        for LQuarter := 0 to 3 do
        begin
          LTarget := ASamples.Item(LQuarter);
          case SPECIAL_QUARTERS[LCharacter][LQuarter + 1] of
            'F':
              Inc(LDistance, TEndoomColorQuantizer.Distance(LTarget, LForegroundColor));
            'f':
              Inc(LDistance, TEndoomColorQuantizer.Distance(LTarget, LMiddleColor));
          else
            Inc(LDistance, TEndoomColorQuantizer.Distance(LTarget, LBackgroundColor));
          end;
        end;
        if (LDistance < LBestDistance) or ((LDistance = LBestDistance) and (SPECIAL_CODES[LCharacter] = Ord(' '))) then
        begin
          LBestDistance := LDistance;
          LBestBackground := LBackground;
          LBestForeground := LForeground;
          LBestCode := SPECIAL_CODES[LCharacter];
        end;
      end;
    end;
  end;
  ACell.Background := LBestBackground;
  ACell.Foreground := LBestForeground;
  ACell.Code := LBestCode;
end;

end.
