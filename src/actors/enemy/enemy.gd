extends "../creature.gd"

# other classes

var Brain = preload("res://ai/decision/brains/DefaultBrain.gd")

# nodes

onready var hero = get_node("../hero")
onready var solids = get_node("../../solids")
onready var anim = get_node("anim")

# AI

onready var brain = Brain.new()
var current_action = null

func _ready():
	connect("take_fall_damage", self, "_handle_fall_damage")
	hp.connect("on_damage", self, "_handle_damage")

	brain.set_goal_value(Brain.GOAL_DESTROY_CARROTS, 45)

func _pre_fixed_process(delta):
	if get_tree().get_frame() % 60 == 0:
		_decide()

	if current_action != null:
		current_action.call_func()

func _decide():
	_update_goals()
	var action = brain.choose_action()

	if action == Brain.ACTION_ATTACK_CARROT:
		get_node("thought").set_text("Attack carrot!")
		current_action = funcref(self, "_action_attack_carrot")
	elif action == Brain.ACTION_ATTACK_PLAYER:
		get_node("thought").set_text("Attack player!")
		current_action = funcref(self, "_action_attack_player")
	elif action == Brain.ACTION_FLEE:
		get_node("thought").set_text("Flee!")
		current_action = funcref(self, "_action_flee")
	elif action == Brain.ACTION_FOLLOW_ALLIES:
		get_node("thought").set_text("Need allies!")
		current_action = null
	else:
		get_node("thought").set_text("Uh...?")
		current_action = null

func _die():
	queue_free()

func _update_goals():
	brain.set_goal_value(Brain.GOAL_SURVIVE, 100 * (hp.max_health - hp.health) / hp.max_health)
	brain.set_goal_value(Brain.GOAL_KILL_PLAYER, 12000 / get_pos().distance_to(hero.get_pos()))
	# TODO: GOAL_FIND_ALLIES

func _handle_fall_damage():
	hp.take_damage((on_air_time - MIN_AIRBONE_TIME_FALL_DAMAGE) * 10)

func _handle_damage(hp):
	anim.play("damage")

func _action_attack_player():
	_go_to_pos(hero.get_pos())

func _action_attack_carrot():
	_go_to_pos(Vector2(0, 0))

func _action_flee():
	_go_to_pos(get_pos() + (get_pos() - hero.get_pos()))

# TEMP: needs improvements (pathfinding, etc)

func _go_to_pos(pos):
	set_go_right(get_pos().x < pos.x - 30)
	set_go_left(get_pos().x > pos.x + 30)

	set_jump(false)
	if go_right or go_left:
		if blocked_on_right() or blocked_on_left():
			_dig()
			if can_jump():
				set_jump(true)

func _dig():
	var dig_pos
	if go_right:
		dig_pos = get_pos() + Vector2(SolidTiles.TILE_SIZE, 0)
	elif go_left:
		dig_pos = get_pos() + Vector2(-SolidTiles.TILE_SIZE, 0)
	else:
		dig_pos = get_pos() + Vector2(0, SolidTiles.TILE_SIZE)

	var tile_pos = solids.world_to_map(dig_pos)
	solids.damage_tile(tile_pos, 1)

func can_jump():
	return solids.get_cellv(solids.world_to_map(get_pos() + Vector2(0, -SolidTiles.TILE_SIZE))) == SolidTiles.TILE_EMPTY

func blocked_on_right():
	return solids.get_cellv(solids.world_to_map(get_pos() + Vector2(SolidTiles.TILE_SIZE, 0))) != SolidTiles.TILE_EMPTY

func blocked_on_left():
	return solids.get_cellv(solids.world_to_map(get_pos() + Vector2(-SolidTiles.TILE_SIZE, 0))) != SolidTiles.TILE_EMPTY
