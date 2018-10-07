#Utils.gd

extends Node

#do liczenia powtórzeń
var i = 0
func i():
	i = i+1
	return i - 1

func unsigned(number):
	if(number >= 0):
		return number
	else:
		return -number

#Sprawdzanie czy dany punkt znajduje się na ekranie, gdy opcja "return_side" jest włączona,
#funkcja zwróci z której strony od ekranu jest punkt, w formacie "N" "S" "W" "E". Jeśli obiekt
#jest na ekranie, funkcja zwróci "O".
func is_in_screen(vector, return_side = false):
	var lower = Vector2(0, 0)
	var higher = Vector2(ProjectSettings.get("display/width"),ProjectSettings.get("display/height"))
	#jeśli jest ustawiona główna kamera
	if not(ProjectSettings.get("currentCamera") == null):
		var cam_pos = ProjectSettings.get("currentCamera").get_global_pos()
		lower = Vector2(cam_pos.x, cam_pos.y)
		higher += Vector2(cam_pos.x, cam_pos.y)
		pass
	if((vector.x < higher.x && vector.x > lower.x) && (vector.y < higher.y && vector.y > lower.y)):
		if(return_side == false):
			return true
		else:
			return "O"
	else:
		if(return_side == false):
			return false
		else:
			var side = ""
			if(vector.y < lower.y):
				side += "N"
			if(vector.y > higher.y):
				side += "S"
			if(vector.x < lower.x):
				side += "W"
			if(vector.x > higher.x):
				side += "E"
			return side

#zwraca głównego Noda
func get_main_node():
	var root_node = get_tree().get_root()
	return root_node.get_child(root_node.get_child_count()-1)

#zwraca tablicę z nazwami plików w folderze
func list_files_in_directory(path):
	var files = []
	var dir = Directory.new()
	if(dir.open(path) == OK):
		dir.list_dir_begin()
		while true:
			var file = dir.get_next()
			if file == "":
				break
			elif not file.begins_with("."):
				files.append(file)
		dir.list_dir_end()
	else:
		print("can't list files, there is no folder like "+path)
		return 1;
	return files

#zmienia rodzica noda, nie wywoływać bezpośrednio
func _real_reparent(node, new_parent):
	#tworzy słabe połączenia
	var wr_node = weakref(node)
	var wr_parent = weakref(new_parent)
	#sprawdza czy połączenia istnieją, tzn. czy w międzyczasie wykonywania funkcji nie został usunięty żaden node
	#potrzebne, bo przy call_deferred do funckji może zostać przekazany nieistniejący node
	if(wr_node.get_ref() && wr_parent.get_ref()):
		#jeśli node ma już rodzica
		if(node.get_parent()):
			#jeśli node ma rodzica który nie jest równy nowemu rodzicowi
			if(node.get_parent() != new_parent):
				#usuwanie połączenia rodzic-dziecko
				node.get_parent().remove_child(node)
			#jeśli rodzicem noda jest new_parent, to po co cokolwiek robić?
			else: return
		#dodawanie nowego rodzica
		if(new_parent):
			new_parent.add_child(node)

#zmienia rodzica noda
func reparent(node, new_parent):
	#trzeba wywoływać przez call_deferred bo inaczej wyskakują błędy
	call_deferred("_real_reparent", node, new_parent)
	
#zwraca sekcję z pliku cfg w formie tabeli słownikowej
func get_cfg_file_section(cfg_file, section_name):
	section_name = String(section_name)
	#jeśli sekcja istnieje
	if(cfg_file.has_section(section_name)):
		#pobieranie kluczy sekcji
		var keys = cfg_file.get_section_keys(section_name)
		#tworzenie tabeli którą funkcja później zwróci
		var dictionary = {}
		
		#zapełnianie tabeli danymi
		for key in keys:
			dictionary[key] = cfg_file.get_value(section_name, key)
		return dictionary
	else: return
	
#zwraca odległość między dwoma prostymi równoległymi, przecinającymi podane punkty pod podanym kątem
func get_planes_dist(point_from, point_to, rads):
	var vector_dist = point_to - point_from
	var normal = Vector2(sin(rads), cos(rads))
	var dist = normal.dot(vector_dist)
	return dist
	pass
	
var days_in_months = [
	31,#styczeń
	28,#luty
	31,#marzec
	30,#kwiecień
	31,#maj
	30,#czerwiec
	31,#lipiec
	31,#sierpień
	30,#wrzesień
	31,#październik
	30,#listopad
	31 #grudzień
]

#sprawdza czy rok jest przestępny
func is_year_lap(year):
	if (year%4 == 0 && (year%100 != 0 || year%400 == 0)):
		return true
	else:
		return false

#zwraca datę w tablicy na podstawie unix stampa
func unix_to_date(unix_stamp):
	unix_stamp = int(unix_stamp)
	var date = {
		"year": 1970,
		"month": 1,
		"day": 1,
		"hour": 0,
		"minute": 0,
		"second": 0
	}
	var hour_stamp = unix_stamp % 86400
	var unix_days = ceil(unix_stamp/86400)+1
	
	#obliczanie roku
	while (unix_days >= 365):
		var days_in_year = 365
		if (isYearLap(date.year)):
			days_in_year = 366
		date.year += 1
		unix_days -= days_in_year
		
	#obliczanie miesiąca
	for days_in_month in days_in_months:
		if(unix_days > days_in_month):
			if(days_in_month == 28 && isYearLap(date.year)):
				days_in_month += 1
			unix_days -= days_in_month
			date.month += 1
		else:
			break
	
	#zapisywanie dnia miesiąca z pozostałych dni
	date.day = unix_days
	
	#liczenie godziny, minuty i sekund
	date.hour = floor(hour_stamp/3600)
	date.minute = floor((hour_stamp%3600)/60)
	date.second = hour_stamp%60
	
	return date
