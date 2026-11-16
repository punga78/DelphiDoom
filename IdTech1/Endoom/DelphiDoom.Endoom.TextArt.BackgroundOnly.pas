{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: background only                       }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.BackgroundOnly;

interface

uses
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf;

type
  /// <summary>ta_background_only: the background nearest to the average of the four pixels; the character stays</summary>
  TEndoomTextArtBackgroundOnly = class(TInterfacedObject, IEndoomTextArtMethod)
  public
    function GetKind: TEndoomTextArtKind;
    procedure Convert(const ASamples: TEndoomTextArtSamples; var ACell: TEndoomTextArtCell);
  end;

implementation

uses
  DelphiDoom.Endoom.ColorQuantizer;

{ TEndoomTextArtBackgroundOnly }

function TEndoomTextArtBackgroundOnly.GetKind: TEndoomTextArtKind;
begin
  Result := eakBackgroundOnly;
end;

procedure TEndoomTextArtBackgroundOnly.Convert(const ASamples: TEndoomTextArtSamples;
  var ACell: TEndoomTextArtCell);
begin
  ACell.Background := TEndoomColorQuantizer.NearestBackground(ASamples.Average);
end;

end.
