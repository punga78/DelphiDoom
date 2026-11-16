{******************************************************************************}
{                                                                              }
{  DelphiDoom: declaration manager - registration of the "articulatedFigure"   }
{  declaration                                                                 }
{                                                                              }
{  Written for DelphiDoom.                                                     }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Decl.ArticulatedFigure.Registration;

interface

uses
  DelphiDoom.Decl.Intf;

type
  /// <summary>Registers <c>articulatedFigure</c> (DECL_AF) with the real class</summary>
  TDeclArticulatedFigureRegistration = class sealed
  public
    class procedure Register(const ARegistry: IDeclRegistry); static;
  end;

implementation

uses
  DelphiDoom.Decl.Types, DelphiDoom.Decl.ArticulatedFigure;

{ TDeclArticulatedFigureRegistration }

class procedure TDeclArticulatedFigureRegistration.Register(const ARegistry: IDeclRegistry);
begin
  ARegistry.RegisterDeclType('articulatedFigure', DECL_AF,
    function: IDecl begin Result := TDeclArticulatedFigure.Create; end);
end;

end.
