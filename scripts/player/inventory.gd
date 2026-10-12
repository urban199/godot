extends Node

signal inventory_changed(items: Array[String])

const MAX_SLOTS := 8
var items: Array[String] = []

func add_item(item_id: String) -> bool:
	if items.has(item_id):
		return true
	if items.size() >= MAX_SLOTS:
		return false
	items.append(item_id)
	inventory_changed.emit(items.duplicate())
	return true

func has_item(item_id: String) -> bool:
	return items.has(item_id)

func consume(item_id: String) -> bool:
	if not items.has(item_id):
		return false
	items.erase(item_id)
	inventory_changed.emit(items.duplicate())
	return true

func restore(saved_items: Array) -> void:
	items.clear()
	for item_id in saved_items:
		if item_id is String and not items.has(item_id):
			items.append(item_id)
	inventory_changed.emit(items.duplicate())

func clear() -> void:
	items.clear()
	inventory_changed.emit(items.duplicate())
