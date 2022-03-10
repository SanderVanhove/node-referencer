# Node Referencer

Godot plugin to easily add node references to scripts and copy the variable name to your clipboard.

### Example

```gdscript
onready var _animated_sprite: AnimatedSprite = $AnimatedSprite
```

![Overview Gif](screenshots/overview.gif)

## Usage

1. Select one or more nodes. There will be a dropdown menu in the scene toolbar if the plugin detects that one of the node's parents has a script. The plugin will scan recursively up the tree.
2. Select the parent to which you want to add the reference.
3. Select the last option to copy the last created reference's variable name.
4. **Reload the parent script** by closing it and reopening it. For some reason I can't get it to reload automatically.
5. Now you can use that variable.

![Usage](screenshots/usage.gif)

## Features

* Add a reference for a node to one of its parents' script.
* Add references for multiple nodes at once.
* Copy the name of the last made reference.
* Makes sure the reference has the appropriate class. Works with custom `class_name`s and `extends`.
* Prevents duplicate references.
* Enumerates variable names when there is a conflict in naming.
* Sorts references alphabetically.

## Variable name convention

The plugin will take the name of the node, convert it to snake case and put a `_` in front to show it's a private value.

### Example

```
AnimatedSprite -> _animated_sprite
```

## References code block

This plugin will create a code block within the parent script to group all its references. This block looks like this:

```gdscript
### Automatic References Start ###
onready var _animated_sprite: AnimatedSprite = $AnimatedSprite
onready var _kinematic_body_2d: KinematicBody2D = $KinematicBody2D
onready var _ray_cast_2d: RayCast2D = $AnimatedSprite/RayCast2D
### Automatic References Stop ###
```

You can rename variables, to prevent duplicate references the plugin looks at the path.

You can change the location of this block of code. As long as the `### Automatic References Start ###` and `### Automatic References Stop ###` are unchanged.

## FAQ

### Can I relocate the reference block?
Yes, as long as it has the same structure.

### Can I change the variable names?
Yes, rename away!

## I changed the node's position in the scene, what now?
You can do one of two things:
* Remove the reference from the reference code block and add it again using the plugin.
* Manually alter the path in the reference code block.

### Why didn't you use exported `NodePaths`?
Because `NodePaths` bug out some times, in my experience.

### Why do I have to close and reopen the parent's script?
The script gets saved to disk correctly, but Godot holds a cache that only get invalidated after closing it. If you know a workaround please let me know.
