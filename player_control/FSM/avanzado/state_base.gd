
class_name StateBase extends Node

## Referencia al Nodo que vamos a controlar
@onready var controlled_Node:Node = self.owner

## Referencia a la Maquina de Estados
var state_machine:StateMachine

#region Métodos Comunes

## Métodos que se ejecutan al entrar en el estado
func start():
	pass
	
func end():
	pass
	
#endregion
