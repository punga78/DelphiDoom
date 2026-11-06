{******************************************************************************}
{                                                                              }
{  DelphiDoom: configuration library - the factory: the composition root       }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Configuration.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Configuration.Intf;

type
  /// <summary>The only place that knows the class behind IConfigurationFormat</summary>
  TConfigurationFactory = class
  public
    class function CreateFormat: IConfigurationFormat; static;
  end;

implementation

uses
  DelphiDoom.Configuration.Format;

{ TConfigurationFactory }

class function TConfigurationFactory.CreateFormat: IConfigurationFormat;
begin
  Result := TConfigurationFormat.Create;
end;

end.
