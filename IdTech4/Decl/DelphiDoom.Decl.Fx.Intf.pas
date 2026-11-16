{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - interface of the "fx" declaration         }
{                                                                              }
{  Not derived from Doom 3 code: written for this repository (GPL v2 or        }
{  later). The data it describes is that of framework\DeclFX.h of Doom 3.      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.Fx.Intf;

interface

uses
  DelphiDoom.Decl.Fx.Types;

type
  /// <summary>The data of an effect declaration (idDeclFX): the actions and the joint it binds to</summary>
  IDeclFx = interface
    ['{5E0C1A52-7B1E-4C0B-9D4B-4C6E3D0A0111}']
    function GetNumEvents: Integer;
    /// <summary>A copy of the action at the index; an <c>EDeclFxException</c> when out of range</summary>
    function GetEvent(const AIndex: Integer): TFxAction;
    /// <summary>The name of the joint the effect binds to (<c>bindto</c>), '' if none</summary>
    function GetJoint: AnsiString;
  end;

implementation

end.
