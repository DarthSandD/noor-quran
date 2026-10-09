"""Build compact, app-ready data bundles for the Qur'an app from the raw sources in _src/."""
import json, os, urllib.request

SRC = r"C:\Users\USER\quran_app\_src"
OUT = r"C:\Users\USER\quran_app\assets\data"
os.makedirs(OUT, exist_ok=True)


def rd(fn):
    with open(os.path.join(SRC, fn), encoding="utf-8") as f:
        return json.load(f)


def wr(fn, obj):
    p = os.path.join(OUT, fn)
    with open(p, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, separators=(",", ":"))
    sz = os.path.getsize(p)
    print(f"  {fn:24} {sz/1024:8.1f} KB")
    return sz


def api_surahs(fn):
    return rd(fn)["data"]["surahs"]


def flat(fn):
    out = []
    for s in api_surahs(fn):
        for a in s["ayahs"]:
            out.append(a["text"].strip())
    return out


print("Loading sources...")
ar = api_surahs("quran_uthmani_api.json")
id_tr = flat("id_indonesian_api.json")
en_sahih = flat("en_sahih.json")
tafsir_id = flat("id_jalalayn.json")
for nm, arr in [("id", id_tr), ("en_sahih", en_sahih), ("tafsir", tafsir_id)]:
    assert len(arr) == 6236, (nm, len(arr))
print("  all editions = 6236 ayahs OK")


def chapters(lang):
    return rd(f"chapters_{lang}.json")["chapters"]


ch_id = {c["id"]: c for c in chapters("id")}
ch_en = {c["id"]: c for c in chapters("en")}
print("  chapters meta loaded (id/en)")

print("Building quran.json ...")
BASMALAH = "بِسْمِ ٱللَّهِ ٱلرَّحْمَٰنِ ٱلرَّحِيمِ"

_HARAKAT = set("\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652\u0653\u0654\u0655\u0656\u0657\u0658\u0670\u0640"
               "\u06D6\u06D7\u06D8\u06D9\u06DA\u06DB\u06DC\u06DD\u06DE\u06DF\u06E0\u06E1\u06E2\u06E3\u06E4"
               "\u06E5\u06E6\u06E7\u06E8\u06E9\u06EA\u06EB\u06EC\u06ED")
_ALEF_FORMS = {"\u0622", "\u0623", "\u0625", "\u0671"}


def _skeleton(text):
    """Diacritic-free consonant skeleton, with alef forms unified."""
    return "".join("\u0627" if c in _ALEF_FORMS else c for c in text if c not in _HARAKAT)


def _split_basmalah(ayah, basmalah):
    """Remove a leading basmalah, tolerating stray harakat. -> (rest, matched)."""
    skel = _skeleton(basmalah)
    acc = []
    for i, c in enumerate(ayah):
        if c in _HARAKAT:
            continue
        acc.append("\u0627" if c in _ALEF_FORMS else c)
        got = "".join(acc)
        if got == skel:
            j = i + 1
            while j < len(ayah) and ayah[j] in _HARAKAT:
                j += 1
            return ayah[j:].strip(), True
        if not skel.startswith(got):
            return ayah, False
    return ayah, False


surahs = []
gidx = 0
for s in ar:
    n = s["number"]
    arabic_name = s["name"].replace("سُورَةُ ", "").replace("سُورَة ", "").strip()
    ayahs = []
    for a in s["ayahs"]:
        gidx += 1
        t = a["text"].lstrip("\ufeff").strip()
        ayahs.append({
            "n": a["numberInSurah"],
            "t": t,
            "j": a["juz"],
            "p": a["page"],
            "s": 1 if a.get("sajda") else 0,
        })
    # The Uthmani source prepends the basmalah to ayah 1 of surahs 2..114
    # (except At-Tawbah/9). Split it out so the UI renders it as a header and
    # ayah 1 keeps only its own words -- the text itself is unchanged.
    # A few surahs (95, 97) carry a stray shadda in the source basmalah, so the
    # match is done on a diacritic-stripped skeleton rather than by prefix.
    bismillah = 0
    first = ayahs[0]["t"]
    if n != 1 and n != 9:
        rest, matched = _split_basmalah(first, BASMALAH)
        if matched and rest:
            ayahs[0]["t"] = rest
            bismillah = 1
    meta_en = ch_en.get(n, {})
    meta_id = ch_id.get(n, {})
    surahs.append({
        "number": n,
        "name": arabic_name,
        "transliteration": meta_en.get("name_simple") or s["englishName"],
        "name_en": (meta_en.get("translated_name") or {}).get("name") or s["englishNameTranslation"],
        "name_id": (meta_id.get("translated_name") or {}).get("name") or s["englishNameTranslation"],
        "revelation": s["revelationType"],
        "revelationOrder": meta_en.get("revelation_order"),
        "ayahCount": len(s["ayahs"]),
        "start": gidx - len(s["ayahs"]) + 1,
        "bismillah": bismillah,
        "ayahs": ayahs,
    })
