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
  DelphiDoom.Sound.Engine, DelphiDoom.Sound.Format.Wav;

{ TSoundFactory }

class function TSoundFactory.CreateFormats: TArray<ISoundFormat>;
begin
  Result := [TWavFormat.Create];
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
