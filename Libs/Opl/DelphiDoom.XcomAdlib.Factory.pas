{******************************************************************************}
{                                                                              }
{  DelphiDoom: X-COM Adlib player - the factory: the composition root           }
{                                                                              }
{  Derived from OpenXcom (the OpenXcom Developers), GPL v3 or later: see        }
{  Libs\Opl\README.md for the license                                           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.XcomAdlib.Factory;

interface

uses
  System.SysUtils, DelphiDoom.Xcom.Intf, DelphiDoom.Opl.Intf, DelphiDoom.Opl.Factory, DelphiDoom.XcomAdlib.Intf,
  DelphiDoom.XcomAdlib.RegisterWriter, DelphiDoom.XcomAdlib.Sequencer, DelphiDoom.XcomAdlib.Player,
  DelphiDoom.XcomAdlib.CatSource;

type
  /// <summary>The only place that knows the classes of the X-COM Adlib player</summary>
  TXcomAdlibFactory = class
  public
    /// <summary>The clock OpenXcom gives its chips (the clock of the AdLib card)</summary>
    const ADLIB_CLOCK = 3579545;
    /// <summary>A player on two new chips (AdlibMusic creates them with the sampling rate of the audio)</summary>
    class function CreatePlayer(ARate: Integer): IXcomAdlibPlayer; overload; static;
    /// <summary>A player on the two chips given</summary>
    class function CreatePlayer(const ALeft, ARight: IOplChip; ARate: Integer): IXcomAdlibPlayer; overload; static;
    /// <summary>The songs of a CAT container</summary>
    class function CreateCatSource(const AArchive: IXcomCatArchive): IXcomAdlibMusicSource; static;
  end;

implementation

{ TXcomAdlibFactory }

class function TXcomAdlibFactory.CreatePlayer(ARate: Integer): IXcomAdlibPlayer;
begin
  Result := CreatePlayer(TOplFactory.CreateChip(ADLIB_CLOCK, ARate), TOplFactory.CreateChip(ADLIB_CLOCK, ARate),
    ARate);
end;

class function TXcomAdlibFactory.CreatePlayer(const ALeft, ARight: IOplChip; ARate: Integer): IXcomAdlibPlayer;
begin
  Result := TXcomAdlibPlayer.Create(ALeft, ARight,
    TXcomAdlibSequencer.Create(TXcomAdlibRegisterWriter.Create(ALeft, ARight)), ARate);
end;

class function TXcomAdlibFactory.CreateCatSource(const AArchive: IXcomCatArchive): IXcomAdlibMusicSource;
begin
  Result := TXcomCatAdlibSource.Create(AArchive);
end;

end.
