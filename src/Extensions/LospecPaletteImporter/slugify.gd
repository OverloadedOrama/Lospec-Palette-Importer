extends Node

## Taken and modified from
## https://github.com/JRiggles/Lospec-Palette-Importer/blob/main/extension/sluggify.lua
## Licensed under MIT

## Mapping of replacement characters
var letters := {
	"áàâǎăãảȧạäåḁāąⱥȁấầẫẩậắằẵẳặǻǡǟȁȃａ": "a",
	"ÁÀÂǍĂÃẢȦẠÄÅḀĀĄȺȀẤẦẪẨẬẮẰẴẲẶǺǠǞȀȂＡ": "A",
	"ḃḅḇƀᵬᶀｂ": "b",
	"ḂḄḆɃƁʙＢ": "B",
	"ćĉčċçḉȼɕｃƇ": "c",
	"ĆĈČĊÇḈȻＣƈ": "C",
	"ďḋḑḍḓḏđɗƌｄᵭᶁᶑȡ": "d",
	"ĎḊḐḌḒḎĐƉƊƋＤᴅᶑȡ": "D",
	"éèêḙěĕẽḛẻėëēȩęɇȅếềễểḝḗḕȇẹệｅᶒⱸ": "e",
	"ÉÈÊḘĚĔẼḚẺĖËĒȨĘɆȄẾỀỄỂḜḖḔȆẸỆＥᴇ": "E",
	"ḟƒｆᵮᶂ": "f",
	"ḞƑＦ": "F",
	"ǵğĝǧġģḡǥɠｇᶃ": "g",
	"ǴĞĜǦĠĢḠǤƓＧɢ": "G",
	"ĥȟḧḣḩḥḫ̱ẖħⱨｈ": "h",
	"ĤȞḦḢḨḤḪĦⱧＨʜ": "H",
	"íìĭîǐïḯĩįīỉȉȋịḭɨiıｉ": "i",
	"ÍÌĬÎǏÏḮĨĮĪỈȈȊỊḬƗİIＩ": "I",
	"ĵɉｊʝɟʄǰ": "j",
	"ĴɈＪᴊ": "J",
	"ḱǩķḳḵƙⱪꝁｋᶄ": "k",
	"ḰǨĶḲḴƘⱩꝀＫᴋ": "K",
	"ĺľļḷḹḽḻłŀƚⱡɫｌɬᶅɭȴ": "l",
	"ĹĽĻḶḸḼḺŁĿȽⱠⱢＬʟ": "L",
	"ḿṁṃɱｍᵯᶆ": "m",
	"ḾṀṂⱮＭᴍ": "M",
	"ńǹňñṅņṇṋṉɲƞｎŋᵰᶇɳȵ": "n",
	"ŃǸŇÑṄŅṆṊṈṉƝȠＮŊɴ": "N",
	"óòŏôốồỗổǒöȫőõṍṏȭȯȱøǿǫǭōṓṑỏȍȏơớờỡởợọộɵｏⱺᴏ": "o",
	"ÓÒŎÔỐỒỖỔǑÖȪŐÕṌṎȬȮȰØǾǪǬŌṒṐỎȌȎƠỚỜỠỞỢỌỘƟＯ": "O",
	"ṕṗᵽ": "p",
	"ṔṖⱣƤＰ": "P",
	"ɋʠｑ": "q",
	"ɊＱ": "Q",
	"ŕřṙŗȑȓṛṝṟɍɽｒᵲᶉɼɾᵳ": "r",
	"ŔŘṘŖȐȒṚṜṞɌⱤＲʀ": "R",
	"śṥŝšṧṡşṣṩșｓßẛᵴᶊʂȿſ": "s",
	"ŚṤŜŠṦṠŞṢṨȘＳẞ": "S",
	"ťṫţṭțṱṯŧⱦƭʈｔẗᵵƫȶ": "t",
	"ŤṪŢṬȚṰṮŦȾƬƮＴᴛ": "T",
	"úùŭûǔůüǘǜǚǖűũṹųūṻủȕȗưứừữửựụṳṷṵʉᶙ": "u",
	"ÚÙŬÛǓŮÜǗǛǙǕŰŨṸŲŪṺỦȔȖƯỨỪỮỬỰỤṲṶṴɄＵ": "U",
	"ṽṿʋｖⱱⱴᴠᶌ": "v",
	"ṼṾƲＶ": "V",
	"ẃẁŵẅẇẉⱳｗẘ": "w",
	"ẂẀŴẄẆẈⱲＷ": "W",
	"ẍẋｘᶍ": "x",
	"ẌẊＸ": "X",
	"ýỳŷÿỹẏȳỷỵɏƴｙẙ": "y",
	"ÝỲŶŸỸẎȲỶỴɎƳＹʏ": "Y",
	"źẑžżẓẕƶȥⱬｚᵶᶎʐʑɀᴢ": "z",
	"ŹẐŽŻẒẔƵȤⱫＺ": "Z",
}


func replace_accents(text: String) -> String:
	var normalized_string := ""
	for character in text:
		var replaced := false
		for accent_chars in letters:
			if character in accent_chars:
				var replacement_char: String = letters[accent_chars]
				normalized_string += replacement_char
				replaced = true
			if replaced:
				break

		if not replaced:  # no replacement_char necessary, append the character as-is
			normalized_string = normalized_string + character
	return normalized_string


func slugify(text: String) -> String:
	var slug := text
	var regex := RegEx.new()
	regex.compile("[\\/ ]+")
	slug = regex.sub(slug, "-", true)  # replace slashes and spaces with dashes "-"
	slug = replace_accents(slug)  # replace all accent characters w/ their 'normal' equiv.
	regex.compile("[^A-Za-z0-9%-]+")
	slug = regex.sub(slug, "", true)  # remove all non-alphanumeric characters
	regex.compile("[%-]+")
	slug = regex.sub(slug, "-", true)  # replace multiple consecutive dashes with a single dash
	regex.compile("^%-+")
	slug = regex.sub(slug, "", true)  # remove leading dashes
	regex.compile("%-+$")
	slug = regex.sub(slug, "", true)  # remove trailing dashes
	slug = slug.to_lower()
	return slug
