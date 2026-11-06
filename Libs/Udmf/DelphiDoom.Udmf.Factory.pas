{******************************************************************************}
{                                                                              }
{  DelphiDoom: UDMF library - the factory: the composition root               }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Udmf.Factory;

interface

uses
  DelphiDoom.Udmf.Intf, DelphiDoom.Udmf.Games, DelphiDoom.Logging.Intf;

type
  /// <summary>The only place that knows the classes behind the UDMF contracts</summary>
  TUdmfFactory = class
  public
    /// <summary>The converter of the maps of a game</summary>
    /// <param name="ASounds">The number of a sound by its name (sectors); may be nil</param>
    /// <param name="ALog">May be nil</param>
    class function CreateConverter(AGame: TUdmfGame; const ASounds: IUdmfSoundResolver;
      const ALog: ILog): IUdmfConverter; overload; static;
    /// <summary>A converter on any profile (a different game, or one for the tests)</summary>
    class function CreateConverter(const AProfile: IUdmfProfile;
      const ALog: ILog): IUdmfConverter; overload; static;
  end;

implementation

uses
  DelphiDoom.Udmf.Converter;

{ TUdmfFactory }

class function TUdmfFactory.CreateConverter(AGame: TUdmfGame; const ASounds: IUdmfSoundResolver;
  const ALog: ILog): IUdmfConverter;
begin
  Result := TUdmfConverter.Create(TUdmfGames.CreateProfile(AGame, ASounds), ALog);
end;

class function TUdmfFactory.CreateConverter(const AProfile: IUdmfProfile;
  const ALog: ILog): IUdmfConverter;
begin
  Result := TUdmfConverter.Create(AProfile, ALog);
end;

end.