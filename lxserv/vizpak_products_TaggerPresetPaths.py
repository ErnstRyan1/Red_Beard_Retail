# python

try:
    import tagger
    tagger.TaggerPresetPaths().add_path("kit_red_beard_retail:Red Beard Presets")

except:
    # Tagger is either not installed, or an older version.
    pass
