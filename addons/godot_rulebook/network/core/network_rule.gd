class_name NetworkRule
extends Rule

signal satisfied(rule: NetworkRule)
signal unsatisfied(rule: NetworkRule)
var solutions: Array[Dictionary] = []


func _init() -> void:
	condition = NetworkCondition.new()
	condition.add_solution.connect(on_add_solution)
	condition.remove_solution.connect(on_remove_solution)


func on_add_solution(solution: Dictionary) -> void:
	solutions.append(solution)
	satisfied.emit(self)


func on_remove_solution(solution: Dictionary) -> void:
	solutions.erase(solution)
	if solutions.is_empty():
		unsatisfied.emit(self)


func resolve(rulebook: Rulebook) -> void:
	var resolution_script: Resolution = load(resolution_path).new()
	for solution in solutions:
		resolution_script._match = solution
		resolution_script.rulebook = rulebook
		await resolution_script._resolve()
	solutions.clear()
