with Ada.Command_Line;
with Ada.Directories;
with Ada.Real_Time;             use Ada.Real_Time;
with Ada.Text_IO;               use Ada.Text_IO;
with Ada.Numerics.Float_Random;

with GL;                        use GL;
with GL.Buffers;                use GL.Buffers;
with GL.Files;
with GL.Objects.Programs;       use GL.Objects.Programs;
with GL.Objects.Vertex_Arrays;  use GL.Objects.Vertex_Arrays;
with GL.Objects.Buffers;        use GL.Objects.Buffers;
with GL.Objects.Shaders;        use GL.Objects.Shaders;
with GL.Objects.Textures;
with GL.Toggles;
with GL.Types;                  use GL.Types; use GL.Types.Singles;

with Glfw;
with Glfw.Input;                use Glfw.Input;
with Glfw.Windows;
with Glfw.Windows.Context;      use Glfw.Windows.Context;
with Glfw.Windows.Hints;        use Glfw.Windows.Hints;

with Cargame.Globals;           use Cargame.Globals;
with Cargame.Models;            use Cargame.Models;
with Cargame.Types;             use Cargame.Types;
with Cargame.Uniforms;
with Cargame.Gameplay;          use Cargame.Gameplay;
with Cargame.Util;
with Cargame.Texture_Loader;
with Cargame.ECS;

--------------------------------------------------------------------------------

procedure Cargame.Main is

   Frame_T0 : Time;
   Frame_T1 : Time;

   Asteroids : array (1 .. 1000) of ECS.Entity;

   Float_Generator : Ada.Numerics.Float_Random.Generator;

   use all type ECS.Enabled_Components;

