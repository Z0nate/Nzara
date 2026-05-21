extends Node

var particle_pool: Dictionary = {}
var pool_size: int = 5
var particles: Node2D

func init(particles_node: Node2D) -> void:
	particles = particles_node
	_build_particle_pool()

func _build_particle_pool() -> void:
	for child in particles.get_children():
		if not child is GPUParticles2D:
			continue
		particle_pool[child.name] = []
		for i in pool_size:
			var clone = child.duplicate() as GPUParticles2D
			clone.emitting = false
			clone.z_index = 10
			clone.top_level = true
			get_tree().current_scene.add_child.call_deferred(clone)
			particle_pool[child.name].append(clone)

func emit_particles_at_position(spawn_position: Vector2, particle_name: String, rotation: float = 0) -> void:
	if not particle_pool.has(particle_name):
		return
	for clone in particle_pool[particle_name] as Array:
		if clone.emitting:
			continue
		clone.global_rotation = rotation
		clone.global_position = spawn_position
		clone.restart()
		return

func play_sound_at_position(spawn_position: Vector2, audio_stream: AudioStream, parent: Node) -> void:
	var audio_player = AudioStreamPlayer2D.new()
	audio_player.stream = audio_stream
	audio_player.global_position = spawn_position
	parent.add_child(audio_player)
	audio_player.play()
	audio_player.finished.connect(audio_player.queue_free)
