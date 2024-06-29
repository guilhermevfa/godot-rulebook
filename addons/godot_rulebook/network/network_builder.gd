class_name NetworkBuilder


static func compile_rulebook(rulebook: Rulebook) -> CompiledRulebook:
	# TODO: Offer saveable version using Node tree and scenes
	var compiled_rulebook := build_compiled_rulebook(rulebook)
	connect_network(compiled_rulebook)
	return compiled_rulebook


static func build_compiled_rulebook(rulebook: Rulebook) -> CompiledRulebook:
	var compiled_rulebook := CompiledRulebook.new()
	var all_premises: Dictionary # String: NetworkPremise
	var context := { 
		"all_premises": all_premises,
		"compiled_rulebook": compiled_rulebook,
	}
	for rule in rulebook.rules:
		var network_rule := build_network_rule(rule, context)
		compiled_rulebook.add_rule(network_rule)
	return compiled_rulebook


static func build_network_rule(rule: Rule, context: Dictionary) -> NetworkRule:
	var network_rule: NetworkRule = NetworkRule.new()
	rule_copy(rule, network_rule)
	for predicate in rule.condition.predicates:
		context["network_codition"] = network_rule.condition
		var network_predicate := build_network_predicate(predicate, context)
		network_rule.condition.predicates.append(network_predicate)
	return network_rule


static func build_network_predicate(predicate: Predicate, context: Dictionary) -> NetworkPredicate:
	var network_predicate: NetworkPredicate = NetworkPredicate.new()
	predicate_copy(predicate, network_predicate)
	
	for premise in predicate.premises:
		var network_premise := build_network_premise(premise, context)
		network_predicate.premises.append(network_premise)
	
	var id_premise := create_id_premise(predicate)
	var network_id_premise := build_network_premise(id_premise, context)
	network_predicate.premises.append(network_id_premise)
	
	network_predicate.premises.sort_custom(sort_premises)
	return network_predicate


static func build_network_premise(premise: Premise, context: Dictionary) -> NetworkPremise:
	var is_variable: bool = premise.operand_type == Premise.OperandType.VARIABLE
	var network_premise := VariablePremise.new() if is_variable else SimplePremise.new()
	var variable: String = network_premise.operand
	premise_copy(premise, network_premise)
	network_premise.parse_expression()
	var all_premises: Dictionary = context["all_premises"]
	network_premise = all_premises.get_or_add(network_premise.get_hash(), network_premise)
	if is_variable:
		var network_codition: NetworkCondition = context["network_codition"]
		network_codition.add_var_association(network_premise, variable)
	var compiled_rulebook: CompiledRulebook = context["compiled_rulebook"]
	compiled_rulebook.add_premise(network_premise)
	return network_premise


static func create_id_premise(predicate: Predicate) -> Premise:
	var premise := Premise.new()
	premise.monitorable_type = predicate.monitorable_type
	premise.attribute = "holder"
	premise.operator = "=="
	premise.operand_type = Premise.OperandType.VARIABLE
	premise.operand = predicate.monitorable_id
	return premise


static func premise_copy(origin: Premise, target: NetworkPremise) -> void:
	target.monitorable_type = origin.monitorable_type
	target.attribute = origin.attribute
	target.operator = origin.operator
	target.operand_type = origin.operand_type
	target.operand = origin.operand
	target.expression_string = origin.expression_string
	target.expression = origin.expression


static func rule_copy(origin: Rule, target: NetworkRule) -> void:
	target.type = origin.type
	target.resolution_path = origin.resolution_path


static func predicate_copy(origin: Predicate, target: NetworkPredicate) -> void:
	target.monitorable_type = origin.monitorable_type
	target.monitorable_id = origin.monitorable_id


static func sort_premises(a: NetworkPremise, b: NetworkPremise) -> bool:
	if a is SimplePremise and b is SimplePremise:
		return a.get_hash() < b.get_hash()
	elif a is SimplePremise and b is VariablePremise:
		return true
	else:
		return false


static func connect_network(rulebook: CompiledRulebook) -> void:
	var accum_conjunctions: Dictionary # String: Conjunction
	for rule in rulebook.rules:
		var var_processing: VariableProcessing = rule.condition.variable_processing
		
		for predicate in rule.condition.predicates:
			var accum_hash := ""
			var previous_conjunction: Conjunction = null
			var var_premises: Array[VariablePremise] = []
			
			for premise in predicate.premises:
				if premise is SimplePremise:
					var conjunction := Conjunction.new()
					connect_conjunctons(previous_conjunction, conjunction)
					accum_hash += premise.get_hash()
					conjunction = accum_conjunctions.get_or_add(accum_hash, conjunction)
					connect_simple_premise(premise, conjunction)
					previous_conjunction = conjunction
				elif premise is VariablePremise:
					var_premises.append(premise)
			
			var_processing.create_node(var_premises, previous_conjunction)
		
		var_processing.build_csp_graph()


static func connect_simple_premise(premise: SimplePremise, conjunction: Conjunction) -> void:
	conjunction.premise = premise
	premise.add.connect(conjunction.add_to_local_memory)
	premise.remove.connect(conjunction.remove_from_local_memory)


static func connect_conjunctons(previous_conjunction: Conjunction, conjunction: Conjunction) -> void:
	if previous_conjunction == null or conjunction == null:
		return
	previous_conjunction.forward_add.connect(conjunction.add_to_local_memory)
	previous_conjunction.forward_remove.connect(conjunction.remove_from_local_memory)
