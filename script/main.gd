extends Node2D

const VU_COUNT = 16
const FREQ_MAX = 10000

const WIDTH = 400
const HEIGHT = 100

const MIN_DB = 60

var record_effect
var recording
var spectrum

var old_hz = []

var torsos = {
	"normal": preload("res://assets/devy/torso.png"),
	"point": preload("res://assets/devy/point.png"),
	"smug": preload("res://assets/devy/torso_smug.png"),
	"h": preload("res://assets/devy/torso_h.png"),
}

var faces = {
	"normal": preload("res://assets/devy/face.png"),
	"sleep": preload("res://assets/devy/face_sleep.png"),
	"happy": preload("res://assets/devy/face_happy.png"),
	"smug": preload("res://assets/devy/face_smug.png"),
	"derp": preload("res://assets/devy/face_derp.png"),
	"cry": preload("res://assets/devy/face_cry.png"),
	"angry": preload("res://assets/devy/face_angry.png"),
	"calm": preload("res://assets/devy/face_calm.png"),
}

var mouths = {
	"normal": preload("res://assets/devy/mouth_normal.png"),
	"a": preload("res://assets/devy/mouth_a.png"),
	"e": preload("res://assets/devy/mouth_e.png"),
	"i": preload("res://assets/devy/mouth_s.png"),
	"o": preload("res://assets/devy/mouth_o.png"),
	"u": preload("res://assets/devy/mouth_u.png"),
}

var bubbles = {
	"love": {
		texture = preload("res://assets/bubbles/love.png"),
		face = "happy",
		torso = "h"
	},
	"curious": {
		texture = preload("res://assets/bubbles/curious.png"),
		face = "normal"
	},
	"nervous": {
		texture = preload("res://assets/bubbles/nervous.png"),
		face = "cry"
	},
	"phew": {
		texture = preload("res://assets/bubbles/nervous.png"),
		face = "calm",
		torso = "h"
	},
}

func _ready():
	DisplayServer.window_set_title("Devy Lipsync")
	
	var idx = AudioServer.get_bus_index("Record")
	record_effect = AudioServer.get_bus_effect(idx, 0)
	
	spectrum = AudioServer.get_bus_effect_instance(1,1)


func _process(_delta):
	queue_redraw()

var debouce = false

func set_mouth(texture):
	if debouce:
		return
	
	debouce = true
	
	$devy/a/Head/Face/Mouth.texture = texture
	
	await get_tree().create_timer(0.05).timeout
	
	debouce = false

func _draw():
	# Draw visualizations for debugging purposes 
	
	#warning-ignore:integer_division
	var w = WIDTH / VU_COUNT
	var prev_hz = 0
	
	var all_hz = []
	
	for i in range(1, VU_COUNT+1):
		var hz = i * FREQ_MAX / VU_COUNT;
		var magnitude: float = spectrum.get_magnitude_for_frequency_range(prev_hz, hz).length()
		
		var energy = clamp((MIN_DB + linear_to_db(magnitude)) / MIN_DB, 0, 1)
		var height = energy * HEIGHT
		draw_rect(Rect2(w * i, HEIGHT - height, w, height), Color.WHITE)
		
		all_hz.append(height)
		
		prev_hz = hz
	
	if old_hz == []:
		old_hz = all_hz
	
	# Filter HZ that aren't increasing.
	for i in range(1,all_hz.size()):
		if all_hz[i] < old_hz[i] and all_hz[i] != 0:
			all_hz[i] = old_hz[i]
	
	#print(all_hz)
	
	# Set mouth to match specfic vowels
	if all_hz[9] > 1:
		set_mouth(mouths.i)
	elif all_hz[0] > 7 and all_hz[1] > 7 and all_hz[2] > 1:
		set_mouth(mouths.a)
	elif all_hz[0] > 7 and all_hz[1] > 7:
		set_mouth(mouths.o)
	elif all_hz[0] > 7:
		set_mouth(mouths.e)
	else:
		set_mouth(mouths.normal)

func set_torso(name):
	$devy/a/Torso.texture = torsos[name]
	
	$devy/AnimPlay.play('swap')

func set_face(name):
	$devy/a/Head/Face/Face.texture = faces[name]
	
	$devy/AnimPlay.play('swap')

func set_bubble(name):
	$devy/Bubble.texture = bubbles[name].texture
	
	if bubbles[name]['face']:
		set_face(bubbles[name].face)

	if 'torso' in bubbles[name]:
		set_torso(bubbles[name].torso)
	
	$devy/BubbleAnim.play("bubble_loop")

func remove_bubble():
	$devy/BubbleAnim.play("RESET")
	
	$devy/AnimPlay.play('swap')


func set_normal_state():
	set_face("normal")
	set_torso("normal")

func open_settings():
	$GUI/SettingsDialog.show()
	$GUI/SettingsDialog.popup_centered()


func change_bg_color(color):
	RenderingServer.set_default_clear_color(color)
