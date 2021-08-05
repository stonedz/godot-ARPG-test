extends KinematicBody2D

const PlayerHurtSound = preload("res://Player/PlayerHurtSound.tscn")

export var ACCELERATION = 500
export var FRICTION = 500
export var MAX_SPEED = 80
export var ROLL_SPEED = 120
export var IFRAME_DURATION = 0.6

enum {
	MOVE,
	ROLL,
	ATTACK
}

var velocity = Vector2.ZERO
var roll_vector = Vector2.DOWN #ricorda la direzione del movimento per il roll e per il knockback
var state = MOVE
var stats = PlayerStats #autoload

onready var animationPlayer = $AnimationPlayer
onready var animationTree = $AnimationTree
onready var animationState = animationTree.get("parameters/playback")
onready var swordHitbox = $HitboxPivot/SwordHitbox
onready var hurtbox = $Hurtbox
onready var blinkAnimationPlayer = $BlinkAnimationPlayer

func _ready():
	animationTree.active = true
	swordHitbox.knockback_vector = roll_vector
	stats.connect("no_health",self,"queue_free")

func _physics_process(delta):
	match state:
		MOVE:
			move_state(delta)
		ROLL:
			roll_state(delta)
		ATTACK:
			attack_state(delta)	

func roll_state(delta):
	velocity = roll_vector * ROLL_SPEED
	move()
	animationState.travel("Roll")
	
func attack_state(delta):
	velocity = Vector2.ZERO
	animationState.travel("Attack")
	
func attack_animation_finished():
	state = MOVE
	
func roll_animation_finished():
	state = MOVE

func move_state(delta):
	var input_vector = Vector2.ZERO
	input_vector.x = Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left")
	input_vector.y = Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	input_vector = input_vector.normalized()
	
	if input_vector != Vector2.ZERO:
		roll_vector = input_vector
		swordHitbox.knockback_vector = input_vector
		animationTree.set("parameters/Idle/blend_position", input_vector)
		animationTree.set("parameters/Run/blend_position", input_vector)
		animationTree.set("parameters/Attack/blend_position", input_vector)
		animationTree.set("parameters/Roll/blend_position", input_vector)
		animationState.travel("Run")

		velocity = velocity.move_toward(input_vector * MAX_SPEED, ACCELERATION * delta)
	else:
		animationState.travel("Idle")
		velocity = velocity.move_toward(Vector2.ZERO, FRICTION * delta)
		
	move()
	
	if Input.is_action_just_pressed("roll"):
		state = ROLL
	
	if Input.is_action_just_pressed("attack"):
		state = ATTACK

func move():
		velocity = move_and_slide(velocity)
	


func _on_Hurtbox_area_entered(area):
	hurtbox.start_invincibility(IFRAME_DURATION)
	hurtbox.create_hit_effect()
	stats.health -= area.damage
	
	var playerHurtsound = PlayerHurtSound.instance()
	get_tree().current_scene.add_child(playerHurtsound)


func _on_Hurtbox_invincibility_started():
	blinkAnimationPlayer.play("Start")


func _on_Hurtbox_invincibility_ended():
	blinkAnimationPlayer.play("Stop")