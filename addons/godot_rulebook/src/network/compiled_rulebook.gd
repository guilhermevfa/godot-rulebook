class_name CompiledRulebook
extends Node

var premises: Dictionary # String: Array[RulePremise]
var conflict_set: Array[NetworkRule]
var rules: Array[NetworkRule]


func add_monitorable_instance(instance: Monitorable) -> void:
	var instance_class: String = instance.get_script().get_global_name()
	var class_premises: Array[NetworkPremise] = premises[instance_class]
	for premise in class_premises:
		premise.connect_instance(instance)


func remove_from_conflict_set(rule: NetworkRule) -> void:
	# NOTE: Maybe implement it using a Dictionary for faster erase?
	conflict_set.erase(rule) 


func add_to_conflict_set(rule: NetworkRule) -> void:
	conflict_set.append(rule)


func add_rule(rule: NetworkRule) -> void:
	rules.append(rule)
	rule.rule_satisfied.connect(add_to_conflict_set)
	rule.rule_unsatisfied.connect(remove_from_conflict_set)