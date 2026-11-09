{******************************************************************************}
{                                                                              }
{  DelphiDoom: xcom surface library - the factory: the composition root         }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\XcomFormats\README.md for the license of this unit                      }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomSurface.Factory;

interface

uses
  System.SysUtils, DelphiDoom.XcomSurface.Surface, DelphiDoom.XcomSurface.Font;

type
  /// <summary>The only place that knows the classes of the xcom surface library</summary>
  TXcomSurfaceFactory = class
  public
    /// <summary>A blank surface; the caller frees it</summary>
    class function CreateSurface(AWidth, AHeight: Integer; AX: Integer = 0; AY: Integer = 0): TXcomSurface; static;
    /// <summary>An empty font; the caller frees it (and with it the surfaces it owns)</summary>
    class function CreateFont: TXcomFont; static;
  end;

implementation

{ TXcomSurfaceFactory }

class function TXcomSurfaceFactory.CreateSurface(AWidth, AHeight, AX, AY: Integer): TXcomSurface;
begin
  Result := TXcomSurface.Create(AWidth, AHeight, AX, AY);
end;

class function TXcomSurfaceFactory.CreateFont: TXcomFont;
begin
  Result := TXcomFont.Create;
end;

end.
