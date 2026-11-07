{******************************************************************************}
{                                                                              }
{  DelphiDoom: Screenshot library - base of the encoders                       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Screenshot.EncoderBase;

interface

uses
  System.SysUtils, DelphiDoom.Screenshot.Types, DelphiDoom.Screenshot.Intf;

type
  /// <summary>
  ///   Checks the image before an encoder sees it: one place for the rule that every
  ///   format shares
  /// </summary>
  TScreenshotEncoderBase = class abstract(TInterfacedObject, IScreenshotEncoder)
  protected
    function GetFormat: TScreenshotFormat; virtual; abstract;
    function DoEncode(APixels: Pointer; AWidth, AHeight: Integer;
      ABottomUp: Boolean): TBytes; virtual; abstract;
  public
    function Encode(APixels: Pointer; AWidth, AHeight: Integer;
      ABottomUp: Boolean): TBytes;
  end;

implementation

{ TScreenshotEncoderBase }

function TScreenshotEncoderBase.Encode(APixels: Pointer; AWidth, AHeight: Integer;
  ABottomUp: Boolean): TBytes;
begin
  if (not Assigned(APixels)) or (AWidth < 1) or (AHeight < 1) or
    (Int64(AWidth) * AHeight > High(Integer) div 4 - 64) then
    raise EScreenshotException.Create(SScreenshotInvalidImage);
  Result := DoEncode(APixels, AWidth, AHeight, ABottomUp);
end;

end.