assert gidx == 6236, gidx

wr("quran.json", {"meta": {"edition": "quran-uthmani", "ayahCount": 6236, "surahCount": 114}, "surahs": surahs})
wr("t_id.json", id_tr)
wr("t_en.json", en_sahih)
wr("tafsir_id.json", tafsir_id)
wr("translations.json", {
    "editions": [
        {"id": "id.indonesian", "lang": "id", "name": "Kemenag — Bahasa Indonesia", "dir": "ltr"},
        {"id": "en.sahih", "lang": "en", "name": "Saheeh International", "dir": "ltr"},
    ],
    "tafsir": [{"id": "id.jalalayn", "lang": "id", "name": "Tafsir Jalalayn"}],
})

print("Building asma.json ...")
asma_kab = rd("asma_kab.json")["data"]
asma_ad = rd("asma_adiman.json")
id_meaning = {}
for a in asma_ad:
    ms = next((x["text"] for x in a.get("meanings", []) if x["lang"] == "ms"), "")
    id_meaning[a.get("transliteration", "").lower().replace("-", "").replace(" ", "")] = ms
asma = []
for a in asma_kab:
    key = a["transliteration"].lower().replace("-", "").replace(" ", "")
    asma.append({
        "number": a["number"],
        "arabic": a["name"],
        "transliteration": a["transliteration"],
        "en": a["en"]["meaning"],
        "en_desc": a["en"]["desc"],
        "id": id_meaning.get(key, ""),
    })
wr("asma.json", {"items": asma})

print("Building duas.json ...")
duas = rd("hisn_duas.json")
segs = []
for s in duas["segments"]:
    cats = []
    for c in s["categories"]:
        titles = []
        for t in c["titles"]:
            ds = []
            for d in t["duas"]:
                ds.append({
                    "id": d["id"],
                    "arabic": d["arabic"],
                    "latin": d.get("latin") or "",
                    "translation": d.get("translation") or "",
                    "source": d.get("source") or "",
                    "benefits": d.get("benefits") or "",
                })
            titles.append({"name": t["title_name"], "duas": ds})
        cats.append({"name": c["category_name"], "titles": titles})
    segs.append({"name": s["segment_name"], "categories": cats})
wr("duas.json", {"segments": segs})

print("Building reciters.json ...")
rec = rd("mp3q_reciters.json")["reciters"]
radios = rd("mp3q_radios.json")["radios"]
out_rec = []
for r in rec:
    moshafs = []
    for m in r.get("moshaf", []):
        moshafs.append({
            "id": m["id"],
            "name": m["name"],
            "server": m["server"],
            "rewaya": m.get("rewaya_id"),
            "surahTotal": m.get("surah_total", 114),
            "surahList": m.get("surah_list", ""),
        })
    if moshafs:
        out_rec.append({"id": r["id"], "name": r["name"], "letter": r.get("letter", ""), "moshafs": moshafs})
out_rad = [{"id": x["id"], "name": x["name"], "url": x["url"]} for x in radios]
wr("reciters.json", {"reciters": out_rec, "radios": out_rad})

total = sum(os.path.getsize(os.path.join(OUT, f)) for f in os.listdir(OUT))
print(f"\nTOTAL bundle: {total/1024/1024:.2f} MB in {OUT}")
