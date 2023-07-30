extends Node

enum SupportedAPIURL {
	LOGIN = 0,
	PRIVATE_RAW = 1,
	PASTE = 2,
	PUBLIC_RAW = 3
}

enum APIOptions {
	PASTE = 0,
	LIST = 1,
	DELETE = 2,
	SHOW_PASTE = 3,
	USER_DETAILS = 4,
}

const API_URL_DICT = {
	SupportedAPIURL.LOGIN: "https://pastebin.com/api/api_login.php",
	SupportedAPIURL.PASTE: "https://pastebin.com/api/api_post.php",
	SupportedAPIURL.PRIVATE_RAW: "https://pastebin.com/api/api_raw.php",
	SupportedAPIURL.PUBLIC_RAW: "https://pastebin.com/raw",
}

const API_OPTIONS_DICT = {
	APIOptions.LIST: "list",
	APIOptions.PASTE: "paste",
	APIOptions.DELETE: "delete",
	APIOptions.SHOW_PASTE: "show_paste",
	APIOptions.USER_DETAILS: "userdetails"
}

var dev_api_key = ""
var user_api_key = ""

var http_client: HTTPClient
var http_request: HTTPRequest

func _ready():
	http_client = HTTPClient.new()
	http_request = HTTPRequest.new()
	add_child(http_request)

func set_developer_key(dev_key):
	dev_api_key = dev_key

func set_user_key(user_key):
	user_api_key = user_key

func login(username, password):
	var query: = http_client.query_string_from_dict(
		{
			api_dev_key = dev_api_key,
			api_user_name = username,
			api_user_password = password,
		}
	)
	user_api_key = await _request(query, SupportedAPIURL.LOGIN)


func paste(_name: String, content, private = '1', language = "json"):
	var api_request = {
			api_dev_key = dev_api_key,
			api_option = API_OPTIONS_DICT[APIOptions.PASTE],
			api_paste_format = language,
			api_paste_private = private,
			api_paste_name = _name,
			api_paste_code = content,
			api_paste_expire_data = "N"
		}
	if user_api_key:
		api_request.merge({
			api_user_key = user_api_key
		})
	var query: = http_client.query_string_from_dict(
		api_request
	)
	return await _request(query)


func my_pastes(limit=50):
	if limit < 1 or limit > 1000:
		return "Err"
	if not user_api_key:
		return "Err"

	var api_request = {
			api_dev_key = dev_api_key,
			api_user_key = user_api_key,
			api_option = API_OPTIONS_DICT[APIOptions.LIST],
			api_results_limit = limit
	}
	
	var query = http_client.query_string_from_dict(
		api_request
	)
	var res = await _request(query, SupportedAPIURL.PASTE)
	var xml = XMLParser.new()
	xml.open_buffer(res.to_utf8_buffer())
	
	var pastes = []
	var paste_id = -1
	var paste_key = ""
	
	while xml.read() != ERR_FILE_EOF:
		if xml.get_node_type() == xml.NODE_ELEMENT:
			if xml.get_node_name() == "paste":
				pastes.append({})
				paste_id += 1
			paste_key = xml.get_node_name()
		if xml.get_node_type() == xml.NODE_TEXT:
			pastes[paste_id][paste_key] = xml.get_node_data()
		if xml.get_node_type() == xml.NODE_ELEMENT_END:
			paste_key = ""
	
	return pastes

func delete_paste(paste_key):
	var api_request = {
		api_dev_key = dev_api_key,
		api_user_key = user_api_key,
		api_paste_key = paste_key,
		api_option = API_OPTIONS_DICT[APIOptions.DELETE],
	}
	var query = http_client.query_string_from_dict(api_request)
	var res = await _request(query)
	return res

func my_user_details():
	var api_request = {
		api_dev_key = dev_api_key,
		api_user_key = user_api_key,
		api_option = API_OPTIONS_DICT[APIOptions.USER_DETAILS],
	}
	var query = http_client.query_string_from_dict(api_request)
	var res = await _request(query)
	var xml = XMLParser.new()
	xml.open_buffer(res.to_utf8_buffer())
	
	var user = {}
	var user_key = ""
	
	while xml.read() != ERR_FILE_EOF:
		if xml.get_node_type() == xml.NODE_ELEMENT:
			if xml.get_node_name() == "user":
				user_key = ""
				continue
			user_key = xml.get_node_name()
		if xml.get_node_type() == xml.NODE_TEXT:
			user[user_key] = xml.get_node_data()
		if xml.get_node_type() == xml.NODE_ELEMENT_END:
			user_key = ""
	return user
	

func get_private_paste_raw(paste_key: String):
	var api_request = {
			api_dev_key = dev_api_key,
			api_user_key = user_api_key,
			api_paste_key = paste_key,
			api_option = API_OPTIONS_DICT[APIOptions.SHOW_PASTE],
	}
	var query = http_client.query_string_from_dict(api_request)
	var res = await _request(query, SupportedAPIURL.PRIVATE_RAW)
	return res

func get_public_paste_raw(paste_key: String):
	var res = await _request_get(paste_key)
	return res

func _request_get(paste_key, api_url: SupportedAPIURL = SupportedAPIURL.PUBLIC_RAW):
	var url = API_URL_DICT[api_url]
	http_request.request(url+"/"+paste_key, [], HTTPClient.METHOD_GET)
	var res = await http_request.request_completed
	var res_string = PackedByteArray(res[3]).get_string_from_utf8()
	if res[0] or res[1] != 200:
		print("something went wrong!", res.slice(0, 3), res_string)
	return res_string 

func _request(query, api_url: SupportedAPIURL = SupportedAPIURL.PASTE):
	var url = API_URL_DICT[api_url]
	
	http_request.request(url, ["Content-Type: application/x-www-form-urlencoded"], HTTPClient.METHOD_POST, query)
	var res = await http_request.request_completed
	var res_string = PackedByteArray(res[3]).get_string_from_utf8()
	if res[0] or res[1] != 200:
		print("something went wrong!", res.slice(0, 3), res_string)
	return res_string 
