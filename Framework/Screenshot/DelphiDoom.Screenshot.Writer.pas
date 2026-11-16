{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - writes a screenshot                        }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.Writer;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf;

type
  /// <summary>
  ///   Picks the encoder of the format (a strategy for each one), writes the file and, when
  ///   asked, the JPEG copy
  /// </summary>
  /// <remarks>
  ///   Differences from the old code: a JPEG file is encoded from the pixels of the screen (no
  ///   temporary TGA file that is written and deleted), the screen is read once, and the result
  ///   is the one of the format that was asked for (for a PNG with the JPEG copy on, the old
  ///   result was the one of the temporary TGA file)
  /// </remarks>
  TScreenshotWriter = class(TInterfacedObject, IScreenshotWriter)
  strict private
    FEncoders: array[TScreenshotFormat] of IScreenshotEncoder;
    FSink: IScreenshotFileSink;
    function WriteFormat(const ATarget: TScreenshotTarget; AFormat: TScreenshotFormat;
      APixels: Pointer; AWidth, AHeight: Integer; ABottomUp: Boolean): Boolean;
  public
    /// <param name="AEncoders">One encoder for every format</param>
    constructor Create(const AEncoders: TArray<IScreenshotEncoder>;
      const ASink: IScreenshotFileSink);
    function Save(const ATarget: TScreenshotTarget; APixels: Pointer;
      AWidth, AHeight: Integer; ABottomUp, AJpegCopy: Boolean): Boolean;
  end;

implementation

uses
  DelphiDoom.Screenshot.Formats;

{ TScreenshotWriter }

constructor TScreenshotWriter.Create(const AEncoders: TArray<IScreenshotEncoder>;
  const ASink: IScreenshotFileSink);
var
  LEncoder: IScreenshotEncoder;
  LFormat: TScreenshotFormat;
begin
  inherited Create;
  if not Assigned(ASink) then
    raise EArgumentNilException.Create('ASink');
  FSink := ASink;
  for LEncoder in AEncoders do
  begin
    if not Assigned(LEncoder) then
      raise EArgumentNilException.Create('AEncoders');
    FEncoders[LEncoder.Format] := LEncoder;
  end;
  for LFormat := Low(TScreenshotFormat) to High(TScreenshotFormat) do
    if not Assigned(FEncoders[LFormat]) then
      raise EScreenshotException.CreateFmt(SScreenshotNoEncoder,
        [TScreenshotFormats.NameOf(LFormat)]);
end;

function TScreenshotWriter.WriteFormat(const ATarget: TScreenshotTarget;
  AFormat: TScreenshotFormat; APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): Boolean;
begin
  try
    Result := FSink.Write(ATarget.PathOf(AFormat),
      FEncoders[AFormat].Encode(APixels, AWidth, AHeight, ABottomUp));
  except
    on EScreenshotException do
      Result := False;
  end;
end;

function TScreenshotWriter.Save(const ATarget: TScreenshotTarget; APixels: Pointer;
  AWidth, AHeight: Integer; ABottomUp, AJpegCopy: Boolean): Boolean;
begin
  Result := WriteFormat(ATarget, ATarget.Format, APixels, AWidth, AHeight, ABottomUp);
  if Result and AJpegCopy and (ATarget.Format <> TScreenshotFormat.Jpg) then
    WriteFormat(ATarget, TScreenshotFormat.Jpg, APixels, AWidth, AHeight, ABottomUp);
end;

end.
