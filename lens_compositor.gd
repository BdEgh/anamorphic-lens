class_name LensCompositor
extends Node3D

@export var light_source : Light3D
@export var camera : Camera3D
@export var lens_effect : ColorRect

@export var sun_intensity_curve: Curve

@export var fade_in_time: float = 0.15
@export var fade_time_not_reachable: float = 0.05
@export var fade_time_not_in_frustum: float = 0.15

@export var max_alpha: float = 1.0

@onready var shader_material: ShaderMaterial = lens_effect.material


func _process(_delta: float) -> void:
	_update_lens_flares_location()
	_update_flare_intensity()
	
	var light_reachable := _is_reachable()
	var light_in_frustum := camera.is_position_in_frustum(light_source.global_position)
	
	if not light_reachable or not light_in_frustum:
		_fade_out_lens_flares(fade_time_not_reachable if not light_reachable else fade_time_not_in_frustum)
		return
	
	_fade_in_lens_flares(fade_in_time)


func _fade_in_lens_flares(fade_time: float) -> void:
	if shader_material.get_shader_parameter("alpha_multiplier") == max_alpha:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(shader_material, "shader_parameter/alpha_multiplier", max_alpha, fade_time)


func _fade_out_lens_flares(fade_time: float) -> void:
	if shader_material.get_shader_parameter("alpha_multiplier") == 0.:
		return
	var tween: Tween = get_tree().create_tween()
	tween.tween_property(shader_material, "shader_parameter/alpha_multiplier", 0., fade_time)


func _update_lens_flares_location() -> void:
	var is_behind := camera.is_position_behind(light_source.global_position)
	if is_behind:
		return
	
	var unproject_position: Vector2 = camera.unproject_position(light_source.global_position) / Vector2(get_viewport().size)
	shader_material.set_shader_parameter("sun_position", unproject_position)


func _update_flare_intensity() -> void:
	const max_distance := 10.0
	
	var distance := camera.global_position.distance_to(light_source.global_position)
	var normalized_dist = clamp(distance / max_distance, 0.0, 1.0)
	
	var curve_value = sun_intensity_curve.sample(normalized_dist)
	
	shader_material.set_shader_parameter("sun_intensity", curve_value)


func _is_reachable() -> bool:
	var space_state := get_world_3d().direct_space_state
	
	var ray_origin := camera.global_position
	var ray_end := light_source.global_position
	
	var parameters: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	
	var ray_array := space_state.intersect_ray(parameters)
	
	if ray_array.has("collider"):
		return false
	
	return true
