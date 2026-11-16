{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: background and foreground             }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.BackgroundForeground;

interface

uses
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf;

type
  /// <summary>
  ///   ta_background_foreground: the color nearest to the average of the four pixels among the 16:
  ///   one of the first eight is a background with a blank character, one of the others is a
  ///   foreground with a full block ($DB). The color that is not chosen stays as it was
  /// </summary>
  TEndoomTextArtBackgroundForeground = class(TInterfacedObject, IEndoomTextArtMethod)
  public
    function GetKind: TEndoomTextArtKind;
    procedure Convert(const ASamples: TEndoomTextArtSamples; var ACell: TEndoomTextArtCell);
  end;

implementation

uses
  DelphiDoom.Endoom.Types, DelphiDoom.Endoom.ColorQuantizer;

const
  CODE_BLANK = Ord(' ');
  CODE_FULL_BLOCK = $DB;

{ TEndoomTextArtBackgroundForeground }

function TEndoomTextArtBackgroundForeground.GetKind: TEndoomTextArtKind;
begin
  Result := eakBackgroundForeground;
end;

procedure TEndoomTextArtBackgroundForeground.Convert(const ASamples: TEndoomTextArtSamples;
  var ACell: TEndoomTextArtCell);
var
  LColor: Integer;
begin
  LColor := TEndoomColorQuantizer.NearestForeground(ASamples.Average);
  if LColor < ENDOOM_BACKGROUND_COLOR_COUNT then
  begin
    ACell.Background := LColor;
    ACell.Code := CODE_BLANK;
  end
  else
  begin
    ACell.Foreground := LColor;
    ACell.Code := CODE_FULL_BLOCK;
  end;
end;

end.
