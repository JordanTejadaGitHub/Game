extends Resource
class_name TileMapLocation

#Path tiles
@export var tile_straight_up: Vector2i = Vector2i(5,2)
@export var tile_straight_side: Vector2i = Vector2i(6,3)
@export var tile_corner_left_up: Vector2i = Vector2i(7,3)
@export var tile_corner_left_down: Vector2i = Vector2i(7,1)
@export var tile_corner_right_down: Vector2i = Vector2i(5,1)
@export var tile_corner_right_up: Vector2i = Vector2i(5,3)
@export var tile_grass: Vector2i = Vector2i(3,2)

#Tree Tiles
@export var tile_tree1: Vector2i = Vector2i(13,6)
@export var tile_tree2: Vector2i = Vector2i(14,6)
@export var tile_tree3: Vector2i = Vector2i(13,7)
@export var tile_tree4: Vector2i = Vector2i(14,7)
@export var tile_red_tree1: Vector2i = Vector2i(13,9)
@export var tile_red_tree2: Vector2i = Vector2i(14,9)
@export var tile_red_tree3: Vector2i = Vector2i(13,10)
@export var tile_red_tree4: Vector2i = Vector2i(14,10)

#Rock detail tiles
@export var tile_rock1: Vector2i = Vector2i(13,12)
@export var tile_rock2: Vector2i = Vector2i(14,12)
@export var tile_rock3: Vector2i = Vector2i(13,13)
@export var tile_rock4: Vector2i = Vector2i(14,13)

#Grass detail tiles
@export var tile_grass_detail1: Vector2i = Vector2i(11,9)
@export var tile_grass_detail2: Vector2i = Vector2i(12,9)

#Stone border tiles
@export var tile_left_top_stone_border: Vector2i = Vector2i(6,10)
@export var tile_left_middle_stone_border: Vector2i = Vector2i(6,11)
@export var tile_left_bottom_stone_border: Vector2i = Vector2i(6,12)
@export var tile_right_top_stone_border: Vector2i = Vector2i(7,10)
@export var tile_right_middle_stone_border: Vector2i = Vector2i(7,11)
@export var tile_right_bottom_stone_border: Vector2i = Vector2i(7,12)
@export var tile_top_left_stone_border: Vector2i = Vector2i(8,9)
@export var tile_top_middle_stone_border: Vector2i = Vector2i(9,9)
@export var tile_top_right_stone_border: Vector2i = Vector2i(10,9)
@export var tile_bottom_left_stone_border: Vector2i = Vector2i(8,10)
@export var tile_bottom_middle_stone_border: Vector2i = Vector2i(9,10)
@export var tile_bottom_right_stone_border: Vector2i = Vector2i(10,10)
@export var tile_corner_left_up_stone_border: Vector2i = Vector2i(8,12)
@export var tile_corner_left_down_stone_border: Vector2i = Vector2i(8,11)
@export var tile_corner_right_down_stone_border: Vector2i = Vector2i(9,11)
@export var tile_corner_right_up_stone_border: Vector2i = Vector2i(9,12)
