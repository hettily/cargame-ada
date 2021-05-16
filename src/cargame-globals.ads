with Ada.Real_Time;        use Ada.Real_Time;
with GL;                   use GL;
with GL.Objects.Programs;
with GL.Objects.Textures;
with GL.Types.Colors;      use GL.Types.Colors;
with GL.Types;             use GL.Types; use GL.Types.Singles;
with Glfw.Input;           use Glfw.Input;
with Glfw.Input.Keys;
with Glfw.Input.Mouse;
with Glfw.Windows;         use Glfw.Windows;

--  Globals pertaining to the program, not necessarily the game logic. This
--  package should have no dependencies on other Cargame packages.

package Cargame.Globals is

   ---------------------------
   --  Fundamental Timings  --
   ---------------------------

   subtype Frame is Positive;
   subtype Frames is Frame;

   Target_FPS      : constant Frames    := Frames (120);
   Frame_Interval  : constant Time_Span := (Seconds (1) / Target_FPS);

   Frame_Number    : Frame := Frames'First;

   -----------------------
   --  Rendering state  --
   -----------------------

   function Ready_To_Render return Boolean;

   Shader            : GL.Objects.Programs.Program;

   Background_Colour : constant Color := (0.1, 0.4, 0.4, 1.0);
   Vertical_FoV      : constant       := 60.0;
   Near_Plane        : constant       := 1.0;
   Far_Plane         : constant       := 200.0;

   --------------------
   --  Window state  --
   --------------------

   package Window is

      type Main_Window_Type is new Glfw.Windows.Window with null record;

      use Glfw.Windows.Callbacks;

      overriding procedure Key_Changed
         (Object   : not null access Main_Window_Type;
          Key      : Keys.Key;
          Scancode : Keys.Scancode;
          Action   : Keys.Action;
          Mods     : Keys.Modifiers);

      overriding procedure Size_Changed
         (Object   : not null access Main_Window_Type;
          Width    : Natural;
          Height   : Natural);

      overriding procedure Mouse_Position_Changed
         (Object   : not null access Main_Window_Type;
          X, Y     : Mouse.Coordinate);

      overriding procedure Mouse_Button_Changed
         (Object   : not null access Main_Window_Type;
          Button   : Mouse.Button;
          State    : Button_State;
          Mods     : Keys.Modifiers);

      Object : aliased Main_Window_Type;
      Ptr    : constant access Main_Window_Type := Object'Access;
      Width  : Glfw.Size := 1280;
      Height : Glfw.Size := 720;

      function Aspect_Ratio return Single is
         (Single (Width) / Single (Height)) with Inline;

      function Calculate_Projection return Matrix4;

   end Window;

   ----------------------------------------------------------------------------
   --  Input state

   package Mouse is
      X, Y : Glfw.Input.Mouse.Coordinate;
      Button_States : array (Glfw.Input.Mouse.Button) of Button_State :=
         (others => Released);

      function Position return Vector2 is
         (Vector2'(GL.X => Single (X), GL.Y => Single (Y)));

      function Normalised_Position_From_Centre return Vector2;
      --  Return a vector with values normalised to [-1,1], where (0,0) is the
      --  centre of the screen, (1,1) is bottom-right, and (-1,-1) is top-left.
   end Mouse;

end Cargame.Globals;