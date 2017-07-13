extends KinematicBody2D

export(float, -2, 2) var orientation = 0
export(int, 1, 1500) var speed = 1000
export(int, 0, 50) var power = 1
export(float, 0, 30, 0.01) var lifetime_sec = 10

var time_alive = 0

func _ready():
	set_fixed_process(true)

func _fixed_process(delta):
	# move the bullet
	advance(speed * delta)

	if is_colliding():
		_on_colliding()
		queue_free() # this free the bullet safely

	time_alive += delta
	if time_alive > lifetime_sec:
		queue_free()

func _on_colliding():
	pass

func advance(force):
	var direction = Vector2(cos(orientation), -sin(orientation))
	move(direction * force)
