extends Node

const SAMPLE_RATE := 11025

var _rain_player: AudioStreamPlayer
var _music_player: AudioStreamPlayer
var _rain_stream: AudioStreamWAV
var _music_stream: AudioStreamWAV
var _step_walk: AudioStreamWAV
var _step_run: AudioStreamWAV
var _stinger: AudioStreamWAV
var _noise_filter := 0.0

func _ready() -> void:
	_rain_stream = _make_rain_stream()
	_music_stream = _make_music_stream()
	_step_walk = _make_step_stream(0.085, 0.32)
	_step_run = _make_step_stream(0.12, 0.48)
	_stinger = _make_stinger_stream()
	_rain_player = AudioStreamPlayer.new()
	_rain_player.name = "RainAmbience"
	_rain_player.stream = _rain_stream
	_rain_player.bus = "Effects"
	_rain_player.volume_db = -19.0
	add_child(_rain_player)
	_rain_player.play()
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "AtmosphereMusic"
	_music_player.stream = _music_stream
	_music_player.bus = "Music"
	_music_player.volume_db = -24.0
	add_child(_music_player)
	_music_player.play()
	SettingsManager.settings_changed.connect(_apply_volume)
	_apply_volume()

func play_step(world_position: Vector3, is_running: bool) -> void:
	var sound := AudioStreamPlayer3D.new()
	sound.stream = _step_run if is_running else _step_walk
	sound.bus = "Effects"
	sound.position = world_position
	sound.max_distance = 18.0
	sound.unit_size = 5.0
	sound.volume_db = -5.0 if is_running else -9.0
	get_tree().current_scene.add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func play_thunder() -> void:
	var stream := _make_thunder_stream()
	var sound := AudioStreamPlayer.new()
	sound.stream = stream
	sound.bus = "Effects"
	sound.volume_db = -12.0
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func play_stinger() -> void:
	var sound := AudioStreamPlayer.new()
	sound.stream = _stinger
	sound.bus = "Effects"
	sound.volume_db = -12.0
	add_child(sound)
	sound.finished.connect(sound.queue_free)
	sound.play()

func _make_rain_stream() -> AudioStreamWAV:
	var frame_count := SAMPLE_RATE * 2
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var white_noise := randf_range(-1.0, 1.0)
		_noise_filter = lerpf(_noise_filter, white_noise, 0.055)
		var sample := int(clampi(int(_noise_filter * 4600.0), -32768, 32767))
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frame_count
	stream.data = bytes
	return stream

func _make_step_stream(duration: float, volume: float) -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * duration)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var progress := float(frame) / float(frame_count)
		var envelope := (1.0 - progress) * (1.0 - progress)
		var tone := sin(float(frame) * 0.075) * 0.55 + randf_range(-0.45, 0.45)
		var sample := int(clampi(int(tone * envelope * volume * 32767.0), -32768, 32767))
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream

func _make_thunder_stream() -> AudioStreamWAV:
	var frame_count := SAMPLE_RATE * 2
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	var low_noise := 0.0
	for frame in range(frame_count):
		var time := float(frame) / SAMPLE_RATE
		var envelope := exp(-time * 2.7)
		low_noise = lerpf(low_noise, randf_range(-1.0, 1.0), 0.025)
		var rumble := sin(time * 39.0) * 0.35 + low_noise * 0.75
		var sample := int(clampi(int(rumble * envelope * 19000.0), -32768, 32767))
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream

func _make_stinger_stream() -> AudioStreamWAV:
	var frame_count := int(SAMPLE_RATE * 0.72)
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var progress := float(frame) / float(frame_count)
		var envelope := minf(progress * 16.0, 1.0) * exp(-progress * 5.0)
		var sweep := sin(TAU * (170.0 + 680.0 * progress) * progress)
		var sample := int(clampi(int(sweep * envelope * 15000.0), -32768, 32767))
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = bytes
	return stream

func _make_music_stream() -> AudioStreamWAV:
	var frame_count := SAMPLE_RATE * 8
	var bytes := PackedByteArray()
	bytes.resize(frame_count * 2)
	for frame in range(frame_count):
		var time := float(frame) / SAMPLE_RATE
		var bed := sin(TAU * 55.0 * time) * 0.42 + sin(TAU * 82.4 * time) * 0.2
		var overtone := sin(TAU * (109.0 + 1.5 * sin(TAU * 0.125 * time)) * time) * 0.12
		var sample := int(clampi(int((bed + overtone) * 2400.0), -32768, 32767))
		bytes.encode_s16(frame * 2, sample)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_end = frame_count
	stream.data = bytes
	return stream

func _apply_volume() -> void:
	if is_instance_valid(_rain_player):
		_rain_player.volume_db = linear_to_db(maxf(0.001, float(SettingsManager.get_value("effects_volume", 1.0)) * 0.12))
