{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the namespaces of a text map                     }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Namespaces;

interface

type
  /// <summary>
  ///   What the namespace of a text map says to the engine: the specials of the lines of a map
  ///   written for another game (for example zdoom) are translated to the ones of the game,
  ///   unless the namespace is the one of the game or ZDOOMTRANSLATED
  /// </summary>
  TUdmfNamespaces = class sealed
  public
    /// <summary>
    ///   True when the specials of the lines have to be translated; ANamespace is the one of the
    ///   map (in capital letters, as the converter and the lump NSPACE give it), AGameName the
    ///   name of the game in any case
    /// </summary>
    class function TranslatesLines(const ANamespace, AGameName: string): Boolean; static;
  end;

implementation

uses
  System.SysUtils;

const
  // a map whose specials are already the ones of the game
  TRANSLATED_NAMESPACE = 'ZDOOMTRANSLATED';

{ TUdmfNamespaces }

class function TUdmfNamespaces.TranslatesLines(const ANamespace, AGameName: string): Boolean;
begin
  Result := (ANamespace <> UpperCase(AGameName)) and (ANamespace <> TRANSLATED_NAMESPACE);
end;

end.
