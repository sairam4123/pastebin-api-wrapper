extends Node

var dev_key = "<DevKey>"

func _ready():
	PastebinAPI.set_developer_key(dev_key)
	# Driver code
	var content = "Test content any variant supported! (except classes)"
	
	await PastebinAPI.login("<UserName>", "<Passkey>")
	print(await PastebinAPI.my_user_details())
	var pastes = await PastebinAPI.my_pastes()
	for paste in pastes:
		print(await PastebinAPI.get_private_paste_raw(paste["paste_key"]))
	
#	await PastebinAPI.delete_paste("Hfatje51")
#	await PastebinAPI.paste("test.json", content)
