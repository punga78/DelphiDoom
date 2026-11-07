{******************************************************************************}
{                                                                              }
{  DelphiDoom: tests of the Screenshot library - the synthetic data            }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Tests.Screenshot.Samples;

{ The images of the tests of parity. The harness that made Tests\Data\Screenshot compiled the
  old code of the engine on these same images (the sizes and the seeds are in the harness
  too), and the tests give them to the library }

interface

uses
  System.SysUtils;

type
  TScreenshotSampleCase = record
    Name: string;
    Width: Integer;
    Height: Integer;
    Seed: Cardinal;
  end;

  TScreenshotSamples = class sealed
  public
    class function Cases: TArray<TScreenshotSampleCase>; static;
    /// <summary>Pixels of 4 bytes (B, G, R and an alpha that is not 255 in most of them)</summary>
    class function Pixels(const ACase: TScreenshotSampleCase): TBytes; static;
  end;

implementation

uses
  DelphiDoom.Tests.Imaging.Samples;

{ TScreenshotSamples }

class function TScreenshotSamples.Cases: TArray<TScreenshotSampleCase>;
  procedure Add(const AName: string; AWidth, AHeight: Integer; ASeed: Cardinal);
  begin
    SetLength(Result, Length(Result) + 1);
    Result[High(Result)].Name := AName;
    Result[High(Result)].Width := AWidth;
    Result[High(Result)].Height := AHeight;
    Result[High(Result)].Seed := ASeed;
  end;
begin
  Result := nil;
  Add('p1x1', 1, 1, 11);
  Add('p7x5', 7, 5, 12);
  Add('p97x53', 97, 53, 13);
  Add('p320x200', 320, 200, 14);
  Add('p64x48', 64, 48, 15);
end;

class function TScreenshotSamples.Pixels(const ACase: TScreenshotSampleCase): TBytes;
begin
  Result := TImagingSamples.RandomBytes(ACase.Seed, ACase.Width * ACase.Height * 4);
end;

end.