begin

   Ada.Directories.Set_Directory
      (Ada.Directories.Containing_Directory (Ada.Command_Line.Command_Name));

   Util.Log ("Running from " & Ada.Directories.Current_Directory);

   ------------------------------
   --  Set up GLFW and OpenGL  --
   ------------------------------

   Util.Log ("Creating a window.");

   Glfw.Init; --  Initialises both GLFW and OpenGL.

   Set_Minimum_OpenGL_Version (Major => 3, Minor => 3);
   Set_Forward_Compat (True);
   Set_Profile (Core_Profile);

   Globals.Window.Init (Object => Globals.Window.Ptr,
                        Title  => "Skeltal Racing",
                        Width  => Globals.Window.Width,
                        Height => Globals.Window.Height);

   pragma Assert (Globals.Window.Object.Initialized,
                  "Failed to initialise main window.");

   Make_Current (Globals.Window.Ptr);
   Set_Swap_Interval (0);

   Set_Color_Clear_Value (Globals.Background_Colour);

   Enable_Callbacks :
   declare
      use Globals.Window;
      use Glfw.Windows;
   begin
      Object.Enable_Callback (Callbacks.Key);
      Object.Enable_Callback (Callbacks.Size);
      Object.Enable_Callback (Callbacks.Mouse_Position);
      Object.Enable_Callback (Callbacks.Mouse_Button);
   end Enable_Callbacks;

   -----------------------------------
   --  Set up GL_Program (shaders)  --
   -----------------------------------

   Util.Log ("Compiling shaders.");

   Shader_Setup :
   declare
      Vertex_Shader   : Shader (Kind => GL.Objects.Shaders.Vertex_Shader);
      Fragment_Shader : Shader (Kind => GL.Objects.Shaders.Fragment_Shader);

      Vertex_Path   : constant String := "../src/shaders/vert.glsl";
      Fragment_Path : constant String := "../src/shaders/frag.glsl";
      use Ada.Directories;
   begin

      Initialize_Id (GL_Program);
      Initialize_Id (Vertex_Shader);
      Initialize_Id (Fragment_Shader);

      GL.Files.Load_Shader_Source_From_File (Vertex_Shader, Vertex_Path);
      GL.Files.Load_Shader_Source_From_File (Fragment_Shader, Fragment_Path);

      Compile (Vertex_Shader);
      Compile (Fragment_Shader);

      if not Vertex_Shader.Compile_Status then
         Util.Log_Error ("Failed to compile Vertex shader.");
         Util.Log (Vertex_Shader.Info_Log);
         pragma Assert (False, "Failed to compile Vertex shader.");
      end if;

      if not Fragment_Shader.Compile_Status then
         Util.Log_Error ("Failed to compile Fragment shader.");
         Util.Log (Fragment_Shader.Info_Log);
         pragma Assert (False, "Failed to compile Fragment shader.");
      end if;

      GL_Program.Attach (Vertex_Shader);
      GL_Program.Attach (Fragment_Shader);
      GL_Program.Link;

      if not GL_Program.Link_Status then
         Put_Line ("Log: " & GL_Program.Info_Log);
         pragma Assert (False, "Failed to link shaders.");
      end if;
   end Shader_Setup;

   GL_Program.Use_Program;
   GL.Toggles.Enable (GL.Toggles.Depth_Test);

   Util.Log ("Shader loaded.");

   ---------------------------
   --  Initialise entities  --
   ---------------------------

   Player_Model   := Create_Model_From_Obj ("../src/models/Barrel02.obj");
   Asteroid_Model := Create_Model_From_Obj ("../src/models/Barrel02.obj");

   Player := ECS.New_Entity;
   ECS.Controlled_By_Player.Set (Player, True);
   ECS.Position.Set             (Player, (others => 0.0));
   ECS.Velocity.Set             (Player, (others => 0.0));
   ECS.Acceleration.Set         (Player, (others => 0.0));
   ECS.Render_Scale.Set         (Player, 10.0);
   ECS.Object_Matrix.Set        (Player, Identity4);
   ECS.CamObj_Matrix.Set        (Player, Identity4);
   ECS.Normal_Matrix.Set        (Player, Identity3);
   ECS.Model.Set                (Player, Player_Model);
   ECS.Rotation.Set             (Player, Radians (0.0));

   for I in Asteroids'Range loop
      Asteroids (I) := ECS.Manager.New_Entity;

      -- Position is set below

      ECS.Rotation.Set         (Asteroids (I), Radians (0.0));
      ECS.Model.Set            (Asteroids (I), Asteroid_Model);
      ECS.Rotational_Speed.Set (Asteroids (I), Radians (if I mod 2 = 0 then 1 else (-1)) * Radians (0.01));
      ECS.Render_Scale.Set     (Asteroids (I), 10.0);

      ECS.Object_Matrix.Set    (Asteroids (I), Identity4);
      ECS.CamObj_Matrix.Set    (Asteroids (I), Identity4);
      ECS.Normal_Matrix.Set    (Asteroids (I), Identity3);

      declare
         package R renames Ada.Numerics.Float_Random;
         Position : Position_Type;
         Factor : constant Single := 50.0;
      begin
         Position (X) := Factor * Single (R.Random (Float_Generator) - 0.5);
         Position (Y) := Factor * Single (R.Random (Float_Generator) - 0.5);
         Position (Z) := Factor * Single (R.Random (Float_Generator) - 0.5);
         ECS.Position.Set (Asteroids (I), Position);
      end;
  end loop;

   ---------------------------
   --  Initialise uniforms  --
   ---------------------------

   Util.Log ("Initialising uniforms.");

   Uniforms.Projection.Initialise
      (GL_Program, Globals.Window.Calculate_Projection);

   Uniforms.Camera_Transform.Initialise
     (GL_Program,
      Look_At (Camera_Position => Globals.Camera_Position,
               Target_Position => Origin,
               Up              => (0.0, 1.0, 0.0)));

   Uniforms.Object_Transform.Initialise (GL_Program, Identity4);
   Uniforms.CamObj_Transform.Initialise (GL_Program, Identity4);
   Uniforms.Normal_Transform.Initialise (GL_Program, Identity3);

   Uniforms.Diffuse_Map.Initialise  (GL_Program, Globals.Diffuse_Map_ID);
   Uniforms.Specular_Map.Initialise (GL_Program, Globals.Specular_Map_ID);

   Uniforms.Material_Ambient.Initialise   (GL_Program);
   Uniforms.Material_Shininess.Initialise (GL_Program);
   Uniforms.Light_Position.Initialise     (GL_Program, Initial_Player_Position);
   Uniforms.Light_Ambient.Initialise      (GL_Program, (others => 1.0));
   Uniforms.Light_Diffuse.Initialise      (GL_Program, (others => 1.0));
   --  Uniforms.Light_Specular.Initialise     (GL_Program);

   -----------------------------------
   --  Initialise default material  --
   -----------------------------------

   --  TODO(2019-02-04): There's related code in cargame-models.adb for
   --  applying this material. Ensure there's no overlap, and maybe tidy these
   --  two up.

   Util.Log ("Loading default material.");

   Set_Default_Material :
   declare
   begin
      Default_Texture := Texture_Loader.Load_Texture
         ("../src/models/default_texture.png");
      pragma Assert (Default_Texture.Initialized);

      Default_Material :=
         (Name             => To_Material_Name ("Default material"),
          Diffuse_Texture  => Default_Texture,
          Specular_Texture => Default_Texture,
          others           => <>);
   end Set_Default_Material;

   ----------------------
   --  Main game loop  --
   ----------------------

   Util.Log ("Frame deadline is " & Util.Image (Globals.Frame_Interval));

   Game_Loop :
   while not Globals.Window.Object.Should_Close loop

      -------------------
      -- Set deadlines --
      -------------------

      Frame_T0 := Clock;
      Next_Frame_Time := Frame_T0 + Frame_Interval;
      Globals.Current_Frame := @ + 1;

      -----------------------
      --  Gameplay update  --
      -----------------------

      Globals.Frame_Number := @ + 1;

      Glfw.Input.Poll_Events;
      Gameplay.Run_All_Systems;

      --------------
      --  Render  --
      --------------

      Clear (Buffer_Bits'(Depth => True, Color => True, others => <>));

      declare
         Pos : constant Position_Type := ECS.Position.Get (Player);
         Vel : constant Velocity_Type := ECS.Velocity.Get (Player);

         function Camera_Offset return Position_Type is (Position_Type (Vel));
      begin
         Uniforms.Camera_Transform.Set
            (Look_At (Camera_Position => (Player_Pos +
                                          Vector3'(0.0, 2.0, -2.0)),
                      Target_Position => (Player_Pos +
                                          Vector3'(0.0, 0.0, +2.0) +
                                          Gameplay.Player.Camera_Movement_Offset),
                      Up              => (Y => 1.0, others => 0.0)));

         Gameplay.Player.Model.Render (Player);
      end;

      Swap_Buffers (Globals.Window.Ptr);

      -----------------------------
      --  Performance analytics  --
      -----------------------------

      Frame_T1 := Clock;

      if Frame_T1 > Next_Frame_Time then
         Util.Log_Warning ("Missed frame deadline by " &
                           Util.Image (Frame_T1 - Next_Frame_Time));
      end if;

      -------------
      --  Vsync  --
      -------------

      delay until Next_Frame_Time;

   end loop Game_Loop;

   Globals.Window.Destroy (Globals.Window.Ptr);
   Glfw.Shutdown;

   Put_Line ("Thanks for playing!");

end Cargame.Main;
