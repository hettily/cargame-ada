with Cargame.Globals;  use Cargame.Globals;
with Cargame.Types;    use Cargame.Types;

with GL;               use GL;
with GL.Types;         use GL.Types;          use GL.Types.Singles;
with GL.Buffers;       use GL.Buffers;
with GL.Objects;
with GL.Objects.Textures;

with Glfw.Windows.Context;

package body Cargame.Engine.ECS is

   function Union (Sets : in Entity_Sets) return Entity_Set is
   begin
      return Ret : Entity_Set := (others => False) do
         for S of Sets loop
            for E in Entity loop
               if S (E) then
                  Ret (E) := True;
               end if;
            end loop;
         end loop;
      end return;
   end Union;

   ------------------
   --  New_Entity  --
   ------------------

   Next_Entity : Entity := Entity'First;

   function New_Entity return Entity is
      pragma Assert (Next_Entity /= Entity'Last,
                     "Exceeded allowable number of entities.");
      Ret : constant Entity := Next_Entity;
   begin
      Next_Entity := Entity'Succ (@);
      return Ret;
   end New_Entity;

   -----------------
   --  Component  --
   -----------------

   package body Component is

      procedure Set (E : in Entity; V : in Data_Type) is
      begin
         Has   (E) := True;
         Value (E) := V;
      end Set;

   end Component;

   ---------------
   --  Systems  --
   ---------------

   package body Systems is
      type Array_Of_System
         is array (Positive range 1 .. Config.Max_Systems)
         of System;

      Registered_Systems : Array_Of_System;
      Last_System_Index  : Positive := Registered_Systems'First;

      procedure Register_System (S : in System) is
      begin
         pragma Assert (Last_System_Index <= Config.Max_Systems);
         Registered_Systems (Last_System_Index) := S;
         Last_System_Index := @ + 1;
      end Register_System;

      procedure Run_All_Systems is
      begin
         for Sys of Registered_Systems (1 .. Last_System_Index) loop
            Sys.all; --  This is a procedure call.
         end loop;
      end Run_All_Systems;

   end Systems;

end Cargame.Engine.ECS;
