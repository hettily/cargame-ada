with GL;
with GL.Types;

with Glfw;
with Glfw.Input;
with Glfw.Input.Keys;

with Cargame.Types;
with Cargame.Engine.Models;
with Cargame.Engine.ECS;

package Cargame.Gameplay is

   use Cargame.Engine.Models;
   use Cargame.Types;
   use GL, GL.Types, GL.Types.Singles;

   package ECS renames Cargame.Engine.ECS;

   --------------------
   --  Game Entities --
   --------------------

   Player : ECS.Entity;

   Num_Asteroids : constant := ECS.Max_Entities - 1;
   Asteroids     : ECS.Entity_Array (1 .. Num_Asteroids);

   ------------------
   --  Components  --
   ------------------

   package Components is
      subtype Cargame_Model is Cargame.Engine.Models.Model;
      package Controlled_By_Player is new ECS.Component (Boolean);
      package Position             is new ECS.Component (Types.Valid_Vector3);
      package Velocity             is new ECS.Component (Types.Valid_Vector3);
      package Acceleration         is new ECS.Component (Types.Valid_Vector3);
      package Model                is new ECS.Component (Cargame_Model);
      package Rotation             is new ECS.Component (Types.Radians);
      package Rotational_Speed     is new ECS.Component (Types.Radians);
      package Render_Scale         is new ECS.Component (Single);
      package Object_Matrix        is new ECS.Component (Matrix4);
      package CamObj_Matrix        is new ECS.Component (Matrix4);
      package Normal_Matrix        is new ECS.Component (Matrix3);
   end Components;

   ----------------
   --  Controls  --
   ----------------

   package Controls is

      use Glfw.Input.Keys;

      type Any_Control_Action is
         (No_Action,
          --  Menu actions
          Quit,
          --  Movement actions:
          Accelerate, Decelerate,
          Strafe_Left, Strafe_Right, Strafe_Up, Strafe_Down,
          --  Rotate actions:
          Yaw_Left, Yaw_Right, Roll_Left, Roll_Right, Pitch_Up, Pitch_Down);

      subtype Control_Action is Any_Control_Action range
         Any_Control_Action'Succ (No_Action) .. Any_Control_Action'Last;

      subtype Player_Action is Control_Action range Accelerate .. Pitch_Down;

      Unbound : Key renames Unknown;

      Control_Mapping : constant array (Control_Action) of Key :=
         (Accelerate   => W, --  Up,
          Decelerate   => S, --  Down,
          Strafe_Left  => A, --  Left,
          Strafe_Right => D, --  Right,
          Strafe_Up    => Space,
          Strafe_Down  => Left_Control,
          Yaw_Left     => Q,
          Yaw_Right    => E,
          Roll_Left    => Unbound,
          Roll_Right   => Unbound,
          Pitch_Up     => Unbound,
          Pitch_Down   => Unbound,
          Quit         => Escape);

      Player_Is_Requesting_Action : array (Control_Action) of Boolean :=
         (others => False);

      function Key_To_Action (K : in Key) return Any_Control_Action;

   end Controls;

end Cargame.Gameplay;
