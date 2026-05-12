class_name ActionQueue
extends Node

# Serial async runner for combat animations. Each step is a Callable that
# either returns immediately (sync work) or returns a SceneTreeTimer / Tween
# whose `finished` signal we await.
#
# Usage:
#   action_queue.push(func() -> SceneTreeTimer: return get_tree().create_timer(0.14))
#   action_queue.push(func(): _spawn_slash_effect())
#   await action_queue.flush()
#
# When `fast_resolve` is true, every wait is collapsed to `fast_min_wait`.

signal queue_drained

@export var fast_resolve: bool = false
@export var fast_min_wait: float = 0.0

var _steps: Array[Callable] = []
var _running: bool = false
var _hit_pause_prev_scale: float = 1.0


func push(step: Callable) -> void:
	_steps.append(step)


func push_wait(seconds: float) -> void:
	push(func() -> SceneTreeTimer:
		var dur := fast_min_wait if fast_resolve else seconds
		if dur <= 0.0:
			return null
		return get_tree().create_timer(dur))


func push_hit_pause(seconds: float = 0.06) -> void:
	# Engine.time_scale freeze. Skipped entirely under fast resolve.
	push(func() -> SceneTreeTimer:
		if fast_resolve:
			return null
		_hit_pause_prev_scale = Engine.time_scale
		Engine.time_scale = 0.0
		# Use unscaled timer (process_always == true makes our timer tick).
		return get_tree().create_timer(seconds, true, false, true)
	)
	push(func() -> void:
		if not fast_resolve:
			Engine.time_scale = _hit_pause_prev_scale
	)


func clear() -> void:
	_steps.clear()


func is_idle() -> bool:
	return not _running and _steps.is_empty()


# Drains the queue. Caller can `await` to wait for it to empty.
func flush() -> void:
	if _running:
		# Already draining; just wait for queue to empty.
		await queue_drained
		return
	_running = true
	while not _steps.is_empty():
		var step := _steps.pop_front() as Callable
		var result = step.call()
		await _await_result(result)
	_running = false
	queue_drained.emit()


func _await_result(result) -> void:
	if result == null:
		return
	if result is Tween:
		if result.is_running():
			await result.finished
		return
	if result is SceneTreeTimer:
		await result.timeout
		return
	if result is Signal:
		await result
		return
	# Anything else: treat as fire-and-forget.
