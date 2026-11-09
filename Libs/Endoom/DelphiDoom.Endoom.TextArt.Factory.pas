{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: the factory                           }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.Factory;

interface

uses
  DelphiDoom.Endoom.TextArt.Types,
  DelphiDoom.Endoom.TextArt.Intf,
  DelphiDoom.Imaging.Intf;

type
  /// <summary>The only place that knows the classes of the text art</summary>
  TEndoomTextArtFactory = class
  public
    class function CreateMethod(AKind: TEndoomTextArtKind): IEndoomTextArtMethod; static;
    /// <param name="AResampler">What shrinks the picture to 160x50 (the Lanczos of the imaging library)</param>
    class function CreateConverter(const AResampler: IImagingResampler): IEndoomTextArtConverter; static;
  end;

implementation

uses
  DelphiDoom.Endoom.TextArt.BackgroundOnly, DelphiDoom.Endoom.TextArt.BackgroundForeground,
  DelphiDoom.Endoom.TextArt.Dither, DelphiDoom.Endoom.TextArt.SpecialChars,
  DelphiDoom.Endoom.TextArt.Converter;

{ TEndoomTextArtFactory }

class function TEndoomTextArtFactory.CreateMethod(AKind: TEndoomTextArtKind): IEndoomTextArtMethod;
begin
  case AKind of
    eakBackgroundOnly:
      Result := TEndoomTextArtBackgroundOnly.Create;
    eakBackgroundForeground:
      Result := TEndoomTextArtBackgroundForeground.Create;
    eakDither:
      Result := TEndoomTextArtDither.Create;
    eakSpecialCharacters:
      Result := TEndoomTextArtSpecialChars.Create(False);
  else
    Result := TEndoomTextArtSpecialChars.Create(True);
  end;
end;

class function TEndoomTextArtFactory.CreateConverter(const AResampler: IImagingResampler): IEndoomTextArtConverter;
begin
  Result := TEndoomTextArtConverter.Create(AResampler);
end;

end.
