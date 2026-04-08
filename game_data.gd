extends Node

const SAVE_PATH := "user://save.json"

# ── Identité ──────────────────────────────────────────────────
var nom_village      := ""
var nom_joueur       := ""
var carnation        := 0
var coiffure         := 0
var couleur_cheveux  := 0
var tenue            := 0

# ── Temps ─────────────────────────────────────────────────────
var heure  : float = 8.0   # 0.0 – 24.0
var jour   : int   = 1
var saison : int   = 0     # 0=Printemps 1=Été 2=Automne 3=Hiver

# ── Besoins ───────────────────────────────────────────────────
var faim : float = 1.0     # 1.0 = rassasié, 0.0 = affamé
var soif : float = 1.0

# ── Ressources ────────────────────────────────────────────────
var ressources := {
	"bois":   0,
	"pierre": 0,
	"herbes": 0,
	"baies":  0,
	"eau":    0,
	"viande": 0,
}


# ── Sauvegarde ────────────────────────────────────────────────

func sauvegarde_existe() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func sauvegarder() -> void:
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
		"ressources":      ressources,
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
	if data.has("ressources"):
		for k in data["ressources"]:
			if ressources.has(k):
				ressources[k] = data["ressources"][k]
	return true
