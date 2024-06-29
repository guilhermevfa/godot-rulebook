class_name VariableProcessing
extends Node

signal solution_found(solution: Dictionary)
signal invalidate_solution(solution: Dictionary)
var condition: NetworkCondition
var csp_nodes: Array[CSPNode]
var solutions: Array[Dictionary] = []
var partial_constraints: Dictionary # String: Array[PartialConstraint]
var constraints: Dictionary # int: Dictionary[ int: Array[Constraint] ]


func _init(_condition: NetworkCondition) -> void:
	condition = _condition


func create_node(premises: Array[VariablePremise], conjunction: Conjunction) -> void:
	var node := new_node()
	if conjunction != null:
		connect_conjunction(conjunction, node)
	else:
		connect_first_premise(premises[0], node)
	for premise in premises:
		connect_premise(premise, node)
		add_partial_constraint(premise, node)


func new_node() -> CSPNode:
	var node := CSPNode.new(csp_nodes.size())
	csp_nodes.append(node)
	node.added_to_domain.connect(on_domain_expansion)
	node.removed_from_domain.connect(on_domain_reduction)
	return node


func connect_conjunction(conjunction: Conjunction, node: CSPNode):
	conjunction.forward_add.connect(node.add_to_domain)
	conjunction.forward_remove.connect(node.remove_from_domain)


func connect_first_premise(premise: VariablePremise, node: CSPNode) -> void:
	premise.created.connect(node.add_to_domain)
	premise.deleted.connect(node.remove_from_domain)


func connect_premise(premise: VariablePremise, node: CSPNode) -> void:
	premise.update.connect(node.update_instance)


func add_partial_constraint(premise: VariablePremise, node: CSPNode) -> void:
	var variable: String = condition.get_premise_var(premise)
	var partial_constraint := PartialConstraint.new(node.id, premise.attribute, premise.operator)
	var variable_constraints = partial_constraints.get_or_add(variable, [])
	variable_constraints.append(partial_constraint)


func build_csp_graph() -> void:
	# Each list represents partial constraints on the same variable (of the 
	# condition), which must be added together to form a complete constraint
	for list: Array in partial_constraints.values():
		for i in range(list.size()):
			for j in range(i + 1 , list.size()):
				var constraint := build_constraint(list[i], list[j])
				if constraint != null:
					add_constraint(constraint)


func build_constraint(r: PartialConstraint, s: PartialConstraint) -> Constraint:
	if r.operator != "==" and s.operator != "==":
		return null
		
	var operator: String = r.operator if r.operator != "==" else s.operator
	# [NodeID].attr [operator] [NodeID].attr
	return Constraint.new(r.node, r.attribute, operator, s.node, s.attribute)


func add_constraint(constraint: Constraint) -> void:
	var left: int = constraint.left_node
	var right: int = constraint.right_node
	
	if constraints.has(left):
		if constraints[left].has(right):
			constraints[left][right].append(constraint)
		else:
			var shared_array := [constraint] 
			constraints[left][right] = shared_array
			constraints[right][left] = shared_array
	else:
		var shared_array := [constraint]
		constraints[left] = { 
			right: shared_array 
		}
		constraints[right] = { 
			left: shared_array 
		}


func on_domain_expansion(node: CSPNode, added_instance: Monitorable) -> void:
	var new_solutions := find_solutions(node, added_instance)
	for solution in new_solutions:
		solutions.append(solution)
		solution_found.emit(solution)


func on_domain_reduction(node: CSPNode, removed_instance: Monitorable) -> void:
	var remove_indexes: Array[int] = []
	for i in range(solutions.size()):
		var solution: Dictionary = solutions[i]
		if solution[node.variable] == removed_instance:
			# It is not recommended to remove from the array during a loop
			remove_indexes.append(i)
			invalidate_solution.emit(solution)
	for index in remove_indexes:
		solutions.remove_at(index)


func empty_domains() -> bool:
	for node in csp_nodes:
		if node.domain.is_empty():
			return true
	return false


func find_solutions(source: CSPNode, instance: Monitorable) -> Array[Dictionary]:
	if empty_domains():
		return []
	var solutions: Array[Dictionary] = []
	var assignment := { 
		source.id: instance, 
		}
	backtrack(assignment, source, 0, solutions)
	return solutions


func backtrack(assignment: Dictionary, source: CSPNode, index: int, solutions: Array[Dictionary]) -> void:
	if index == csp_nodes.size():
		solutions.append(extract_condition_solution(assignment))
		return
	
	var node: CSPNode = csp_nodes[index]
	if node == source:
		backtrack(assignment, source, index + 1, solutions)
	else:
		for instance in node.domain:
			assignment[node.id] = instance
			if is_assignment_valid(assignment):
				backtrack(assignment, source, index + 1, solutions)
			assignment.erase(node.name)


func is_assignment_valid(assignment: Dictionary) -> bool:
	for node: int in assignment.keys():
		for other_node: int in assignment.keys():
			if node != other_node \
			and constraints.has(node) \
			and constraints[node].has(other_node):
				for constraint: Constraint in constraints[node][other_node]:
					var partial_assignment := { 
						node: assignment[node], 
						other_node: assignment[other_node] 
					}
					if not constraint.evaluate(partial_assignment):
						return false
	return true


func extract_condition_solution(assignment: Dictionary) -> Dictionary:
	var solution: Dictionary
	for variable in partial_constraints.keys():
		for partial_constraint: PartialConstraint in partial_constraints[variable]:
			if partial_constraint.operator == "==":
				var instance: Monitorable = assignment[partial_constraint.node]
				var attribute: String = partial_constraint.attribute
				solution[variable] = instance.get(attribute)
				break
	return solution


class PartialConstraint:
	var node: int
	var attribute: String
	var operator: String
	
	func _init(_node: int, _attribute: String, _operator: String) -> void:
		operator = _operator
		node = _node
		attribute = _attribute


class Constraint:
	var string: String
	var left_node: int
	var right_node: int
	var expression := Expression.new()
	
	func _init(left_id: int, l_attr: String, operator: String, right_id: int, r_attr: String) -> void:
		left_node = left_id
		right_node = right_id
		string = "%s.%s %s %s.%s" % [left_id, l_attr, operator, right_id, r_attr]
		expression.parse(string, [str(left_id), str(right_id)])
	
	func evaluate(instances: Dictionary) -> bool:
		var l_instance: Monitorable
		var r_instance: Monitorable
		
		for node in instances:
			if left_node == node:
				l_instance = instances[node]
			elif right_node == node:
				r_instance = instances[node]
		
		return expression.execute([l_instance, r_instance])
