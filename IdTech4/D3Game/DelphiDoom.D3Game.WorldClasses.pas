{******************************************************************************}
{                                                                              }
{  DelphiDoom: Doom 3 game library - the CLASS_DECLARATION lines of the        }
{  entity classes                                                              }
{                                                                              }
{  Declares in a class system the entity classes of this library with their    }
{  superclass and <c>EVENT</c> lines: idEntity, idWorldspawn, idTrigger and    }
{  its subclasses, idMover_Binary, idDoor and idMover. The classes that are    }
{  not here (items, lights, the player...) are declared by the caller.         }
{  Written for this repository; licensed under the GNU General Public License, }
{  version 2 or later.                                                         }
{                                                                              }
{******************************************************************************}
unit DelphiDoom.D3Game.WorldClasses;

interface

uses
  DelphiDoom.D3Game.EntityEvents, DelphiDoom.D3Game.ClassSystem, DelphiDoom.D3Game.Local;

type
  /// <summary>The declaration of the entity classes of the library</summary>
  TD3WorldClasses = class
  public
    /// <summary>
    ///   Declares the classes (call it before <c>TD3ClassSystem.Init</c>). The game owns the objects the classes
    ///   make; the events are the ones of the registry that <c>AEvents</c> was made on.
    /// </summary>
    class procedure Declare(const AClasses: TD3ClassSystem; const AEvents: TD3EntityEvents;
      const AGame: TD3GameLocal); static;
  end;

implementation

uses
  DelphiDoom.D3Game.ClassBase, DelphiDoom.D3Game.Entity, DelphiDoom.D3Game.Player, DelphiDoom.D3Game.Worldspawn, DelphiDoom.D3Game.Trigger,
  DelphiDoom.D3Game.Trigger.Multi, DelphiDoom.D3Game.Trigger.EntityName, DelphiDoom.D3Game.Trigger.Timer, DelphiDoom.D3Game.Trigger.Count,
  DelphiDoom.D3Game.Trigger.Hurt, DelphiDoom.D3Game.Trigger.Fade, DelphiDoom.D3Game.MoverBinary,
  DelphiDoom.D3Game.Door, DelphiDoom.D3Game.Mover;

class procedure TD3WorldClasses.Declare(const AClasses: TD3ClassSystem; const AEvents: TD3EntityEvents;
  const AGame: TD3GameLocal);
begin
  // ABSTRACT_DECLARATION( idClass, idEntity )
  TD3Entity.DeclareEvents(AClasses.Declare('idEntity', 'idClass', nil, TD3Entity.SpawnClass, True), AEvents);

  AClasses.Declare('idPlayer', 'idEntity',
    function: TD3Class
    begin
      Result := TD3Player.Create(AGame, AGame);
    end, TD3Player.SpawnClass);

  AClasses.Declare('idWorldspawn', 'idEntity',
    function: TD3Class
    begin
      Result := TD3Worldspawn.Create(AGame, AGame);
    end, TD3Worldspawn.SpawnClass);

  TD3Trigger.DeclareEvents(AClasses.Declare('idTrigger', 'idEntity',
    function: TD3Class
    begin
      Result := TD3Trigger.Create(AGame, AGame);
    end, TD3Trigger.SpawnClass), AEvents);
  TD3TriggerMulti.DeclareEvents(AClasses.Declare('idTrigger_Multi', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerMulti.Create(AGame, AGame);
    end, TD3TriggerMulti.SpawnClass), AEvents);
  TD3TriggerEntityName.DeclareEvents(AClasses.Declare('idTrigger_EntityName', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerEntityName.Create(AGame, AGame);
    end, TD3TriggerEntityName.SpawnClass), AEvents);
  TD3TriggerTimer.DeclareEvents(AClasses.Declare('idTrigger_Timer', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerTimer.Create(AGame, AGame);
    end, TD3TriggerTimer.SpawnClass), AEvents);
  TD3TriggerCount.DeclareEvents(AClasses.Declare('idTrigger_Count', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerCount.Create(AGame, AGame);
    end, TD3TriggerCount.SpawnClass), AEvents);
  TD3TriggerHurt.DeclareEvents(AClasses.Declare('idTrigger_Hurt', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerHurt.Create(AGame, AGame);
    end, TD3TriggerHurt.SpawnClass), AEvents);
  TD3TriggerFade.DeclareEvents(AClasses.Declare('idTrigger_Fade', 'idTrigger',
    function: TD3Class
    begin
      Result := TD3TriggerFade.Create(AGame, AGame);
    end, TD3TriggerFade.SpawnClass), AEvents);

  TD3MoverBinary.DeclareEvents(AClasses.Declare('idMover_Binary', 'idEntity',
    function: TD3Class
    begin
      Result := TD3MoverBinary.Create(AGame, AGame);
    end, TD3MoverBinary.SpawnClass), AEvents);
  TD3Door.DeclareEvents(AClasses.Declare('idDoor', 'idMover_Binary',
    function: TD3Class
    begin
      Result := TD3Door.Create(AGame, AGame);
    end, TD3Door.SpawnClass), AEvents);
  TD3Mover.DeclareEvents(AClasses.Declare('idMover', 'idEntity',
    function: TD3Class
    begin
      Result := TD3Mover.Create(AGame, AGame);
    end, TD3Mover.SpawnClass), AEvents);
end;

end.
