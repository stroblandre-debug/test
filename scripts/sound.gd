extends AudioStreamPlayer
## Short original synthesized cues; no external sound assets.

var sound_enabled: bool = true

func cue(frequency: float = 440, duration: float = 0.15, rising: bool = false) -> void:
	if not sound_enabled:
		return
	var wav: AudioStreamWAV = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = 22050
	var frames: int = int(duration * wav.mix_rate)
	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(frames * 2)
	var phase: float = 0
	for frame in range(frames):
		var progress: float = float(frame) / frames
		var pitch: float = frequency * (1 + progress * 0.5 if rising else 1.0)
		phase += TAU * pitch / wav.mix_rate
		var envelope: float = minf(1.0, progress * 30) * pow(1 - progress, 2)
		var sample: float = (sin(phase) + sin(phase * 2.01) * 0.25) * envelope * 0.13
		bytes.encode_s16(frame * 2, int(sample * 32767))
	wav.data = bytes
	stream = wav
	volume_db = -9
	play()
