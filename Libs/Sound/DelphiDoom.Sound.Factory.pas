{******************************************************************************}
{                                                                              }
{  DelphiDoom: sound decoder - composition root                                }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.Sound.Factory;

interface

uses
  DelphiDoom.Sndfile.Intf, DelphiDoom.Sound.Format;

type
  /// <summary>
  ///   The only place that knows which formats exist: builds the engine with
  ///   all of them. Everything else receives the formats it needs
  /// </summary>
  TSoundFactory = class
  public
    /// <summary>The formats the engine reads, in the order they are tried</summary>
    class function CreateFormats: TArray<ISoundFormat>; static;
    class function CreateEngine: ISndfile; overload; static;
    class function CreateEngine(const AFormats: TArray<ISoundFormat>): ISndfile; overload; static;
  end;

implementation

uses
  DelphiDoom.Sound.Engine, DelphiDoom.Sound.Format.Wav,
  DelphiDoom.Sound.Format.Aiff, DelphiDoom.Sound.Format.Au,
  DelphiDoom.Sound.Format.Voc, DelphiDoom.Sound.Format.Avr,
  DelphiDoom.Sound.Format.Htk, DelphiDoom.Sound.Format.W64,
  DelphiDoom.Sound.Format.Rf64, DelphiDoom.Sound.Format.Caf, DelphiDoom.Sound.Format.Flac,
  DelphiDoom.Sound.Format.Svx, DelphiDoom.Sound.Format.Ircam, DelphiDoom.Sound.Format.Mat4,
  DelphiDoom.Sound.Format.Mat5, DelphiDoom.Sound.Format.Wve,
  DelphiDoom.Sound.Format.Mpc2k, DelphiDoom.Sound.Format.Ogg, DelphiDoom.Sound.Format.Paf;

{ TSoundFactory }

class function TSoundFactory.CreateFormats: TArray<ISoundFormat>;
begin
  Result := [TWavFormat.Create, TAiffFormat.Create, TAuFormat.Create,
    TVocFormat.Create, TAvrFormat.Create, THtkFormat.Create,
    TW64Format.Create, TRf64Format.Create,
    TCafFormat.Create, TFlacFormat.Create,
    TSvxFormat.Create, TIrcamFormat.Create,
    TMat4Format.Create, TMat5Format.Create,
    TWveFormat.Create, TMpc2kFormat.Create, TOggFormat.Create, TPafFormat.Create];
end;

class function TSoundFactory.CreateEngine: ISndfile;
begin
  Result := CreateEngine(CreateFormats);
end;

class function TSoundFactory.CreateEngine(
  const AFormats: TArray<ISoundFormat>): ISndfile;
begin
  Result := TSoundEngine.Create(AFormats);
end;

end.
