class_name Conjunction
extends Node

signal forward_add(instance: Monitorable)
signal forward_remove(instance: Monitorable)

var premise: SimplePremise
var local_memory: Array[Monitorable] 


func add_to_local_memory(instance: Monitorable) -> void:
	local_memory.append(instance)
	if premise.get_evaluation(instance):
		forward_add.emit(instance)


func remove_from_local_memory(instance: Monitorable) -> void:
	# NOTE: Maybe implement it using a Dictionary for faster erase?
	local_memory.erase(instance)
	if premise.get_evaluation(instance):
		forward_remove.emit(instance)


func premise_add(instance: Monitorable) -> void:
	if local_memory.has(instance):
		forward_add.emit(instance)


func premise_remove(instance: Monitorable) -> void:
	if local_memory.has(instance):
		forward_remove.emit(instance)
