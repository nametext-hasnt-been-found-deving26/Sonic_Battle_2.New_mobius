# CharacterData.gd
# Defines the core data used by the Char_Loader and Select Screen

extends Resource
class_name CharacterData
@export var name: String
@export var scene: PackedScene
@export var portrait: Texture2D
@export var icon: Texture2D
@export var description: String = ""
@export var speed: float = 1.0
@export var power: float = 1.0
@export var defense: float = 1.0
