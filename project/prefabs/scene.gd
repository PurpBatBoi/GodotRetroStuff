@tool
extends Node3D

@onready var mm: MultiMeshInstance3D = $RLS_VertexLightManager3D/RLS_LitMultiMeshInstance3D

func _ready() -> void:
	var multimesh: MultiMesh = mm.multimesh
	multimesh.instance_count = 2048
	multimesh.visible_instance_count = 2048

	for i in range(multimesh.instance_count):
		var x: int = i % 32
		var z: int = i / 32
		multimesh.set_instance_transform(
			i,
			Transform3D(Basis(), Vector3(x * 2.0, 0.0, z * 2.0))
		)
