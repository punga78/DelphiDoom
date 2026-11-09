{******************************************************************************}
{                                                                              }
{  DelphiDoom: endoom library - text art: the contracts                         }
{  Copyright (C) 2021-2022 by Jim Valavanis (original ENDEDIT)                  }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Endoom.TextArt.Intf;

interface

uses
  DelphiDoom.Endoom.Intf,
  DelphiDoom.Endoom.TextArt.Types;

type
  /// <summary>
  ///   One way to turn the four pixels of a cell into a background, a foreground and a character.
  ///   The cell has what the screen had: a method changes only what it decides on (the first two
  ///   do not choose the foreground, or the background, of every cell)
  /// </summary>
  IEndoomTextArtMethod = interface
    ['{C2A5D183-7F04-4E69-B1A8-5D3E9F0C6B27}']
    function GetKind: TEndoomTextArtKind;
    procedure Convert(const ASamples: TEndoomTextArtSamples; var ACell: TEndoomTextArtCell);
    property Kind: TEndoomTextArtKind read GetKind;
  end;

  /// <summary>Turns a picture into the text screen, cell by cell, with a method</summary>
  IEndoomTextArtConverter = interface
    ['{0E7B94D6-A318-4C25-8F5A-D1C60B7293E8}']
    /// <summary>
    ///   APixels holds AHeight rows of AWidth pixels ($xxRRGGBB). The picture is shrunk (or
    ///   stretched) to 160x50, two pixels for each column and row of the screen, and every cell
    ///   of AScreen is given by the method from its four pixels
    /// </summary>
    procedure Convert(const AScreen: IEndoomScreen; const APixels: TArray<Cardinal>; AWidth, AHeight: Integer;
      const AMethod: IEndoomTextArtMethod);
  end;

implementation

end.
