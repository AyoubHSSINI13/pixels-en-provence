extends Node

const SAVE_PATH := "user://save.json"

# ── Définition des objets ──────────────────────────────────────
const ITEMS := {
	"bois":   {"nom": "Bois",   "col": Color("#c87830"), "stackable": true,  "max_stack": 64, "type": "ressource"},
	"pierre": {"nom": "Pierre", "col": Color("#9a9a9a"), "stackable": true,  "max_stack": 64, "type": "ressource"},
	"hache":  {"nom": "Hache",  "col": Color("#a05020"), "stackable": false, "max_stack": 1,  "type": "outil", "arme_sprite": "ax01"},
	"epee":   {"nom": "Épée",   "col": Color("#c0c8e0"), "stackable": false, "max_stack": 1,  "type": "outil", "arme_sprite": "sw01"},
}

const TAILLE_HOTBAR := 9
const TAILLE_INV    := 27   # 3 lignes × 9 colonnes

# ── Identité ──────────────────────────────────────────────────
var nom_village     := ""
var nom_joueur      := ""
var carnation       := 0
var coiffure        := 0
var couleur_cheveux := 0
var tenue           := 0

# ── Temps ─────────────────────────────────────────────────────
var heure  : float = 8.0
var jour   : int   = 1
var saison : int   = 0

# ── Besoins ───────────────────────────────────────────────────
var faim : float = 1.0
var soif : float = 1.0

# ── Spawn override ────────────────────────────────────────────
var spawn_override: Vector2 = Vector2.ZERO
var spawn_override_actif: bool = false

# ── UI State ──────────────────────────────────────────────────
var inventaire_ouvert := false

# ── Inventaire ────────────────────────────────────────────────
# Chaque slot : null (vide) ou {"id": String, "qty": int}
var slots_hotbar:     Array = []
var slots_inventaire: Array = []
var slot_actif: int = 0


func _ready() -> void:
	slots_hotbar.resize(TAILLE_HOTBAR)
	slots_inventaire.resize(TAILLE_INV)


# ── Helpers inventaire ────────────────────────────────────────

func item_actif():
	var s = slots_hotbar[slot_actif]
	return s if s != null else {}


# Ajoute qty unités d'un item. Remplit d'abord les stacks existants,
# puis crée de nouveaux slots (hotbar en priorité, puis inventaire).
# Retourne le nombre d'unités non ajoutées (0 si tout est entré).
func ajouter_item(id: String, qty: int) -> int:
	var max_stack: int = ITEMS[id]["max_stack"] if ITEMS.has(id) else 64
	var reste := qty

	# Remplir stacks existants
	for slots in [slots_hotbar, slots_inventaire]:
		for s in slots:
			if reste <= 0: break
			if s != null and s["id"] == id:
				var espace: int = max_stack - s["qty"]
				var ajout: int  = mini(reste, espace)
				s["qty"] += ajout
				reste    -= ajout

	# Nouveaux slots
	for slots in [slots_hotbar, slots_inventaire]:
		for i in slots.size():
			if reste <= 0: break
			if slots[i] == null:
				var ajout: int = mini(reste, max_stack)
				slots[i] = {"id": id, "qty": ajout}
				reste    -= ajout

	return reste


# ── Sauvegarde ────────────────────────────────────────────────

func sauvegarde_existe() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func sauvegarder() -> void:
	var hotbar_data: Array = []
	for s in slots_hotbar:
		hotbar_data.append({} if s == null else {"id": s["id"], "qty": s["qty"]})

	var inv_data: Array = []
	for s in slots_inventaire:
		inv_data.append({} if s == null else {"id": s["id"], "qty": s["qty"]})

	var data := {
		"nom_village":     nom_village,
		"nom_joueur":      nom_joueur,
		"carnation":       carnation,
		"coiffure":        coiffure,
		"couleur_cheveux": couleur_cheveux,
		"tenue":           tenue,
		"heure":           heure,
		"jour":            jour,
		"saison":          saison,
		"faim":            faim,
		"soif":            soif,
		"slot_actif":      slot_actif,
		"slots_hotbar":    hotbar_data,
		"slots_inventaire": inv_data,
	}
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))


func charger() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var f := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not f:
		return false
	var json := JSON.new()
	if json.parse(f.get_as_text()) != OK:
		return false
	var data: Dictionary = json.get_data()

	nom_village     = data.get("nom_village",     "")
	nom_joueur      = data.get("nom_joueur",       "")
	carnation       = data.get("carnation",        0)
	coiffure        = data.get("coiffure",         0)
	couleur_cheveux = data.get("couleur_cheveux",  0)
	tenue           = data.get("tenue",            0)
	heure           = data.get("heure",            8.0)
	jour            = data.get("jour",             1)
	saison          = data.get("saison",           0)
	faim            = data.get("faim",             1.0)
	soif            = data.get("soif",             1.0)
	slot_actif      = data.get("slot_actif",       0)

	if data.has("slots_hotbar"):
		var arr: Array = data["slots_hotbar"]
		for i in mini(arr.size(), TAILLE_HOTBAR):
			var d: Dictionary = arr[i]
			slots_hotbar[i] = null if d.is_empty() else {"id": d["id"], "qty": d["qty"]}

	if data.has("slots_inventaire"):
		var arr: Array = data["slots_inventaire"]
		for i in mini(arr.size(), TAILLE_INV):
			var d: Dictionary = arr[i]
			slots_inventaire[i] = null if d.is_empty() else {"id": d["id"], "qty": d["qty"]}

	# Migration depuis l'ancien format "ressources"
	if not data.has("slots_hotbar") and data.has("ressources"):
		var res: Dictionary = data["ressources"]
		for key in res:
			if res[key] > 0:
				ajouter_item(key, res[key])

	return true
