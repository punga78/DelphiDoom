{******************************************************************************}
{                                                                              }
{  DelphiDoom: ActorDef library - the definitions go to the engine as a patch  }
{  Copyright (C) 2004-2022 by Jim Valavanis (original DelphiDoom)              }
{                                                                              }
{  Licensed under the GNU General Public License, version 2 or later           }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.ActorDef.DehSink;

interface

uses
  DelphiDoom.ActorDef.Types, DelphiDoom.ActorDef.Intf, DelphiDoom.ActorDef.DehWriter;

type
  /// <summary>
  ///   Takes each actor and each weapon as the parser ends it, writes it as a patch and gives the
  ///   text to the consumer (the DEH subsystem of the engine), so that the next definition
  ///   finds what this one made
  /// </summary>
  TActorDefDehSink = class(TInterfacedObject, IActorDefDefinitionSink)
  private
    FWriter: TActorDefDehWriter;
    FConsumer: IActorDefDehConsumer;
  public
    /// <param name="AWriter">The sink owns it</param>
    constructor Create(AWriter: TActorDefDehWriter; const AConsumer: IActorDefDehConsumer);
    destructor Destroy; override;
    procedure SubmitActor(const AActor: TActorDefActor);
    procedure SubmitWeapon(const AWeapon: TActorDefWeapon);
  end;

implementation

{ TActorDefDehSink }

constructor TActorDefDehSink.Create(AWriter: TActorDefDehWriter; const AConsumer: IActorDefDehConsumer);
begin
  inherited Create;
  FWriter := AWriter;
  FConsumer := AConsumer;
end;

destructor TActorDefDehSink.Destroy;
begin
  FWriter.Free;
  inherited Destroy;
end;

procedure TActorDefDehSink.SubmitActor(const AActor: TActorDefActor);
begin
  FConsumer.ParseText(FWriter.ActorText(AActor));
end;

procedure TActorDefDehSink.SubmitWeapon(const AWeapon: TActorDefWeapon);
begin
  FConsumer.ParseText(FWriter.WeaponText(AWeapon));
end;

end.
