class_name CompiledRulebook
extends Rulebook

var premises: Dictionary # String: Array[NetworkPremise]
var conflict_set := MinHeap.new(Rule.greater)
var effects_queue: Array[Effect]


func add_monitorable_instance(instance: Monitorable) -> void:
	var instance_class: String = instance.get_script().get_global_name()
	var class_premises: Array = premises.get(instance_class, [])
	for premise in class_premises:
		premise.connect_instance(instance)


func add_premise(premise: NetworkPremise) -> void:
	var class_premises: Array = premises.get_or_add(premise.monitorable_type, [])
	class_premises.append(premise)


func add_rule(rule: NetworkRule) -> void:
	rules.append(rule)
	rule.satisfied.connect(on_rule_satisfied)
	rule.unsatisfied.connect(on_rule_unsatisfied)


func on_rule_satisfied(rule: NetworkRule) -> void:
	conflict_set.push(rule)


func on_rule_unsatisfied(rule: NetworkRule) -> void:
	conflict_set.delete(rule)


func enqueue_effect(effect: Effect, push_front: bool = false):
	if push_front:
		effects_queue.push_front(effect)
	else:
		effects_queue.push_back(effect)


func dequeue_effect(effect: Effect):
	effects_queue.erase(effect)


func execute():
	while not effects_queue.is_empty():
		var effect: Effect = effects_queue.pop_front()
		effect.start_monitoring(self)
		while not conflict_set.is_empty():
			var rule: NetworkRule = conflict_set.pop()
			await rule.resolve(self)
		effect.queue_free()
