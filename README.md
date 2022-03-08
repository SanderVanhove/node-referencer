# Node Referencer

Easily add node references to scripts and copy the variable name to your clipboard.

### Example

```
onready var _animated_sprite: AnimatedSprite = $AnimatedSprite
```

## Usage

1. There will be a button under the `Node` category, in the inspector, if the plugin detects that one of the node's parents has a script. The plugin will scan recursively up the tree.
2. Click it to add a reference to the parent's script.
3. Click the button again to copy the resulting variable name.
4. **Reload the parent script** by closing it and reopening it. For some reason I can't get it to reload automatically.
5. Now you can use that variable.

## Features

* Adds a reference of a node to the parent's script.
* Make sure the reference has the appropriate class. Works with custom `class_name`s and `extends`.
* Prevent duplicate references.
* Enumerate variable names when there is a conflict in naming.
* Sort references alphabetically.

## Variable name convention

The plugin will take the name of the node, convert it to snake case and put a `_` in front to show it's a private value.

### Example

```
AnimatedSprite -> _animated_sprite
```

## References code block

This plugin will create a code block within the parent script to group all its references. This block looks like this:

```
### Automatic References Start ###
onready var _animated_sprite: AnimatedSprite = $AnimatedSprite
onready var _kinematic_body2_d: KinematicBody2D = $KinematicBody2D
onready var _ray_cast2_d: RayCast2D = $AnimatedSprite/RayCast2D
### Automatic References Stop ###
```

You can rename variables, to prevent duplicate references the plugin looks at the path.

You can change the location of this block of code. As long as the `### Automatic References Start ###` and `### Automatic References Stop ###` are unchanged.

## FAQ

## Can I relocate the reference block?
Yes, as long as it has the same structure.

## Can I change the variable names?
Yes, rename away!

## Why didn't you use exported `NodePaths`?
Because `NodePaths` bug out some times, in my experience.

## Why do I have to close and reopen the parent's script?
The script gets saved to dick correctly, but Godot holds a cache that only get invalidated after closing it. If you know a workaround please let me know.