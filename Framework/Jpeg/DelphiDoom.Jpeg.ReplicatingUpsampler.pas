{******************************************************************************}
{                                                                              }
{  DelphiDoom: JPEG - upsampling by repeating the samples                      }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{  Derived from libjpeg 6b by the Independent JPEG Group                       }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Jpeg.ReplicatingUpsampler;

interface

uses
  DelphiDoom.Jpeg.RowUpsampler;

type
  /// <summary>
  ///   Each sample is written AFactor times (h2v1_upsample and int_upsample of
  ///   libjpeg). The factor is a whole number
  /// </summary>
  TJpegReplicatingUpsampler = class(TInterfacedObject, IJpegRowUpsampler)
  private
    FFactor: Integer;
    FOutputWidth: Integer;
  public
    /// <param name="AFactor">How many times a sample is repeated</param>
    /// <param name="AOutputWidth">The width of the image</param>
    constructor Create(AFactor, AOutputWidth: Integer);

    procedure UpsampleRow(ARow, ANeighbour, AOutput: PByte);
  end;

implementation

{ TJpegReplicatingUpsampler }

constructor TJpegReplicatingUpsampler.Create(AFactor, AOutputWidth: Integer);
begin
  inherited Create;
  FFactor := AFactor;
  FOutputWidth := AOutputWidth;
end;

procedure TJpegReplicatingUpsampler.UpsampleRow(ARow, ANeighbour, AOutput: PByte);
var
  LCount: Integer;
  LRepeat: Integer;
  LValue: Byte;
begin
  // Whole groups of samples are written, so the last group can go past the
  // width of the image
  LCount := FOutputWidth;
  while LCount > 0 do
  begin
    LValue := ARow^;
    Inc(ARow);
    for LRepeat := 1 to FFactor do
    begin
      AOutput^ := LValue;
      Inc(AOutput);
    end;
    Dec(LCount, FFactor);
  end;
end;

end.
