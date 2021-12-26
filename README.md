# GodetteVN, A Visual Novel Framework for Godot Users

## I am focusing on making a game with this rn. No update planned unless it's a bug. I lied. A few more updates before I jump into my own game!

![Godette](/Showcases/show1.png)

#### For more showcases, scroll down and see the gallery.
---------------------------------------------

## Goal and Vision: Bringing the theatrical experience into your story, right in the Godot Engine.

### Highlights and Goals: (subject to change...)

1. Actor Editor: any 2d customization doable in Godot should be applicable to actors. (Usable...)
2. Script Editor: script should be similar to that of a play in the traditional setting, but formatted in a more programmatic language. (Usable, not the simplest...)
3. Rich template libraries for "commonly" used components, e.g. timed choices, parallax, weather, etc. (In progress...) 
4. Key components should be callable programmatically and should be functional without others. (Almost?...)
5. Strong unit testing support, instantenous display for the event in your script. (Started, but secretly wants to 
postpone this after Godot 4...)
6. Light Weight (Godot engine + the framework is < 100mb.). Not including export templates, which is only needed when exporting the game. 
7. **Much easier to code any other game outside of VNs.**
8. **UI interface for UI editing.**

### Dehightlights: (Not necessarily...)
1. You probably need to learn shaders and more stuff to do make image effects.
2. You will have to learn Godot along the way if you want to step outside Visual Novels in your game.
3. There will always be things you want to do but the framework doesn't neccesarily support. (whichatever editor you use)

### Future Plans:
1. Side Picture correspondence. (Already has everything needed. Just need to create an interface.)
2. Simplify the whole process.
3. More builtin templates. (Like a customizable phone screen template, liteDialog (for rpg), LiveDialog, etc.)
4. Lip sync.

-------------------------------------------------------------------------------------------------------------

## Every journey starts with a single step.

For basic dialog for RPG games, then [Dialogic](https://github.com/coppolaemilio/dialogic) might be a better addon than this, 
because this framework is solely focused on the making of Visual/Graphic Novel. Renpy is also a good 
alternative if your game doesn't require features that are easier to make in Godot. Programming knowledge is highly recommended to
make full use of the framework.

In the folder res://GodetteVN/ , you can find sample projects to run.

Before you run your own sample scene, make sure your character is created via the 
actor editor and saved as a scene. Moreover, you have to register your characters. 
Go to GodetteVN/Core/Singletons/vn.tscn, and find RegisteredCharacters node and follow the examples
from there. Same deal with dvars. 

There are 3 core components in this framework.
1. An actor editor (WIP, mostly stable for written functions) 
2. A script editor (WIP, mostly stable for written functions)
3. A core dialog system (basically a json interpreter, mostly stable)  

Transition system is integrated from eh-jogos's project. You can find it [here](https://github.com/eh-jogos/eh_Transitions)

Shaders are taken from Godot Asset Library, [here](https://godotengine.org/asset-library/asset/122) and
[here](https://godotshaders.com/shader/glitch-effect-shader/) @arlez80. Not all shaders are implemented yet.

Video Showcases (Possibly outdated):

[Parallax and Sprite Sheet Animation](https://www.youtube.com/watch?v=sG7tDFsk4HE)

[General Gameplay](https://www.youtube.com/watch?v=uODpTQz6Vu0&t=43s)

[Floating Text](https://www.youtube.com/watch?v=2KSO_qQ8pqw)

Other examples like timed choice, investigation scene, can be found in the folder /GodetteVN/

Projects done with this template:

[Songbird](https://tqqq.itch.io/o2a2-elegy-to-a-songbird)
[Video of the game](https://youtu.be/BArw1Qwrz10)

More in the making ~

------------------------------------------------------------------------------------------------------------------------------
### Default Controls:

1. Left click, enter, space : continue dialog
2. right click : hide VN related UI (dialog box, name box, quick menu) and only show sprites and background
3. control + z : rollback to previous dialog
4. Tab (only in script editor) : generates the ":: ;" string for you. When you have selected text which corresponds to some events, then it will try to generate the event text for you. For instance, if you have selected "a join", it will be interpreted as "there exists a character with uid a, and is joining the scene" and will print "chara:: a join; loc :: * ; expression :: default ;" for you in the script editor.
5. Control + F : reloads the game script it the json file has been modified and saved. Only works when game is launched in the editor and when dialog is passed as a json. This function currently does not work if current dialog is displayed in NVL mode. You may still be able to refresh when in NVL, but script may not update automatically. You will have to rollback before NVL and then refresh. 

### Exporting your game

Make sure you know where the game data directory is. Go to top left corner, project -> open project data folder. You will have to run the project at least once to have a folder. The path of this folder is where save data and some other data is saved.

You need to download the Godot export template to export your game. In addition, you need to enter *.json in the resource tab when exporting. See here

![Exporting](/Showcases/exporting.png)

### Known issues:

1. Mac export will be considered corrupted. Most likely you will need to do the command line trick to run it.


### Documentations

Documentation will be in the VNScript editor in the framework.

------------------------------------------------------------------------------------------------------------------------------

## You can contact me on Discord for any questions.

Discord: T.Q#8863

Twitter: @TqAbstrac


-----

# Gallery (Framework Showcases)

![Weather](/Showcases/show3.png)
Builtin weather system made by particle effects.

![tint](/Showcases/show2.png)
Builtin tint screen functionality.

![flashlight](/Showcases/show4.png)
Easy to integrate other visual effects like flashlights. 
